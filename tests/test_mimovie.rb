require 'minitest/autorun'
require 'json'

require_relative '../lib/moving_images/spotlight.rb'
require_relative '../lib/moving_images/smigobjectid.rb'
require_relative '../lib/moving_images/smig.rb'
require_relative '../lib/moving_images/smigcommands.rb'
require_relative '../lib/moving_images/midrawing.rb'
require_relative '../lib/moving_images/mifilterchain.rb'
require_relative '../lib/moving_images/milibrary.rb'
require_relative '../lib/moving_images/mimovie.rb'

include MovingImages
include MIMovie
include MICGDrawing
include CommandModule

module EqualHashes
  def self.equal_arrays?(array1, array2)
    return false unless array1.kind_of?(Array)
    return false unless array2.kind_of?(Array)
    unless array1.size.eql?(array2.size)
      puts "Arrays have different lengths"
      return false
    end
    begin
      array1.each_index do |index|
        if array1[index].kind_of?(Hash)
          return false unless self.equal_hashes?(array1[index], array2[index])
        elsif array1[index].kind_of?(Array)
          return false unless self.equal_arrays?(array1[index], array2[index])
        else
          result = array1[index].eql?(array2[index])
          unless result
            puts "array1: #{array1.to_json}"
            puts "array2: #{arrat2.to_json}"
          end
          return false unless result
        end
      end
    rescue RuntimeError => e
      return false
    end
    return true
  end

  def self.equal_hashes?(hash1, hash2)
    return false unless hash1.kind_of?(Hash)
    return false unless hash2.kind_of?(Hash)
    unless hash1.size.eql?(hash2.size)
      puts "Number of hash attributes different"
      puts "hash1 keys: #{hash1.keys}"
      puts "hash2 keys: #{hash2.keys}"
      return false
    end
    return false unless hash1.size.eql?(hash2.size)
    begin
      hash1.keys.each do |key|
        # First check keys where the key must exist in both but value can differ
        if key.eql?('objectname')
          return false if hash2[key].nil?
        elsif key.eql?('file')
          return false if hash2[key].nil?
        elsif key.eql?('propertyvalue')
          return false if hash2[key].nil?
        elsif key.eql?('imageidentifier')
          return false if hash2[key].nil?
        else
          if hash1[key].kind_of?(Hash)
# Uncomment the following if you want context of difference displayed.
#            areEqual = self.equal_hashes?(hash1[key], hash2[key])
#            unless areEqual
#              puts "hash1: #{hash1.to_json}"
#              puts "hash2: #{hash2.to_json}"
#            end
            return false unless self.equal_hashes?(hash1[key], hash2[key])
          elsif hash1[key].kind_of?(Array)
            return false unless self.equal_arrays?(hash1[key], hash2[key])
          else
            result = hash1[key].eql?(hash2[key])
            unless result
              puts "hash1: #{hash1.to_json}"
              puts "hash2: #{hash2.to_json}"
            end
            return false unless result
          end
        end
      end
    rescue RuntimeError => e
      return false
    end
    return true
  end
end

# Test class for creating hashes that represent times that can be used by movie objects.
class TestMovieTime < MiniTest::Test
  def test_movietime_make
    movie_time = MovieTime.make_movietime(timevalue: 900, timescale: 600)
    assert movie_time[:flags].eql?(1), 'CMTime flag hash value not 1'
    assert movie_time[:epoch].eql?(0), 'CMTime epoch not 0'
    assert movie_time[:value].eql?(900), 'CMTime time value should be 900'
    assert movie_time[:timescale].eql?(600), 'CMTime timescale should be 600'
  end
  
  def test_movietime_make_fromseconds
    movie_time = MovieTime.make_movietime_fromseconds(0.9324)
    assert movie_time[:timeinseconds].eql?(0.9324), 'Movie time not equal to 0.9324'
  end
  
  def test_movietime_make_nextframe
    next_frame = MovieTime.make_movietime_nextsample
    assert next_frame.eql?(:movienextsample), 'Movie time next sample is not :nextsampe'
  end
  
  def test_movietime_make_movie_timerange
    start_time = MovieTime.make_movietime(timevalue: 10010, timescale: 30000)
    duration = MovieTime.make_movietime(timevalue: 1001, timescale: 30000)
    time_range = MovieTime.make_movie_timerange(start: start_time,
                                             duration: duration)
    assert time_range[:start].kind_of?(Hash), 'Start time is not a hash object'
    assert time_range[:duration].kind_of?(Hash), 'Time range duration is not a hash'
    assert time_range[:start][:value].eql?(10010), 'Start time value is not 10010'
    assert time_range[:duration][:timescale].eql?(30000), 'Duration time scale is not 30000'
  end
