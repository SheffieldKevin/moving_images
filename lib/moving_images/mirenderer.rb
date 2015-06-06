# Copyright (c) 2015 Zukini Ltd.

module MovingImages
  # A representation of the objective-c class MIRenderer
  class MIRenderer
    # Initialize a MIRender object which sets @rendererHash to an empty list.    
    # @return [MIPath]
    def initialize()
      # The ruby hash representation of the MIRenderer object.
      @rendererHash = {}
    end

    # Return the render hash.    
    # @return [Hash] The render hash.
    def renderhash
      @renderHash
    end
    
    # Assign the setup commands to the renderer hash.    
    # @param commands [Hash, #commandshash] The setup commands to be assigned.
    # @return [Hash] The assigned setup commands.
    def setupcommands=(commands)
      if commands.respond_to? "commandshash"
        commands = commands.commandshash
      end
      @renderHash[:setupcommandsdictionry] = commands
    end
    
    # Assign the background commands to the renderer hash.    
    # These are commands that will be run not on the main thread. Time
    # consuming commands can be included.
    # @param commands [Hash, #commandshash] The background commands to be assigned
    # @return [Hash] The assigned background commands.
    def backgroundcommands=(commands)
      if commands.respond_to? "commandshash"
        commands = commands.commandshash
      end
      @renderHash[:backgroundcommandsdictionary] = commands
    end
    
    # Assign the foreground commands to the renderer hash.    
    # These are commands that should be completed quickly otherwise they will
    # block the main thread.
    # @param commands [Hash, #commandshash] The foreground commands to be assigned
    # @return [Hash] The assigned foreground commands.
    def foregroundcommands=(commands)
      if commands.respond_to? "commandshash"
        commands = commands.commandshash
      end
      @renderHash[:mainthreadcommandsdictionary] = commands
    end

    # Assign the cleanup commands to the renderer hash.    
    # These are commands that will be used to do any final cleanup before the
    # the renderering object is disposed of.
    # @param commands [Hash, #commandshash] The foreground commands to be assigned
    # @return [Hash] The assigned foreground commands.
    def cleanupcommands=(commands)
      if commands.respond_to? "commandshash"
        commands = commands.commandshash
      end
      @renderHash[:mainthreadcommandsdictionary] = commands
    end
    
    # Assign the draw instructions.    
    # The draw instructions will be applied directly to the view's context.
    # This is similar to the draw instructions applied to the simple renderer.
    # The difference being the draw instructions can draw images generated by the
    # background or foreground commands into the context.
    def drawinstructions=(drawInstructions)
      if drawInstructions.respond_to? "elementhash"
        drawInstructions = drawInstructions.elementhash
      end
      @renderHash[:drawdictionary] = drawInstructions
    end
  end
end
