
# require_relative 'smig'

module MovingImages

  # == MILAMeta - information about MovingImages LaunchAgent.
  # Get and set the LaunchAgent's idle time.
  module MILAMeta
    # The command line tool to be called.
    Smig = "smig"
  
    # The smig return code. Non zero values indicate an error occurred.
    @@exitvalue = 0
  
    # The smig return string when an error occurs.
    @@exitstring = ""

    private
  
    # Raise an exception if there was an error calling smig.
    def self.raiseexception_unlesstatuszero(method: "", status: 0, result: nil)
      @@exitstring = ""
      @@exitvalue = status.exitstatus
      @@exitstring = result unless result.nil?
      raise "Method #{method} failed." unless @@exitvalue.zero?
    end

    public

    # Get exit value from the last failed smig call. Call in exception handler.
    # @return [Fixnum] The error value.
    def self.exitvalue
      return @@exitvalue
    end

    # Get the exit string if last smig call failed. Call in exception handler.
    # @return [String]. The smig error message.
    def self.exitstring
      return @@exitstring
    end

    # Gets the length of time the MovingImages Launch Agent will remain alive
    # before the agent will exit. MovingImages Launch Agent will only exit if it
    # contains no base objects.
    # @return [Fixnum] The time in seconds.
    def self.idletime
      resultStr, exitVal = Open3.capture2(Smig, "getproperty", "-property", 
                                        "idletime")
      self.raiseexception_unlesstatuszero(method: "MIMeta.idletime",
                                      status: exitVal, result: resultStr)
      return resultStr.to_i
    end

    # Sets the length of time the MovingImages Launch Agent will remain alive
    # before the agent will exit.
    # @param idletime [Fixnum] Time in seconds (1..900) (1 sec to 15 mins)
    # @return [Fixnum] The time actually set
    def self.idletime=(idletime: 10)
      result, exitVal = Open3.captures(smig, "setproperty", "-property", 
                                        "idletime", idletime.to_s)
      self.raiseexception_unlesstatuszero(method: "MIMeta.idletime",
                                      status: exitVal, result: result)
      return result
    end
  end

  # == Metadata to do with MovingImages
  # Get a list of the different objects types you can create.    
  # Get lists of the commands MovingImages handles, including by class type, 
  # or object type.    
  # Get lists of core image filters, including filters by category.    
  # Get filter attributes    
  # Get the list of bitmapcontent presets.    
  # Get the list of draw element blend modes.
  module MIMeta
    # The bitmap context type. Used for creating objects or getting class info.
    BitmapContextType = :bitmapcontext
  
    # The image importer type
    ImageImporterType = :imageimporter
  
    # The image exporter type
    ImageExporterType = :imageexporter
  
    # The image filter chain type
    ImageFilterChainType = :imagefilterchain
  
    # The pdf context type
    PDFContextType = :pdfcontext
  
    # The window context type
    WindowContextType = :nsgraphiccontext

    # The get property command. Handled by objects and classes.
    GetPropertyCommand = :getproperty
  
    # The set property command. Handled by objects.
    SetPropertyCommand = :setproperty
  
    # The get properties command. Handled by objects.
    GetPropertiesCommand = :getproperties
  
    # The set properties command. Handled by objects.
    SetPropertiesCommand = :setproperties
  
    # The create object command. Handled by by classes only.
    CreateObjectCommand = :create
  
    # The close objects command. Handled by objects of any type.
    CloseObjectCommand = :close
  
    # The close all objects command. Handled by classes and the framework.
    CloseAllObjectsCommand = :closeall
  
    # The add image command. Handled by a imageexport type object only.
    AddImageCommand = :addimage
  
    # The export command.  Handled by a imageexport type object only.
    ExportCommand = :export
  
    # The draw element command. Handled by objects of type bitmapcontext,
    # pdfcontext and the nsgraphicscontext only.
    DrawElementCommand = :drawelement
  
    # The snap shot command. Handled by objects of type bitmapcontext,
    # and the nsgraphicscontext only.
    SnapShotCommand = :snapshot
  
    # The finalize page command. Handled by a pdf context object only.
    FinalizePageCommand = :finalizepage
  
    # The get pixel data command. Handled by a bitmapcontext object only.
    GetPixelDataCommand = :getpixeldata
  
    # The calculate graphic size of text command. Handled by 
    # bitmapcontext, a nsgraphiccontext or pdfcontext types.
    CalculateGraphicSizeOfTextCommand = :calculategraphicsizeoftext
  
    # The render filter chain command. Handled by a imagefilterchain object.
    RenderFilterChainCommand = :renderfilterchain

    # Lists of commands handled by objects of a particular type
    CommandsForObjectsOfClasses = {
      BitmapContextType => [ GetPropertyCommand, GetPropertiesCommand,
      CloseObjectCommand, DrawElementCommand, SnapShotCommand,
                                                      GetPixelDataCommand ],
      ImageImporterType => [ GetPropertyCommand, GetPropertiesCommand,
                                      SetPropertyCommand, CloseObjectCommand ],
      ImageExporterType => [ GetPropertyCommand, GetPropertiesCommand,
      SetPropertyCommand, SetPropertiesCommand, CloseObjectCommand,
                                            AddImageCommand, ExportCommand ],
      ImageFilterChainType => [ GetPropertyCommand, GetPropertiesCommand,
            SetPropertyCommand, CloseObjectCommand, RenderFilterChainCommand ],
      WindowContextType => [ GetPropertyCommand, GetPropertiesCommand,
                      CloseObjectCommand, DrawElementCommand, SnapShotCommand ],
      PDFContextType => [ GetPropertyCommand, GetPropertiesCommand,
                                       CloseObjectCommand, DrawElementCommand ]
    }

    # Get a list of the different types of objects MovingImages can create.
    # @return [Array<Symbol>] The list of object types as ruby symbols
    def self.listobjecttypes
      return [ BitmapContextType, ImageImporterType, ImageExporterType, 
                ImageFilterChainType, PDFContextType, WindowContextType ]
    end

    # Get a list of all the commands handled by MovingImages.
    # @return [Array<Symbol>] The array of commands as ruby symbols
    def self.listofallcommands
      return [ GetPropertyCommand, SetPropertyCommand, GetPropertiesCommand,
               SetPropertiesCommand, CreateObjectCommand, CloseObjectCommand,
               CloseAllObjectsCommand, AddImageCommand, ExportCommand,
               DrawElementCommand, SnapShotCommand, FinalizePageCommand, 
               GetPixelDataCommand, CalculateGraphicSizeOfTextCommand, 
               RenderFilterChainCommand ]
    end

    # Get a list of the commands handled by classes of type.
    # @param bytype [Symbol] The type to get list of commands from.
    # @return [Array<Symbol>] The array of commands as as ruby symbols
    def self.listofclasscommands(bytype: BitmapContextType)
      if (bytype.eql? BitmapContextType) || (bytype.eql? PDFContextType) ||
                                             (bytype.eql? WindowContextType)
        return [ CreateObjectCommand, GetPropertyCommand, 
                 CloseAllObjectsCommand, CalculateGraphicSizeOfTextCommand ]
      else
        return [ CreateObjectCommand, GetPropertyCommand,
                 CloseAllObjectsCommand ]
      end
    end

    # Get a list of the commands handled by objects of class type.
    # @param bytype [Symbol] The type to get list of commands from.
    # @return [Array<Symbol>] A list of commands handled by objects of type.
    def self.listofobjectcommands(bytype: BitmapContextType)
      return CommandsForObjectsOfClasses[bytype]
    end

    # Get the list of filters that can be part of an image filter chain object.
    # If no category is specified (default) then return a list of all filters
    # @param category [String] The category to get the list of filters from.
    # @return [String] A space delimited string with the list of filter names.
    def self.get_listoffilters(category: nil)
      commandHash = { :command => "getproperty",
                        :objecttype => "imagefilterchain",
                        :propertykey => "imagefilters" }
      commandHash[:filtercategory] = category unless category.nil?
      return Smig.perform_commands( { :commands => [ commandHash ] } )
    end

    # Get a list of the commands handled by objects of class type.
    # @param filtername [String] The type to get list of commands from.
    # @return [String] A JSON object describing the filter attributes
    def self.get_filterattributes(filtername: "CIBoxBlur")
      commandHash = { :command => "getproperty",
                      :objecttype => "imagefilterchain",
                      :propertykey => "filterattributes",
                      :filtername => filtername }
      return Smig.perform_commands( { :commands => [ commandHash ] } )
    end

    # Get the list of presets that can be used to create a bitmap context.
    # @return [String] A space delimited string with the list of presets.
    def self.listofpresets
      return Smig.get_classtypeproperty(objecttype: BitmapContextType,
                                        property: :presets)
    end

    # Get the list of blend modes for drawing into a context.
    # @return [String] A space delimited string with the list of blend modes.
    def self.cgblendmodes
      return Smig.get_classtypeproperty(objecttype: BitmapContextType,
                                          property: "blendmodes")
    end

    # Get the list of the available user interface fonts.
    # @return [String] A space delimited string of user interface fonts
    def self.listofuserinterfacefonts
      return Smig.get_classtypeproperty(objecttype: BitmapContextType,
                                         property: "userinterfacefonts")
    end
  end
end