end

# Test class for creating hashes that represent track identifiers.
class TestMovieTrackIdentifiers < MiniTest::Test
  def test_make_trackidentifier_with_mediatype
    track_id = MovieTrackIdentifier.make_movietrackid_from_mediatype(
                                    mediatype: :vide, trackindex: 0)
    assert track_id[:mediatype].eql?(:vide), 'Media type is not vide'
    assert track_id[:trackindex].eql?(0), 'Track index is not 0'
  end

  def test_make_trackidentifier_with_mediacharacteristic
    track_id = MovieTrackIdentifier.make_movietrackid_from_characteristic(
        characteristic: :AVMediaCharacteristicFrameBased, trackindex: 1)
    assert track_id[:mediacharacteristic].eql?(:AVMediaCharacteristicFrameBased),
                          'Characteristic is not AVMediaCharacteristicFrameBased'
    assert track_id[:trackindex].eql?(1), 'Track index is not 1'
  end

  def test_make_trackidentifier_from_persistenttrackid
    track_id = MovieTrackIdentifier.make_movietrackid_from_persistenttrackid(2)
    assert track_id[:trackid].eql?(2), 'Persistent track id is not 2'
  end
end

# Test class for creating layer instruction hashes for MovieEditor video 
# composition instructions
class TestVideoLayerInstructions < MiniTest::Test
  def test_add_passthrulayerinstruction
    track = MovieTrackIdentifier.make_movietrackid_from_mediatype(
                                                       mediatype: :vide,
                                                      trackindex: 0)
    layer_instructions = VideoLayerInstructions.new
    layer_instructions.add_passthrulayerinstruction(track: track)
    layer_instructions_array = layer_instructions.layerinstructionsarray
    assert layer_instructions_array.count.eql?(1),
                                        'Should have 1 layer instruction'
    assert layer_instructions_array[0][:layerinstructiontype].eql?(
          :passthruinstruction),
          'Layer instruction type is not pass thru'
    assert layer_instructions_array[0][:track].kind_of?(Hash), 
                                        'Track definition is not a hash object'
    assert layer_instructions_array[0][:track][:mediatype].eql?(:vide), 
                                        'Track media type is not :vide'
  end
  
  def test_add_opacitylayerinstruction
    track = MovieTrackIdentifier.make_movietrackid_from_mediatype(
                                                       mediatype: :vide,
                                                      trackindex: 0)
    opacity_starttime = MovieTime.make_movietime(timevalue: 900, timescale: 600)
    layer_instructions = VideoLayerInstructions.new
    layer_instructions.add_opacitylayerinstruction(track: track,
                                            opacityvalue: 0.5,
                                                    time: opacity_starttime)
    layer_instructions_array = layer_instructions.layerinstructionsarray
    assert layer_instructions_array.count.eql?(1),
                                        'Should have 1 layer instruction'
    assert layer_instructions_array[0][:layerinstructiontype].eql?(
          :opacityinstruction), 'Layer instruction type is not opacity'
    assert layer_instructions_array[0][:track].kind_of?(Hash), 
                                        'Track definition is not a hash object'
    assert layer_instructions_array[0][:track][:mediatype].eql?(:vide), 
                                        'Track media type is not :vide'
  end

  def test_add_croplayerinstruction
    track = MovieTrackIdentifier.make_movietrackid_from_mediatype(
                                                       mediatype: :vide,
                                                      trackindex: 0)
    croprect_starttime = MovieTime.make_movietime(timevalue: 2002,
                                                  timescale: 30000)
    layer_instructions = VideoLayerInstructions.new
    crop_rect = MIShapes.make_rectangle(origin: { x: 100, y: 50 },
                                          size: { width: 1400, height: 800 })
    layer_instructions.add_croplayerinstruction(track: track,
                                        croprectvalue: crop_rect,
                                                 time: croprect_starttime)
    layer_instructions_array = layer_instructions.layerinstructionsarray
    assert layer_instructions_array.count.eql?(1),
                                        'Should have 1 layer instruction'
    assert layer_instructions_array[0][:layerinstructiontype].eql?(
          :cropinstruction), 'Layer instruction type is not crop rectangle'
    assert layer_instructions_array[0][:track].kind_of?(Hash), 
                                        'Track definition is not a hash object'
    assert layer_instructions_array[0][:track][:mediatype].eql?(:vide), 
                                        'Track media type is not :vide'
  end
  
  def test_add_transformand_opacitylayerinstruction
    track = MovieTrackIdentifier.make_movietrackid_from_mediatype(
                                                       mediatype: :vide,
                                                      trackindex: 0)
    instruction_starttime = MovieTime.make_movietime(timevalue: 200,
                                                     timescale: 6000)
    layer_instructions = VideoLayerInstructions.new
    layer_instructions.add_opacitylayerinstruction(track: track,
                                            opacityvalue: 0.7,
                                                    time: instruction_starttime)
    transform = MITransformations.make_affinetransform(m11: 0.5, m12: 0.0,
                                    m21: 0.0, m22: 0.5,  tX: 0.0,  tY: 0.0)

    layer_instructions.add_transformlayerinstruction(track: track,
                                            transformvalue: transform,
                                                      time: instruction_starttime)
    
    layer_instructions_array = layer_instructions.layerinstructionsarray
    assert layer_instructions_array.count.eql?(2),
                                        'Should have 2 layer instruction'
    assert layer_instructions_array[1][:layerinstructiontype].eql?(
          :transforminstruction), 'Layer instruction type is not transform'
    assert layer_instructions_array[1][:track].kind_of?(Hash), 
                                        'Track definition is not a hash object'
    assert layer_instructions_array[1][:track][:mediatype].eql?(:vide), 
                                        'Track media type is not :vide'
    assert layer_instructions_array[0][:layerinstructiontype].eql?(
                                                          :opacityinstruction)
  end

