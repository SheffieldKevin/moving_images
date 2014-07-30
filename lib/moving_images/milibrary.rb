require 'Open3'
require 'optparse'
require 'pp'
require 'JSON'

module MovingImages
  # A library of functions that do actual stuff
  module MILibrary
    # A collection of utility functions.
    module Utility
      # Translate option into a CoreGraphics option    
      # @param interp [String, Symbol] Interpolation default, none, low, ...
      # @return [String] String representation of core graphics value.
      def self.get_cginterpolation(interp)
        interpdict = { :default => "kCGInterpolationDefault",
                           :none => "kCGInterpolationNone",
                           :low => "kCGInterpolationLow", 
                           :medium => "kCGInterpolationMedium",
                           :high => "kCGInterpolationHigh" }
        # verboseputs(interpdict[@@options[:interpqual]])
        return interpdict[interp.to_sym]
      end

      # Display a dialog asking the user to select a folder.    
      # Return the full path to the selected folder.    
      # Never use this method in production scripts. This is just a convenience
      # method to use for documentation scripts and while developing scripts. 
      # There are issues with the dialog that is displayed.
      # @param message [String] The message to display in the choose folder
      #   dialog
      # @return [String] The path to the folder
      def self.select_a_folder(message: "Select a folder with images:")
        applescript = "POSIX path of (choose folder with prompt \"#{message}\")"
        the_command = "osascript -e \'#{applescript}\'"
        the_path = `#{the_command}`
        the_path.chomp!
      end

      # Display a dialog asking the user to select a file.    
      # Return the full path to the selected file.    
      # Never use this method in production scripts. This is just a convenience
      # method to use for documentation scripts and while developing scripts.
      # There are issues with the display dialog.
      # @param message [String] The message to display in the choose file dialog
      # @return [String] The path to the file
      def self.request_a_file(message: "Select a file:")
        applescript = "POSIX path of (choose file with prompt \"#{message}\")"
        the_command = "osascript -e \'#{applescript}\'"
        the_path = `#{the_command}`
        the_path.chomp!
      end

      # Save the metadata about an image from an image file as a json
      # or plist file. Will throw on failure.
      # @param imagefile_path [String] Path to the file containing images
      # @param imageindex [Fixnum] The index of the image in the image file
      # @param savemetadataformat [:jsonfile, :plistfile]
      # @param savemetadatato [String, nil] Path to file to save metadata to. If
      #   the path is nil then the metadata will be saved in the same directory
      #   as the original file.
      # @return [void]
      def self.save_imagemetadata(imagefile_path, imageindex: 0,
                                  savemetadataformat: :jsonfile,
                                  savemetadatato: nil)
        filename = File.basename(imagefile_path, ".*")
        
        extension = ".json"
        extension = ".plist" if savemetadataformat.to_sym.eql?(:plistfile)
        if savemetadatato.nil?
          parent_folder = File.dirname(imagefile_path)
          savemetadatato = File.join(parent_folder, filename + extension)
        end
        smig_commands = CommandModule::SmigCommands.new
        importer_object = smig_commands.make_createimporter(imagefile_path)
        get_properties_command = CommandModule.make_get_objectproperties(
                                    importer_object, imageindex: 0,
                                    saveresultstype: savemetadataformat,
                                    saveresultsto: savemetadatato)
        smig_commands.add_command(get_properties_command)
        Smig.perform_commands(smig_commands)
      end
    end

    # Scale images using the lanczos CoreImage filter.
    # @param theOpts [Hash] Configuring options for scaling images
    # @param fileList [Array] List of paths to scale
    # @return [void]
    def self.scale_files_uselanczos(theOpts, fileList)
      fail "No output directory specified." if theOpts[:outputdir].nil?
      outputDirectory = File.expand_path(theOpts[:outputdir])
      FileUtils.mkdir_p(outputDirectory)

      firstItem = File.expand_path(fileList.first)

      # Create the command list object that we can then add commands to.
      theCommands = CommandModule::SmigCommands.new

      # Use spotlight to get the image dimensions so we can calculate how
      # big the bitmap contexts need to be.
      dimensions = SpotlightCommand.get_imagedimensions(firstItem)
      
      # The export file type will be the same as the input file type so get
      # the fileType from the first file as well.
      fileType = SpotlightCommand.get_imagefiletype(firstItem)
      if dimensions.size.zero?
        fail "Spotlight couldn't get dimensions from image file: "
      end
      
      # Calculated the dimensions of the scaled image
      scaledWidth = dimensions[:width].to_f * theOpts[:scalex]
      scaledHeight = dimensions[:height].to_f * theOpts[:scaley]

      destinationRect = MIShapes.make_rectangle(size: dimensions)

      # make the create bitmap context and add it to list of commands.
      # setting addtocleanup to true means when commands have been completed
      # the bitmap context object will be closed in cleanup.
      bitmapObject = theCommands.make_createbitmapcontext(addtocleanup: true,
                                  size: { :width => scaledWidth.to_i,
                                          :height => scaledHeight.to_i })
      # Make the create exporter object command and add it to commands.
      # setting addtocleanup to true means when commands have been completed
      # the exporter object will be closed in cleanup.
      exporterObject = theCommands.make_createexporter("~/placeholder.jpg",
                                    export_type: fileType, addtocleanup: true)

      # Make the intermediate bitmap context into which the original image
      # will be drawn into without scaling. This context will provide an
      # input image for the Lanczos image filter.
      intermediateBitmapObject = theCommands.make_createbitmapcontext(
                                    size: dimensions, addtocleanup: true)

      # Now building up the image filter chain to scale the image.
      theFilter = MIFilter.new(:CILanczosScaleTransform)
