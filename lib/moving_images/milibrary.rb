require 'Open3'
require 'optparse'
require 'pp'
require 'JSON'

# require_relative 'midrawing'
# require_relative 'mifilterchain'
# require_relative 'smigcommands'
# require_relative 'smig'
# require_relative 'smigobjectid'
# require_relative 'spotlight'

module MovingImages
  # A library of functions that do actual stuff
  module Library
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
  end # Library
end # MovingImages