end

$resources_dir = File.expand_path(File.join(File.dirname(__FILE__), "resources"))

class TestMovieProcessFramesCommand < MiniTest::Test
  def test_process_movieframe_commandgeneration
    sourceMovie = "/Users/ktam/images/604_sd_clip.mov"
    width = 576
    height = 360
    movieLength = 300.0 # seconds.
    borderWidth = 32
    bitmapWidth = (3.0 * width.to_f * 0.5 + (3+1) * borderWidth).to_i
    bitmapHeight = (4.0 * height.to_f * 0.5 + (4+1) * borderWidth).to_i
    bitmapSize = MIShapes.make_size(bitmapWidth, bitmapHeight)
    baseFileName = "coversheet"
  
    # 1. Create the list of commands object, ready to have commands added to it.
    theCommands = SmigCommands.new
    theCommands.saveresultstype = :lastcommandresult
  
    # 2. Create movie importer and assign to list of commands.
    # Basically after the first block of commands is run, the movie importer
    # is closed automatically in the cleanup commands.
    movieImporterName = SecureRandom.uuid
    movieObject = theCommands.make_createmovieimporter(sourceMovie,
                                                 name: movieImporterName)
    
    # 3. Create the process movie frames command and configure.
    imageIdentifier = SecureRandom.uuid
  
    processFramesCommand = ProcessFramesCommand.new(movieObject)
    processFramesCommand.create_localcontext = false
    processFramesCommand.imageidentifier = imageIdentifier
  
    track_id = MovieTrackIdentifier.make_movietrackid_from_mediatype(
                                                mediatype: :vide, trackindex: 0)
    
    processFramesCommand.videotracks = [ track_id ]
  
    # 4. Make a pre-process command list.
    preProcessCommands = []
    
    # 5. Make a create a bitmap context command.
    bitmapName = SecureRandom.uuid
    createBitmapCommand = CommandModule.make_createbitmapcontext(
                                            name: bitmapName, size: bitmapSize)
  
    bitmapObject = SmigIDHash.make_objectid(objecttype: :bitmapcontext,
                                            objectname: bitmapName)
  
    # 6. Add the create bitmap context object command to the pre-process list.
    preProcessCommands.push(createBitmapCommand.commandhash)
  
    # 7. Make a create exporter object command and add it to the pre-process list
    exporterName = SecureRandom.uuid
    createExporterCommand = CommandModule.make_createexporter(
              "~/placeholder.jpg", export_type: 'public.jpeg', name: exporterName)
    preProcessCommands.push(createExporterCommand.commandhash)
    exporterObject = SmigIDHash.make_objectid(objecttype: :imageexporter,
                                              objectname: exporterName)
  
    # 8. Assign the pre-process commands to the process movie frames command.
    processFramesCommand.preprocesscommands = preProcessCommands
    
    # 9. Add a close bitmap object command to cleanup commands.
    processFramesCommand.add_tocleanupcommands_closeobject(bitmapObject)
    
    # 10. Add a close exporter object command to cleanup commands.
    processFramesCommand.add_tocleanupcommands_closeobject(exporterObject)
  
    # 11. Add a remove image from collection command to cleanup commands.
    processFramesCommand.add_tocleanupcommands_removeimage(imageIdentifier)
  
    # 12. Prepare and start looping for creating process frame instrutions.
    numFrames = 12
    framesPerPage = 12 # 3 x 4
    frameDuration = movieLength / (numFrames - 1)
    pageNumber = 0
    x = 0
    y = 0
    halfWidth = width / 2
    halfHeight = height / 2
    drawnFrameSize = MIShapes.make_size(halfWidth, halfHeight)
    textBoxSize = MIShapes.make_size(halfWidth, borderWidth * 3 / 4)
    filesToCompare = []
    numFrames.times do |i|
      # 13. Create a ProcessMovieFrameInstruction object
      frameInstructions = ProcessMovieFrameInstructions.new
      
      # 14. Calculate the frame time and assign it.
      time = i.to_f * frameDuration
      frameTime = MovieTime.make_movietime_fromseconds(time)
      frameInstructions.frametime = frameTime
      
      # 15. Determine the frame number on the page & destination rectangle.
      frameNumber = i % framesPerPage
      x = frameNumber % 3
      y = 3 - (frameNumber / 3)
      xloc = x * halfWidth + (x + 1) * borderWidth
      yloc = y * halfHeight + (y + 1) * borderWidth
      origin = MIShapes.make_point(xloc, yloc)
      drawnFrameRect = MIShapes.make_rectangle(size: drawnFrameSize,
                                             origin: origin)
      
      # 16. Create the draw image element to draw the frame onto the bitmap.
      drawImageElement = MIDrawImageElement.new()
      drawImageElement.destinationrectangle = drawnFrameRect
      drawImageElement.set_imagecollection_imagesource(identifier: imageIdentifier)
      
      # 17. Create the draw image command and add it to the frame instructions.
      drawImageCommand = CommandModule.make_drawelement(bitmapObject,
                        drawinstructions: drawImageElement, createimage: false)
      frameInstructions.add_command(drawImageCommand)
      
      # 18. Prepare drawing the text with the time.
      timeString = "Frame time: %.3f secs" % time
      drawStringElement = MIDrawBasicStringElement.new()
      drawStringElement.stringtext = timeString
      drawStringElement.userinterfacefont = "kCTFontUIFontLabel"
      drawStringElement.textalignment = "kCTTextAlignmentCenter"
      drawStringElement.fillcolor = MIColor.make_rgbacolor(0.0, 0.0, 0.0)
      boxOrigin = MIShapes.make_point(xloc, yloc - borderWidth)
      boundingBox = MIShapes.make_rectangle(size: textBoxSize, origin: boxOrigin)
      drawStringElement.boundingbox = boundingBox
      drawTextCommand = CommandModule.make_drawelement(bitmapObject,
                      drawinstructions: drawStringElement, createimage: false)
      frameInstructions.add_command(drawTextCommand)
  
      # 19. If this was the last frame to be drawn then export the page.
      if (frameNumber == framesPerPage - 1) || i == numFrames - 1
        addImageCommand = CommandModule.make_addimage(exporterObject, bitmapObject)
        frameInstructions.add_command(addImageCommand)
        pageNum = (i / 12).to_s.rjust(3, '0')
        fileName = baseFileName + pageNum + ".jpg"
        filesToCompare.push(fileName)
        filePath = File.join("/Users/ktam", fileName)
        setExportPathCommand = CommandModule.make_set_objectproperty(
                                                               exporterObject,
                                                  propertykey: :exportfilepath,
                                                propertyvalue: filePath)
        frameInstructions.add_command(setExportPathCommand)
        exportCommand = CommandModule.make_export(exporterObject)
        frameInstructions.add_command(exportCommand)
        # 20. Now redraw the bitmap context with a white rectangle.
        redrawBitmapElement = MIDrawElement.new(:fillrectangle)
        redrawBitmapElement.fillcolor = MIColor.make_rgbacolor(1.0, 1.0, 1.0)
        redrawBitmapElement.rectangle = MIShapes.make_rectangle(size: bitmapSize)
        redrawCommand = CommandModule.make_drawelement(bitmapObject,
                                     drawinstructions: redrawBitmapElement)
        frameInstructions.add_command(redrawCommand)
      end
      # 21. Set the frame processing intructions to the process frames command.
      processFramesCommand.add_processinstruction(frameInstructions)
    end
    
    # 22. Add the process frames command to the list of commands.
    theCommands.add_command(processFramesCommand)
    result = JSON.pretty_generate(theCommands.commandshash)
    json_filepath = File.join($resources_dir, "json", "processframescommand.json")
    # File.write(json_filepath, result)
    the_json = File.read(json_filepath)
    json_hash = JSON.parse(the_json)
    assert EqualHashes::equal_hashes?(JSON.parse(result), json_hash),
                                              'Different process movie frame json'
  end
