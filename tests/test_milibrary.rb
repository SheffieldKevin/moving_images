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

# The equal_hashes method iterates through a ruby hash
# and its array and compares entries. There are three
# properties that are ignored for comparison purposes.
# These properties are: 'objectname', 'file',
# 'propertyvalue' This is to deal with the fact that
# object names are generated in each run using
# 'SecureRandom'. That full paths to files on
# different computers will be different. The last is
# that getting dimensions from images will fail
# for images in an installed ruby gem. It uses
# Spotlight to get image dimensions which fails on
# files that Spotlight believes are system files.

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
        if key.eql?('objectname')
          return false if hash2[key].nil?
        elsif key.eql?('file')
          return false if hash2[key].nil?
        elsif key.eql?('propertyvalue')
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

$resources_dir = File.expand_path(File.join(File.dirname(__FILE__), "resources"))
$images_dir = File.join($resources_dir, "images")

# Test class for creating shape hashes
class TestMILibrary < MiniTest::Test
  def test_dotransition
    json_filepath = File.join($resources_dir, "json", "dotransition.json")
    the_json = File.read(json_filepath)

    the_options = { generate_json: true,
                    outputdir: $resources_dir,
                    sourceimage: File.join($images_dir, "DSCN0744.JPG"),
                    targetimage: File.join($images_dir, "DSCN0746.JPG"),
                    exportfiletype: :'public.tiff',
                    transitionfilter: :CIBarsSwipeTransition,
                    basename: 'image',
                    count: 5,
                    inputAngle: 2.0,
                    inputWidth: 20,
                    inputBarOffset: 60,
                    verbose: false,
                    softwarerender: false }
    generated_json = MILibrary.dotransition(the_options)
#    File.write(json_filepath, generated_json)
    json_hash = JSON.parse(the_json)
    assert EqualHashes::equal_hashes?(JSON.parse(generated_json), json_hash),
                                                  'Different dotransition json'
  end

  def test_customcrop
    json_filepath = File.join($resources_dir, "json", "customcrop.json")
    the_json = File.read(json_filepath)

    the_options = MILibrary::Utility.make_customcrop_options(
                                      left: 30,
                                      right: 120,
                                      top: 60,
                                      bottom: 90,
                                      outputdir: $resources_dir,
                                      exportfiletype: 'public.jpeg',
                                      quality: 0.8,
                                      copymetadata: false,
                                      assume_images_have_same_dimensions: true,
                                      async: false,
                                      verbose: false)
    the_options[:generate_json] = true
    files = [ "#{File.join($images_dir, "DSCN0744.JPG")}",
              "#{File.join($images_dir, "DSCN0746.JPG")}" ]
    file_list = { width: 908, height: 681, files: files }
    generated_json = MILibrary.customcrop_files(the_options, file_list)
#    File.write(json_filepath, generated_json)
    json_hash = JSON.parse(the_json)
    assert EqualHashes::equal_hashes?(JSON.parse(generated_json), json_hash),
                                                  'Different customcrop json'
  end

  def test_custompad
    json_filepath = File.join($resources_dir, "json", "custompad.json")
    the_json = File.read(json_filepath)

    the_options = MILibrary::Utility.make_custompad_options(
                                    left: 25,
                                    right: 100,
                                    top: 75,
                                    bottom: 50,
                                    red: 0.4,
                                    green: 0.2,
                                    blue: 0.1,
                                    scale: 1.0,
                                    outputdir: $resources_dir,
                                    exportfiletype: :'public.png',
                                    quality: 0.9,
                                    copymetadata: true,
                                    assume_images_have_same_dimensions: false,
                                    async: true,
                                    verbose: false)

    the_options[:generate_json] = true
    files = [ "#{File.join($images_dir, "DSCN0744.JPG")}",
              "#{File.join($images_dir, "DSCN0746.JPG")}" ]
    file_list = { width: 908, height: 681, files: files }
    generated_json = MILibrary.custompad_files(the_options, file_list)
#    File.write(json_filepath, generated_json)
    json_hash = JSON.parse(the_json)
    assert EqualHashes::equal_hashes?(JSON.parse(generated_json), json_hash),
                                                  'Different custompad json'
  end

  def test_scale
    json_filepath = File.join($resources_dir, "json", "scale.json")
    the_json = File.read(json_filepath)

    the_options = MILibrary::Utility.make_scaleimages_options(
                                          scalex: 0.5,
                                          scaley: 0.5,
                                          outputdir: $resources_dir,
                                          exportfiletype: :'public.tiff',
                                          quality: 0.7,
                                          interpqual: :default,
                                          copymetadata: false,
                                          assume_images_have_same_dimensions: false,
                                          async: true,
                                          verbose: false)

    the_options[:generate_json] = true
    files = [ "#{File.join($images_dir, "DSCN0744.JPG")}",
              "#{File.join($images_dir, "DSCN0746.JPG")}" ]
    file_list = { width: 908, height: 681, files: files }
    generated_json = MILibrary.scale_files(the_options, file_list)
