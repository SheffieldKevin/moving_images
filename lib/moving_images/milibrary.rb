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
        interp_dict = { :default => "kCGInterpolationDefault",
                           :none => "kCGInterpolationNone",
                           :low => "kCGInterpolationLow", 
                           :medium => "kCGInterpolationMedium",
                           :high => "kCGInterpolationHigh" }
        # verboseputs(interpdict[@@options[:interpqual]])
        return interp_dict[interp.to_sym]
      end

      # Convert a uti image file type to a file extension.    
      # @param filetype [String, Symbol] The image file type.
      # @return [String] A file extension with the dot.
      def self.get_extension_fromimagefiletype(filetype: 'public.jpeg')
        filetype_dict = { :'public.jpeg' => '.jpg', :'public.png' => '.png',
                  :'com.compuserve.gif' => '.gif',
                  :'public.tiff' => '.tiff', :'public.jpeg-2000' => '.jp2',
                  :'com.apple.icns' => '.icns', :'com.apple.rjpeg' => '.rjpeg',
                  :'com.adobe.photoshop-image' => '.psd' }
        return filetype_dict[filetype.to_sym]
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
        applescript = "tell application \"System Events\"\n" \
        "set p1 to process 1 whose frontmost is true\n" \
        "activate\n" \
        "set f to POSIX path of (choose folder with prompt \"#{message}\")\n" \
        "set frontmost of p1 to true\n" \
        "return f\n" \
        "end tell\n"
        result, _ = Open3.capture2('osascript', '-e', applescript)
        result.chomp
      end

      # Display a dialog asking the user to select a file.    
      # Return the full path to the selected file.    
      # Never use this method in production scripts. This is just a convenience
      # method to use for documentation scripts and while developing scripts.
      # There are issues with the display dialog.
      # @param message [String] The message to display in the choose file dialog
      # @return [String] The path to the file
      def self.request_a_file(message: "Select a file:")
        applescript = "tell application \"System Events\"\n" \
          "set p1 to process 1 whose frontmost is true\n" \
          "activate\n" \
          "set f to POSIX path of (choose file with prompt \"#{message}\")\n" \
          "set frontmost of p1 to true\n" \
          "return f\n" \
          "end tell\n"
        result, _ = Open3.capture2('osascript', '-e', applescript)
        result.chomp
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
                                    importer_object, imageindex: imageindex,
                                    saveresultstype: savemetadataformat,
                                    saveresultsto: savemetadatato)
        smig_commands.add_command(get_properties_command)
        Smig.perform_commands(smig_commands)
      end

      # Calculate the number of command lists to create.    
      # The idea is to be able to distribute work asynchronously, but that there
      # is little point until we have enough items to process to make switching
      # to asynchronous processing effective. If numitems_forasync is left at
      # default of 50 items, then async processing will be triggered when we
      # have 51 items or more to process. With 51 items we will have 2 queues
      # of 26 & 25 items. At 101 items we will have 3 queues of 34,34,33 items,
      # at 151 items we have 4 queues etc of 38, 38, 38, 37
      # @param item_list [Array] A list of items to be processed.
      # @param numitems_forasync [Fixnum] The number of items for async process
      # @return The number of lists to create
      def self.calculate_num_commandlist(item_list, numitems_forasync = 50)
        if item_list[:files].length < numitems_forasync
          return 1
        end
        return (item_list[:files].size+numitems_forasync - 1)/numitems_forasync
      end

      # Split the input list into a list of lists
      # @param input_list [Array] A list of objects
      # @param num_list [Fixnum] The number of lists to split input list into.
      # @return [Array<Array>] An array of an array of items
      def self.splitlist(input_list, num_lists: 4)
        listof_list_offiles = []
        num_lists.times do |index|
          sub_list = { files: [], width: input_list[:width],
                       height: input_list[:height] }
          file_list = input_list[:files]
          file_list.each_index do |i|
            sub_list[:files].push(file_list[i]) if (i % num_lists).eql? index
          end
          listof_list_offiles.push(sub_list)  
        end
        listof_list_offiles
      end

      # Make lists of processing hashes.    
      # This method takes a list of image file paths, it first splits the list
      # into lists of hashes:
      #   !{ width: images_width, height: images_height,
      #      files: list_of_imagefilepaths }
      # where the list of image file paths in the hash is the list of files 
      # which have the width and height in the hash. It takes a bit of time to
      # sort the image files into the different lists, so if you know that
      # all the images have the same dimension, then you can set the
      # assume_images_have_same_dimensions to true which saves lots of time.
      # After that the script then splits any list so that there are no more 
      # than maxlength_forprocessinglist image file paths in each list.
      # @param imagefilelist [Array<Paths>] A list of image file paths.
      # @param assume_images_have_same_dimensions [true, false]
      #   If true method assumes all image files in the list have same dims.
      # @param maxlength_forprocessinglist [Fixnum] Maximum number of files
      #   allowed in each processing list. Default value works well.
      # @return [Array<Hash>] An array of processing lists. Each processing
      #   list is a hash containing three attributes, width, height, and files.
      #   The files attributes is the list of files to be processed.
      def self.make_imagefilelists_forprocessing(imagefilelist: [],
                                    assume_images_have_same_dimensions: true,
                                    maxlength_forprocessinglist: 50)
        # First create all the collected lists, a collected list is one which
        # is a hash with three attributes. A width and height attribute and
        # an attribute which is a list of file paths with those dimensions.
        image_lists = []
        if assume_images_have_same_dimensions
          file_path = File.expand_path(imagefilelist[0])
          dimensions = SpotlightCommand.get_imagedimensions(file_path)
          new_list = []
          imagefilelist.each do |file_path|
            new_list.push(File.expand_path(file_path))
          end
          image_list = { width: dimensions[:width],
                         height: dimensions[:height],
                         files: new_list }
          image_lists.push(image_list)
        else
          image_lists = SpotlightCommand.sort_imagefilelist_bydimension(
                                                                  imagefilelist)
        end

        # Now that the list of file paths to image files are broken up into
        # lists of list of file paths, with each list being a collected list,
        # we now need to break any lists down for asynchronous processing to
        # maximize throughput.
        processlists_ofimages = []
        image_lists.each do |image_list|
          num_lists = MILibrary::Utility.calculate_num_commandlist(image_list,
                                                    maxlength_forprocessinglist)
          new_lists = MILibrary::Utility.splitlist(image_list,
                                                   num_lists: num_lists)
          new_lists.each { |new_list| processlists_ofimages.push(new_list) }
        end
        processlists_ofimages
      end

      # Make an options hash with all attributes specified for scale images.    
      # The parameters scalex, scaley, and outputdir all need to be specified
      # with non nil values. The exportfiletype parameter if left as nil will
      # result in all exported images being exported in the image file format
      # of the first image. The supplied values for the other named parameters
      # represent default values.
      # @param scalex [Float] A floating point number typical range: 0.1 - 4.0
      # @param scalex [Float] A floating point number typical range: 0.1 - 4.0
      # @param outputdir [Path] A path to the directory where files exported to
      # @param exportfiletype [Symbol] The export file type: e.g. "public.tiff"
      # @param quality [Float] The export compression quality. 0.0 - 1.0.
      #    Small file size, low quality 0.1, higher quality & larger file size
      #    use 0.9
      # @param interpqual [Symbol] The scaling interpolation value. Values are:
      #    :default, :low, :medium, :high, :lanczos
      # @param copymetadata [true, false] If true copy metadata to new file.
      # @param assume_images_have_same_dimensions [true, false]. If true don't
      #   check each image file to determine it's file size, use first file to
      #   get image dimensions from and assume all others are the same.
      # @verbose [true, false] Output info about script status.
      def self.make_scaleimages_options(
                                    scalex: nil,
                                    scaley: nil,
                                    outputdir: nil,
                                    exportfiletype: nil,
                                    quality: 0.7,
                                    interpqual: :default,
                                    copymetadata: false,
                                    assume_images_have_same_dimensions: false,
                                    verbose: false)
        { scalex: scalex, scaley: scaley, quality: quality, verbose: verbose,
          copymetadata: copymetadata, outputdir: outputdir,
          exportfiletype: exportfiletype,
          assume_images_have_same_dimensions: assume_images_have_same_dimensions
        }
      end
    end

    # Scale images using the lanczos CoreImage filter.    
    # The input images will all have dimensions described in the file_list
    # hash.
    # @param options [Hash] Configuration options for scaling images
    # @param file_list [Hash] With keys, :width, :height, :files
    # @return [void]
    def self.scale_files_uselanczos(options, file_list)
      fail "No output directory specified." if options[:outputdir].nil?
      outputDirectory = File.expand_path(options[:outputdir])
      FileUtils.mkdir_p(outputDirectory)
      fileList = file_list[:files]
      firstItem = File.expand_path(fileList.first)

      # Create the command list object that we can then add commands to.
      theCommands = CommandModule::SmigCommands.new

      async = false
      unless options[:async].nil?
        theCommands.run_asynchronously = options[:async]
        async = options[:async]
      end

      # Use spotlight to get the image dimensions so we can calculate how
      # big the bitmap contexts need to be.
      # dimensions = SpotlightCommand.get_imagedimensions(firstItem)
      dimensions = { width: file_list[:width], height: file_list[:height] }

      # The export file type will be the same as the input file type so get
      # the fileType from the first file as well.
      if options[:exportfiletype].nil?
        # The export file type is the same as the input file type
        fileType = SpotlightCommand.get_imagefiletype(firstItem)
      else
        fileType = options[:exportfiletype]
      end
      name_extension = Utility.get_extension_fromimagefiletype(
                                                          filetype: fileType)

      if dimensions.size.zero?
        fail "Spotlight couldn't get dimensions from image file: "
      end
      
      # Calculated the dimensions of the scaled image
      scaledWidth = dimensions[:width].to_f * options[:scalex]
      scaledHeight = dimensions[:height].to_f * options[:scaley]

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
      scaleProperty = MIFilterProperty.make_cinumberproperty(key: :inputScale,
                                                    value: options[:scalex])
      theFilter.add_property(scaleProperty)
      sourceImageProperty = MIFilterProperty.make_ciimageproperty(
                                              value: intermediateBitmapObject)
      theFilter.add_property(sourceImageProperty)
      filterChain = MIFilterChain.new(bitmapObject,
                                      filterList: [ theFilter.filterhash ])
      unless options[:softwarerender].nil?
        filterChain.softwarerender = options[:softwarender]
      end
      
      if async
        filterChain.softwarerender = true
      end

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
        fileName = File.basename(filePath, '.*') + name_extension

        # Combine it with the output directory.
        exportPath = File.join(options[:outputdir], fileName)
        
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
        if options[:copymetadata]
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

    # Scale images using CoreGraphics transformations.    
    # Assumes all input images have dimensions specified in file_list hash.
    # @param options [Hash] Configuration options for scaling images
    # @param file_list [Hash] With keys, :width, :height, :files
    # @return [void]
    def self.scale_files_usequartz(options, file_list)
      fail "No output directory specified." if options[:outputdir].nil?
      outputDirectory = File.expand_path(options[:outputdir])
      fileList = file_list[:files]
      fail "No files list." if fileList.nil?
      fail "No files to scale." if fileList.size.zero?

      # make the output directory. The p version of mkdir will make all
      # directories to ensure path is complete. It will also not generate
      # an error if path already exists.
      FileUtils.mkdir_p(outputDirectory)

      # Create the smig commands object
      theCommands = CommandModule::SmigCommands.new
      unless options[:async].nil?
        theCommands.run_asynchronously = options[:async]
      end

      unless options[:savejsonfileto].nil?
        theCommands.informationreturned = :lastcommandresult
        theCommands.saveresultsto = options[:savejsonfileto]
        theCommands.saveresultstype = :jsonfile
      end

      dimensions = { width: file_list[:width], height: file_list[:height] }
      if options[:exportfiletype].nil?
        # The export file type is the same as the file type of the first file.
        firstItem = fileList.first
        fileType = SpotlightCommand.get_imagefiletype(firstItem)
      else
        fileType = options[:exportfiletype]
      end
      name_extension = Utility.get_extension_fromimagefiletype(
                                                        filetype: fileType)
      scaledWidth = dimensions[:width].to_f * options[:scalex]
      scaledHeight = dimensions[:height].to_f * options[:scaley]
      bitmapObject = theCommands.make_createbitmapcontext(addtocleanup: true,
                                    size: { :width => scaledWidth.to_i,
                                            :height => scaledHeight.to_i })
      exporterObject = theCommands.make_createexporter("~/placeholder.jpg",
                                      export_type: fileType, addtocleanup: true)

      destinationRect = MIShapes.make_rectangle(size: dimensions)
      contextTransformations = MITransformations.make_contexttransformation()
      scale = MIShapes.make_point(options[:scalex], options[:scaley])
      MITransformations.add_scaletransform(contextTransformations, scale)

      fileList.each do |filePath|
        importerObject = theCommands.make_createimporter(filePath,
                                                            addtocleanup: false)
        drawImageElement = MIDrawImageElement.new
        drawImageElement.set_imagesource(source_object: importerObject, 
                                         imageindex: 0)
        drawImageElement.contexttransformations = contextTransformations
        drawImageElement.destinationrectangle = destinationRect
        interpQual = Utility.get_cginterpolation(options[:interpqual])
        drawImageElement.interpolationquality = interpQual
        scaleImageCommand = CommandModule.make_drawelement(bitmapObject,
                                          drawinstructions: drawImageElement)
        theCommands.add_command(scaleImageCommand)

        fileName = File.basename(filePath, '.*') + name_extension
        exportPath = File.join(options[:outputdir], fileName)
        setExportPathCommand = CommandModule.make_set_objectproperty(
                                                  exporterObject,
                                                  propertykey: :exportfilepath,
                                                  propertyvalue: exportPath)
        theCommands.add_command(setExportPathCommand)
        addImageCommand = CommandModule.make_addimage(exporterObject,
                                                      bitmapObject)
        theCommands.add_command(addImageCommand)
        if options[:copymetadata]
          copyImagePropertiesCommand = CommandModule.make_copymetadata(
                                              exporterObject,
                                              importersource: importerObject,
                                              importerimageindex: 0,
                                              imageindex: 0)
          theCommands.add_command(copyImagePropertiesCommand)
        end
        
        unless options[:quality].nil?
          setExportCompressionQuality = CommandModule.make_set_objectproperty(
                                        exporterObject,
                                        propertykey: :exportcompressionquality,
                                        propertyvalue: options[:quality])
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
    end # #scale_files_usequartz
    
    # Scale images transformations.    
    # The file_list hash has three keys, width and height properties which all
    # the images files listed in the files property will have dimensions of.
    # Selects one of two methods depending on two of the attributes of the
    # options hash. If :async is false and :interpqual is missing or set to
    # :lanczos then scaling will use the core image lanczos filter to scale
    # the image. Otherwise core graphics will be used to do the image scaling.
    # @param options [Hash] Configuration options for scaling images
    # @param file_list [Hash] With keys, :width, :height, :files
    # @return [void]
    def self.scale_files(options, file_list)
      islanczos = options[:interpqual].nil? || 
                                    options[:interpqual].to_sym.eql?(:lanczos)
      islanczos = false if options[:async]
      if islanczos
        self.scale_files_uselanczos(options, file_list)
      else
        self.scale_files_usequartz(options, file_list)
      end
    end # #scale_files
  end # MILibrary
end # MovingImages

