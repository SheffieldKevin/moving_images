require 'minitest/autorun'
require 'json'

require_relative '../lib/moving_images/midrawing'

include MovingImages

# Test class for creating shape hashes
class TestMIShapes < MiniTest::Unit::TestCase
  def test_point_make
    my_point = MIShapes.make_point(0, 0)
    assert my_point[:x].is_a?(Numeric), 'In point hash :x is not a float'
    assert my_point[:y].is_a?(Numeric), 'In point hash :y is not a float'
    assert my_point[:x].to_f.eql?(0.0), 'Point hash created with 0,0 not zero'
    assert my_point[:y].to_f.eql?(0.0), 'Point hash created with 0,0 not zero'
    assert my_point.to_json.eql?('{"x":0,"y":0}'), 'JSON point different'
  end

  def test_point_addxy
    my_point = MIShapes.make_point(0, 0)
    MIShapes.point_addxy(my_point, x: 20.5, y: 30)
    assert my_point.to_json.eql?('{"x":20.5,"y":30.0}'), 'Points did not add'
  end

  def test_point_set_equation
    my_point = MIShapes.make_point(20, 30.32)
    MIShapes.point_setx_equation(my_point, '4 + $xadjustment')
    assert my_point.to_json.eql?('{"x":"4 + $xadjustment","y":30.32}'),
           'Equation x not added correctly'
    MIShapes.point_sety_equation(my_point, '40 - $yadjustment')
    assert my_point.to_json.eql?(
                      '{"x":"4 + $xadjustment","y":"40 - $yadjustment"}'),
           'Equation y not added correctly'
  end

  def test_size_make
    my_size = MIShapes.make_size(1000, 1.00003100)
    assert my_size[:width].is_a?(Numeric), 'In size hash :width is not a float'
    assert my_size[:height].is_a?(Numeric), 'In size hash :height not a float'
    assert my_size[:width].eql?(1000), 'Size.width not 1000.0'
    assert my_size[:height].eql?(1.000031), 'Size.height not 1.000031'
    assert my_size.to_json.eql?('{"width":1000,"height":1.000031}'),
           'JSON size different'
  end

  def test_rect_make
    my_size = MIShapes.make_size(250.0, 250.0)
    my_rect = MIShapes.make_rectangle(size: my_size)
    json = '{"origin":{"x":0.0,"y":0.0},"size":{"width":250.0,"height":250.0}}'
    assert my_rect.to_json.eql?(json), '1. JSON rectangle different'
    my_rect = MIShapes.make_rectangle(size: my_size, xloc: 200, yloc: 150)
    json = '{"origin":{"x":200,"y":150},"size":{"width":250.0,"height":250.0}}'
    assert my_rect.to_json.eql?(json), '2.0 JSON rectangle different'
  end
end

# Test class for transformation hashes
class TestMITransformations < MiniTest::Unit::TestCase
  def test_transformations
    point = MIShapes.make_point('5 + $halfwidth', '4 + $halfheight')
    transforms = MITransformations.make_contexttransformation
    MITransformations.add_translatetransform(transforms, point)
    scale_point = MIShapes.make_point(0.5, 0.4)
    MITransformations.add_scaletransform(transforms, scale_point)
    MITransformations.add_rotatetransform(transforms, 0.78)
    back_point = MIShapes.make_point('-(5 + $halfwidth)', '-(4 + $halfheight)')
    MITransformations.add_translatetransform(transforms, back_point)
    json = '[{"transformationtype":"translate","translation":'\
    '{"x":"5 + $halfwidth","y":"4 + $halfheight"}},'\
    '{"transformationtype":"scale","scale":{"x":0.5,"y":0.4}},'\
    '{"transformationtype":"rotate","rotation":0.78},'\
    '{"transformationtype":"translate","translation":{"x":"-(5 + $halfwidth)",'\
    '"y":"-(4 + $halfheight)"}}]'
    assert transforms.to_json.eql?(json), 'Transform JSON different'
  end

  def test_affinetransform
    affine_transform = MITransformations.make_affinetransform(
                  m11: 1.2, m12: 0.2, m21: -0.2, m22: -0.8, tX: 100, tY: 20)
    json = '{"m11":1.2,"m12":0.2,"m21":-0.2,"m22":-0.8,"tX":100,"tY":20}'
    assert affine_transform.to_json.eql?(json), 'JSON Affine transforms diff'
  end
end

# Test class for color hashes
class TestMIColor < MiniTest::Unit::TestCase
  def test_rgba_color
    color = MIColor.make_rgbacolor(1, 0, 0.5)
    the_json = '{"red":1,"green":0,"blue":0.5,"alpha":1.0,'\
              '"colorcolorprofilename":"kCGColorSpaceSRGB"}'
    assert color.to_json.eql?(the_json), 'JSON Colors diff' + color.to_json
  end
end
