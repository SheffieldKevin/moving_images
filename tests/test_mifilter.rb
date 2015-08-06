require 'minitest/autorun'
require 'json'

require_relative '../lib/moving_images/mifilterchain'

include MovingImages

# Test class for MIFilter

class TestMIFilter < MiniTest::Test
  def test_mifilter
    gamma_filter = MIFilter.new(:CIGammaAdjust,
                                identifier: :testidentifierfilter)
    new_json = gamma_filter.filterhash.to_json
    old_json =  '{"cifiltername":"CIGammaAdjust",'\
                '"mifiltername":"testidentifierfilter"}'
    assert new_json.eql?(old_json), 'Different JSON making a filter'
    filter_property = MIFilterProperty.make_cinumberproperty(key: :inputPower,
                                                             value: 1.2)
    new_json = filter_property.to_json
    old_json = '{"cifilterkey":"inputPower","cifiltervalue":1.2}'
    assert new_json.eql?(old_json), 'Different JSON filter properties'
    gamma_filter.add_property(filter_property)
    new_json = gamma_filter.filterhash.to_json
    old_json = '{"cifiltername":"CIGammaAdjust","mifiltername":'\
               '"testidentifierfilter","cifilterproperties":'\
               '[{"cifilterkey":"inputPower","cifiltervalue":1.2}]}'
    assert new_json.eql?(old_json), 'Different JSON adding filter property'
  end
end

class TestMIFilterProperty < MiniTest::Test
  def test_make_inputimage_filterproperty
    filter_property = MIFilterProperty.make_ciimageproperty(
                          key: :inputImage,
                          value: { mifiltername: :blurfilter },
                          keep_static: nil)
    new_json = filter_property.to_json
    old_json = '{"cifilterkey":"inputImage","cifiltervalueclass":"CIImage",'\
               '"cifiltervalue":{"mifiltername":"blurfilter"}}'
    assert new_json.eql?(old_json), '1 Different JSON: image filter property'

    filter_property = MIFilterProperty.make_ciimageproperty(
                          key: :inputImage,
                          value: { objectreference: 4 },
                          keep_static: false)
    new_json = filter_property.to_json
    old_json = '{"cifilterkey":"inputImage","cifiltervalueclass":"CIImage",'\
        '"cifiltervalue":{"objectreference":4},"cisourceimagekeepstatic":false}'
    assert new_json.eql?(old_json), '2. Different JSON: image filter property'
  end
end

# Tests needed for a wider variety of filters
# Tests needed for a wider variety of filter properties
# Tests needed for the MIFilterChain
# Tests needed for the MIFilterChainRenderProperty
# Tests needed for the MIFilterChainRender