end

# Testing the creation of audio instructions.
class TestMovieAudioInstruction < MiniTest::Test
  def test_make_setvolume_audio_instruction
    track_id = MovieTrackIdentifier.make_movietrackid_from_mediatype(
                                    mediatype: :soun, trackindex: 0)
    volumeInstruction = AudioInstruction.new(track: track_id)
    
    volumeTime = MovieTime.make_movietime_fromseconds(2.0)
    volumeInstruction.set_volume_instruction(time: volumeTime, volume: 0.5)
    
    hashOriginal = {
      track: {
        mediatype: :soun,
        trackindex: 0
      },
      audioinstruction: :volumeinstruction,
      time: { timeinseconds: 2.0 },
      instructionvalue: 0.5
    }
    # puts JSON.pretty_generate(hashOriginal)
    # puts JSON.pretty_generate(volumeInstruction.audioinstructionhash)
    hashesEqual = EqualHashes::equal_hashes?(hashOriginal,
                                      volumeInstruction.audioinstructionhash)
    assert hashesEqual, "Volume instructions different."
  end

  def test_make_setvolumeramp_audio_instruction
    track_id = MovieTrackIdentifier.make_movietrackid_from_mediatype(
                                    mediatype: :soun, trackindex: 0)
    volumeInstruction = AudioInstruction.new(track: track_id)
    
    startVolumeRampTime = MovieTime.make_movietime(timevalue: 6000, timescale: 6000)
    volumeRampDuration = MovieTime.make_movietime(timevalue: 6000, timescale: 12000)
    volumeRampTimeRange = MovieTime.make_movie_timerange(start: startVolumeRampTime,
                                                      duration: volumeRampDuration)
    
    volumeInstruction.set_volumeramp_instruction(timerange: volumeRampTimeRange,
                                               startvolume: 0.0,
                                                 endvolume: 1.0)
                                                 
    hashOriginal = {
      track: {
        mediatype: :soun,
        trackindex: 0
      },
      audioinstruction: :volumerampinstruction,
      timerange: {
        start: MovieTime.make_movietime(timevalue: 6000, timescale: 6000),
        duration: MovieTime.make_movietime(timevalue: 6000, timescale: 12000)
      },
      startrampvalue: 0.0,
      endrampvalue: 1.0
    }
    # puts JSON.pretty_generate(hashOriginal)
    # puts JSON.pretty_generate(volumeInstruction.audioinstructionhash)
    hashesEqual = EqualHashes::equal_hashes?(hashOriginal,
                                      volumeInstruction.audioinstructionhash)
    assert hashesEqual, "Volume instructions different."
  end
end
