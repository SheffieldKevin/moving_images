require 'securerandom'

# The MovingImages module wraps all the moving_images gem interface
module MovingImages
  # The command module. Houston, all your commands are belong to us.    
  # All the module methods, and these all begin with "make_" create command
  # objects. The created commands can be added to the list of commands or can be
  # performed immediately by calling Smig.perform_command(...) with the
  # command as the argument.
  module CommandModule

    # The base class for defining commands
    class Command
      
      # The constructor for a MovingImages::Command object
      # @param theCommand [String] The command key which defines the command.
      def initialize(theCommand)
        # The command hash containing the configuration options and command list
        @commandHash = { :command => theCommand }
      end
    
      # Get the command hash, ready to be passed to Smig.perform_commands.
      # @return [Hash] The command hash that the options have been added to.
      def commandhash
        return @commandHash
      end

      # Add an option to the command hash.
      # @param key [String, Symbol] The option to be added to the dictionary
      # @param value [String, Symbol, Fixnum, Float] The value to be assigned
      def add_option(key: nil, value: "")
        @commandHash[key] = value unless key.nil?
      end
    end

    # The base class for defining commands handled by objects
    class ObjectCommand < Command
      # Constructor for ObjectCommand    
      # @param theCommand [String] The name of the command to be performed
      # @param receiverObject [Hash] The object that will handle the command
      # @return SmigObjectCommand command object
      def initialize(theCommand, receiverObject)
        super(theCommand)
        self.add_option(key: :receiverobject, value: receiverObject)
      end

      # Set the receiver for the object.    
      # This method allows the receiver
      # to be overridden at a later time. I use this when I want to send 
      # the command again but to a new object. Be careful though because if the 
      # command to the first object has not yet been performed then this can
      # can change receiver object of the original command.
      # @param receiver [Hash] The new object to handle the command.
      def receiver=(receiver)
        self.add_option(key: :receiverobject, value: receiver)
      end
    end

    # A process movie frames command object    
    # Handled by objects of the movie importer class.    
    class ProcessFramesCommand < ObjectCommand
      # Initialize a new process movie frames command.    
      # @param receiverObject [Hash] The object handling the command.
      # @return [ProcessFramesCommand] The process frames command.
      def initialize(receiverObject)
        super(:processframes, receiverObject)
      end

      # Set the instructions for getting and processing movie frames.    
      # Each instruction contains a frame time, which is the time in the movie
      # from which to obtain the frame, and a command list which is used to
      # process the image frame. Plus a couple of other optional properties.
      # @param instructions [Array<Hash>] Instructions for processing frames
      # @return [Array<Hash>] The instructions added to the process frames command.
      def instructions=(instructions)
        self.add_option(key: :processinstructions, value: instructions)
        instructions
      end

      # Add a processing instruction to the list of instructions.    
      # The instruction contains a frame time, which is the time in the movie
      # from which to obtain the frame, and a command list which is used to
      # process the image frame. Plus a couple of other optional properties.
      # @param insruction [Hash, #instructionshash] The instruction for
      #   processing a movie frame.
      # @return [Hash] The processing instruction hash.
      def add_processinstruction(instruction)
        if instruction.respond_to?("instructionshash")
          instruction = instruction.instructionshash
        end
        if self.commandhash[:processinstructions].nil?
          self.commandhash[:processinstructions] = [ instruction ]
        else
          self.commandhash[:processinstructions].push(instruction)
        end
        instruction
      end

      # Assign the pre-process commands for process frames command. Optional    
      # @param preProcessCommands [#commandshash, Array] The commands to be assigned
      # @return [Array] The preProcessCommands assigned.
      def preprocesscommands=(preProcessCommands)
        if preProcessCommands.respond_to?("commandshash")
          preProcessCommands = preProcessCommands.commandshash[:commands]
        end
        self.add_option(key: :preprocess, value: preProcessCommands)
        preProcessCommands
      end

      # Assign the post-process commands for process frames command. Optional    
      # @param postProcessCommands [#commandshash, Array] The commands to be assigned
      # @return [SmigCommands, Hash] The postProcessCommands assigned.
      def postprocesscommands=(postProcessCommands)
        if postProcessCommands.responds_to?("commandshash")
          postProcessCommands = postProcessCommands.commandshash[:commands]
        end
        self.add_option(key: :postprocess, value: postProcessCommands)
        postProcessCommands
      end

      # Assign the cleanup commands for process frames command. Optional    
      # Will replace any previously assigned cleanup commands.
      # The cleanup commands are meant to be only used for closing objects
      # and removing images from the image collection. The cleanup commands will
      # always be run whether a previous error has occured, and the failure of
      # any cleanup command will not stop following cleanup commands to be run.
      # @param cleanupCommands [SmigCommands, Hash] The commands to be assigned
      # @return [SmigCommands, Hash] The cleanupCommands assigned.
      def cleanupcommands=(cleanupCommands)
        if cleanupCommands.responds_to?("commandshash")
          cleanupCommands = cleanupCommands.commandshash
        end
        self.add_option(key: :cleanupcommands, value: cleanupCommands)
        cleanupCommands
      end
      
      # Add a cleanup command to the list of cleanup commands.    
      # @param cleanupCommand [Command, Hash] The cleanup command to be added.
      # @return [Command, Hash] The cleanup command added to the list.
      def add_tocleanupcommands(cleanupCommand)
        if cleanupCommand.respond_to?("commandhash")
          cleanupCommand = cleanupCommand.commandhash
        end
        if self.commandhash[:cleanupcommands].nil?
          self.commandhash[:cleanupcommands] = [ cleanupCommand ]
        else
          self.commandhash[:cleanupcommands].push(cleanupCommand)
        end
        cleanupCommand
      end
      
      # Add a close object command to the list of cleanup commands.    
      # @param objectToClose [Hash] The object identifying hash.
      # @return [Hash] The object identifier to be closed.
      def add_tocleanupcommands_closeobject(objectToClose)
        closeCommand = CommandModule.make_close(objectToClose)
        self.add_tocleanupcommands(closeCommand)
        objectToClose
      end

      # Add a remove image from collection to list of cleanup commands.    
      # @param imageIdentifier [String] The identifier for the image in collection
      # @return [String] The string used to identify the image.
      def add_tocleanupcommands_removeimage(imageIdentifier)
        rICommand = CommandModule.make_removeimage_fromcollection(imageIdentifier)
        self.add_tocleanupcommands(rICommand)
        imageIdentifier
      end

      # Set whether to create a local context. Optional.    
      # If a local context is created then all commands (pre,post,cleanup and
      # process frame instructions) are run within the local context. This
      # isolates the frame processing from other actions. If not specified
      # then the default is false. The local context will be discarded after
      # cleanup commands along with objects and images it refers to.
      # @param createLocalContext [bool] A bool value, default is false
      # @return [bool] The create local context value assigned.
      def create_localcontext=(createLocalContext)
        self.add_option(key: :localcontext, value: createLocalContext)
        createLocalContext
      end
      
      # Assign the list of video tracks from which to composite frames. Optional.    
      # When each frame is generated, it is composited from the list of video
      # tracks. Default is all tracks. If this property isn't set then the
      # frames will be composited using all video tracks.
      # @param videoTracks [Array<Hash>] An array of track identifiers.
      # @return [Array<Hash>] The list of assigned video tracks.
      def videotracks=(videoTracks)
        self.add_option(key: :tracks, value: videoTracks)
        videoTracks
      end
      
      # Set the image identifier which will be used to identify the frame. Optional    
      # The processing of each frame can use this value, or it can use the
      # imageidentifier specific to the processing of an individual frame. One
      # of the two needs to be defined. If both are set the local imageidentifier
      # takes precedence.
      def imageidentifier=(identifier)
        self.add_option(key: :imageidentifier, value: identifier)
        identifier
      end
    end
    
    # A draw element command object    
    # Handled by a bitmap object, window object, pdf object.    
    class DrawElementCommand < ObjectCommand
      # Initialize a new draw element command object.    
      # @param receiverObject [Hash] Object handling the draw element command
      # @param drawinstructions [Hash, #elementhash] The draw instructions.
      # @param createimage [nil, true, false] Generate an image after drawing.
      # @return [DrawElementCommand] The draw element command object.
      def initialize(receiverObject, drawinstructions: nil, createimage: nil)
        super(:drawelement, receiverObject)
        self.drawinstructions = drawinstructions unless drawinstructions.nil?
        self.createimage = createimage unless createimage.nil?
      end

      # Assign the draw instructions to the draw element command object.
      # @param drawInstructions [Hash, #elementhash] The draw instructions.
      # @return [Hash, #elementhash] The draw instruction hash.
      def drawinstructions=(drawInstructions)
        drawInstructionsHash = drawInstructions
        if drawInstructionsHash.respond_to?("elementhash")
          drawInstructionsHash = drawInstructionsHash.elementhash
        end
        self.add_option(key: :drawinstructions, value: drawInstructionsHash)
        drawInstructions
      end

      # Assign whether an image should be generated after drawing happens.    
      # After drawing finishes this option allows an image to be generated 
      # taken of the context the drawing happened to.
      # @param createImage [true, false] Should we create the image.
      # @return [Bool] the create image value assigned.
      def createimage=(createImage)
        self.add_option(key: :createimage, value: createImage)
        createImage
      end
    end

    # A render imager filter chain command
    class RenderFilterChainCommand < ObjectCommand
      # Initialize a new render filter chain command object
      # @param filterChainObject [Hash] filter chain object that handles render
      # @param instructions [Hash] Render instructions and filter properties
      # @param createimage [Bool] Should an image be created after rendering.
      # @return [RenderFilterChainCommand] The newly created object
      def initialize(filterChainObject, instructions: nil, createimage: nil)
        super(:renderfilterchain, filterChainObject)
        self.renderinstructions = instructions unless instructions.nil?
        self.createimage = createimage unless createimage.nil?
      end
  
      # Set the render instructions which can include filter properties, 
      # destination and source rectangles. The filter properties are applied to
      # the filters in the filter chain before the filter chain is rendered.
      # The source rectangle crops the filter chain rendering and the 
      # destination rectangle specifies where in the render destination the 
      # rendered image should be drawn to.
      # @param renderInstructions [Hash, #renderfilterhchainhash]
      # @return [Hash, #renderfilterhchainhash] The render instructions.
      def renderinstructions=(renderInstructions)
        if renderInstructions.respond_to?("renderfilterchainhash")
          renderInstructions = renderInstructions.renderfilterchainhash
        end
        self.add_option(key: :renderinstructions, value: renderInstructions)
        renderInstructions
      end
      
      # Assign whether an image should be generated after drawing happens.    
      # After drawing finishes this option allows an image to be generated 
      # taken of the context the drawing happened to.
      # @param createImage [true, false] Should we create the image.
      # @return [Bool] the create image value assigned.
      def createimage=(createImage)
        self.add_option(key: :createimage, value: createImage)
        createImage
      end
    end

    # Make a create importer command object.    
    # @param imageFilePath [String] A path to an image file
    # @param name [String] The name of the object to be created
    # @param pathsubstitutionkey [String, Symbol] Get file path from variables.
    # @return [Command] The command that create the importer
    def self.make_createimporter(imageFilePath, name: nil,
                                 pathsubstitutionkey: nil)
      theCommand = Command.new(:create)
      theCommand.add_option(key: :objecttype, value: :imageimporter)
      theCommand.add_option(key: :file, value: imageFilePath)
      theCommand.add_option(key: :objectname, value: name) unless name.nil?
      unless pathsubstitutionkey.nil?
        theCommand.add_option(key: :pathsubstitution, value: pathsubstitutionkey)
      end
      theCommand
    end


    # Make a create a movie importer command object
    # @param imageFilePath [String] A path to the movie file
    # @param name [String] The name of the object to be created
    # @param pathsubstitutionkey [String, Symbol] Get file path from variables.
    # @return [Command] The command that create the importer
    def self.make_createmovieimporter(movieFilePath, name: nil,
                                      pathsubstitutionkey: nil)
      theCommand = Command.new(:create)
      theCommand.add_option(key: :objecttype, value: :movieimporter)
      theCommand.add_option(key: :file, value: movieFilePath)
      theCommand.add_option(key: :objectname, value: name) unless name.nil?
      unless pathsubstitutionkey.nil?
        theCommand.add_option(key: :pathsubstitution, value: pathsubstitutionkey)
      end
      theCommand
    end

    # Make a create bitmap context command    
    # The preset can be any of:    
    # AlphaOnly8bpcInt Gray8bpcInt Gray16bpcInt Gray32bpcFloat
    # AlphaSkipFirstRGB8bpcInt AlphaSkipLastRGB8bpcInt
    # AlphaPreMulFirstRGB8bpcInt AlphaPreMulLastRGB8bpcInt
    # AlphaPreMulLastRGB16bpcInt AlphaSkipLastRGB16bpcInt
    # AlphaSkipLastRGB32bpcFloat AlphaPreMulLastRGB32bpcFloat CMYK8bpcInt
    # CMYK16bpcInt CMYK32bpcFloat    
    # The color profile must match the color space, rgb profiles for a rgb
    # color space, and a grayscale profile for a grayscale color space.
    # The default rgb profile name is: kCGColorSpaceSRGB and a common
    # alternative is: kCGColorSpaceGenericRGB
    # @param width [Fixnum, Float] The width of the bitmap context to be created
    # @param height [Fixnum, Float] Height of the bitmap context to be created.
    # @param size [Hash] A size hash. Size of bitmap. See {MIShapes.make_size}
    # @param preset [String, Symbol] Preset used to create the bitmap context.
    # @param profile [nil, String, Symbol] Name of a color profile to use.
    # @param name [String] The name of the object to be created.
    # @return [Command] The command to create the bitmap object
    def self.make_createbitmapcontext(width: 800, height: 600,
                                      size: nil,
                                      preset: :AlphaPreMulFirstRGB8bpcInt,
                                      profile: nil,
                                      name: nil)
      the_command = Command.new(:create)
      the_command.add_option(key: :objecttype, value: :bitmapcontext)
      the_command.add_option(key: :objectname, value: name) unless name.nil?
      if size.nil?
        the_command.add_option(key: :width, value: width)
        the_command.add_option(key: :height, value: height)
      else
        the_command.add_option(key: :size, value: size)
      end
      unless profile.nil?
        the_command.add_option(key: :colorprofile, value: profile)
      end
      the_command.add_option(key: :preset, value: preset)
      the_command
    end

    # Make a create window context command
    # @param width [Fixnum, Float] The content width of the window to be created
    # @param height [Fixnum, Float] Content height of the window to be created.
    # @param xloc [Fixnum, Float] x position of bottom left corner of window
    # @param yloc [Fixnum, Float] y position of bottom left corner of window
    # @param rect [Hash] A representation of a rect {MIShapes.make_rectangle}
    # @param borderlesswindow [true, false] Should the window be borderless?
    # @param name [String] The name of the object to be created.
    # @return [Command] The command to create a window context
    def self.make_createwindowcontext(rect: nil, width: 800, height: 600,
                                      xloc: 100, yloc: 100,
                                      borderlesswindow: false, name: nil)
      theCommand = Command.new(:create)
      theCommand.add_option(key: :objecttype, value: :nsgraphicscontext)
      theCommand.add_option(key: :objectname, value: name) unless name.nil?
      if rect.nil?
        theCommand.add_option(key: :width, value: width)
        theCommand.add_option(key: :height, value: height)
        theCommand.add_option(key: :x, value: xloc)
        theCommand.add_option(key: :y, value: yloc)
      else
        theCommand.add_option(key: :rect, value: rect)
      end
      theCommand.add_option(key: :borderlesswindow, value: borderlesswindow)
      theCommand
    end

    # Make a create image exporter object command
    # @param exportFilePath [String] Path to the file where image exported to
    # @param export_type [String] The uti export file type.
    # @param name [String] The name of the image exporter object to create.
    # @param pathsubstitutionkey [String, Symbol] Get file path from variables dict
    # @return [Command] The command to create an image exporter object
    def self.make_createexporter(exportFilePath, export_type: "public.jpeg",
                                 name: nil, pathsubstitutionkey: nil)
      theCommand = Command.new(:create)
      theCommand.add_option(key: :objecttype, value: :imageexporter)
      theCommand.add_option(key: :file, value: exportFilePath)
      theCommand.add_option(key: :utifiletype, value: export_type)
      theCommand.add_option(key: :objectname, value: name) unless name.nil?
      unless pathsubstitutionkey.nil?
        theCommand.add_option(key: :pathsubstitution, value: pathsubstitutionkey)
      end
      theCommand
    end

    # Make a create image filter chain object command
    # @param filterChain [Hash, #filterchainhash] Filter chain description
    # @param name [String] The name of the image filter chain object to create
    # @return [Command] A command to create an image filter chain object
    def self.make_createimagefilterchain(filterChain, name: nil)
      theCommand = Command.new(:create)
      theCommand.add_option(key: :objecttype, value: :imagefilterchain)
      if filterChain.respond_to? "filterchainhash"
        filterChain = filterChain.filterchainhash
      end
      theCommand.add_option(key: :imagefilterchaindict, value: filterChain)
      theCommand.add_option(key: :objectname, value: name) unless name.nil?
      theCommand
    end

    # Make a create PDF Context object command.
    # The PDF file will be finalized with everything drawn only when the
    # PDF context object is closed. Initialize the create pdf context command    
    # If filepath is nil when SmigCreatePDFContext is initialized then the file
    # option needs to be set before the command is sent to be performed. The
    # file can be set using:    
    # makePDFContextCommand.add_option(key: :file, value: filePath)
    # @param width [Fixnum, Float] The width of the pdf context to be created.
    # @param height [Fixnum, Float] The height of the pdf context to be created.
    # @param filepath [String, nil] The path to where the file will be created.
    # @param name [String] The name of the pdf context object to create.
    # @return [Command] A command to create a pdf context object
    def self.make_createpdfcontext(size: nil, width: 480, height: 640,
                                   filepath: nil, name: nil)
      theCommand = Command.new(:create)
      theCommand.add_option(key: :objecttype, value: :pdfcontext)
      if size.nil?
        theCommand.add_option(key: :width, value: width)
        theCommand.add_option(key: :height, value: height)
      else
        theCommand.add_option(key: :size, value: size)
      end
      theCommand.add_option(key: :objectname, value: name) unless name.nil?
      theCommand.add_option(key: :file, value: filepath) unless filepath.nil?
      theCommand
    end

    # Get a property of the moving images framework or a base class type.
    # Some properties require an extra option. For example the filter 
    # properties of a filter, requires a filter name option to get the filter 
    # properties of a specific filter or if requesting the list of filters that 
    # belong to a specific category.    
    #     getFilterPropertiesCommand.add_option(key: :filtername,
    #                                           value: "CIBoxBlur")    
    # or    
    #     getFiltersInCategory.add_option(key: :filtercategory, 
    #                                     value: "CICategoryBlur")    
    # Initialize a get non object property command.
    # @param property [String, Symbol] The property to get.
    # @param type [String, Symbol, nil] Optional class type to get property from
    # @return [Command] The get non object property command.
    def self.make_get_nonobjectproperty(property: :numberofobjects, type: nil)
      theCommand = Command.new(:getproperty)
      theCommand.add_option(key: :propertykey, value: property)
      theCommand.add_option(key: :objecttype, value: type) unless type.nil?
      theCommand
    end

    # Make a calculate the graphic size of text command.    
    # The minimum needed for this command to function is the text and user 
    # interface font to be specified. Alternate to specifying the user interface 
    # font, you can specify the postscript font name and a font size as well as 
    # the text. If using the user interface font you can override its built in 
    # font size by specifying the font size.
    # @param text [String] The text to be measured how much space it takes
    # @param postscriptfontname [String, Symbol, nil] The post script font name
    # @param userinterfacefont [String,Symbol,nil] User interface name font name
    # @param fontsize [Fixnum, Float, nil] The font size.
    # @return [Command] The calculate graphic size of text command
    def self.make_calculategraphicsizeoftext(
                                         text: "How long is a piece of string",
                                         postscriptfontname: nil,
                                         userinterfacefont: nil,
                                         fontsize: nil)
      theCommand = Command.new(:calculategraphicsizeoftext)
      theCommand.add_option(key: :objecttype, value: :bitmapcontext)
      theCommand.add_option(key: :getdatatype, value: :dictionaryobject)
      dict = { :stringtext => text }
      unless postscriptfontname.nil?
        dict[:postscriptfontname] = postscriptfontname
      end

      unless userinterfacefont.nil?
        dict[:userinterfacefont] = userinterfacefont
      end

          
      unless fontsize.nil?
        dict[:fontsize] = fontsize
      end
    
      theCommand.add_option(key: :saveresultstype, value: :jsonstring)
      theCommand.add_option(key: :inputdata, value: dict)
      theCommand
    end

    # Make a get object property command.    
    # A few properties require an extra option to be specified to provide
    # context for the get property option. These can be added using the
    # add_option method. The index of an image within a image importer object
    # is sometimes needed. The image index defaults to 0 if unspecified.
    # @param receiverObject [Hash] The object to get the property from
    # @param property [String, Symbol] The property to get
    # @param imageindex [Fixnum, nil] The image index, optional.
    # @return [ObjectCommand] The object get property command
    def self.make_get_objectproperty(receiverObject, property: :objecttype,
                                     imageindex: nil)
      theCommand = ObjectCommand.new(:getproperty, receiverObject)
      theCommand.add_option(key: :propertykey, value: property)
      unless imageindex.nil?
        theCommand.add_option(key: :imageindex, value: imageindex)
      end
      theCommand
    end

    # Make a get object properties command
    # @param receiverObject [Hash] The object to get the properties from
    # @param imageindex [Fixnum, nil] The image index, optional.
    # @param saveresultstype [String, Symbol] :jsonstring, :jsonfile, 
    #   :propertyfile, :dictionaryobject
    # @param saveresultsto [String] The path to json or property list file.
    # @return [ObjectCommand] The get object properties command.
    def self.make_get_objectproperties(receiverObject,
                                       imageindex: nil,
                                       saveresultstype: :jsonstring,
                                       saveresultsto: nil)
      theCommand = ObjectCommand.new(:getproperties, receiverObject)
      unless imageindex.nil?
        theCommand.add_option(key: :imageindex, value: imageindex)
      end

      theCommand.add_option(key: :saveresultstype, value: saveresultstype)
      # The saveresultsto option is only relevant if saveresultstype is set
      # to one of :jsonfile or :propertyfile.
      unless saveresultsto.nil?
        theCommand.add_option(key: :saveresultsto, value: saveresultsto)
      end
      theCommand
    end

    # Make a set property command.    
    # If setting property values for images in an image exporter object then it
    # will also be necessary to add a image index option to specify a specific 
    # image in the exporter. The image index defaults to 0 if unspecified.    
    # set_imagepropertycommand.add_option(key: :imageindex,
    #                                     value: imageindex)
    # @param receiver_object [Hash] The object to set the property of
    # @param propertykey [String, Symbol] The property to be set.
    # @param propertyvalue [String,Symbol,Fixnum,Float,Hash] Value to be set
    # @param imageindex [nil, Fixnum] nil means no index.
    # @return [ObjectCommand] The set property object command.
    def self.make_set_objectproperty(receiver_object, propertykey: nil,
                                     propertyvalue: nil, imageindex: nil)
      theCommand = ObjectCommand.new(:setproperty, receiver_object)
      unless propertykey.nil?
        theCommand.add_option(key: :propertykey, value: propertykey)
      end
      unless propertyvalue.nil? 
        theCommand.add_option(key: :propertyvalue, value: propertyvalue)
        if propertyvalue.is_a?(Hash)
          theCommand.add_option(key: :getdatatype, value: :dictionaryobject)
        end
      end
      unless imageindex.nil?
        theCommand.add_option(key: :imageindex, value: imageindex)
      end
      theCommand
    end

    # Set the export path object property.    
    # Applies only to the exporter object. One of propertyvalue or
    # pathsubsitutionkey needs to be set. If both are set then the substituted 
    # path overrides. The substituted path is obtained from the contexts
    # variables dictionary using the pathsubstitutionkey.
    # @param receiver_object [Hash] The object to set the property of
    # @param propertyvalue [String,Symbol] The path to be set.
    # @param pathsubstitutionkey [String,Symbol] The key into the variables dict.
    # @return [ObjectCommand] The set export path property command.
    def self.make_set_object_exportpathproperty(receiver_object,
                                                propertyvalue: nil,
                                                pathsubstitutionkey: nil)
      theCommand = ObjectCommand.new(:setproperty, receiver_object)
      theCommand.add_option(key: :propertykey, value: :exportfilepath)

      unless pathsubstitutionkey.nil?
        theCommand.add_option(key: :pathsubstitution, value: pathsubstitutionkey)
      end
      if propertyvalue.nil?
        theCommand.add_option(key: :propertyvalue, value: "")
      else
        theCommand.add_option(key: :propertyvalue, value: propertyvalue)
      end
      theCommand
    end

    # Make a set properties command.    
    # If setting preoperties for images in an image exporter object then it
    # will also be necessary to add a image index option to specify a specific 
    # image in the exporter. The image index defaults to 0 if unspecified.
    # @param receiver_object [Hash] The object to set the properties of
    # @param properties [Hash] hash object to be assigned
    # @param imageindex [nil, Fixnum] nil means no index
    # @return [ObjectCommand] The set property object command.
    def self.make_set_objectproperties(receiver_object, properties,
                                       imageindex: nil)
      fail "properties needs to be a hash" unless properties.is_a?(Hash)
      the_command = ObjectCommand.new(:setproperties, receiver_object)
      the_command.add_option(key: :getdatatype, value: :dictionaryobject)
      the_command.add_option(key: :inputdata, value: properties)
      unless imageindex.nil?
        the_command.add_option(key: :imageindex, value: imageindex)
      end
      the_command
    end

    # Make a copy metadata command.    
    # Copy metadata from an image importer for an image at index to the
    # image in the exporter receiver object.
    # @param receiver_object [Hash] The object to set the property of
    # @param importersource [Hash] The image importer object
    # @param importerimageindex [Fixnum] The image index in the image importer
    # @param imageindex [Fixnum] The exporter image index to receive metadata
    # @return [ObjectCommand] The copy metadata command.
    def self.make_copymetadata(receiver_object, importersource: nil, 
                                importerimageindex: 0, imageindex: 0)
      theCommand = ObjectCommand.new(:setproperties, receiver_object)
      unless imageindex.nil?
        theCommand.add_option(key: :imageindex, value: imageindex)
      end
      unless importersource.nil?
        theCommand.add_option(key: :secondaryobject, value: importersource)
      end
      unless importerimageindex.nil?
        theCommand.add_option(key: :secondaryimageindex,
                              value: importerimageindex)
      end
      theCommand
    end

    # Make a new draw element command object.    
    # If you want to set the draw instructions after making the draw 
    # element command then call drawinstructions= on the draw element
    # object.
    # @param receiver_object [Hash] Object handling the draw element command
    # @param drawinstructions [Hash, #elementhash] The draw instructions.
    # @param createimage [Bool] Create an image of context after render.
    # @return [DrawElementCommand] The draw element command object.
    def self.make_drawelement(receiver_object, drawinstructions: nil,
                              createimage: nil)
      theCommand = DrawElementCommand.new(receiver_object,
                                          drawinstructions: drawinstructions,
                                          createimage: createimage)
      theCommand
    end
    
    # Make a render filter chain command object
    # @param receiver_object [Hash] filter chain object that handles render
    # @param renderinstructions [Hash] Render instructions and filter properties
    # @param createimage [Bool] Create an image of context after render.
    # @return [RenderFilterChainCommand] The newly created command
    def self.make_renderfilterchain(receiver_object, renderinstructions: nil,
                                    createimage: nil)
      theCommand = RenderFilterChainCommand.new(receiver_object, 
                                               instructions: renderinstructions,
                                               createimage: createimage)
      theCommand
    end

    # Make a addimage command    
    # The image can be sourced from an image importer object, if so you can
    # optionally supply an image index and assign the grabmetadata attribute
    # with a value of true if you want to copy the original images metadata
    # to be included with the added image when the image file is saved. If
    # the image is sourced from any of the contexts (bitmap, pdf, window) then
    # both the image index and grab metadata options will be ignored if
    # specified.
    # @param receiver_object [Hash] Object that will handle add image command
    # @param image_source [Hash] Object from which to get the image.
    # @param imageindex [Fixnum] the image index into source object to get image
    # @param grabmetadata [true, false] Default:false. Copy metadata from source
    # @return [ObjectCommand] The addimage command.
    def self.make_addimage(receiver_object, image_source, imageindex: nil,
                           grabmetadata: nil)
      theCommand = ObjectCommand.new(:addimage, receiver_object)
      theCommand.add_option(key: :secondaryobject, value: image_source)
      unless grabmetadata.nil?
        theCommand.add_option(key: :grabmetadata, value: grabmetadata)
      end

      unless imageindex.nil?
        options = { imageindex: imageindex }
        theCommand.add_option(key: :imageoptions, value: options)
      end
      
      theCommand
    end

    # Make a addimage command that gets the image from a movie object    
    # The image is sourced from a movie object. To get the image the time in
    # the movie of the desired frame is required. You can also optionally 
    # specify the tracks from which to generate the image. If no tracks are
    # are specified then the image generated is the movie frame at that time. 
    # @param receiver_object [Hash] Object that will handle add image command
    # @param movie_object [Hash] Movie object from which to get the image.
    # @param frametime [Hash] A time representation. Either a CMTime rep or a
    #   time value representing time in seconds from start of the movie.
    # @param tracks [Array] Optional list of tracks to build image from.
    # @return [ObjectCommand] The addimage command.
    def self.make_addimage_frommovie(receiver_object, movie_object,
                                        frametime: nil,
                                           tracks: nil)
      fail "No frame time is specified." if frametime.nil?
      theCommand = ObjectCommand.new(:addimage, receiver_object)
      theCommand.add_option(key: :secondaryobject, value: movie_object)

      options = { frametime: frametime }
      options[:trakcs] = tracks unless tracks.nil?
      theCommand.add_option(key: :imageoptions, value: options)

      theCommand
    end

    # Assign an image to the image collection.    
    # The bitmap and window contexts, the movie and image file importer objects
    # can all add images to the image collection. The importer objects take
    # image_creation_options for creating the image to be added to the collection
    # @param receiver_object [Hash] Object that is to add the image to collection
    # @param image_creation_options [Hash] Options for creating image
    # @param identifier [String] The string to identify the image in collection
    # @return [ObjectCommand] The assignimagetocollection command object
    def self.make_assignimage_tocollection(receiver_object,
                                      image_creation_options: nil,
                                      identifier: nil)
      fail "Image collection identifier not specified. " if identifier.nil?
      theCommand = ObjectCommand.new(:assignimagetocollection, receiver_object)
      unless image_creation_options.nil? 
        theCommand.add_option(key: :imageoptions, value: image_creation_options)
      end
      theCommand.add_option(key: :imageidentifier, value: identifier)
      theCommand
    end

    # Assign an imported image to the image collection.    
    # @param receiver_object [Hash] File importer object that handles assign command
    # @param imageindex [Fixum] Optional. The image index defaults to 0.
    # @param identifier [String] The string to identify the image in collection
    # @return [ObjectCommand] The assignimagetocollection command object
    def self.make_assignimage_fromimporter_tocollection(receiver_object,
                                                imageindex: nil,
                                                identifier: nil)
      imageOptions = nil
      imageOptions = { imageindex: imageindex } unless imageindex.nil?
      return self.make_assignimage_tocollection(receiver_object,
                                          image_creation_options: imageOptions,
                                                      identifier: identifier)
    end

    # Assign an movie frame image to the image collection.    
    # If the tracks param is nil then the image is generated as if the movie
    # is being rendered for display, which is typically rendering of all video
    # tracks. Otherwise the image is generated from the compositing of the tracks
    # in the tracks array.
    # @param receiver_object [Hash] Movie importer object that handles assign command
    # @param frametime [Hash] The movie time that specifies when to get frame.
    # @param tracks [Array] Optional. List of tracks to composite to create image.
    # @param identifier [String] The string to identify the image in collection
    # @return [ObjectCommand] The assignimagetocollection command object
    def self.make_assignimage_frommovie_tocollection(receiver_object,
                                                                 frametime: nil,
                                                                    tracks: nil,
                                                                identifier: nil)
      fail "Frame time to get movie frame from not specified. " if frametime.nil?
      imageOptions = { frametime: frametime }
      imageOptions[:tracks] = tracks unless tracks.nil?
      return self.make_assignimage_tocollection(receiver_object,
                                          image_creation_options: imageOptions,
                                                      identifier: identifier)
    end

    # Remove an image from the image collection.    
    # @param identifier [String] The identifier for the image in the collection.
    def self.make_removeimage_fromcollection(identifier)
      theCommand = Command.new(:removeimagefromcollection)
      theCommand.add_option(key: :imageidentifier, value: identifier)
      theCommand
    end

    # Make an Export images to a image file command.
    # @param receiver_object [Hash] Object that receives the export message
    # @param runasynchronously [bool, nil] Default is false. Export the images
    #   asynchronously.
    # @return [ObjectCommand] The export command
    def self.make_export(receiver_object, runasynchronously: nil)
      theCommand = ObjectCommand.new(:export, receiver_object)
      unless runasynchronously.nil?
        theCommand.add_option(key: :runasynchronously, value: runasynchronously)
      end
      theCommand
    end

    # Make a close object command
    # @param receiver_object [Hash] Object to handle the close command
    # @return [ObjectCommand] The close command
    def self.make_close(receiver_object)
      theCommand = ObjectCommand.new(:close, receiver_object)
      theCommand
    end

    # Make a snap shot command    
    # @param receiver_object [Hash] Object that will handle snap shot command
    # @param snapshottype [:takesnapshot, :drawsnapshot, :clearsnapshot]
    # @return [ObjectCommand] The snap shot command.
    def self.make_snapshot(receiver_object, snapshottype: :takesnapshot)
      theCommand = ObjectCommand.new(:snapshot, receiver_object)
      theCommand.add_option(key: :snapshotaction, value: snapshottype)
      theCommand
    end

    # Make a get pixel data command    
    # If the savelocation is not initially specified and resultstype is set to
    # jsonfile or propertyfile then the save location will need to be set using
    # add_option before the get pixel data command is sent.
    # @param receiver_object [Hash] Object that handles the getpixeldata command
    # @param rectangle [Hash] Representing the area to get pixel data from
    # @param resultstype [:jsonfile, :propertyfile, :dictionaryobject]
    # @param savelocation [String, nil] path, required if resultstypes is a file
    # @return [ObjectCommand] The get pixel data command
    def self.make_getpixeldata(receiver_object, rectangle: nil,
                               resultstype: :jsonfile, savelocation: nil)
      fail "Rectangle not specified" if rectangle.nil?
      theCommand = ObjectCommand.new(:getpixeldata, receiver_object)
      theCommand.add_option(key: :saveresultstype, value: resultstype)

      unless savelocation.nil?
        theCommand.add_option(key: :saveresultsto, value: savelocation)
      end

      theCommand.add_option(key: :getdatatype, value: :dictionaryobject)
      theCommand.add_option(key: :propertyvalue, value: rectangle)
      theCommand
    end
    
    # Make a finalize page and start new page command    
    # This command is handled by an object with class type pdfcontext.
    # @param receiver_object [Hash] pdfcontext handles finalize pdf page command
    # @return [ObjectCommand] The finalize page and start new command.
    def self.make_finalizepdfpage_startnew(receiver_object)
      theCommand = ObjectCommand.new(:finalizepage, receiver_object)
      theCommand
    end

    # Manages a list of commands, and lets you configure how commands are run.    
    # The @commandsHash contains a list of commands to be run, options as
    # to how the commands will be run, plus a list of cleanup commands. The
    # cleanup commands are run whether the main command successfully completed 
    # or not. Mostly they should just be a list of close object commands 
    # attempting to close all the possible objects that could have been created 
    # from other commands.
    class SmigCommands
      # Initialize the SmigCommands object.
      def initialize()
        # The command hash containing the configuration options and command list
        @commandsHash = {}
      end

      # If a command fails, then if stop on failure is true following commands 
      # wont run. true is the default value, so if set to true I could just 
      # scrub the option altogether. with @elementHash.delete(:stoponfailure)
      # As soon as one command fails, no more commands in the command list will
      # be run & after any cleanup commands are run, MovingImages will finish &
      # the information returned will be the result of the failed command.
      # @param stopOnFailure [true, false] If true then stop running commands.
      # @return [true, false] The stop on failure value assigned.
      def stoponfailure=(stopOnFailure)
        @commandsHash[:stoponfailure] = stopOnFailure
      end

      # Assign the variables dictionary to the commands hash. The variables
      # dictionary will be used when interpreting the draw dictionary and
      # rendering the core image filter chain. The variables dictionary values 
      # are numerical values (int or float) and string values for use 
      # when drawing text or when they are a path to a file to be imported
      # or exported.
      # @param theVariables [Hash] A hash of variable names for keys with values
      # @return [Hash] The variables hash just assigned.
      def variables=(theVariables)
        @commandsHash[:variables] = theVariables
      end

      # Set the list of commands to be run.
      # @param commandList [Array<Hash>] The list of commands that will be run.
      # @return [Array<Hash>] The list of commands that has been assigned.
      def commands=(commandList)
        @commandsHash[:commands] = commandList
      end

      # Add a command to the list of commands to be run
      # @param command [Hash, #commandhash] Command to be added to list
      # @return [void]
      def add_command(command)
        if command.respond_to?("commandhash")
          theCommand = command.commandhash
        else
          theCommand = command
        end

        if @commandsHash[:commands].nil?
          @commandsHash[:commands] = [ theCommand ]
        else
          @commandsHash[:commands] << theCommand
        end
        nil
      end

      # Add a close command to the list of cleanup commands to be run
      # @param objectToClose [Hash] The object to be closed
      # @return [void]
      def add_tocleanupcommands_closeobject(objectToClose)
        closeCommand = CommandModule.make_close(objectToClose)
        if @commandsHash[:cleanupcommands].nil?
          @commandsHash[:cleanupcommands] = [ closeCommand.commandhash ]
        else
          @commandsHash[:cleanupcommands].push(closeCommand.commandhash)
        end
        nil
      end

      # Sets the level of information to be returned by running the commands.
      # Three possible values. They are "lastcommandresult", "listofresults",
      # "noresults". If the info returned is set to "lastcommandresult" then
      # the results of the last command to be run in the list will be returned.
      # If info returned is set to "listofresults" then the result string for
      # each command will be returned, one line per result, but only the error
      # code for the last command will be returned. If info returned is set to
      # "noresults" then no results will be returned if the commands are being
      # run asynchronously otherwise the result of last command is returned.
      # @param infoReturned [:lastcommandresult, :listofresults, :noresults]
      def informationreturned=(infoReturned)
        @commandsHash[:returns] = infoReturned
      end

      # If the results are being saved to a file, then this specifies whether 
      # the file is a json or plist file. With ruby it might be sensible to hard
      # code this to json.
      # @param resultType [:jsonfile, :propertyfile] Save results file type
      def saveresultstype=(resultType)
        @commandsHash[:saveresultstype] = resultType
      end

      # Specify a file location where the results will be saved to. Relevant if
      # saveresultstype is set to "propertyfile" or "jsonfile"
      # @param pathToJSONorPLISTFile [String] Path to the output results file.
      def saveresultsto=(pathToJSONorPLISTFile)
        @commandsHash[:saveresultsto] = pathToJSONorPLISTFile
      end

      # If the commands are set to run asynchronously then we might want 
      # commands to run after completion of the asynchronously running commands
      # this provides the mechanism.
      # @param runAsync [bool] Should run commands asynchronously.
      def run_asynchronously=(runAsync)
        @commandsHash[:runasynchronously] = runAsync
      end

      # Reset the command hash.
      def clear()
        @commandsHash = {}
      end

      # Scrub the command list, leaving other options unchanged.
      def clear_commandlist()
        @commandsHash.delete(:commands)
        return @commandsHash
      end

      # Get the commands hash ready to be passed to Smig.perform_commands
      # @return [Hash] The command has ready for Smig.perform_commands.
      def commandshash
        return @commandsHash
      end

      # Make a create bitmap context command and add it to list of commands.    
      # If no name is provided (name = nil) then automatically creates a name.    
      # Optionally add the object to be created to the list of objects to
      # be cleaned up. If all the commands to be performed are in one
      # SmigCommands list and performed as one then you want to make sure
      # objects you created & no longer need get closed. Adding
      # close object commands that take the object id to the list of clean up
      # commands ensures these objects will be closed.    
      # AlphaOnly8bpcInt Gray8bpcInt Gray16bpcInt Gray32bpcFloat
      # AlphaSkipFirstRGB8bpcInt AlphaSkipLastRGB8bpcInt
      # AlphaPreMulFirstRGB8bpcInt AlphaPreMulLastRGB8bpcInt
      # AlphaPreMulLastRGB16bpcInt AlphaSkipLastRGB16bpcInt
      # AlphaSkipLastRGB32bpcFloat AlphaPreMulLastRGB32bpcFloat CMYK8bpcInt
      # CMYK16bpcInt CMYK32bpcFloat    
      # The default color profile for a rgb space is kCGColorSpaceSRGB.
      # Alternatives are: kCGColorSpaceGenericRGBLinear, kCGColorSpaceGenericRGB
      # @param size [Hash] The size of the context to create. Default: 800x600
      # @param addtocleanup [true, false] Should created context be closed
      # @param preset [String, Symbol] Used to define type of bitmap to create
      # @param profile [String] A named color profile to use. 
      # @param name [String, nil] Object name identifier.
      # @return [Hash] The bitmap context object id, to refer to the context
      def make_createbitmapcontext(size: nil, addtocleanup: true,
                                        preset: "AlphaPreMulFirstRGB8bpcInt",
                                        profile: nil,
                                        name: nil)
        size = MIShapes.make_size(800, 600) if size.nil?
        theName = SecureRandom.uuid if name.nil?
        theName = name unless name.nil?
        bitmapObject = SmigIDHash.make_objectid(objectname: theName,
                                                    objecttype: :bitmapcontext)
        createBitmapContext = CommandModule.make_createbitmapcontext(
                                      size: size, name: theName, preset: preset,
                                      profile: profile)
        self.add_command(createBitmapContext)
        if addtocleanup
          self.add_tocleanupcommands_closeobject(bitmapObject)
        end
        bitmapObject
      end

      # Make a create window context command
      # @param rect [Hash] A representation of a rect {MIShapes.make_rectangle}
      # @param addtocleanup [true, false] Should created window be closed?
      # @param borderlesswindow [true, false] Should the window be borderless?
      # @param name [String] The name of the object to be created.
      # @return [Command] The command to create a window context
      def make_createwindowcontext(rect: nil, addtocleanup: true,
                                      borderlesswindow: false, name: nil)
        theName = SecureRandom.uuid if name.nil?
        theName = name unless name.nil?
        windowObject = SmigIDHash.make_objectid(objectname: theName,
                                                objecttype: :nsgraphicscontext)
        createWindowContext = CommandModule.make_createwindowcontext(rect: rect, 
                              borderlesswindow: borderlesswindow, name: theName)
        self.add_command(createWindowContext)
        if addtocleanup
          self.add_tocleanupcommands_closeobject(windowObject)
        end
        windowObject
      end

      # Make a create pdf command and add it to list of commands    
      # If no name is provided (name = nil) then automatically creates a name.    
      # Optionally add the object to be created to the list of objects to
      # be cleaned up. If all the commands to be performed are in one
      # SmigCommands list and performed as one then you want to make sure
      # objects you created & no longer need get closed. Adding
      # close object commands that take the object id to the list of clean up
      # commands ensures these objects will be closed.
      # @param size [Hash] The size of the context to create.
      # @param addtocleanup [true, false] Should created context be closed
      # @param filepath [String] The location where pdf file should be created.
      # @param name [String, nil] Object name identifier.
      # @return [Hash] The pdf context object id, to refer to the context
      def make_createpdfcontext(size: nil, addtocleanup: true, filepath: nil, 
                                                                     name: nil)
        fail "No dimensions provided" if size.nil?
        fail "No path provided" if filepath.nil?
        theName = SecureRandom.uuid if name.nil?
        theName = name unless name.nil?
        pdfObject = SmigIDHash.make_objectid(objectname: theName,
                                                    objecttype: :pdfcontext)
        createPdfContext = CommandModule.make_createpdfcontext(size: size, 
                                              filepath: filepath, name: theName)
        self.add_command(createPdfContext)
        if addtocleanup
          self.add_tocleanupcommands_closeobject(pdfObject)
        end
        pdfObject
      end

      # Make a create exporter command and add it to list of commands    
      # Optionally add the object to be created to the list of objects to
      # be cleaned up. If all the commands to be performed are in one
      # SmigCommands list and performed as one then you want to make sure
      # that objects you created & no longer need get closed. Adding
      # close object commands that take the object id to the list of clean up
      # commands ensures these objects will be closed.
      # @param export_filepath [String] Path to file where to export to.
      # @param export_type [String, Symbol] The export file type.
      # @param name [String] The name of the exporter to be created. optional.
      # @param pathsubstitutionkey [String, Symbol] Get path from variables dict
      # @param addtocleanup [true, false] Should created context be closed.
      # @return [Hash] Object id, a reference to refer to a created object.
      def make_createexporter(export_filepath, export_type: :"public.jpeg" ,
                              addtocleanup: true, name: nil,
                              pathsubstitutionkey: nil)
        the_name = SecureRandom.uuid if name.nil?
        the_name = name unless name.nil?
        exporter_object = SmigIDHash.make_objectid(objectname: the_name,
                                                   objecttype: :imageexporter)
        create_exporter = CommandModule.make_createexporter(export_filepath,
                                  export_type: export_type, name: the_name,
                                  pathsubstitutionkey: pathsubstitutionkey)
        self.add_command(create_exporter)
        if addtocleanup
          self.add_tocleanupcommands_closeobject(exporter_object)
        end
        exporter_object
      end

      # Make a create image filter chain command and add it to list of commands    
      # Optionally add the object to be created to the list of objects to
      # be cleaned up. If all the commands to be performed are in one
      # SmigCommands list and performed as one then you want to make sure
      # that objects you created & no longer need get closed. Adding
      # close object commands that take the object id to the list of clean up
      # commands ensures these objects will be closed.
      # @param filterChain [Hash] The filter chain description
      # @param name [String] The name of the exporter to be created. optional.
      # @param addtocleanup [true, false] Should created context be closed.
      # @return [Hash] Object id, a reference to refer to a created object.
      def make_createimagefilterchain(filterChain, addtocleanup: true,name: nil)
        theName = SecureRandom.uuid if name.nil?
        theName = name unless name.nil?
        filterChainObject = SmigIDHash.make_objectid(objectname: theName,
                                                  objecttype: :imagefilterchain)
        createFilterChain = CommandModule.make_createimagefilterchain(
                                                filterChain, name: theName)
        self.add_command(createFilterChain)
        if addtocleanup
          self.add_tocleanupcommands_closeobject(filterChainObject)
        end
        filterChainObject
      end

      # Make a create image importer command and add it to list of commands    
      # Optionally add the object to be created to the list of objects to
      # be cleaned up. If all the commands to be performed are in one
      # SmigCommands list and performed as one then you want to make sure
      # that objects you created & no longer needed get closed. Adding
      # close object commands that take the object id to the list of clean up
      # commands ensures these objects will be closed.
      # @param filePath [String] The path to the file to import
      # @param name [String] The name of the exporter to be created. optional
      # @param addtocleanup [true, false] Should created context be closed
      # @param pathsubstitutionkey [String, Symbol] Get path from variables dict
      # @return [Hash] Object id, a reference to refer to a created object
      def make_createimporter(filePath, addtocleanup: true, name: nil,
                              pathsubstitutionkey: nil)
        theName = SecureRandom.uuid if name.nil?
        theName = name unless name.nil?
        importerObject = SmigIDHash.make_objectid(objectname: theName,
                                                  objecttype: :imageimporter)
        createImporter = CommandModule.make_createimporter(filePath,
                                                  name: theName,
                                   pathsubstitutionkey: pathsubstitutionkey)
        self.add_command(createImporter)
        if addtocleanup
          self.add_tocleanupcommands_closeobject(importerObject)
        end
        importerObject
      end

      # Make a create movie importer command and add it to list of commands    
      # Optionally add the object to be created to the list of objects to
      # be cleaned up. If all the commands to be performed are in one
      # SmigCommands list and performed as one then you want to make sure
      # that objects you created & no longer needed get closed. Adding
      # close object commands that take the object id to the list of clean up
      # commands ensures these objects will be closed.
      # @param filePath [String] The path to the file to import
      # @param name [String] The name of the exporter to be created. optional
      # @param addtocleanup [true, false] Should created context be closed
      # @param pathsubstitutionkey [String, Symbol] Get path from variables dict
      # @return [Hash] Object id, a reference to refer to a created object
      def make_createmovieimporter(filePath, addtocleanup: true, name: nil,
                                   pathsubstitutionkey: nil)
        theName = SecureRandom.uuid if name.nil?
        theName = name unless name.nil?
        importerObject = SmigIDHash.make_objectid(objectname: theName,
                                                  objecttype: :movieimporter)
        createImporter = CommandModule.make_createmovieimporter(filePath,
                                                    name: theName,
                                     pathsubstitutionkey: nil)
        self.add_command(createImporter)
        if addtocleanup
          self.add_tocleanupcommands_closeobject(importerObject)
        end
        importerObject
      end
    end
  end

  # SmigHelpers A collection of MovingImages helper methods.    
  # Methods for doing common actions.
  module SmigHelpers
    # Save an image from a bitmapcontext or a nsgraphicscontext (window).    
    # This function will throw an exception if there's a problem.
    # @param imagesource [Hash] The bitmap or window context object.
    # @param pathtofile [String] The path to where the image will be saved.
    # @param filetype [String, Symbol] The image file type. Default :public.jpeg
    # @return [void]. 
    def self.save_image(imagesource: nil, pathtofile: nil,
                        filetype: :"public.jpeg")
      commands = CommandModule::SmigCommands.new
      exporterName = SecureRandom.uuid
      createExporterCommand = CommandModule.make_createexporter(pathtofile,
                                                         export_type: filetype,
                                                         name: exporterName)
      commands.add_command(createExporterCommand)
      exporterObject = { :objectname => exporterName,
                          :objecttype => :imageexporter }
      commands.add_tocleanupcommands_closeobject(exporterObject)
      addImageToExporterCommand = CommandModule.make_addimage(exporterObject, 
                                                              imagesource)
      commands.add_command(addImageToExporterCommand)
      exportCommand = CommandModule.make_export(exporterObject)
      commands.add_command(exportCommand)
      Smig.perform_commands(commands)
    end

    # Create a window and return the window object.    
    # @param width [Fixnum, Float] The content width of the window to be created
    # @param height [Fixnum, Float] Content height of the window to be created.
    # @param xloc [Fixnum, Float] x position of bottom left corner of window
    # @param yloc [Fixnum, Float] y position of bottom left corner of window
    # @param borderlesswindow [true, false] Should the window be borderless?
    # @return [Hash] A window object reference.
    def self.create_window(width: 800, height: 600, xloc: 100, yloc: 100,
                           borderlesswindow: false)
      createWC = CommandModule.make_createwindowcontext(
                                            width: width, height: height,
                                            xloc: xloc, yloc: yloc,
                                            borderlesswindow: borderlesswindow)
      result = Smig.perform_command(createWC)
      # puts "Create window command result: #{result}"
      { :objectreference => result.to_i }
      # { :objectname => windowName, :objecttype => :nsgraphicscontext }
    end

    # Create a bitmap context and return the bitmap context object.    
    # @see MIMeta.listpresets for a list of bitmap context presets.
    # @param width [Fixnum, Float] The bitmap content width to be created
    # @param height [Fixnum, Float] The bitmap content height to be created
    # @param preset [String, Symbol] The preset used to create the bitmap with.
    # @return [Hash] A bitmap context object reference.
    def self.create_bitmapcontext(width: 800, height: 600,
                                  preset: "AlphaPreMulFirstRGB8bpcInt")
      createBMC = CommandModule.make_createbitmapcontext(
                                              width: width,
                                              height: height,
                                              preset: preset)
      result =  Smig.perform_command(createBMC)
      { :objectreference => result.to_i }
    end

    # Draw an image in a image file to the destination.    
    # @param destination [Hash] Destination object, bitmap or window context.
    # @param destinationrect [Hash] Where to draw. {MIShapes.make_rectangle}
    # @param imagefile [String] Path to the image file to draw
    # @param imageindex [Fixnum] Index to image in file, optional
    # @param drawimageelement [MIDrawImageElement] Draw image options, optional
    # @return [String] Empty string on success, otherwise a message
    def self.drawimage_to_object(destination: nil, destinationrect: nil,
                        imagefile: nil, imageindex: nil, drawimageelement: nil)
      return "No image file path specified." if imagefile.nil?
      return "No destination object specified." if destination.nil?
      return "No destination rectangle specified." if destinationrect.nil?

      theCommands = CommandModule::SmigCommands.new
      drawImageElement = if drawimageelement.nil?
                           MIDrawImageElement.new
                         else
                           drawimageelement
                         end
      drawImageElement.destinationrectangle = destinationrect
      imageImporterName = SecureRandom.uuid
      createImageImporterCommand = CommandModule.make_createimporter(
                                                      imagefile,
                                                      name: imageImporterName)
      imageImporterObject = SmigIDHash.make_objectid(objecttype: :imageimporter,
                                                objectname: imageImporterName)
      theCommands.add_command(createImageImporterCommand)
      theCommands.add_tocleanupcommands_closeobject(imageImporterObject)
      drawImageElement.set_imagesource(source_object: imageImporterObject,
                                       imageindex: imageindex)
      drawImageCommand = CommandModule.make_drawelement(
                                destination, drawinstructions: drawImageElement)
      theCommands.add_command(drawImageCommand)
      Smig.perform_commands(theCommands)
      ""
    end
  end
end