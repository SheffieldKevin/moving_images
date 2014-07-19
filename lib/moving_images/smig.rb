require 'Open3'
require 'JSON'
require 'tmpdir'
require 'securerandom'

# require_relative 'smigcommands'

module MovingImages

  # ==The Smig module is used for sending commands using "smig" to MovingImages
  # The perform_commands method will raise an exception and set the module
  # properties @@exitvalue, and @@exitstring if smig returns an error.
  # The no throw version of the perform_command method ignores the return value
  # and are useful within the rescue and ensure sections of a begin - end block.    
  # To create a smig command see {CommandModule} and its classes. To
  # create a list of smig commands and configure how they are run see
  # {CommandModule::SmigCommands}
  module Smig
    # The command line tool used to communicate with MovingImages.
    Smig = "smig" # Scripting MovingImaGes
  
    # The return value. Non zero values indicate an error occurred.
    @@exitvalue = 0
  
    # If @@exitvalue is non zero @@exitstring will hold a short error message
    @@exitstring = ""

    private
  
    # Raise an exception if there was an error calling smig.
    def self.raiseexception_unlesstatuszero(method: "", status: 0, result: nil)
      @@exitstring = ""
      @@exitvalue = status.exitstatus
      @@exitstring = result unless result.nil?
      fail "Method #{method} failed." unless @@exitvalue.zero?
    end

    public

    # Get exit value from the last perform_commands method run
    # @return [Fixnum] The error code. A value of 0 indicates no error.
    def self.exitvalue
      return @@exitvalue
    end

    # Get the string returned from the smig command if an error occurred
    # @return [String] The error message.
    def self.exitstring
      return @@exitstring
    end

    # Perform MovingImages commands one at a time
    # This method unwraps the commands and performs each command individually.
    # Also performs the cleanup commands after the command list.
    # @param commands [Hash] A ruby hash contain the list of commands to run.
    # @return [String] The result from running the commands.
    def self.perform_debugcommands(commands)
      puts "Debug commands"
      begin
        theCommands = commands[:commands]
        theCommands.each do |command|
          newCommandList = CommandModule::SmigCommands.new
          newCommandList.commands = [ command ]
          # newCommandList.set_saveresultstype("lastcommandresult")
          newCommandList.informationreturned = :lastcommandresult
          jsonString = newCommandList.commandshash.to_json
          if jsonString.length > 200000
            tempDir = Dir.tmpdir()
            fileName = SecureRandom.uuid + ".json"
            fullPath = File.join(tempDir, fileName)
            begin
              open(fullPath, 'w') { |f| f.puts jsonString }
              result, exitVal = Open3.capture2(Smig, "performcommand",
                                            "-jsonfile", fullPath)
            ensure
              FileUtils.rm_f(fullPath)
            end
          else
            result, exitVal = Open3.capture2(Smig, "performcommand",
                                            "-jsonstring", jsonString)
          end
          self.raiseexception_unlesstatuszero(
                          method: "Smig.perform_debugcommands",
                          status: exitVal, result: result)
        end
        ""
      rescue RuntimeError => e
        puts e.message
        puts "With error code #{@@exitvalue} and output : #{@@exitstring} "
      ensure
        # now perform the cleanup commands.
        cleanupCommands = commands[:cleanupcommands]
        unless cleanupCommands.nil? || cleanupCommands.length.zero?
          self.perform_debugcommands({ :commands => cleanupCommands })
        end
      end
    end

    # Perform MovingImages commands
    # If an error occurs then then an exception is raised
    # @param commands [Hash] A ruby hash containing the list of commands to run
    # @param debug [bool] Run the commands through self.perform_debugcommands.
    # @return [String] The result from running the commands
    def self.perform_commands(commands, debug: false)
      if commands.respond_to? "commandshash"
        commands = commands.commandshash
      end

      return self.perform_debugcommands(commands) if debug
      jsonString = commands.to_json
      if jsonString.length > 200000
        tempDir = Dir.tmpdir()
        fileName = SecureRandom.uuid + ".json"
        fullPath = File.join(tempDir, fileName)
        begin
          open(fullPath, 'w') { |f| f.puts jsonString }
          result, exitVal = Open3.capture2(Smig, "performcommand",
                                        "-jsonfile", fullPath)
        ensure
          FileUtils.rm_f(fullPath)
        end
      else
        # puts "JSON string length: " + jsonString.length.to_s
        result, exitVal = Open3.capture2(Smig, "performcommand",
                                        "-jsonstring", jsonString)
      end
      self.raiseexception_unlesstatuszero(method: "Smig.perform_commands",
                                          status: exitVal, result: result)
      return result
    end

    # Perform MovingImages commands and return how long the commands took to run
    # @param commands [Hash, #commandshash] The commands to be run
    # @param debug [bool] Should the commands be run one after the other.
    # @return [String] A message informing how long the commands took to run.
    def self.perform_timed_commands(commands, debug: false)
      oldTime = Time.now
      self.perform_commands(commands, debug: debug)
      return "Time to run commands: #{Time.now - oldTime} seconds"
    end

    # Perform a single MovingImages command
    # @param theCommand [Hash, #commandhash] The command to be performed
    # @return [String] The output from running the command
    def self.perform_command(theCommand)
      if theCommand.respond_to? "commandhash"
        theCommand = theCommand.commandhash
      end
      commandWrapper = { :commands => [ theCommand ] }
      self.perform_commands(commandWrapper)
    end

    # Perform a single MovingImages command and don't throw if an error occurs
    # @param theCommand [Hash, #commandhash] The command to be performed
    # @return [String] The output from running the command
    def self.perform_command_nothrow(theCommand)
      if theCommand.respond_to? "commandhash"
        theCommand = theCommand.commandhash
      end
      commandWrapper = { :commands => [ theCommand ] }
      result, _ = Open3.capture2(Smig, "performcommand",
                                      "-jsonstring", commandWrapper.to_json)
      return result
    end

    # Perform MovingImages commands without raising an exception
    # @param commands [Hash, #commandshash] The commands to run.
    # @return [String] The result from running the commands.
    def self.perform_commands_nothrow(commands)
      if commands.respond_to? "commandshash"
        commands = commands.commandshash
      end
      result, _ = Open3.capture2(Smig, "performcommand",
                                      "-jsonstring", commands.to_json)
      return result
    end

    # Get the number of MovingImages base objects    
    # If objecttype is nil, then get the count of all the base objects, 
    # otherwise objecttype is the base object class type which we want to
    # the how many objects of that type there are.
    # @param objecttype [String, Symbol, nil] 
    # @return [Fixnum] The number of base objects.
    def self.get_numberofobjects(objecttype: nil)
      commandHash = { :command => "getproperty",
                      :propertykey => "numberofobjects" }
      commandHash[:objecttype] = objecttype unless objecttype.nil?
      return self.perform_command(commandHash).to_i
    end

    # Get a class type property
    # @param objecttype [String, Symbol] The class type to get the property from
    # @param property [String] The property to be requested of the class.
    # @return [String] The property value
    def self.get_classtypeproperty(objecttype: "bitmapcontext",
                                    property: "numberofobjects")
      commandHash = { :command => "getproperty",
                       :objecttype => objecttype.to_s,
                       :propertykey => property }
      return self.perform_commands( { :commands => [ commandHash ] } )
    end

    # Get a property of an object    
    # The optional imageindex parameter provides an option to get the property 
    # of an image at a particular image index, in for example an image importer
    # object.
    # @param object [Hash] An object identifier.
    # @param propertyKey [String] The property to be requested of the object.
    # @param imageindex [Fixnum] The image index.
    # @return [String] The property value
    def self.get_objectproperty(object, propertyKey, imageindex: nil)
      commandHash = { :command => "getproperty", :receiverobject => object,
                          :propertykey => propertyKey }
      commandHash[:imageindex] = imageindex unless imageindex.nil?
      return self.perform_commands( { :commands => [ commandHash ] } )
    end

    # Close the object with object id.
    # @param object_id [Hash] The object identifier.
    # @return [void] No valid result.
    def self.close_object(object_id)
      close_command = CommandModule.make_close(object)
      Smig.perform_command(close_command)
    end
    
    # Close all MovingImages objects    
    # This is a bit dangerous, if moving images is responding to more than
    # one scripts concurrently then this command will close all the objects,
    # not just the ones related to the script running this command. If
    # objectType is not nil, then only objects of type objectType will be 
    # closed.
    # @param objectType [String, Symbol] Optional object type.
    # @return [String] The result of running command. Empty string is no error.
    def self.closeall_nothrow(objectType: nil)
      commandHash = { :command => "closeall" }
      commandHash[:objecttype] = objectType unless objectType.nil?
      return self.perform_commands_nothrow( { :commands => [ commandHash ] } )
    end
  end
end