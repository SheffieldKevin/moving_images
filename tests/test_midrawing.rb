require 'minitest/autorun'
require 'json'

require_relative '../lib/moving_images/midrawing'

include MovingImages

# Test class for creating shape hashes
class TM_MIShapes < MiniTest::Unit::TestCase
  def test_point_make
    myPoint = MIShapes.make_point(0, 0)
    assert myPoint[:x].is_a?(Numeric), 'In point hash :x is not a float'
    assert myPoint[:y].is_a?(Numeric), 'In point hash :y is not a float'
    assert myPoint[:x].to_f.eql?(0.0), 'Point hash created with 0,0 not zero'
    assert myPoint[:y].to_f.eql?(0.0), 'Point hash created with 0,0 not zero'
    assert myPoint.to_json.eql?('{"x":0,"y":0}'), 'JSON point different'
  end

  def test_point_addxy
    myPoint = MIShapes.make_point(0, 0)
    MIShapes.point_addxy(myPoint, x: 20.5, y: 30)
    assert myPoint.to_json.eql?('{"x":20.5,"y":30.0}'), 'Points did not add'
  end

  def test_point_set_equation
    myPoint = MIShapes.make_point(20, 30.32)
    MIShapes.point_setx_equation(myPoint, '4 + $xadjustment')
    assert myPoint.to_json.eql?('{"x":"4 + $xadjustment","y":30.32}'),
           'Equation x not added correctly'
    MIShapes.point_sety_equation(myPoint, '40 - $yadjustment')
    assert myPoint.to_json.eql?(
                      '{"x":"4 + $xadjustment","y":"40 - $yadjustment"}'),
           'Equation y not added correctly'
  end

  def test_size_make
    mySize = MIShapes.make_size(1000, 1.00003100)
    assert mySize[:width].is_a?(Numeric), 'In size hash :width is not a float'
    assert mySize[:height].is_a?(Numeric), 'In size hash :height is not a float'
    assert mySize[:width].eql?(1000), 'Size.width not 1000.0'
    assert mySize[:height].eql?(1.000031), 'Size.height not 1.000031'
    assert mySize.to_json.eql?('{"width":1000,"height":1.000031}'),
           'JSON size different'
  end

  def test_rect_make
    mySize = MIShapes.make_size(250.0, 250.0)
    myRect = MIShapes.make_rectangle(size: mySize)
    json = '{"origin":{"x":0.0,"y":0.0},"size":{"width":250.0,"height":250.0}}'
    assert myRect.to_json.eql?(json), '1. JSON rectangle different'
    myRect = MIShapes.make_rectangle(size: mySize, xloc: 200, yloc: 150)
    json = '{"origin":{"x":200,"y":150},"size":{"width":250.0,"height":250.0}}'
    assert myRect.to_json.eql?(json), '2.0 JSON rectangle different'
  end
end

# Test class for transformation hashes
class TM_MITransformations < MiniTest::Unit::TestCase
  def test_transformations
    thePoint = MIShapes.make_point('5 + $halfwidth', '4 + $halfheight')
    transforms = MITransformations.make_contexttransformation
    MITransformations.add_translatetransform(transforms, thePoint)
    scalePoint = MIShapes.make_point(0.5, 0.4)
    MITransformations.add_scaletransform(transforms, scalePoint)
    MITransformations.add_rotatetransform(transforms, 0.78)
    backPoint = MIShapes.make_point('-(5 + $halfwidth)', '-(4 + $halfheight)')
    MITransformations.add_translatetransform(transforms, backPoint)
    theJSON = '[{"transformationtype":"translate","translation":'\
    '{"x":"5 + $halfwidth","y":"4 + $halfheight"}},'\
    '{"transformationtype":"scale","scale":{"x":0.5,"y":0.4}},'\
    '{"transformationtype":"rotate","rotation":0.78},'\
    '{"transformationtype":"translate","translation":{"x":"-(5 + $halfwidth)",'\
    '"y":"-(4 + $halfheight)"}}]'
    assert transforms.to_json.eql?(theJSON), 'Transform JSON different'
  end

  def test_affinetransform
    affineTransform = MITransformations.make_affinetransform(
                  m11: 1.2, m12: 0.2, m21: -0.2, m22: -0.8, tX: 100, tY: 20)
    theJSON = '{"m11":1.2,"m12":0.2,"m21":-0.2,"m22":-0.8,"tX":100,"tY":20}'
    assert affineTransform.to_json.eql?(theJSON), 'JSON Affine transforms diff'
  end
end

# Test class for color hashes
class TM_MIColor < MiniTest::Unit::TestCase
  def test_rgba_color
    theColor = MIColor.make_rgbacolor(1, 0, 0.5)
    theJSON = '{"red":1,"green":0,"blue":0.5,"alpha":1.0,'\
              '"colorcolorprofilename":"kCGColorSpaceSRGB"}'
    assert theColor.to_json.eql?(theJSON), 'JSON Colors diff' + theColor.to_json
  end
end

