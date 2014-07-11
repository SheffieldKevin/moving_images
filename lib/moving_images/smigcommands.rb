
# The all encompassing MovingImages module
module MovingImages
  # == The command module. Houston, all your commands are belong to us.
  # All the module methods, and these all begin with "make_" create command
  # objects. The created commands can be added to the list of commands or can be
  # performed immediately by calling Smig.perform_command(...) with the
  # command as the argument.
  module CommandModule
    # == The base class for defining commands
    class Command
      @commandHash
      
      # The constructor for a MovingImages::Command object
      def initialize(theCommand)
        @commandHash = { :command => theCommand }
      end
    
      # Get the command hash, ready to be passed to Smig.perform_commands.
      # @return [Hash] The command hash that the options have been added to.
      def get_commandhash()
        return @commandHash
      end

      # Add an option to the command hash.
      # @param key [String, Symbol] The option to be added to the dictionary
      # @param value [String, Symbol, Fixnum, Float] The value to be assigned
      def add_option(key: nil, value: "")
        @commandHash[key] = value unless key.nil?
      end
    end

    # == The base class for defining commands handled by objects
    class ObjectCommand < Command
      # Constructor for ObjectCommand
      # @param theCommand [String] The name of the command to be performed
      # @param receiverObject [Hash] The object that will handle the command
      # @return SmigObjectCommand command object
      def initialize(theCommand, receiverObject)
        super(theCommand)
        self.add_option(key: :receiverobject, value: receiverObject)
      end

      # Set the receiver for the object. This method allows the receiver
      # to be overridden at a later time. I use this when I want to send 
      # the command again but to a new object. Be careful though because if the 
      # command to the first object has not yet been performed then this can
      # can change receiver object of the original command.
      # @param receiver [Hash] The new object to handle the command.
      def set_receiver(receiver)
        self.add_option(key: :receiverobject, value: receiver)
      end
    end

    # == A draw element command object
    class DrawElementCommand < ObjectCommand
      # Initialize a new draw element command object
      # @param receiverObject [Hash] Object handling the draw element command
      # @param drawinstructions [Hash, #get_elementhash] The draw instructions.
      # @return [DrawElementCommand] The draw element command object.
      def initialize(receiverObject, drawinstructions: nil)
        super(:drawelement, receiverObject)
        self.set_drawinstructions(drawinstructions) unless drawinstructions.nil?
      end

      # Assign the draw instructions to the draw element command object.
      # @param drawInstructions [Hash] Instructions that will do the drawing.
      # @return [Hash] The draw instruction hash.
      def set_drawinstructions(drawInstructions)
        drawInstructionsHash = drawInstructions
        if drawInstructionsHash.respond_to?("get_elementhash")
          drawInstructionsHash = drawInstructionsHash.get_elementhash()
        end
        self.add_option(key: :drawinstructions, value: drawInstructionsHash)
        self.get_commandhash()
      end
    end

    # == A render imager filter chain command
    class RenderFilterChainCommand < ObjectCommand
      # Initialize a new render filter chain command object
      # @param filterChainObject [Hash] filter chain object that handles render
      # @param instructions [Hash] Render instructions and filter properties
      # @return [RenderFilterChainCommand] The newly created object
      def initialize(filterChainObject, instructions: nil)
        super(:renderfilterchain, filterChainObject)
        self.set_renderinstructions(instructions) unless instructions.nil?
      end
  
      # Set the render instructions which can include filter properties, 
      # destination and source rectangles. The filter properties are applied to
      # the filters in the filter chain before the filter chain is rendered.
      # The source rectangle crops the filter chain rendering and the 
      # destination rectangle specifies where in the render destination the 
      # rendered image should be drawn to.
      # @param renderInstructions [Hash, #get_renderfilterhchainhash]
      # @return [Hash] The render hash.
      def set_renderinstructions(renderInstructions)
        if renderInstructions.respond_to?("get_renderfilterchainhash")
          renderInstructions = renderInstructions.get_renderfilterchainhash()
        end
        self.add_option(key: :renderinstructions, value: renderInstructions)
        self.get_commandhash()
      end
    end

    # Make a create importer command object
    # @param imageFilePath [String] A path to an image file
    # @param name [String] The name of the object to be created
    # @return [Command] The command that create the importer
    def self.make_createimporter(imageFilePath, name: nil)
      theCommand = Command.new(:create)
      theCommand.add_option(key: :objecttype, value: :imageimporter)
      theCommand.add_option(key: :file, value: imageFilePath)
      theCommand.add_option(key: :objectname, value: name) unless name.nil?
      theCommand
    end

    # Make a create bitmap context command
    # @param width [Fixnum, Float] The width of the bitmap context to be created
    # @param height [Fixnum, Float] Height of the bitmap context to be created.
    # @param size [Hash] A size hash. Size of bitmap. See {MIShapes#make_size}
    # @param preset [String, Symbol] Preset used to create the bitmap context.
    # @param name [String] The name of the object to be created.
    # @return [Command] The command to create the bitmap object
    def self.make_createbitmapcontext(width: 800, height: 600,
                                      size: nil,
                                      preset: "AlphaPreMulFirstRGB8bpcInt", 
                                      name: nil)
      theCommand = Command.new(:create)
      theCommand.add_option(key: :objecttype, value: :bitmapcontext)
      theCommand.add_option(key: :objectname, value: name) unless name.nil?
      if size.nil?
        theCommand.add_option(key: :width, value: width)
        theCommand.add_option(key: :height, value: height)
      else
        theCommand.add_option(key: :size, value: size)
      end
      theCommand.add_option(key: :preset, value: preset)
      theCommand
    end

    # Make a create window context command
    # @param width [Fixnum, Float] The content width of the window to be created
    # @param height [Fixnum, Float] Content height of the window to be created.
    # @param xloc [Fixnum, Float] x position of bottom left corner of window
    # @param yloc [Fixnum, Float] y position of bottom left corner of window
    # @param rect [Hash] A representation of a rect {MIShapes#make_rectangle}
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
    # @param exportType [String] The uti export file type.
    # @param name [String] The name of the image exporter object to create.
    # @return [Command] The command to create an image exporter object
    def self.make_createexporter(exportFilePath, exportType: "public.jpeg",
                                      name: nil)
      theCommand = Command.new(:create)
      theCommand.add_option(key: :objecttype, value: :imageexporter)
      theCommand.add_option(key: :file, value: exportFilePath)
      theCommand.add_option(key: :utifiletype, value: exportType)
      theCommand.add_option(key: :objectname, value: name) unless name.nil?
      theCommand
    end

    # Make a create image filter chain object command
    # @param filterChain [Hash, #get_filterchainhash] Filter chain description
    # @param name [String] The name of the image filter chain object to create
    # @return [Command] A command to create an image filter chain object
    def self.make_createimagefilterchain(filterChain, name: nil)
      theCommand = Command.new(:create)
      theCommand.add_option(key: :objecttype, value: :imagefilterchain)
      if filterChain.respond_to? "get_filterchainhash"
        filterChain = filterChain.get_filterchainhash()
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
    def self.make_getnonobjectproperty(property: :numberofobjects, type: nil)
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
    # @param strokewidth [Fixnum, Float, nil] The stroke width to use.
    # @return [Command] The calculate graphic size of text command
    def self.make_calculategraphicsizeoftext(
                                         text: "How long is a piece of string",
                                         postscriptfontname: nil,
                                         userinterfacefont: nil,
                                         fontsize: nil,
                                         strokewidth: nil)
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
    
      unless strokewidth.nil?
        dict[:stringstrokewidth] = strokewidth
      end
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

    # Make a get object properties command.
    # @param receiverObject [Hash] The object to get the properties from
    # @param imageindex [Fixnum, nil] The image index, optional.
    def self.make_get_objectproperties(receiverObject, imageindex: nil)
      theCommand = ObjectCommand.new(:getproperty, receiverObject)
      unless imageindex.nil?
        theCommand.add_option(key: :imageindex, value: imageindex)
      end
      theCommand
    end

    # Make a set property command.    
    # If setting property values for images in an image exporter object then it
    # may also be necessary to add a image index option to specify a specific 
    # image in the exporter. The image index defaults to 0 if unspecified.    
    # setImagePropertyCommand.add_option(key: :imageindex, value: imageIndex)
    # @param receiverObject [Hash] The object to set the property of
    # @param propertykey [String, Symbol] The property to be set.
    # @param propertyvalue [String,Symbol,Fixnum,Float,Hash] Value to be
    # @return [ObjectCommand] The set property object command.
    def self.make_set_objectproperty(receiverObject, propertykey: nil,
                                     propertyvalue: nil)
      theCommand = ObjectCommand.new(:setproperty, receiverObject)
      unless propertykey.nil?
        theCommand.add_option(key: :propertykey, value: propertykey)
      end
      unless propertyvalue.nil? 
        theCommand.add_option(key: :propertyvalue, value: propertyvalue)
      end
      theCommand
    end

    # Make an add metadata command.    
    # Copy metadata from an image importer for an image at index to the
    # image in the exporter receiver object.
    # @param receiverObject [Hash] The object to set the property of
    # @param importersource [Hash] The image importer object
    # @param importerimageindex [Fixnum] The image index in the image importer
    # @param imageindex [Fixnum] The exporter image index to receive metadata
    # @return [ObjectCommand] The copy metadata command.
    def self.make_add_metadata(receiverObject, importersource: nil, 
                                importerimageindex: 0, imageindex: 0)
      theCommand = ObjectCommand.new(:setproperties, receiverObject)
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
    # element command then call set_drawinstructions on the draw element
    # object.
    # @param receiverObject [Hash] Object handling the draw element command
    # @param drawinstructions [Hash, #get_elementhash] The draw instructions.
    # @return [DrawElementCommand] The draw element command object.
    def self.make_drawelement(receiverObject, drawinstructions: nil)
      theCommand = DrawElementCommand.new(receiverObject,
                                          drawinstructions: drawinstructions)
      theCommand
    end
    
    # Make a render filter chain command object
    # @param receiverObject [Hash] filter chain object that handles render
    # @param renderinstructions [Hash] Render instructions and filter properties
    # @return [RenderFilterChainCommand] The newly created command
    def self.make_renderfilterchain(receiverObject, renderinstructions: nil)
      theCommand = RenderFilterChainCommand.new(receiverObject, 
                                               instructions: renderinstructions)
      theCommand
    end

    # Make a addimage command
    # @param receiverObject [Hash] Object that will handle the add image command
    # @param imageSource [Hash] Object from which to get the image from.
    # @param imageIndex [Fixnum] the image index from object to get image from.
    # @return [ObjectCommand] The addimage command.
    def self.make_addimage(receiverObject, imageSource, imageIndex: nil)
      theCommand = ObjectCommand.new(:addimage, receiverObject)
      theCommand.add_option(key: :secondaryobject, value: imageSource)
      unless imageIndex.nil?
        theCommand.add_option(key: :secondaryimageindex, value: imageIndex)
      end
      theCommand
    end

    # Make an Export images to a image file command.
    # @param receiverObject [Hash] Object that receives the export message
    # @return [ObjectCommand] The export command.
    def self.make_export(receiverObject)
      theCommand = ObjectCommand.new(:export, receiverObject)
      theCommand
    end

    # Make a close object command
    # @param receiverObject [Hash] Object to handle the close command
    # @return [ObjectCommand] The close command
    def self.make_close(receiverObject)
      theCommand = ObjectCommand.new(:close, receiverObject)
      theCommand
    end

    # Make a snap shot command    
    # @param receiverObject [Hash] Object that will handle the snap shot command
    # @param snapshottype [:takesnapshot, :drawsnapshot, :clearsnapshot]
    # @return [ObjectCommand] The snap shot command.
    def self.make_snapshot(receiverObject, snapshottype: :takesnapshot)
      theCommand = ObjectCommand.new(:snapshot, receiverObject)
      theCommand.add_option(key: :snapshotaction, value: snapshottype)
      theCommand
    end

    # Make a get pixel data command    
    # If the savelocation is not initially specified and resultstype is set to
    # jsonfile or propertyfile then the save location will need to be set using
    # add_option before the get pixel data command is sent.
    # @param receiverObject [Hash] Object that handles the getpixeldata command
    # @param rectangle [Hash] Representing the area to get pixel data from
    # @param resultstype [:jsonfile, :propertyfile, :dictionaryobject]
    # @param savelocation [String, nil] path, required if resultstypes is a file
    # @return [ObjectCommand] The get pixel data command
    def self.make_getpixeldata(receiverObject, rectangle: {},
                               resultstype: :jsonfile, savelocation: nil)
      theCommand = ObjectCommand.new(:getpixeldata, receiverObject)
      theCommand.add_option(key: :saveresultstype, value: resultstype)
      theCommand.add_option(key: :saveresultsto, value: savelocation)
      theCommand
    end
    
    # Make a finalize page and start new page command    
    # This command is handled by an object with class type pdfcontext.
    # @param receiverObject [Hash] Object that handles finalize pdf page command
    # @return [ObjectCommand] The finalize page and start new command.
    def self.make_finalizepdfpage_startnew(receiverObject)
      theCommand = ObjectCommand.new(:finalizepage, receiverObject)
      theCommand
    end

    # == Manages a list of commands, and lets you configure how commands are run    
    # The @commandsHash contains a list of commands to be run, options as
    # to how the commands will be run, plus a list of cleanup commands. The
    # cleanup commands are run whether the main command successfully completed 
    # or not. Mostly they should just be a list of close object commands 
    # attempting to close all the possible objects that could have been created 
    # from other commands.
    class SmigCommands
      # The command hash containing the configuration options and command list
      @commandsHash
  
      # Initialize the SmigCommands object.
      def initialize()
        @commandsHash = { }
      end

      # If a command fails, then if stop on failure is true following commands 
      # wont run. true is the default value, so if set to true I could just 
      # scrub the option altogether. with @elementHash.delete(:stoponfailure)
      # As soon as one command fails, no more commands in the command list will
      # be run & after any cleanup commands are run, MovingImages will finish &
      # the information returned will be the result of the failed command.
      # @param stopOnFailure [true, false] If true then stop running commands.
      # @return [true, false] The stop on failure value assigned.
      def set_stoponfailure(stopOnFailure)
        @commandsHash[:stoponfailure] = stopOnFailure
      end

      # Set the list of commands to be run.
      # @param commandList [Array<Hash>] The list of commands that will be run.
      # @return [Array<Hash>] The list of commands that has been assigned.
      def set_commands(commandList)
        @commandsHash[:commands] = commandList
      end

      # Add a command to the list of commands to be run
      # @param command [Hash, #get_commandhash] Command to be added to list
      # @return [void]
      def add_command(command)
        if command.respond_to?("get_commandhash")
          theCommand = command.get_commandhash()
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
          @commandsHash[:cleanupcommands] = [ closeCommand.get_commandhash() ]
        else
          @commandsHash[:cleanupcommands].push(closeCommand.get_commandhash())
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
      def set_informationreturned(infoReturned)
        @commandsHash[:returns] = infoReturned
      end

      # If the results are being saved to a file, then this specifies whether 
      # the file is a json or plist file. With ruby it might be sensible to hard
      # code this to json.
      # @param resultType [:jsonfile, :propertyfile] Save results file type
      def set_saveresultstype(resultType = :jsonfile)
        @commandsHash[:saveresultstype] = resultType
      end

      # Specify a file location where the results will be saved to. Relevant if
      # saveresultstype is set to "propertyfile" or "jsonfile"
      # @param pathToJSONorPLISTFile [String] Path to the output results file.
      def set_saveresultsto(pathToJSONorPLISTFile)
        @commandsHash[:saveresultsto] = pathToJSONorPLISTFile
      end

      # If the commands are set to run asynchronously then we might want 
      # commands to run after completion of the asynchronously running commands
      # this provides the mechanism.
      # @param runAsync [bool] Should run commands asynchronously.
      def set_run_asynchronously(runAsync)
        @commandsHash[:runasynchronously] = runAsync
      end

      # Reset the command hash.
      def clear()
        @commandsHash = { }
      end

      # Scrub the command list, leaving other options unchanged.
      def clear_commandlist()
        @commandsHash.delete(:commands)
        return @commandsHash
      end

      # Get the commands hash ready to be passed to Smig.perform_commands
      # @return [Hash] The command has ready for Smig.perform_commands.
      def get_commandshash()
        return @commandsHash
      end

      # Make a create bitmap context command and add it to list of commands    
      # If no name is provided (name = nil) then automatically creates a name.    
      # Optionally add the object to be created to the list of objects to
      # be cleaned up. If all the commands to be performed are in one
      # SmigCommands list and performed as one then you want to make sure
      # objects you created & no longer need get closed. Adding
      # close object commands that take the object id to the list of clean up
      # commands ensures these objects will be closed.
      # @param size [Hash] The size of the context to create.
      # @param addtocleanup [true, false] Should created context be closed
      # @param preset [String, Symbol] Used to define type of bitmap to create
      # @param name [String, nil] Object name identifier.
      # @return [Hash] The bitmap context object id, to refer to the context
      def make_createbitmapcontext(size: nil, addtocleanup: true,
                                        preset: "AlphaPreMulFirstRGB8bpcInt",
                                        name: nil)
        raise "No dimensions provided" if size.nil?
        theName = SecureRandom.uuid if name.nil?
        theName = name unless name.nil?
        bitmapObject = SmigIDHash.make_objectid(objectname: theName,
                                                    objecttype: :bitmapcontext)
        createBitmapContext = CommandModule.make_createbitmapcontext(
                                      size: size, name: theName, preset: preset)
        self.add_command(createBitmapContext)
        if addtocleanup
          self.add_tocleanupcommands_closeobject(bitmapObject)
        end
        bitmapObject
      end

      # Make a create window context command
      # @param rect [Hash] A representation of a rect {MIShapes#make_rectangle}
      # @param addtocleanup [true, false] Should created window be closed?
      # @param borderlesswindow [true, false] Should the window be borderless?
      # @param name [String] The name of the object to be created.
      # @return [Command] The command to create a window context
      def make_createwindowcontext(rect: nil, addtocleanup: true,
                                      borderlesswindow: false, name: nil)
        raise "No window rectangle provided" if rect.nil?
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
        raise "No dimensions provided" if size.nil?
        raise "No path provided" if filepath.nil?
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
      # @param exportFilePath [String] Path to file where to export to.
      # @param exportType [String, Symbol] The export file type.
      # @param name [String] The name of the exporter to be created. optional.
      # @param addtocleanup [true, false] Should created context be closed.
      # @return [Hash] Object id, a reference to refer to a created object.
      def make_createexporter(exportFilePath, exportType: :"public.jpeg" ,
                                                addtocleanup: true, name: nil)
        theName = SecureRandom.uuid if name.nil?
        theName = name unless name.nil?
        exporterObject = SmigIDHash.make_objectid(objectname: theName,
                                                  objecttype: :imageexporter)
        createExporter = CommandModule.make_createexporter(exportFilePath,
                                      exportType: exportType, name: theName)
        self.add_command(createExporter)
        if addtocleanup
          self.add_tocleanupcommands_closeobject(exporterObject)
        end
        exporterObject
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
      # that objects you created & no longer need get closed. Adding
      # close object commands that take the object id to the list of clean up
      # commands ensures these objects will be closed.
      # @param filePath [String] The path to the file to import
      # @param name [String] The name of the exporter to be created. optional
      # @param addtocleanup [true, false] Should created context be closed
      # @return [Hash] Object id, a reference to refer to a created object
      def make_createimporter(filePath, addtocleanup: true, name: nil)
        theName = SecureRandom.uuid if name.nil?
        theName = name unless name.nil?
        importerObject = SmigIDHash.make_objectid(objectname: theName,
                                                  objecttype: :imageimporter)
        createImporter = CommandModule.make_createimporter(filePath,
                                                              name: theName)
        self.add_command(createImporter)
        if addtocleanup
          self.add_tocleanupcommands_closeobject(importerObject)
        end
        importerObject
      end
    end
  end

  # == SmigHelpers A collection of MovingImages helper methods
  # Methods for doing common actions.
  module SmigHelpers
    # Save an image from a bitmapcontext or a nsgraphicscontext (window)
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
                                                           exportType: filetype,
                                                           name: exporterName)
      commands.add_command(createExporterCommand)
      exporterObject = { :objectname => exporterName,
                          :objecttype => :imageexporter}
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
    # @see MIMeta.get_listofpresets for a list of bitmap context presets.
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

    # Close an object. Will throw if an error occurs closing the object.
    # @param theObject [Hash] A reference to the object to close.
    # @return [void]
    def self.close_object(theObject)
      closeCommand = CommandModule.make_close(theObject)
      Smig.perform_command(closeCommand)
    end

    # Close an object and don't throw or report any error.
    # @param theObject [Hash] A reference to the object to close.
    # @return [void]
    def self.close_object_nothrow(theObject)
      closeCommand = CommandModule.make_close(theObject)
      commands = { :commands => [ closeCommand.get_commandhash() ] }
      Smig.perform_commands_nothrow(commands)
      nil
    end

    # Draw an image in a image file to the destination.
    # @param destination [Hash] Destination object, bitmap or window context.
    # @param destinationrect [Hash] Where to draw. {MIShapes.make_rectangle}
    # @param imagefile [String] Path to the image file to draw
    # @param imageindex [Fixnum] Index to image in file, optional.
    # @param drawimageelement [MIDrawImageElement] Draw image options, optional.
    # @return [String] Empty string on success, otherwise a message.
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
      drawImageElement.set_destinationrectangle(destinationrect)
      imageImporterName = SecureRandom.uuid
      createImageImporterCommand = CommandModule.make_createimporter(
                                                      imagefile,
                                                      name: imageImporterName)
      imageImporterObject = SmigIDHash.makeid_withobjecttypeandname(
                                              :imageimporter, imageImporterName)
      theCommands.add_command(createImageImporterCommand)
      theCommands.add_tocleanupcommands_closeobject(imageImporterObject)
      drawImageElement.set_imagesource(sourceObject: imageImporterObject,
                                      imageIndex: imageindex)
      drawImageCommand = CommandModule.make_drawelement(
                                destination, drawInstructions: drawImageElement)
      theCommands.add_command(drawImageCommand)
      Smig.perform_commands(theCommands)
      ""
    end
  end
end