#    File.write(json_filepath, generated_json)
    json_hash = JSON.parse(the_json)
    assert EqualHashes::equal_hashes?(JSON.parse(generated_json), json_hash),
                                                  'Different scale json'
  end

  def test_customaddshadow
    json_filepath = File.join($resources_dir, "json", "customaddshadow.json")
    the_json = File.read(json_filepath)

    the_options = MILibrary::Utility.make_customaddshadow_options(
                                        left: 10,
                                        right: 15,
                                        top: 5,
                                        bottom: 20,
                                        red: 0.4,
                                        green: 0.4,
                                        blue: 0.4,
                                        scale: 1.0,
                                        outputdir: $resources_dir,
                                        exportfiletype: :'public.png',
                                        quality: 0.7,
                                        copymetadata: false,
                                        assume_images_have_same_dimensions: false,
                                        async: true,
                                        verbose: false)

    the_options[:generate_json] = true
    files = [ "#{File.join($images_dir, "DSCN0744.JPG")}",
              "#{File.join($images_dir, "DSCN0746.JPG")}" ]
    file_list = { width: 908, height: 681, files: files }
    generated_json = MILibrary.customaddshadow_files(the_options, file_list)
#    File.write(json_filepath, generated_json)
    json_hash = JSON.parse(the_json)
    assert EqualHashes::equal_hashes?(JSON.parse(generated_json), json_hash),
                                              'Different custom add shadow json'
  end

  def test_simplesinglecifilter
    json_filepath = File.join($resources_dir, "json", "simplesinglecifilter.json")
    the_json = File.read(json_filepath)

    the_options = MILibrary::Utility.make_simplesinglecifilter_options(
                                       cifilter: :CIUnsharpMask,
                                      outputdir: $resources_dir,
                                 exportfiletype: :'public.jpeg',
                                        quality: nil, # nil means use default.
                                 softwarerender: false,
                                      inputkey1: :inputRadius,
                                    inputvalue1: 10.0,
                                      inputkey2: :inputIntensity,
                                    inputvalue2: 0.7)

    the_options[:generate_json] = true
    files = [ "#{File.join($images_dir, "DSCN0744.JPG")}",
              "#{File.join($images_dir, "DSCN0746.JPG")}" ]
    file_list = { width: 908, height: 681, files: files }
    generated_json = MILibrary.simplesinglecifilter_files(the_options, file_list)
    # File.write(json_filepath, generated_json)
    json_hash = JSON.parse(the_json)
    assert EqualHashes::equal_hashes?(JSON.parse(generated_json), json_hash),
                                            'Different simplesinglecifilter json'
  end

  def test_addtextwatermark
    json_filepath = File.join($resources_dir, "json", "addtextwatermark.json")
    the_json = File.read(json_filepath)

    the_options = MILibrary::Utility.make_addtextwatermark_options(
                                      text: "©Kevin Meaney",
                                 fillcolor: MIColor.make_rgbacolor(0.3, 0.1, 0.0, a: 0.25),
                               strokecolor: MIColor.make_rgbacolor(1.0, 0.8, 0.8, a: 0.25),
                               strokewidth: 4.0, # 0 means don't stroke.
                                  fontsize: 60, # nil means calculate font size.
                                      font: 'GillSans-UltraBold',
                                 outputdir: $resources_dir,
                            exportfiletype: :'public.jpeg',
                                   quality: 0.8,
                              copymetadata: false,
        assume_images_have_same_dimensions: true,
                                     async: false,
                                   verbose: false)

    the_options[:generate_json] = true
    files = [ "#{File.join($images_dir, "DSCN0744.JPG")}",
              "#{File.join($images_dir, "DSCN0746.JPG")}" ]
    file_list = { width: 908, height: 681, files: files }
    generated_json = MILibrary.addtextwatermark_files(the_options, file_list)
#    File.write(json_filepath, generated_json)
    json_hash = JSON.parse(the_json)
    assert EqualHashes::equal_hashes?(JSON.parse(generated_json), json_hash),
                                            'Different addtextwatermark json'
  end
end

