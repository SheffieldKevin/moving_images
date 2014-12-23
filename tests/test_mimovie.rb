require 'minitest/autorun'
require 'json'

require_relative '../lib/moving_images/mimovie'

include MovingImages

# Test class for creating hashes that represent times that can be used by movie objects.
class TestMovieTime < MiniTest::Unit::TestCase
  def test_movietime_make
    movie_time = MovieTime.make_movietime(timevalue: 900, timescale: 600)
    assert movie_time[:flags].eql?(1), 'CMTime flag hash value not 1'
    assert movie_time[:epoch].eql?(0), 'CMTime epoch not 0'
    assert movie_time[:value].eql?(900), 'CMTime time value should be 900'
    assert movie_time[:timescale].eql?(600), 'CMTime timescale should be 600'
  end
  
  def test_movietime_make_fromseconds
    movie_time = MovieTime.make_movietime_fromseconds(0.9324)
    assert movie_time[:time].eql?(0.9324), 'Movie time not equal to 0.9324'
  end
end

# Test class for creating hashes that represent track identifiers.
class TestMovieTrackIdentifiers
  def test_make_trackidentifier_with_mediatype
    track_id = MovieTrackIdentifier.make_movietrackid_from_mediatype(
                                    mediatype: :vide, trackindex: 0)
    assert track_id[:mediatype].eql?(:vide), 'Media type is not vide'
    assert track_id[:trackindex].eql?(0), 'Track index is not 0'
  end

  def test_make_trackidentifier_with_mediacharacteristic
    track_id = MovieTrackIdentifier.make_movietrackid_from_characteristic(
        characteristic: :AVMediaCharacteristicFrameBased, trackindex: 1)
    assert track_id[:characteristic].eql?(:AVMediaCharacteristicFrameBased),
                          'Characteristic is not AVMediaCharacteristicFrameBased'
    assert track_id[:trackindex].eql?(1), 'Track index is not 1'
  end

  def test_make_trackidentifier_from_persistenttrackid
    track_id = MovieTrackIdentifier.make_movietrackid_from_persistenttrackid(2)
    assert track_id[:trackid].eql?(2), 'Persistent track id is not 2'
  end
end
