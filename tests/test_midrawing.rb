require 'minitest/autorun'
require 'json'

require_relative '../lib/moving_images/midrawing'

include MovingImages

class TM_MIShapes < MiniTest::Unit::TestCase
  def test_point_make
    myPoint = MIShapes.make_point(0,0)
    assert myPoint[:x].is_a?(Float), 'In point hash :x is not a float'
    assert myPoint[:y].is_a?(Float), 'In point hash :y is not a float'
    assert myPoint[:x].eql?(0.0), 'Point hash created with 0,0 not zero'
    assert myPoint[:y].eql?(0.0), 'Point hash created with 0,0 not zero'
    assert myPoint.to_json.eql?('{"x":0.0,"y":0.0}'), 'JSON point different'
  end
  
  def test_point_addxy
    myPoint = MIShapes.make_point(0,0)
    MIShapes.point_addxy(myPoint, x: 20.5, y: 30)
    assert myPoint.to_json.eql?('{"x":20.5,"y":30.0}'), 'Points did not add'
  end
  
  def test_point_set_equation
    myPoint = MIShapes.make_point(20, 30.32)
    MIShapes.point_setx_equation(myPoint, "4 + $xadjustment")
    assert myPoint.to_json.eql?('{"x":"4 + $xadjustment","y":30.32}'),
                                      'Equation x not added as it should be'
    MIShapes.point_sety_equation(myPoint, "40 - $yadjustment")
    assert myPoint.to_json.eql?(
                      '{"x":"4 + $xadjustment","y":"40 - $yadjustment"}'),
                      'Equation y not added as it should be'
  end
  
  def test_size_make
    mySize = MIShapes.make_size(1000, 1.00003100)
    assert mySize[:width].is_a?(Float), 'In size hash :width is not a float'
    assert mySize[:height].is_a?(Float), 'In size hash :height is not a float'
    assert mySize[:width].eql?(1000.0), 'Size.width not 1000.0'
    assert mySize[:height].eql?(1.000031), 'Size.height not 1.000031'
    assert mySize.to_json.eql?('{"width":1000.0,"height":1.000031}'),
                                    'JSON size different'
  end
end

