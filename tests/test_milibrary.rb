require 'minitest/autorun'
require 'json'

require_relative '../lib/moving_images/spotlight.rb'
require_relative '../lib/moving_images/smigobjectid.rb'
require_relative '../lib/moving_images/smigcommands.rb'
require_relative '../lib/moving_images/midrawing.rb'
require_relative '../lib/moving_images/mifilterchain.rb'
require_relative '../lib/moving_images/milibrary.rb'

include MovingImages

module EqualHashes
  def self.equal_arrays?(array1, array2)
    return false unless array1.kind_of?(Array)
    return false unless array2.kind_of?(Array)
    return false unless array1.size.eql?(array2.size)
    begin
      array1.each_index do |index|
        if array1[index].kind_of?(Hash)
          return false unless self.equal_hashes?(array1[index], array2[index])
        elsif array1[index].kind_of?(Array)
          return false unless self.equal_arrays?(array1[index], array2[index])
        else
          return false unless array1[index].eql?(array2[index])
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
    return false unless hash1.size.eql?(hash2.size)
    begin
      hash1.keys.each do |key|
        if key.eql?('objectname')
          return false if hash2[key].nil?
        else
          if hash1[key].kind_of?(Hash)
            return false unless self.equal_hashes?(hash1[key], hash2[key])
          elsif hash1[key].kind_of?(Array)
            return false unless self.equal_arrays?(hash1[key], hash2[key])
          else
            return false unless hash1[key].eql?(hash2[key])
          end
        end
      end
    rescue RuntimeError => e
      return false
    end
    return true
  end
end


# Test class for creating shape hashes
class TestMILibrary < MiniTest::Unit::TestCase
  def test_dotransition
    json_filepath = File.join(File.dirname(__FILE__), "resources/json", "dotransition.json")
    the_json = File.read(json_filepath)

    the_options = { generate_json: true,
                    outputdir: "~/Desktop/dotransition",
                    sourceimage: "resources/images/DSCN0744.JPG",
                    targetimage: "resources/images/DSCN0746.JPG",
                    exportfiletype: :'public.tiff',
                    transitionfilter: :CIBarsSwipeTransition,
                    basename: 'image',
                    count: 5,
                    inputAngle: 2.0,
                    inputWidth: 20,
                    inputBarOffset: 60,
                    verbose: false,
                    generate_json: true }
    generated_json = MILibrary.dotransition(the_options)
    json_hash = JSON.parse(the_json)
    assert EqualHashes::equal_hashes?(JSON.parse(generated_json), json_hash),
                                                  'Different dotranstion json'
  end
end

