

module MovingImages
  module MIMovie
    # Methods for creating movie time hashes.    
    module MovieTime
      # Create a movie time hash which takes a seconds float value.    
      # @param seconds [Float] Time in seconds from start of movie.
      # @return [Hash] A hash object containing the movie time.
      def self.make_movietime_fromseconds(seconds)
        return { time: seconds }
      end
      
      # Create a movie time hash which takes a time value and scale.    
      # The movie time is specified by a numerator and a denominator. The
      # time in the movie is specified by the numerator divided by the
      # denominator in seconds. The numerator is the time value and denominator
      # is the time scale. The timescale often has a value of 600.
      # @param timevalue [Bignum, Fixnum] The time numerator.
      # @param timescale [Fixnum] The denominator.
      # @return [Hash] A hash object representing a movie CMTime structure.
      def self.make_movietime(timevalue: nil, timescale: nil)
        fail "The movie time value was not specified. " if timevalue.nil?
        fail "The movie time scale was not specified. " if timescale.nil?
        return { value: timevalue, timescale: timescale, flags: 1, epoch: 0 }
      end
      
      # The movie time is the time of the next movie sample.    
      # @return [:movienextsample] The value for the frame time property.
      def self.make_movietime_nextsample()
        return :movienextsample
      end
    end
  
    # Functions for creating track identifying hashes.
    module MovieTrackIdentifier
      # Create a track id hash from the mediatype and track index.    
      # Possible mediatype values are: "soun clcp meta muxx sbtl text tmcd vide"
      # That is sound, clip, metadata, muxx, subtitle, text, tmcd, and video.
      # @param mediatype [String] Optional or one of the values listed above.
      # @param trackindex [Fixnum] An index into the list of tracks of type.
      # @return [Hash] A Track identifier hash object.
      def self.make_movietrackid_from_mediatype(mediatype: nil, trackindex: nil)
        # fail "The track media type was not specified. " if mediatype.nil?
        fail "The track index was not specified. " if trackindex.nil?
        trackID = { trackindex: trackindex }
        trackID[:mediatype] = mediatype unless mediatype.nil?
        return trackID
      end
      
      # Create a track id hash from the media characteristic and track index.    
      # Possible characteristic values are: "AVMediaCharacteristicAudible
      # AVMediaCharacteristicFrameBased AVMediaCharacteristicLegible
      # AVMediaCharacteristicVisual" plus others. A track can conform to more than
      # characteristic unlike media type.
      # @param mediacharacteristic [String] Optional or one of the values listed above.
      # @param trackindex [Fixnum] An index into the list of tracks of type.
      # @return [Hash] A Track identifier hash object.
      def self.make_movietrackid_from_characteristic(characteristic: nil,
                                                     trackindex: nil)
        # fail "The track characteristic was not specified. " if characteristic.nil?
        fail "The track index was not specified. " if trackindex.nil?
        trackID = { trackindex: trackindex }
        trackID[:mediacharacteristic] = characteristic unless characteristic.nil?
        return trackID
      end
      
      # Create a track id hash from a persistent track id value.    
      # @param trackid [Fixnum] A track id within context of a movie doesn't change
      # @return [Hash] A track identifier hash object.
      def self.make_movietrackid_from_persistenttrackid(trackid)
        return { trackid: trackid }
      end
    end
    
    # ProcessMovieFrameInstructions Objects are instructions for processing a frame    
    class ProcessMovieFrameInstructions
      # Initialize the ProcessMovieFrameInstructions object.
      def initialize()
        @instructions = { }
      end
      
      # Return the hash representation of the process movie frame instructions
      # @return [Hash] The instructions hash.
      def instructionshash
        @instructions
      end
      
      # Set the frame time. Required.    
      # @param frameTime [Hash] The frameTime represented as a hash. See {MovieTime}
      # @return [Hash] The frame time just assigned. 
      def frametime=(frameTime)
        @instructions[:frametime] = frameTime
        frameTime
      end
      
      # Set the list of commands to process the movie frame. Required.    
      # This will overwrite any commands that might have already been added
      # to the commands list. Alternative to using add_command.
      # @param commands [Array<Hash>] The array of commands to process movie frame.
      # @return [Array<Hash>] The list commands just assigned.  
      def commands=(commands)
        @instructions[:commands] = commands
        commands
      end
      
      # Add a command to the list of process frame instrution commands. Required.    
      # @param command [Hash, #commandhash] The command to be added to command list
      # @return [Hash] The command added to the command list.
      def add_command(command)
        if command.respond_to?("commandhash")
          command = command.commandhash
        end
        if @instructions[:commands].nil?
          @instructions[:commands] = [ command ]
        else
          @instructions[:commands].push(command)
        end
        command
      end
      
      # Set the identifier to be used for the movie frame to be processed. Optional.    
      # To be able to access the movie frame image, the commands uses the identifier.
      # The same identifier can be used for all movie frames, or if more fine
      # grained control is needed then you can specify the image identifier here.
      # @param identifier [String] The image identifier string value.
      # @return [String] The image identifier string just assigned.
      def imageidentifier=(identifier)
        @instructions[:imageidentifier] = identifier
        identifier
      end
    end
  end
end
