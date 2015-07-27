# Copyright (c) 2015 Zukini Ltd.

require 'Open3'
require 'JSON'
require 'tmpdir'

include MovingImages::MICGDrawing
include MovingImages::MICoreImage

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
      # @return [String, "Cancel"] The path to the folder or the word Cancel.
      def self.select_a_folder(message: "Select a folder with images:")
        applescript = "tell application \"System Events\"\n" \
        "set p1 to process 1 whose frontmost is true\n" \
        "activate\n" \
        "set f to POSIX path of (choose folder with prompt \"#{message}\")\n" \
        "set frontmost of p1 to true\n" \
        "return f\n" \
        "end tell\n"

        # ignore any error output, only check for a non zero exit value.
        # I just want to make sure error output doesn't end up in result.
        result, eo, exitVal = Open3.capture3('osascript', '-e', applescript)
        unless exitVal.exitstatus.eql? 0
          result = "Cancel"
        end
        result.chomp
      end

      # Display a dialog asking the user to select a file.    
      # Return the full path to the selected file.    
      # Never use this method in production scripts. This is just a convenience
      # method to use for documentation scripts and while developing scripts.
      # There are issues with the display dialog.
      # @param message [String] The message to display in the choose file dialog
      # @return [String] The path to the file or the word Cancel.
      def self.request_a_file(message: "Select a file:")
        applescript = "tell application \"System Events\"\n" \
          "set p1 to process 1 whose frontmost is true\n" \
          "activate\n" \
          "set f to POSIX path of (choose file with prompt \"#{message}\")\n" \
          "set frontmost of p1 to true\n" \
          "return f\n" \
          "end tell\n"

        # ignore any error output, only check for a non zero exit value.
        # I just want to make sure error output doesn't end up in result.
        result, eo, exitVal = Open3.capture3('osascript', '-e', applescript)
        unless exitVal.exitstatus.eql? 0
          result = "Cancel"
        end
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
      # @param input_list [Hash] A hash containing, a width, height & file list
      # @param num_lists [Fixnum] The number of lists to split input list into.
      # @return [Array<Hash>] An array of hashes with same keys as input_list.
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

      # Split the input list into a list of lists.    
      # This function will split the items evenly between the new lists.
      # There will be a maximum of max_number items in each list. The files
      # attribute of the input_list parameter contains the list of items to
      # be split. The method will return an array of hashes.
      # @param input_list [Hash] Contains three attribs, :width, :height, :files
      # @param max_number [Fixnum] Maximum number of items in each list.
      # @return [Array<Hash>] An array of hash objects. :width, :height, :files
      def self.splitlists_intolists_withmaxnum(input_list, max_number = 50)
        num_lists = MILibrary::Utility.calculate_num_commandlist(input_list,
                                                                 max_number)
        new_lists = MILibrary::Utility.splitlist(input_list,
                                                 num_lists: num_lists)
        new_lists
      end

      # Make lists of processing hashes.    
      # This method takes a list of image file paths, it first splits the list
      # into lists of hashes: !{ width: images_width, height: images_height,
      #                          files: list_of_imagefilepaths }
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
          file_path = imagefilelist[0]
          dimensions = SpotlightCommand.get_imagedimensions(file_path)
          new_list = []
          imagefilelist.each do |file_path|
            new_list.push(file_path)
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
          new_lists = self.splitlists_intolists_withmaxnum(image_list,
                                                    maxlength_forprocessinglist)
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
      # @param scaley [Float] A floating point number typical range: 0.1 - 4.0
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
      # @param verbose [true, false] Output info about script status.
      # @return [Hash] The options hash.
      def self.make_scaleimages_options(
                                    scalex: nil,
                                    scaley: nil,
                                    outputdir: nil,
                                    exportfiletype: nil,
                                    quality: 0.7,
                                    interpqual: :default,
                                    copymetadata: false,
                                    assume_images_have_same_dimensions: false,
                                    async: false,
                                    verbose: false)
        { scalex: scalex, scaley: scaley, quality: quality, verbose: verbose,
          copymetadata: copymetadata, outputdir: outputdir,
          exportfiletype: exportfiletype, async: async, interpqual: interpqual,
          assume_images_have_same_dimensions: assume_images_have_same_dimensions
        }
      end

      # Make an options hash with all attributes specified for customcrop.    
      # At least one of left, right, top or bottom needs to be set to a non
      # zero value. The parameter outputdir needs to be set to a non nil value.
      # The exportfiletype parameter if left as nil will
      # result in all exported images being exported in the image file format
      # of the first image. The supplied values for the other named parameters
      # represent default values.
      # @param left [Fixnum] The distance to crop from the left edge in pixels.
      # @param right [Fixnum] The distance to crop from right edge in pixels.
      # @param top [Fixnum] The distance to crop from the top edge in pixels.
      # @param bottom [Fixnum] The distance to crop from bottom edge in pixels.
      # @param outputdir [Path] A path to the directory where files exported to
      # @param exportfiletype [Symbol] The export file type: e.g. "public.tiff"
      # @param quality [Float] The export compression quality. 0.0 - 1.0.
      #    Small file size, low quality 0.1, higher quality & larger file size
      #    use 0.9
      # @param copymetadata [true, false] If true copy metadata to new file.
      # @param assume_images_have_same_dimensions [true, false]. If true don't
      #   check each image file to determine it's file size, use first file to
      #   get image dimensions from and assume all others are the same.
      # @param verbose [true, false] Output info about script status.
      # @return [Hash] The options hash.
      def self.make_customcrop_options(
                                    left: 0,
                                    right: 0,
                                    top: 0,
                                    bottom: 0,
                                    outputdir: nil,
                                    exportfiletype: nil,
                                    quality: 0.7,
                                    copymetadata: false,
                                    assume_images_have_same_dimensions: false,
                                    async: false,
                                    verbose: false)
        { left: left, right: right, top: top, bottom: bottom, verbose: verbose,
          copymetadata: copymetadata, outputdir: outputdir, quality: quality, 
          exportfiletype: exportfiletype, async: async,
          assume_images_have_same_dimensions: assume_images_have_same_dimensions
        }
      end

      # Make an options hash with all attributes specified for custompad.    
      # At least one of left, right, top or bottom needs to be set to a non
      # zero value. The parameter outputdir needs to be set to a non nil value.
      # The exportfiletype parameter if left as nil will
      # result in all exported images being exported in the image file format
      # of the first image. The supplied values for the other named parameters
      # represent default values.
      # @param left [Fixnum] The distance to crop from the left edge in pixels.
      # @param right [Fixnum] The distance to crop from right edge in pixels.
      # @param top [Fixnum] The distance to crop from the top edge in pixels.
      # @param bottom [Fixnum] The distance to crop from bottom edge in pixels.
      # @param red [Float] The red color component of the pad color 0 - 1.
      # @param green [Float] The green color component of the pad color 0 - 1
      # @param blue [Float] The blue color component of the pad color 0 - 1
      # @param scale [Float] The scale to apply to the image before padding.
      # @param outputdir [Path] A path to the directory where files exported to
      # @param exportfiletype [Symbol] The export file type: e.g. "public.tiff"
      # @param quality [Float] The export compression quality. 0.0 - 1.0.
      #    Small file size, low quality 0.1, higher quality & larger file size
      #    use 0.9
      # @param copymetadata [true, false] If true copy metadata to new file.
      # @param assume_images_have_same_dimensions [true, false]. If true don't
      #   check each image file to determine it's file size, use first file to
      #   get image dimensions from and assume all others are the same.
      # @param verbose [true, false] Output info about script status.
      # @return [Hash] The options hash.
      def self.make_custompad_options(
                                    left: 0,
                                    right: 0,
                                    top: 0,
                                    bottom: 0,
                                    red: 0.0,
                                    green: 0.0,
                                    blue: 0.0,
                                    scale: 1.0,
                                    outputdir: nil,
                                    exportfiletype: nil,
                                    quality: 0.7,
                                    copymetadata: false,
                                    assume_images_have_same_dimensions: false,
                                    async: false,
                                    verbose: false)
        { left: left, right: right, top: top, bottom: bottom, 
          red: red, green: green, blue: blue, scale: scale, verbose: verbose,
          copymetadata: copymetadata, outputdir: outputdir, quality: quality, 
          exportfiletype: exportfiletype, async: async,
          assume_images_have_same_dimensions: assume_images_have_same_dimensions
        }
      end

      # Make an options hash with all attributes specified for customaddshadow.    
      # At least one of left, right, top or bottom needs to be set to a non
      # zero value. The parameter outputdir needs to be set to a non nil value.
      # The exportfiletype parameter if left as nil will
      # result in all exported images being exported in the image file format
      # of the first image. The supplied values for the other named parameters
      # represent default values.
      # @param left [Fixnum] The distance to crop from the left edge in pixels.
      # @param right [Fixnum] The distance to crop from right edge in pixels.
      # @param top [Fixnum] The distance to crop from the top edge in pixels.
      # @param bottom [Fixnum] The distance to crop from bottom edge in pixels.
      # @param red [Float] The red color component of the pad color 0 - 1.
      # @param green [Float] The green color component of the pad color 0 - 1
      # @param blue [Float] The blue color component of the pad color 0 - 1
      # @param scale [Float] Scale factor to apply to image before add shadow
      # @param outputdir [Path] A path to the directory where files exported to
      # @param exportfiletype [Symbol] The export file type: e.g. "public.tiff"
      # @param quality [Float] The export compression quality. 0.0 - 1.0.
      #    Small file size, low quality 0.1, higher quality & larger file size
      #    use 0.9
      # @param copymetadata [true, false] If true copy metadata to new file.
      # @param assume_images_have_same_dimensions [true, false]. If true don't
      #   check each image file to determine it's file size, use first file to
      #   get image dimensions from and assume all others are the same.
      # @param verbose [true, false] Output info about script status.
      # @return [Hash] The options hash.
      def self.make_customaddshadow_options(
                                    left: 0,
                                   right: 0,
                                     top: 0,
                                  bottom: 0,
                                     red: 0.0,
                                   green: 0.0,
                                    blue: 0.0,
                                   scale: 1.0,
                               outputdir: nil,
                          exportfiletype: nil,
                                 quality: 0.7,
                            copymetadata: false,
      assume_images_have_same_dimensions: false,
                                   async: false,
                                 verbose: false)
        { left: left, right: right, top: top, bottom: bottom, 
          red: red, green: green, blue: blue, scale: scale, verbose: verbose,
          copymetadata: copymetadata, outputdir: outputdir, quality: quality, 
          exportfiletype: exportfiletype, async: async,
          assume_images_have_same_dimensions: assume_images_have_same_dimensions
        }
      end

      # Make an options hash with all attributes specified for addtextwatermark.    
      # The parameter outputdir needs to be set to a non nil value.
      # The exportfiletype parameter if left as nil will
      # result in all exported images being exported in the image file format
      # of the first image. The supplied values for the other named parameters
      # represent default values.
      # @param text [String] The watermark text to be drawn
      # @param fillcolor [Hash] The hash fill color see {MIColor.make_rgbacolor}
      # @param strokecolor [Hash] The hash stroke color: {MIColor.make_rgbacolor}
      # @param strokewidth [Float] The stroke width to use when stroking text.
      # @param fontsize [nil, Fixnum] If nil then font size will be calculated.
      # @param font [String] The postscript name of the font to draw with.
      # @param scale [Float] Scale the image by scale factor.
      # @param outputdir [Path] A path to the directory where files exported to
      # @param exportfiletype [Symbol] The export file type: e.g. "public.tiff"
      # @param quality [Float] The export compression quality. 0.0 - 1.0.
      #    Small file size, low quality 0.1, higher quality & larger file size
      #    use 0.9
      # @param copymetadata [true, false] If true copy metadata to new file.
      # @param assume_images_have_same_dimensions [true, false]. If true don't
      #   check each image file to determine it's file size, use first file to
      #   get image dimensions from and assume all others are the same.
      # @param verbose [true, false] Output info about script status.
      # @return [Hash] The options hash.
      def self.make_addtextwatermark_options(
                                      text: nil,
                                 fillcolor: nil, # defaults to black opaque
                               strokecolor: nil, # defaults to white opaque
                               strokewidth: 0.0, # 0 means don't stroke.
                                  fontsize: nil, # nil means calculate font size.
                                      font: 'AvenirNext-Heavy',
                                     scale: 1.0, # Image scale factor.
                                 outputdir: nil,
                            exportfiletype: nil,
                                   quality: 0.8,
                              copymetadata: false,
        assume_images_have_same_dimensions: false,
                                     async: false,
                                   verbose: false)
        if fillcolor.nil?
          fillcolor = MIColor.make_rgbacolor(0.0, 0.0, 0.0)
        end
        
        if strokecolor.nil?
          strokecolor = MIColor.make_rgbacolor(1.0, 1.0, 1.0)
        end

        { text: text, fillcolor: fillcolor, strokecolor: strokecolor,
          strokewidth: strokewidth, fontsize: fontsize, font: font,
          outputdir: outputdir, exportfiletype: exportfiletype,
          scale: scale, quality: quality, copymetadata: copymetadata,
          assume_images_have_same_dimensions: assume_images_have_same_dimensions,
          async: async, verbose: verbose
        }
      end

      # Make an options hash with all attributes specified for simplesinglefilter.    
      # The default values represent setting up a CIBloom core image 
      # filter. If the filter is one that takes 0 or 1 inputs then set 
      # inputkey1 and or inputkey2 to nil. 
      # @param cifilter [Symbol, String] The cifilter to apply to the images
      # @param outputdir [Path] A path to the directory where files exported to.
      # @param exportfiletype [Symbol] The export file type: e.g. "public.tiff"
      # @param quality [Float] The export compression quality. 0.0 - 1.0.
      # @param softwarerender [true, false] Should the cifilter be software rendered
      # @param inputkey1 [String] The core image filter input key for the filter
      # @param inputvalue1 [Float] The value associated with inputkey1
      # @param inputkey2 [String] The core image filter input key for the filter
      # @param inputvalue2 [Float] The value associated with inputkey2
      # @return [Hash] The options hash
      def self.make_simplesinglecifilter_options(
                                       cifilter: :CIBloom,
                                      outputdir: nil,
                                 exportfiletype: nil,
                                        quality: 0.8,
                                 softwarerender: false,
                                      inputkey1: :inputRadius,
                                    inputvalue1: 10.0,
                                      inputkey2: :inputIntensity,
                                    inputvalue2: 0.7)
        { cifilter: cifilter, outputdir: outputdir, exportfiletype: exportfiletype,
          softwarerender: softwarerender,
          inputkey1: inputkey1, inputvalue1: inputvalue1,
          inputkey2: inputkey2, inputvalue2: inputvalue2
        }
      end
    end

    # A module of methods used by MILibrary and not really intended for 
    # general use.
    module Private
      # This method assumes the file type has already been applied to
      # the exporter object.
      # The method adds commands to the commands objects. These commands are:
      # 1. Set the property file path
      # 2. Add image
      # 3. Copy metadata if metadata option set, and metadata source defined.
      # 4. Set the export compression quality level.
      # 5. Make the export command.
      # All arguments except metadata_source are required.
      # @param commands [SmigCommands] The object to add the commands to.
      # @param exporter [Hash] The exporter object id.
      # @param image_source [Hash] The image source object id. Likely a bitmap
      # @param file_path [Path] A file path to where image file will be saved.
      # @param options [Hash] The script configuration options.
      # @param metadata_source [Hash] Image importer object id.
      # @return [SmigCommands] The smig commands object with commands added.
      def self.make_commands_forexport(commands: nil, exporter: nil,
                                       image_source: nil, file_path: nil,
                                       options: nil, metadata_source: nil)
        # Set the export file location to the exporter object
        setExportPathCommand = CommandModule.make_set_objectproperty(
                                                  exporter,
                                                  propertykey: :file,
                                                  propertyvalue: file_path)
        commands.add_command(setExportPathCommand)

        # Add the image to the exporter object
        addImageCommand = CommandModule.make_addimage(exporter,
                                                      image_source)
        commands.add_command(addImageCommand)

        # If requested copy the metadata from original file to scaled file.
        if options[:copymetadata] && !metadata_source.nil?
          copyImagePropertiesCommand = CommandModule.make_copymetadata(
                                              exporter,
                                              importersource: metadata_source,
                                              importerimageindex: 0,
                                              imageindex: 0)
          commands.add_command(copyImagePropertiesCommand)
        end

        # Set the export compression quality.
        unless options[:quality].nil?
          setExportCompressionQuality = CommandModule.make_set_objectproperty(
                                        exporter,
                                        propertykey: :exportcompressionquality,
                                        propertyvalue: options[:quality])
          setExportCompressionQuality.add_option(key: :imageindex,
                                                 value: 0)
          commands.add_command(setExportCompressionQuality)
        end

        exportCommand = nil
        if options[:async_export].nil?
          exportCommand = CommandModule.make_export(exporter)
        else
          exportCommand = CommandModule.make_export(exporter,
                                      runasynchronously: options[:async_export])
        end
        commands.add_command(exportCommand)
        commands
      end
      
      # Create shadow colors is used by customaddshadow.   
      # Used to create an array of color hashes where the alpha component
      # changes between each color hash. This creates the shadow colors for
      # one edge of the image.
      # @param options [Hash] The customaddshadow script options.
      # @param width [Fixnum] The width of the shadow for one edge.
      # @param min_alpha [Float] The min alpha component.
      # @param alpha_inc [Float] The alpha component increment.
      # @return [Array<Hash>] An array of color objects.
      def self.create_shadow_colors(options, width, min_alpha, alpha_inc)
        alpha = min_alpha
        theColors = []
        while width > 0
          theColors << { :red => options[:red], :green => options[:green],
                          :blue => options[:blue], :alpha => alpha,
                          :colorcolorprofilename => "kCGColorSpaceSRGB" }
          alpha += alpha_inc
          width = width - 1
        end
        theColors
      end
      
      # Create an object with info about the shadow to be added.    
      # Called from the customaddshadow script.
      # @param options [Hash] The customaddshadow script options.
      # @param shadow_scalar [Fixnum] The width or height of shadow on the side
      # @param min_alpha [Float] The minimum alpha value on image edge.
      # @param alpha_range [Float] The range of values alpha will vary over.
      # @param add1 [true, false] Bottom & left shadow edges need 1 added.
      # @return [Hash] A hash describing the shadow to be drawn for one edge.
      #   has attributes: :hashshadow, :scalar_i, :colors
      def self.create_shadowhash(options, shadow_scalar, min_alpha,
                                 alpha_range, add1: false)
        shadowHash = {}
        extra = add1 ? 1 : 0
        if shadow_scalar <= 0
          shadowHash[:hasshadow] = false
        else
          shadowHash[:hasshadow] = true
          shadowHash[:scalar_i] = shadow_scalar
          alphaDiff = alpha_range / shadow_scalar.to_f
          shadowHash[:colors] = self.create_shadow_colors(options,
                                                          shadow_scalar + extra,
                                                          min_alpha,
                                                          alphaDiff)
        end
        shadowHash
      end

      # Create a shading image from a radial gradient and crop filter.    
      # @param filter_chain [MIFilterChain] Filter chain to add filters to.
      # @return void
      def self.create_cifilter_shadingimage(filter_chain)
        radial_filter = MIFilter.new(:CIRadialGradient,
                                     identifier: :shading_radialgradient)
        large_radius = 400
        small_radius = large_radius * 0.05
        center = MIShapes.make_point(large_radius, large_radius)
        center_property = MIFilterProperty.make_civectorproperty_frompoint(
                                            key: :inputCenter, value: center)
        radial_filter.add_property(center_property)
        inner_radius_property = MIFilterProperty.make_cinumberproperty(
                                      key: :inputRadius0, value: small_radius)
        radial_filter.add_property(inner_radius_property)
        outer_radius_property = MIFilterProperty.make_cinumberproperty(
                                      key: :inputRadius1, value: large_radius)
        radial_filter.add_property(outer_radius_property)
        color0 = MIColor.make_rgbacolor(1, 1, 1, a: 0)
        color0_property = MIFilterProperty.make_cicolorproperty(
                                      key: :inputColor0, value: color0)
        radial_filter.add_property(color0_property)
        color1 = MIColor.make_rgbacolor(0, 0, 0, a: 0.7)
        color1_property = MIFilterProperty.make_cicolorproperty(
                                      key: :inputColor1, value: color1)
        radial_filter.add_property(color1_property)
        filter_chain.add_filter(radial_filter)
        crop_filter = MIFilter.new(:CICrop, identifier: :shading_crop)
        diameter = large_radius * 2
        crop_rect = MIShapes.make_rectangle(width: diameter, height: diameter)
        croprect_property =MIFilterProperty.make_civectorproperty_fromrectangle(
                                      key: :inputRectangle, value: crop_rect)
        crop_filter.add_property(croprect_property)
        inputimage_property = MIFilterProperty.make_ciimageproperty(
                               key: :inputImage,
                               value: { mifiltername: :shading_radialgradient })
        crop_filter.add_property(inputimage_property)
        filter_chain.add_filter(crop_filter)
      end
    end # !{End of Private}

    # Apply a transition filter, starting with source, ends with target.    
    # The options hash contains all the information necessary for performing
    # the transition. Save the results of applying the transition filter to
    # a sequence of image files.
    # @param options [Hash] As created by the dotransition script
    # @return [String] The result of running commands or commands hash.
    def self.dotransition(options)
      theCommands = CommandModule::SmigCommands.new
      if options[:outputdir].nil?
        puts "No output directory specified."
        return
      end

      outputDir = File.expand_path(options[:outputdir])
      FileUtils.mkdir_p(outputDir)

      sourceImagePath = File.expand_path(options[:sourceimage])
      targetImagePath = File.expand_path(options[:targetimage])

      unless File.exists?(sourceImagePath)
        puts "Source file doesn't exist: #{sourceImagePath}"
        return
      end
      unless File.exists?(targetImagePath)
        puts "Target file doesn't exist: #{targetImagePath}"
        return
      end

      dimensions = SpotlightCommand.get_imagedimensions(sourceImagePath)
      # Assume target image dimensions are the same.
      sourceImage = theCommands.make_createimporter(sourceImagePath)
      targetImage = theCommands.make_createimporter(targetImagePath)
      bitmap = theCommands.make_createbitmapcontext(size: dimensions)
      filterChain = MIFilterChain.new(bitmap)
      filterChain.softwarerender = options[:softwarerender]
      # don't add the filter to the filter chain until after the filter 
      # properties have been setup, this is so that the shading image property
      # can be created from filters which will need to precede the transition
      # filter in the filter list.
      filter = MIFilter.make_filter_withname(
                          filtername: options[:transitionfilter],
                          identifier: :maintransitionfilter)
      if filter.nil?
        puts "CoreImage filter name not recognized."
        return
      end

      unless filter.is_a?(MIFilters::MITransitionFilter)
        puts "CoreImage filter is not a transition filter"
        return
      end

      filter_prop = filter.get_property_withunset_value()
      until filter_prop.nil?
        case filter_prop[:cifilterkey]
          when :inputImage
            filter_prop[:cifiltervalue] = sourceImage
          when :inputTargetImage
            filter_prop[:cifiltervalue] = targetImage
          when :inputShadingImage
            Private.create_cifilter_shadingimage(filterChain)
            filter_prop[:cifiltervalue] = { mifiltername: :shading_crop }
          when :inputMaskImage
            if options[:inputMaskImage].nil?
              puts "Missing option: inputMaskImage (file path)"
              return
            end
            mask_path = File.expand_path(options[:inputMaskImage])
            unless File.exists?(mask_path)
              puts "Mask file doesn't exist: #{mask_path}"
              return
            end
            importer_object = theCommands.make_createimporter(mask_path)
            mask_object = theCommands.make_createbitmapcontext(size: dimensions)
            drawImageElement = MIDrawImageElement.new
            drawImageElement.interpolationquality = :kCGInterpolationHigh
            rect = MIShapes.make_rectangle(size: dimensions)
            drawImageElement.destinationrectangle = rect
            drawImageElement.set_imagefile_imagesource(
                                             source_object: importer_object)
            drawImageCommand = CommandModule.make_drawelement(mask_object,
                                          drawinstructions: drawImageElement)
            theCommands.add_command(drawImageCommand)
            filter_prop[:cifiltervalue] = mask_object
          when :inputBacksideImage
            if options[:inputBacksideImage].nil?
              puts "Missing option: inputMaskImage (file path)"
              return
            end
            backside_path = File.expand_path(options[:inputBacksideImage])
            unless File.exists?(backside_path)
              puts "Mask file doesn't exist: #{backside_path}"
              return
            end
            backside_object = theCommands.make_createimporter(backside_path)
            filter_prop[:cifiltervalue] = backside_object
          else
            assigned = MIFilterProperty.set_propertyvalue_fromoptions(
                                                            filter_prop,
                                                            options)
            unless assigned
              puts "Error assigning property #{filter_prop[:cifilterkey]}"
              return
            end #unless
          end # case
        filter_prop = filter.get_property_withunset_value()
      end # until
      if options[:verbose]
        puts JSON.pretty_generate(filter.filterhash)
      end
      filterChain.add_filter(filter)
      filterChainObject = theCommands.make_createimagefilterchain(filterChain)
      type = options[:exportfiletype]
      nameExtension = Utility.get_extension_fromimagefiletype(filetype: type)
      exporter = theCommands.make_createexporter("temp/file/path.tiff",
                                                 export_type: type)
      
      redrawImage = nil
      sourceRectange = nil
      if options[:transitionfilter].to_sym.eql?(:CIPageCurlTransition) ||
         options[:transitionfilter].to_sym.eql?(:CIPageCurlWithShadowTransition)
        drawImageElement = MIDrawImageElement.new
        drawImageElement.set_imagefile_imagesource(source_object: sourceImage)
        sourceRectangle = MIShapes.make_rectangle(size: dimensions)
        drawImageElement.destinationrectangle = sourceRectangle
        redrawImage = CommandModule.make_drawelement(bitmap,
                                          drawinstructions: drawImageElement)
      end
      if options[:verbose]
        puts JSON.pretty_generate(theCommands.commandshash)
      end
      
      options[:count].times do |i|
        unless redrawImage.nil?
          theCommands.add_command(redrawImage)
        end
        time = i.to_f / (options[:count] - 1).to_f
        prop = MIFilterRenderProperty.make_renderproperty_withfilternameid(
                              key: :inputTime,
                            value: time,
                    filtername_id: :maintransitionfilter)
        filterChainRender = MIFilterChainRender.new
        filterChainRender.add_filterproperty(prop)
        unless sourceRectangle.nil?
          filterChainRender.sourcerectangle = sourceRectangle
          filterChainRender.destinationrectangle = sourceRectangle
        end
        renderCommand = CommandModule.make_renderfilterchain(filterChainObject,
                                        renderinstructions: filterChainRender)
        if options[:verbose]
          puts JSON.pretty_generate(renderCommand.commandhash)
        end
        theCommands.add_command(renderCommand)
        fileName = options[:basename] + i.to_s.rjust(3, '0') + nameExtension
        exportPath = File.join(outputDir, fileName)
        Private.make_commands_forexport(commands: theCommands,
                                        exporter: exporter,
                                        image_source: bitmap,
                                        file_path: exportPath,
                                        options: options,
                                        metadata_source: nil)
      end # options[:count].times do
      if options[:generate_json]
        JSON.pretty_generate(theCommands.commandshash)
        # theCommands.commandshash.to_json
      else
        Smig.perform_commands(theCommands)
      end
    end

    # Apply a simplesinglecifilter taking options and applying to the file list.
    # @param options [Hash] See: {Utility.make_simplesinglecifilter_options}
    # @param file_list [Hash] Contains properties width, height, files.
    # @return [String] The result of running the command or the JSON.
    def self.simplesinglecifilter_files(options, file_list)
      if options[:outputdir].nil?
        puts  "Simple single cifilter: output directory not specified"
        return
      end
      
      fileList = file_list[:files]
      if fileList.nil? || fileList.size.zero?
        puts "No files to be processed."
        return
      end
      
      if options[:cifilter].nil?
        puts "No filter specified."
        return
      end
      
      outputDirectory = File.expand_path(options[:outputdir])
      FileUtils.mkdir_p(outputDirectory)
      
      theCommands = CommandModule::SmigCommands.new
      run_async = false
      run_async = options[:async] unless options[:async].nil?
      theCommands.run_asynchronously = run_async
      firstItem = File.expand_path(fileList.first)
      if options[:exportfiletype].nil?
        fileType = SpotlightCommand.get_imagefiletype(firstItem)
      else
        fileType = options[:exportfiletype]
      end
      nameExtension = Utility.get_extension_fromimagefiletype(filetype: fileType)
      
      size = MIShapes.make_size(file_list[:width], file_list[:height])
      sourceBitmap = theCommands.make_createbitmapcontext(addtocleanup: true,
                                                          size: size)
      targetBitmap = theCommands.make_createbitmapcontext(addtocleanup: true,
                                                          size: size)
      filterChain = MIFilterChain.new(targetBitmap)
      filterChain.softwarerender = false
      unless options[:softwarerender].nil?
        filterChain.softwarerender = options[:softwarerender]
      end
      if run_async
        filterChain.softwarerender = true
      end
      filter = MIFilter.new(options[:cifilter])
      unless options[:inputkey1].nil?
        if [:inputvalue1].nil?
          puts "Input key1 provided but no input value1 provided"
          return
        end
        filter_property1 = { cifilterkey: options[:inputkey1],
                             cifiltervalue: options[:inputvalue1] }
        filter.add_property(filter_property1)
      end
      
      unless options[:inputkey2].nil?
        if [:inputvalue2].nil?
          puts "Input key2 provided but no input value2 provided"
          return
        end
        filter_property2 = { cifilterkey: options[:inputkey2],
                             cifiltervalue: options[:inputvalue2] }
        filter.add_property(filter_property2)
      end
      
      filter.add_inputimage_property(sourceBitmap)
      filterChain.add_filter(filter)
      filterObject = theCommands.make_createimagefilterchain(filterChain)

      exporterObject = theCommands.make_createexporter("~/placeholder.jpg",
                                      export_type: fileType, addtocleanup: true)

      destinationRect = MIShapes.make_rectangle(size: size)
      filterRender = MIFilterChainRender.new
      filterRender.destinationrectangle = destinationRect
      filterRender.sourcerectangle = destinationRect

      renderCommand = CommandModule.make_renderfilterchain(filterObject,
                        renderinstructions: filterRender.renderfilterchainhash)

      fileList.each do |filePath|
        importerObject = theCommands.make_createimporter(filePath,
                                                            addtocleanup: false)
        drawImageElement = MIDrawImageElement.new
        drawImageElement.set_imagefile_imagesource(source_object: importerObject, 
                                         imageindex: 0)
        drawImageElement.sourcerectangle = destinationRect
        drawImageElement.destinationrectangle = destinationRect

        drawImageCommand = CommandModule.make_drawelement(sourceBitmap,
                                          drawinstructions: drawImageElement)
        theCommands.add_command(drawImageCommand)
        theCommands.add_command(renderCommand)
        fileName = File.basename(filePath, '.*') + nameExtension
        exportPath = File.join(outputDirectory, fileName)
        # options[:async_export] = true
        Private.make_commands_forexport(commands: theCommands,
                                        exporter: exporterObject,
                                        image_source: targetBitmap,
                                        file_path: exportPath,
                                        options: options,
                                        metadata_source: importerObject)
        closeCommand = CommandModule.make_close(importerObject)
        theCommands.add_command(closeCommand)
      end
      # The full command list has been built up. Nothing has been run yet.
      # Smig.perform_commands sends the commands to MovingImages or alternately
      # we will return the generated json only.
      if options[:generate_json]
        JSON.pretty_generate(theCommands.commandshash)
      else
        Smig.perform_commands(theCommands)
      end
    end

    # Crop the image files list in the files attribute of the file_list hash.    
    # Usually called from the customcrop script, but can be called from
    # anywhere. The options hash is the same as generated by parsing the
    # command line options, and same as that generated from:
    # {Utility.make_customcrop_options}. The file_list hash attribute :files
    # has a list of file paths which are the image files to be processed.
    # @param options [Hash] As created by {Utility.make_customcrop_options}
    # @param file_list [Hash] A hash with attributes, :width, :height, :files
    # return [void]
    def self.customcrop_files(options, file_list)
      width_subtract = options[:left] + options[:right]
      height_subtract = options[:top] + options[:bottom]
      width_remaining = file_list[:width] - width_subtract
      height_remaining = file_list[:height] - height_subtract
      if width_remaining <= 0 || height_remaining <= 0
        puts "Crop - negative size images"
        return
      end

      if options[:outputdir].nil?
        puts "No output directory specified"
        return
      end

      fail "No output directory specified." if options[:outputdir].nil?
      outputDirectory = File.expand_path(options[:outputdir])
      FileUtils.mkdir_p(outputDirectory)
      fileList = file_list[:files]
      
      if fileList.size.zero?
        puts "No files to crop."
        return
      end

      # Create the command list object that we can then add commands to.
      theCommands = CommandModule::SmigCommands.new
      
      theCommands.run_asynchronously = false
      theCommands.run_asynchronously = options[:async] unless options[:async].nil?
      # The export file type will be the same as the input file type so get
      # the fileType from the first file as well.
      firstItem = File.expand_path(fileList.first)
      if options[:exportfiletype].nil?
        # The export file type is the same as the input file type
        fileType = SpotlightCommand.get_imagefiletype(firstItem)
      else
        fileType = options[:exportfiletype]
      end
      nameExtension=Utility.get_extension_fromimagefiletype(filetype: fileType)

      # Calculate the size of the cropped image.
      size = MIShapes.make_size(width_remaining, height_remaining)

      # make the create bitmap context and add it to list of commands.
      # setting addtocleanup to true means when commands have been completed
      # the bitmap context object will be closed in cleanup.
      bitmapObject = theCommands.make_createbitmapcontext(addtocleanup: true,
                                                          size: size)

      exporterObject = theCommands.make_createexporter("~/placeholder.jpg",
                                      export_type: fileType, addtocleanup: true)

      destinationRect = MIShapes.make_rectangle(size: size)
      sourceRect = MIShapes.make_rectangle(size: size,
                                           xloc: options[:left],
                                           yloc: options[:right])
      fileList.each do |filePath|
        importerObject = theCommands.make_createimporter(filePath,
                                                            addtocleanup: false)
        drawImageElement = MIDrawImageElement.new
        drawImageElement.set_imagefile_imagesource(source_object: importerObject, 
                                                   imageindex: 0 )
        drawImageElement.sourcerectangle = sourceRect
        drawImageElement.destinationrectangle = destinationRect

        cropImageCommand = CommandModule.make_drawelement(bitmapObject,
                                          drawinstructions: drawImageElement)
        theCommands.add_command(cropImageCommand)

        fileName = File.basename(filePath, '.*') + nameExtension
        exportPath = File.join(outputDirectory, fileName)
        Private.make_commands_forexport(commands: theCommands,
                                        exporter: exporterObject,
                                        image_source: bitmapObject,
                                        file_path: exportPath,
                                        options: options,
                                        metadata_source: importerObject)
        closeCommand = CommandModule.make_close(importerObject)
        theCommands.add_command(closeCommand)
      end
      # The full command list has been built up. Nothing has been run yet.
      # Smig.perform_commands sends the commands to MovingImages or alternately
      # we will return the generated json only.
      if options[:generate_json]
        JSON.pretty_generate(theCommands.commandshash)
      else
        Smig.perform_commands(theCommands)
      end
    end

    # Pad the image files list in the files attribute of the file_list hash.    
    # Usually called from the custompad script, but can be called from
    # anywhere. The options hash is the same as generated by parsing the
    # command line options, and same as that generated from:
    # {Utility.make_custompad_options}. The file_list hash attribute :files
    # has a list of file paths which are the image files to be processed.
    # @param options [Hash] As created by {Utility.make_custompad_options}
    # @param file_list [Hash] A hash with attributes, :width, :height, :files
    # return [void]
    def self.custompad_files(options, file_list)
      fail "No output directory specified." if options[:outputdir].nil?
      outputDirectory = File.expand_path(options[:outputdir])
      FileUtils.mkdir_p(outputDirectory)
      fileList = file_list[:files]
      fail "No files list." if fileList.nil?

      if fileList.size.zero?
        puts "No files to scale." if options[:verbose]
        return
      end

      # Create the command list object that we can then add commands to.
      theCommands = CommandModule::SmigCommands.new

      theCommands.run_asynchronously = options[:async]
      # The export file type will be the same as the input file type so get
      # the fileType from the first file as well.
      firstItem = File.expand_path(fileList.first)
      if options[:exportfiletype].nil?
        # The export file type is the same as the input file type
        fileType = SpotlightCommand.get_imagefiletype(firstItem)
      else
        fileType = options[:exportfiletype]
      end
      nameExtension=Utility.get_extension_fromimagefiletype(filetype: fileType)

      # Calculate the size of the padded image.
      scaledImageWidth = (options[:scale] * file_list[:width]).to_i
      scaledImageHeight = (options[:scale] * file_list[:height]).to_i
      size = MIShapes.make_size(
                        scaledImageWidth + options[:left] + options[:right],
                        scaledImageHeight + options[:top] + options[:bottom])
      
      # make the create bitmap context and add it to list of commands.
      # setting addtocleanup to true means when commands have been completed
      # the bitmap context object will be closed in cleanup.
      bitmapObject = theCommands.make_createbitmapcontext(addtocleanup: true,
                                                          size: size)

      exporterObject = theCommands.make_createexporter("~/placeholder.jpg",
                                      export_type: fileType, addtocleanup: true)

      destinationRect = MIShapes.make_rectangle(
              size: MIShapes.make_size(scaledImageWidth, scaledImageHeight),
              origin: MIShapes.make_point(options[:left], options[:bottom]))

      fileList.each do |filePath|
        importerObject = theCommands.make_createimporter(filePath,
                                                         addtocleanup: false)
        drawBackgroundElement = MIDrawElement.new(:fillrectangle)
        fillColor = MIColor.make_rgbacolor(options[:red], options[:green],
                                           options[:blue])
        drawBackgroundElement.fillcolor = fillColor
        drawBackgroundElement.rectangle = MIShapes.make_rectangle(size: size)
        drawBackgroundCommand = CommandModule.make_drawelement(bitmapObject,
                                      drawinstructions: drawBackgroundElement)
        theCommands.add_command(drawBackgroundCommand)
        drawImageElement = MIDrawImageElement.new
        drawImageElement.set_imagefile_imagesource(source_object: importerObject, 
                                                      imageindex: 0 )
        drawImageElement.destinationrectangle = destinationRect
        drawImageElement.interpolationquality = :kCGInterpolationHigh
        drawImageCommand = CommandModule.make_drawelement(bitmapObject,
                                          drawinstructions: drawImageElement)
        theCommands.add_command(drawImageCommand)

        fileName = File.basename(filePath, '.*') + nameExtension
        exportPath = File.join(outputDirectory, fileName)
        Private.make_commands_forexport(commands: theCommands,
                                        exporter: exporterObject,
                                        image_source: bitmapObject,
                                        file_path: exportPath,
                                        options: options,
                                        metadata_source: importerObject)
        closeCommand = CommandModule.make_close(importerObject)
        theCommands.add_command(closeCommand)
      end
      # The full command list has been built up. Nothing has been run yet.
      # Smig.perform_commands sends the commands to MovingImages.
      if options[:generate_json]
        JSON.pretty_generate(theCommands.commandshash)
      else
        Smig.perform_commands(theCommands)
      end
    end

    # Add a semi-transparent shadow to images in files attribute of file_list.    
    # Usually called from the customaddshadow script, but can be called from
    # anywhere. The options hash is the same as generated by parsing the
    # command line options, and same as that generated from:
    # {Utility.make_custompad_options}. The file_list hash attribute :files
    # has a list of file paths which are the image files to be processed.
    # @param options [Hash] As created by {Utility.make_custompad_options}
    # @param file_list [Hash] A hash with attributes, :width, :height, :files
    # return [void]
    def self.customaddshadow_files(options, file_list)
      fail "No output directory specified." if options[:outputdir].nil?
      outputDirectory = File.expand_path(options[:outputdir])
      FileUtils.mkdir_p(outputDirectory)
      fileList = file_list[:files]
      fail "No files list." if fileList.nil?

      if fileList.size.zero?
        puts "No files to scale." if options[:verbose]
        return
      end

      # Create the command list object that we can then add commands to.
      theCommands = CommandModule::SmigCommands.new

      theCommands.run_asynchronously = options[:async]
      # The export file type will be set to public.png unless set. At
      # present only 2 choices are provided because the export file type needs
      # to support transparency.
      if options[:exportfiletype].nil?
        # The export file type is the same as the input file type
        fileType = :'public.png'
      else
        fileType = options[:exportfiletype]
      end
      nameExtension=Utility.get_extension_fromimagefiletype(filetype: fileType)

      # Calculate the size of the cropped image.
      scaledImageWidth = (file_list[:width] * options[:scale]).to_i
      scaledImageHeight = (file_list[:height] * options[:scale]).to_i
      size = MIShapes.make_size(
                        scaledImageWidth + options[:left] + options[:right],
                        scaledImageHeight + options[:top] + options[:bottom])
      
      # make the create bitmap context and add it to list of commands.
      # setting addtocleanup to true means when commands have been completed
      # the bitmap context object will be closed in cleanup.
      bitmapObject = theCommands.make_createbitmapcontext(addtocleanup: true,
                                                          size: size)

      exporterObject = theCommands.make_createexporter("~/placeholder.png",
                                      export_type: fileType, addtocleanup: true)

      # Create hashes which describe the drawing of the customshadow on
      # each edge of the image.
      minAlpha = 0.03
      maxAlpha = 0.7
      alphaRange = maxAlpha - minAlpha
      leftShadowhash = Private.create_shadowhash(options,
                                                  options[:left],
                                                  minAlpha,
                                                  alphaRange,
                                                  add1: true)

      rightShadowhash = Private.create_shadowhash(options,
                                                   options[:right],
                                                   minAlpha,
                                                   alphaRange,
                                                   add1: true)

      bottomShadowhash = Private.create_shadowhash(options,
                                                    options[:bottom],
                                                    minAlpha,
                                                    alphaRange,
                                                    add1: true)

      topShadowhash = Private.create_shadowhash(options,
                                                 options[:top],
                                                 minAlpha,
                                                 alphaRange,
                                                 add1: true)

      destinationRect = MIShapes.make_rectangle(
              size: MIShapes.make_size(scaledImageWidth, scaledImageHeight),
              origin: MIShapes.make_point(options[:left], options[:bottom]))

      # We need three different draws to the bitmap context for each image
      # generated. Two of them can be setup before iterating through the files.
      # The bitmap context should be wiped clean to remove old
      # transparency information. So that is a draw fill rectangle covering the
      # full size of the bitmap context of an opaque white color using the
      # copy blend mode. Since that is the same for each image lets create
      # the draw command here.
      drawBackground = MIDrawElement.new(:fillrectangle)
      drawBackground.fillcolor = MIColor.make_rgbacolor(1,1,1)
      drawBackground.rectangle = MIShapes.make_rectangle(size: size)
      drawBackground.blendmode = :kCGBlendModeCopy
      drawBackgroundCommand = CommandModule.make_drawelement(bitmapObject,
                                              drawinstructions: drawBackground)

      # Background draw command is prepped, now prep shadow drawing command.
      shadowDrawElements = MIDrawElement.new(:arrayofelements)
      shadowDrawElements.linewidth = 1.0
      shadowDrawElements.blendmode = :kCGBlendModeCopy
      # Since the shadow is made by drawing a series of lines, we want those
      # lines to be drawn on pixel boundaries. To achieve that we need to offset
      # the drawing by half a pixel.
      contextTransform = MITransformations.make_contexttransformation
      MITransformations.add_translatetransform(contextTransform,
                                               MIShapes.make_point(0.5, 0.5))
      shadowDrawElements.contexttransformations = contextTransform
      
      # OK, the next shit is hard, at least for me. Calculating all the lines
      # to draw to create the shadow.
      bmcWidthM05 = size[:width].to_f #
      bmcHeightM05 = size[:height].to_f #

      if bottomShadowhash[:hasshadow]
        bottomHeight = bottomShadowhash[:scalar_i]
        while bottomHeight >= 0
          pos = bottomHeight.to_f
          scaleFactor = 1.0 - pos / bottomShadowhash[:scalar_i].to_f
          startPoint = MIShapes.make_point(
                      leftShadowhash[:scalar_i].to_f * (1.0 - scaleFactor), pos)
          endPoint = MIShapes.make_point(bmcWidthM05 -
                     rightShadowhash[:scalar_i].to_f * (1.0 - scaleFactor), pos)
          lineDrawElement = MIDrawElement.new(:drawline)
          lineDrawElement.line = MIShapes.make_line(startPoint, endPoint)
          lineDrawElement.strokecolor = bottomShadowhash[:colors][bottomHeight]
          shadowDrawElements.add_drawelement_toarrayofelements(lineDrawElement)
          bottomHeight = bottomHeight.pred
        end
      end

      if leftShadowhash[:hasshadow]
        leftWidth = leftShadowhash[:scalar_i]
        while leftWidth >= 0
          pos = leftWidth.to_f
          scaleFactor = 1.0 - pos / leftShadowhash[:scalar_i].to_f
          startPoint = MIShapes.make_point(pos,
                    (1.0 - scaleFactor) * bottomShadowhash[:scalar_i].to_f)
          endPoint = MIShapes.make_point(pos,
            bmcHeightM05 - (1.0 - scaleFactor) * topShadowhash[:scalar_i].to_f)
          lineDrawElement = MIDrawElement.new(:drawline)
          lineDrawElement.line = MIShapes.make_line(startPoint, endPoint)
          lineDrawElement.strokecolor = leftShadowhash[:colors][leftWidth]
          shadowDrawElements.add_drawelement_toarrayofelements(lineDrawElement)
          leftWidth = leftWidth.pred
        end
      end

      if rightShadowhash[:hasshadow]
        rightWidth = rightShadowhash[:scalar_i]
        while rightWidth >= 0 #
          pos = rightWidth.to_f
          scaleFactor = 1.0 - pos / rightShadowhash[:scalar_i].to_f
          startPoint = MIShapes.make_point(bmcWidthM05 - pos,
                      (1.0 - scaleFactor) * bottomShadowhash[:scalar_i].to_f)
          endPoint = MIShapes.make_point(bmcWidthM05 - pos,
            bmcHeightM05 - (1.0 - scaleFactor) * topShadowhash[:scalar_i].to_f)
          lineDrawElement = MIDrawElement.new(:drawline)
          lineDrawElement.line = MIShapes.make_line(startPoint, endPoint)
          lineDrawElement.strokecolor = rightShadowhash[:colors][rightWidth]
          shadowDrawElements.add_drawelement_toarrayofelements(lineDrawElement)
          rightWidth = rightWidth.pred #
        end
      end

      if topShadowhash[:hasshadow]
        topHeight = topShadowhash[:scalar_i]
        while topHeight >= 0 #
          pos = topHeight.to_f
          scaleFactor = 1.0 - pos / topShadowhash[:scalar_i].to_f
          startPoint = MIShapes.make_point(
                          leftShadowhash[:scalar_i].to_f * (1.0 - scaleFactor),
                          bmcHeightM05 - pos)
          endPoint = MIShapes.make_point(bmcWidthM05 - 
                          rightShadowhash[:scalar_i].to_f * (1.0 - scaleFactor),
                          bmcHeightM05 - pos)
          lineDrawElement = MIDrawElement.new(:drawline)
          lineDrawElement.line = MIShapes.make_line(startPoint, endPoint)
          lineDrawElement.strokecolor = topShadowhash[:colors][topHeight]
          shadowDrawElements.add_drawelement_toarrayofelements(lineDrawElement)
          topHeight = topHeight.pred #
        end
      end

      drawShadowCommand = CommandModule.make_drawelement(bitmapObject,
                                      drawinstructions: shadowDrawElements)

      fileList.each do |filePath|
        importerObject = theCommands.make_createimporter(filePath,
                                                         addtocleanup: false)
        theCommands.add_command(drawBackgroundCommand)
        drawImageElement = MIDrawImageElement.new
        drawImageElement.set_imagefile_imagesource(source_object: importerObject, 
                                                    imageindex: 0)
        drawImageElement.destinationrectangle = destinationRect
        drawImageElement.interpolationquality = :kCGInterpolationHigh
        drawImageCommand = CommandModule.make_drawelement(bitmapObject,
                                          drawinstructions: drawImageElement)
        theCommands.add_command(drawImageCommand)
        theCommands.add_command(drawShadowCommand)
        fileName = File.basename(filePath, '.*') + nameExtension
        exportPath = File.join(outputDirectory, fileName)
        Private.make_commands_forexport(commands: theCommands,
                                        exporter: exporterObject,
                                        image_source: bitmapObject,
                                        file_path: exportPath,
                                        options: options,
                                        metadata_source: importerObject)
        closeCommand = CommandModule.make_close(importerObject)
        theCommands.add_command(closeCommand)
      end
      # The full command list has been built up. Nothing has been run yet.
      # Smig.perform_commands sends the commands to MovingImages, otherwise
      # return the generated json.
      if options[:generate_json]
      	JSON.pretty_generate(theCommands.commandshash)
      else
      	Smig.perform_commands(theCommands)
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
      fail "No files list." if fileList.nil?

      if fileList.size.zero?
        puts "No files to scale." if options[:verbose]
        return
      end

      firstItem = File.expand_path(fileList.first)

      # Create the command list object that we can then add commands to.
      theCommands = CommandModule::SmigCommands.new

      theCommands.run_asynchronously = options[:async]

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

      if options[:async]
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
        drawImageElement.set_imagefile_imagesource(
                                      source_object: importerObject,
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
        exportPath = File.join(outputDirectory, fileName)
        
        # Do all the prep work for saving scaled image to a file.
        Private.make_commands_forexport(commands: theCommands,
                                        exporter: exporterObject,
                                        image_source: bitmapObject,
                                        file_path: exportPath,
                                        options: options,
                                        metadata_source: importerObject)
        # Close the importer
        closeCommand = CommandModule.make_close(importerObject)
        theCommands.add_command(closeCommand)
      end
      # The full command list has been built up. Nothing has been run yet.
      # Smig.perform_commands sends the commands to MovingImages, otherwise
      # return the generated json.
      if options[:generate_json]
      	JSON.pretty_generate(theCommands.commandshash)
      else
      	Smig.perform_commands(theCommands)
      end
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

      if fileList.size.zero?
        puts "No files to scale." if options[:verbose]
        return
      end

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
        drawImageElement.set_imagefile_imagesource(source_object: importerObject, 
                                                   imageindex: 0)
        drawImageElement.contexttransformations = contextTransformations
        drawImageElement.destinationrectangle = destinationRect
        interpQual = Utility.get_cginterpolation(options[:interpqual])
        drawImageElement.interpolationquality = interpQual
        scaleImageCommand = CommandModule.make_drawelement(bitmapObject,
                                          drawinstructions: drawImageElement)
        theCommands.add_command(scaleImageCommand)

        fileName = File.basename(filePath, '.*') + name_extension
        exportPath = File.join(outputDirectory, fileName)

        # Do all the prep work for saving scaled image to a file.
        Private.make_commands_forexport(commands: theCommands,
                                        exporter: exporterObject,
                                        image_source: bitmapObject,
                                        file_path: exportPath,
                                        options: options,
                                        metadata_source: importerObject)
        closeCommand = CommandModule.make_close(importerObject)
        theCommands.add_command(closeCommand)
      end
      # The full command list has been built up. Nothing has been run yet.
      # Smig.perform_commands sends the commands to MovingImages, otherwise
      # return the generated json.
      if options[:generate_json]
      	JSON.pretty_generate(theCommands.commandshash)
      else
      	Smig.perform_commands(theCommands)
      end
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

    # Add a text watermark to the of list in the files taking an options hash.        
    # Usually called from the addtextwatermark script, but can be called from
    # anywhere. The options hash is the same as generated by parsing the
    # command line options, and same as that generated from:
    # {Utility.make_addtextwatermark_options}. The file_list hash attribute :files
    # has a list of file paths which are the image files to be processed.
    # @param options [Hash] As created by {Utility.make_custompad_options}
    # @param file_list [Hash] A hash with attributes, :width, :height, :files
    # return [void]
    def self.addtextwatermark_files(options, file_list)
      fail "No output directory specified." if options[:outputdir].nil?
      outputDirectory = File.expand_path(options[:outputdir])
      FileUtils.mkdir_p(outputDirectory)
      fileList = file_list[:files]
      fail "No files list." if fileList.nil?

      if fileList.size.zero?
        puts "No files to scale." if options[:verbose]
        return
      end

      # Create the command list object that we can then add commands to.
      theCommands = CommandModule::SmigCommands.new

      theCommands.run_asynchronously = options[:async]
      # The export file type will be the same as the input file type so get
      # the fileType from the first file as well.
      firstItem = File.expand_path(fileList.first)
      if options[:exportfiletype].nil?
        # The export file type is the same as the input file type
        fileType = SpotlightCommand.get_imagefiletype(firstItem)
      else
        fileType = options[:exportfiletype]
      end
      nameExtension=Utility.get_extension_fromimagefiletype(filetype: fileType)

      # Calculate the size of the bitmap.
      size = MIShapes.make_size((file_list[:width] * options[:scale]).to_i,
                                (file_list[:height] * options[:scale]).to_i)
      
      # make the create bitmap context and add it to list of commands.
      # setting addtocleanup to true means when commands have been completed
      # the bitmap context object will be closed in cleanup.
      bitmapObject = theCommands.make_createbitmapcontext(addtocleanup: true,
                                                          size: size)

      drawTextElement = MIDrawBasicStringElement.new
      drawTextElement.fillcolor = options[:fillcolor]
      drawTextElement.stringtext = options[:text]
      
      # Basically if stroke with is less than abs(0.1) assume no stroke
      doesDrawStroke = !((options[:strokewidth] * 10.0).to_i.eql?(0))
      if doesDrawStroke
        drawTextElement.stringstrokewidth = options[:strokewidth]
        drawTextElement.strokecolor = options[:strokecolor]
      end

      drawTextElement.postscriptfontname = options[:font]

      textSize = nil
      fontSize = options[:fontsize]
      if options[:fontsize].nil?
        # a nil fontsize indicates we need to calculate the font size to fill.
        # This means I need to calculate space text takes up. We are not dealing
        # with user interface fonts here.
        # Try with a fontsize of 100 points to start with.
        fontSize = 100
        calculateTextSizeCommand = CommandModule.make_calculategraphicsizeoftext(
                                                text: options[:text],
                                  postscriptfontname: options[:font],
                                            fontsize: fontSize)
        text_size = Smig.perform_command(calculateTextSizeCommand)
        text_size = JSON.parse(text_size)
        scale_factor = size[:width] / (text_size['width'] * 2.0)
        fontSize = scale_factor * fontSize
        drawTextElement.fontsize = fontSize
      else
        drawTextElement.fontsize = options[:fontsize]
      end
      calculateTextSizeCommand = CommandModule.make_calculategraphicsizeoftext(
                                              text: options[:text],
                                postscriptfontname: options[:font],
                                          fontsize: fontSize)
      text_size = JSON.parse(Smig.perform_command(calculateTextSizeCommand))
      text_loc = MIShapes.make_point(0.5 * (size[:width] - text_size['width']),
                                     0.5 * (size[:height] + 0.5 * text_size['height']))
      drawTextElement.point_textdrawnfrom = text_loc
      drawTextCommand = CommandModule.make_drawelement(bitmapObject,
                                              drawinstructions: drawTextElement)

      # Make the create a image exporter command and add it to list of commands.
      exporterObject = theCommands.make_createexporter("~/placeholder.jpg",
                                      export_type: fileType, addtocleanup: true)

      destinationRect = MIShapes.make_rectangle(size: size)

      fileList.each do |filePath|
        importerObject = theCommands.make_createimporter(filePath,
                                                         addtocleanup: false)
        drawImageElement = MIDrawImageElement.new
        drawImageElement.set_imagefile_imagesource(source_object: importerObject, 
                                         imageindex: 0)
        drawImageElement.destinationrectangle = destinationRect
        drawImageElement.interpolationquality = :kCGInterpolationHigh
        drawImageCommand = CommandModule.make_drawelement(bitmapObject,
                                          drawinstructions: drawImageElement)
        theCommands.add_command(drawImageCommand)
        theCommands.add_command(drawTextCommand)
        fileName = File.basename(filePath, '.*') + nameExtension
        exportPath = File.join(outputDirectory, fileName)
        Private.make_commands_forexport(commands: theCommands,
                                        exporter: exporterObject,
                                        image_source: bitmapObject,
                                        file_path: exportPath,
                                        options: options,
                                        metadata_source: importerObject)
        closeCommand = CommandModule.make_close(importerObject)
        theCommands.add_command(closeCommand)
      end
      # The full command list has been built up. Nothing has been run yet.
      # Smig.perform_commands sends the commands to MovingImages.
      if options[:generate_json]
        JSON.pretty_generate(theCommands.commandshash)
      else
        Smig.perform_commands(theCommands)
      end
    end
  end # MILibrary
end # MovingImages

