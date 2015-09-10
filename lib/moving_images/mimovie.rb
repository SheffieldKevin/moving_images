# Copyright (c) 2015 Zukini Ltd.

module MovingImages
  module MIMovie
    # Methods for creating movie time hashes.    
    module MovieTime
      # Make a movie time hash which takes a seconds float value.    
      # @param seconds [Float, String] Time in seconds from start of movie.
      # @return [Hash] A hash object containing the movie time.
      def self.make_movietime_fromseconds(seconds)
        return { timeinseconds: seconds }
      end
      
      # Make a movie time hash which takes a time value and scale.    
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
      
      
      # Make a movie time range that takes a start time and a duration time.    
      # Both the start and duration times are [Hash] objects created by one
      # of {MovieTime.make_movietime}, {MovieTime.make_movietime_fromseconds}
      # @param start [Hash] The start time of the time range.
      # @param duration [Hash] The duration of the time range.
      # @return [Hash] The time range hash.
      def self.make_movie_timerange(start: nil, duration: nil)
        return { start: start, duration: duration }
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
      # @param characteristic [String] Optional or one of the values listed above.
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
    
    # Objects of the FrameOptions class specify the frametime within the move
    # from when to get the image frame and the video tracks from which to generate
    # the image. 
    class FrameOptions

      # Initialize the FrameOptions object.
      def initialize()
        @options = { }
      end
      
      # Return the FrameOptions hash representation
      def optionshash
        @options
      end
      
      # Set a frame time dictionary. Required. See {MovieTime}
      def frametime=(frametime)
        @options[:frametime] = frametime
      end
      
      # Set a list of tracks. Optional. See {MovieTrackIdentifier}
      def tracks=(tracks)
        @options[:tracks] = tracks
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
      
      # Add a command to the list of process frame instrution commands.    
      # Required at least once.
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
    
    module CleanAperture
      # Make a cleanaperture Hash. A clean aperture is made up of dimensions
      # and offset.    
      # @param horizontal_offset [Fixnum] The offset from left edge of frame.
      # @param vertical_offset [Fixnum] The offset from the bottom edge of frame.
      # @param width [Fixnum] The width of the clean aperture.
      # @param height [Fixnum] The height of the clean aperture.
      def self.make_cleanaperture(horizontal_offset, vertical_offset,
                                  width, height)
        return {
                 AVVideoCleanApertureWidthKey: width,
                 AVVideoCleanApertureHeightKey: height,
                 AVVideoCleanApertureHorizontalOffsetKey: horizontal_offset,
                 AVVideoCleanApertureVerticalOffsetKey: vertical_offset
               }
      end
    end

    # Instruction for specifying track volume. Only set one of volume/volumeramp.
    class AudioInstruction
      # Initialize an audio instruction with an optional track.    
      # @param track [Hash] Track identifier to have volume change applied to.
      def initialize(track: nil)
        @audioinstructions = {}
        @audioinstructions[:track] = track unless track.nil?
      end
      
      # Return the audio instruction.
      # @return [Hash] The audio instructions.
      def audioinstructionhash
        @audioinstructions
      end
      
      # Assign the track to have volume instruction applied. 
      # @param track [Hash] Track identifier to have volume change applied to.
      def track=(track)
        @audioinstructions[:track] = track
      end

      # Assign a volume instruction.    
      # The volume will remain at this level until the next time the volume
      # is specified or the audio track ends.
      # @param time [Hash] The time when to set the audio track volume level.
      #   See: {MovieTime.make_movietime}
      # @param volume [Float] The volume level to be assigned.. Range 0..1
      # @return [Hash] The audio instructions.
      def set_volume_instruction(time: nil, volume: nil)
        @audioinstructions[:audioinstruction] = :volumeinstruction
        @audioinstructions[:time] = time
        @audioinstructions[:instructionvalue] = volume
        @audioinstructions
      end

      # Assign a volume ramp audio instruction.    
      # @param timerange [Hash] The time range over which the volume
      #   ramp is applied. The time range specifies the start time and how long
      #   the ramp takes. {MovieTime.make_movie_timerange}
      # @param startvolume [Float] The start volume level. Range 0..1
      # @param endvolume [Float] The end volume level. Range 0..1
      # @return [Hash] The audio instructions.
      def set_volumeramp_instruction(timerange: nil, startvolume: nil,
                                     endvolume: nil)
        @audioinstructions[:audioinstruction] = :volumerampinstruction
        @audioinstructions[:timerange] = timerange
        @audioinstructions[:startrampvalue] = startvolume
        @audioinstructions[:endrampvalue] = endvolume
        @audioinstructions
      end
    end
    
    # An array of layer video composition instructions which is part of a 
    # video composition instruction. See {CommandModule.make_addvideoinstruction}
    # To get the array of layer instructions to be passed into the 
    # make_addvideoinstruction command use the layerinstructionsarray method.
    class VideoLayerInstructions
      # Initialize a VideoLayerInstructions object.
      def initialize()
        @layerinstructions = []
      end
      
      # Return the array of video layer instructions.
      def layerinstructionsarray
        @layerinstructions
      end
      
      # Add a passthru layer instruction layer to the list of layer instructions.
      # @param track [Hash] Track identifier to have layer instruction applied to.
      # @return [Hash] The layer instruction 
      def add_passthrulayerinstruction(track: nil)
        fail "Track needs to be defined" if track.nil?
        passthru = {
          layerinstructiontype: :passthruinstruction,
          track: track
        }
        @layerinstructions.push(passthru)
      end

      # Add an opacity layer instruction to the list of layer instructions.    
      # The opacity layer instruction is applied to the specified track.
      # @param track [Hash] The identified track, see {MovieTrackIdentifier}
      # @param opacityvalue [Float] the opacity to apply to the track.
      # @param time [Hash] The starting time from when the opacity layer
      #   instruction is applied. This must be within the time range specified
      #   for the containing video composition instruction. Optional. {MovieTime}
      # @return [Hash] The opacity layer instruction just added to list.
      def add_opacitylayerinstruction(track: nil,
                               opacityvalue: nil,
                                       time: nil)
        fail "Track needs to be defined" if track.nil?
        fail "opacityvalue needs to be defined" if opacityvalue.nil?
        opacitylayerinstruction = {
          layerinstructiontype: :opacityinstruction,
          instructionvalue: opacityvalue,
          track: track
        }
        unless time.nil?
          opacitylayerinstruction[:time] = time
        end
        @layerinstructions.push(opacitylayerinstruction)
      end
      
      # Add an crop layer instruction to the list of layer instructions.    
      # The crop layer instruction is applied to the specified track.
      # @param track [Hash] The identified track, see {MovieTrackIdentifier}
      # @param croprectvalue [Hash] the crop rectangle to apply to the track.
      #   See {MICGDrawing::MIShapes.make_rectangle}
      # @param time [Hash] The starting time from when the crop layer
      #   instruction is applied. This must be within the time range specified
      #   for the containing video composition instruction. Optional. {MovieTime}
      # @return [Hash] The crop layer instruction just added to list.
      def add_croplayerinstruction(track: nil,
                           croprectvalue: nil,
                                    time: nil)
        fail "Track needs to be defined" if track.nil?
        fail "croprectvalue needs to be defined" if croprectvalue.nil?
        croplayerinstruction = {
          layerinstructiontype: :cropinstruction,
          instructionvalue: croprectvalue,
          track: track
        }
        unless time.nil?
          croplayerinstruction[:time] = time
        end
        @layerinstructions.push(croplayerinstruction)
      end

      # Add an transform layer instruction to the list of layer instructions.    
      # The transform layer instruction is applied to the specified track.
      # @param track [Hash] The identified track, see {MovieTrackIdentifier}
      # @param transformvalue [Hash] the transform to apply to the track.
      #   See {MICGDrawing::MITransformations}
      # @param time [Hash] The starting time from when the opacity layer
      #   instruction is applied. This must be within the time range specified
      #   for the containing video composition instruction. Optional. {MovieTime}
      # @return [Hash] The transform layer instruction just added to list.
      def add_transformlayerinstruction(track: nil,
                               transformvalue: nil,
                                         time: nil)
        fail "Track needs to be defined" if track.nil?
        fail "transformvalue needs to be defined" if transformvalue.nil?
        transforminstruction = {
          layerinstructiontype: :transforminstruction,
          instructionvalue: transformvalue,
          track: track
        }
        unless time.nil?
          transforminstruction[:time] = time
        end
        @layerinstructions.push(transforminstruction)
      end
      
      # Add an opacity ramp layer instruction to the list of layer instructions.    
      # The opacity ramp layer instruction is applied to the specified track.
      # The timerange parameter specifies the start time and duration of the
      # opacity ramp.
      # @param track [Hash] The identified track, see {MovieTrackIdentifier}
      # @param startopacityvalue [Float] the initial opacity value to apply. (0-1)
      # @param endopacityvalue [Float] the final opacity value to be applied. (0-1)
      # @param timerange [Hash] The time range over which the opacity ramp is
      #   applied. The time range specifies the start time and how long the
      #   ramp takes. Optional. (MovieTime.make_movie_timerange)
      # @return [Hash] The opacity ramp layer instruction just added to list.
      def add_opacityramplayerinstruction(track: nil,
                              startopacityvalue: 1.0,
                                endopacityvalue: 0.0,
                                      timerange: nil)
        fail "Track needs to be defined" if track.nil?
        fail "start opacity value needs to be defined" if startopacityvalue.nil?
        fail "end opacity value needs to be defined" if endopacityvalue.nil?
        opacity_rampinstruction = {
          layerinstructiontype: :opacityramp,
                startrampvalue: startopacityvalue,
                  endrampvalue: endopacityvalue,
                         track: track
        }
        opacity_rampinstruction[:timerange] = timerange unless timerange.nil?
        @layerinstructions.push(opacity_rampinstruction)
      end
      
      # Add an crop rect ramp layer instruction to the list of layer instructions.    
      # The crop rect ramp layer instruction is applied to the specified track.
      # The timerange parameter specifies the start time and duration of the
      # crop rect ramp.
      # @param track [Hash] The identified track, see {MovieTrackIdentifier}
      # @param startcroprectvalue [Hash] the initial rect value to apply.
      #   See {MICGDrawing::MIShapes.make_rectangle}
      # @param endcroprectvalue [Hash] the final rect value to be applied.
      #   See {MICGDrawing::MIShapes.make_rectangle}
      # @param timerange [Hash] The time range over which the crop rectangle
      #   ramp is applied. The time range specifies the start time and how long
      #   the ramp takes. Optional. (MovieTime.make_movie_timerange)
      # @return [Hash] The crop rect ramp layer instruction just added to list.
      def add_croprectramplayerinstruction(track: nil,
                              startcroprectvalue: nil,
                                endcroprectvalue: nil,
                                       timerange: nil)
        fail "Track needs to be defined" if track.nil?
        fail "start crop rectangle value needs to be defined" if startcroprectvalue.nil?
        fail "end crop rectangle value needs to be defined" if endcroprectvalue.nil?
        croprect_rampinstruction = {
          layerinstructiontype: :cropramp,
                startrampvalue: startcroprectvalue,
                  endrampvalue: endcroprectvalue,
                         track: track
        }
        croprect_rampinstruction[:timerange] = timerange unless timerange.nil?
        @layerinstructions.push(croprect_rampinstruction)
      end

      # Add an transform ramp layer instruction to the list of layer instructions.    
      # The transform ramp layer instruction is applied to the specified track.
      # The timerange parameter specifies the start time and duration of the
      # transform ramp. The start and end transform values can be defined either
      # by a Hash representation of an affine transform, or an array of context
      # transformations. See {MICGDrawing::MITransformations}
      # @param track [Hash] The identified track, see {MovieTrackIdentifier}
      # @param starttransformvalue [Hash, Array] the initial transform to apply.
      # @param endtransformvalue [Hash, Array] the final transform to be applied.
      # @param timerange [Hash] The time range over which the transform
      #   ramp is applied. The time range specifies the start time and how long
      #   the ramp takes. Optional. (MovieTime.make_movie_timerange)
      # @return [Hash] The transform ramp layer instruction just added to list.
      def add_transformramplayerinstruction(track: nil,
                              starttransformvalue: nil,
                                endtransformvalue: nil,
                                        timerange: nil)
        fail "Track needs to be defined" if track.nil?
        fail "start transform value needs to be defined" if starttransformvalue.nil?
        fail "end transform value needs to be defined" if endtransformvalue.nil?
        transform_rampinstruction = {
          layerinstructiontype: :transformramp,
                startrampvalue: starttransformvalue,
                  endrampvalue: endtransformvalue,
                         track: track
        }
        transform_rampinstruction[:timerange] = timerange unless timerange.nil?
        @layerinstructions.push(transform_rampinstruction)
      end
    end
  end
end