#      theFilter = MIFilter.makefilter(filter: :CILanczosScaleTransform,
#                                inputImage: intermediateBitmapObject)
      scaleProperty = MIFilterProperty.make_cinumberproperty(key: :inputScale,
                                                    value: theOpts[:scalex])
      theFilter.add_property(scaleProperty)
#      MIFilter.addproperty_tocifilter(filterObject: theFilter,
#                                      theProperty: scaleProperty)
      filterChain = MIFilterChain.new(bitmapObject,
                                      filterList: [ theFilter.filterhash ])

      # filterChain description has been created. Now make a create image
      # filter chain command.
      filterChainObject = theCommands.make_createimagefilterchain(
                                          filterChain, addtocleanup: true)

      # Now iterate through each file in the list and process the file.
      fileList.each do |filePath|
        importerObject = theCommands.make_createimporter(filePath,
                                                            addtocleanup: false)
        # Set up the draw image element
        drawImageElement = MIDrawImageElement.new
        drawImageElement.set_imagesource(source_object: importerObject,
                                         imageindex: 0)
        drawImageElement.destinationrectangle = destinationRect
        # Create the draw image command
        drawImageCommand = CommandModule.make_drawelement(
                                          intermediateBitmapObject,
                                          drawinstructions: drawImageElement)
        theCommands.add_command(drawImageCommand)
        # now render filter chain.
        renderFilterChain = MIFilterChainRender.new
        renderDestRect = MIShapes.make_rectangle(
                    size: { :width => scaledWidth, :height => scaledHeight })
        renderFilterChain.destinationrectangle = renderDestRect
        renderFilterChainCommand = CommandModule.make_renderfilterchain(
                                  filterChainObject,
                                  renderinstructions: renderFilterChain)
        theCommands.add_command(renderFilterChainCommand)
        # Get the file name of the input file.
        fileName = File.basename(filePath)
        
        # Combine it with the output directory.
        exportPath = File.join(theOpts[:outputdir], fileName)
        
        # Set the export location to the exporter object
        setExportPathCommand = CommandModule.make_set_objectproperty(
                                                  exporterObject,
                                                  propertykey: :exportfilepath,
                                                  propertyvalue: exportPath)
        theCommands.add_command(setExportPathCommand)
        
        # Add the image to the exporter
        addImageCommand = CommandModule.make_addimage(exporterObject,
                                                      bitmapObject)
        theCommands.add_command(addImageCommand)
        
        # If requested copy the metadata from original file to scaled file.
        if theOpts[:copymetadata]
          copyImagePropertiesCommand = CommandModule.make_copymetadata(
                                              exporterObject,
                                              importersource: importerObject,
                                              importerimageindex: 0,
                                              imageindex: 0)
          theCommands.add_command(copyImagePropertiesCommand)
        end
        
        # make the export command
        exportCommand = CommandModule.make_export(exporterObject)
        theCommands.add_command(exportCommand)
        
        # Close the importer
        closeCommand = CommandModule.make_close(importerObject)
        theCommands.add_command(closeCommand)
      end
      # The full command list has been built up. Nothing has been run yet.
      # Smig.perform_commands sends the commands to MovingImages, and will
      # wait for the commands to be completed in this case.
      Smig.perform_commands(theCommands)
    end

    # Scale images using CoreGraphics transformations    
    # @param theOpts [Hash] Configuring options for scaling images
    # @param fileList [Array] List of paths to scale
    # @param async [true, false] Should processing happen asynchronously.
    # @return [void]
    def self.scale_files_usequartz(theOpts, fileList, async: false)
      fail "No output directory specified." if theOpts[:outputdir].nil?
      outputDirectory = File.expand_path(theOpts[:outputdir])
      fail "No files to scale." if fileList.size.zero?

      # make the output directory. The p version of mkdir will make all
      # directories to ensure path is complete. It will also not generate
      # an error if path already exists.
      FileUtils.mkdir_p(outputDirectory)

      firstItem = File.expand_path(fileList.first)

      theCommands = CommandModule::SmigCommands.new
      theCommands.run_asynchronously = async

      dimensions = SpotlightCommand.get_imagedimensions(firstItem)
      # The export file type is the same as the input file type
      fileType = SpotlightCommand.get_imagefiletype(firstItem)
      fail "Couldn't get dimensions from image file: " if dimensions.size.zero?
      scaledWidth = dimensions[:width].to_f * theOpts[:scalex]
      scaledHeight = dimensions[:height].to_f * theOpts[:scaley]
      bitmapObject = theCommands.make_createbitmapcontext(addtocleanup: true,
                                    size: { :width => scaledWidth.to_i,
                                            :height => scaledHeight.to_i })
      exporterObject = theCommands.make_createexporter("~/placeholder.jpg",
                                      export_type: fileType, addtocleanup: true)

      destinationRect = MIShapes.make_rectangle(size: dimensions)
      contextTransformations = MITransformations.make_contexttransformation()
      scale = MIShapes.make_point(theOpts[:scalex], theOpts[:scaley])
      MITransformations.add_scaletransform(contextTransformations, scale)

      fileList.each do |filePath|
        importerObject = theCommands.make_createimporter(filePath,
                                                            addtocleanup: false)
        drawImageElement = MIDrawImageElement.new
        drawImageElement.set_imagesource(source_bject: importerObject, 
                                         imageindex: 0)
        drawImageElement.contexttransformations = contextTransformations
        drawImageElement.destinationrectangle = destinationRect
        interpQual = Utility.get_cginterpolation(theOpts[:interpqual])
        drawImageElement.interpolationquality = interpQual
        scaleImageCommand = CommandModule.make_drawelement(bitmapObject,
                                          drawinstructions: drawImageElement)
        theCommands.add_command(scaleImageCommand)

        fileName = File.basename(filePath)
        exportPath = File.join(theOpts[:outputdir], fileName)
        setExportPathCommand = CommandModule.make_set_objectproperty(
                                                  exporterObject,
                                                  propertykey: :exportfilepath,
                                                  propertyvalue: exportPath)
        theCommands.add_command(setExportPathCommand)
        addImageCommand = CommandModule.make_addimage(exporterObject,
                                                      bitmapObject)
        theCommands.add_command(addImageCommand)
        if theOpts[:copymetadata]
          copyImagePropertiesCommand = CommandModule.make_copymetadata(
                                              exporterObject,
                                              importersource: importerObject,
                                              importerimageindex: 0,
                                              imageindex: 0)
          theCommands.add_command(copyImagePropertiesCommand)
        end
        
        unless theOpts[:quality].nil?
          setExportCompressionQuality = CommandModule.make_set_objectproperty(
                                        exporterObject,
                                        propertykey: :exportcompressionquality,
                                        propertyvalue: theOpts[:quality])
          setExportCompressionQuality.add_option(key: :imageindex,
                                                 value: 0)
          theCommands.add_command(setExportCompressionQuality)
        end
        exportCommand = CommandModule.make_export(exporterObject)
        theCommands.add_command(exportCommand)
        closeCommand = CommandModule.make_close(importerObject)
        theCommands.add_command(closeCommand)
      end
      # The full command list has been built up. Nothing has been run yet.
      # Smig.perform_commands sends the commands to MovingImages, and if
      # running the commands synchronously then will wait for the commands
      # to be run before returning, if the commands are to be run
      # asynchronously then perform_commands will return quickly and 
      # MovingImages will process the images asynchronously.
      Smig.perform_commands(theCommands)
    end # #scale_images
  end # MILibrary
end # MovingImages

