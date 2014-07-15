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

  # test needed for inset rect for stroking
  # test needed for making a line.
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
  # tests needed for setting color components to equations.
  # tests needed for making grayscale and cmyk colors
end

# Test class for path hashes
class TestMIPath < MiniTest::Unit::TestCase
  def test_make_mipath
    path = MIPath.new
    assert path.patharray.is_a?(Array), 'The path is not an array'
    assert path.patharray.length.eql?(0), 'The length of the array is not 0'
    size = MIShapes.make_size(200, 350.25)
    origin = MIShapes.make_point(100.23, 120)
    rect = MIShapes.make_rectangle(origin: origin, size: size)
    radiuses = [32, 12, 2, 12]
    path.add_roundedrectangle_withradiuses(rect, radiuses: radiuses)
    origin2 = MIShapes.make_point(310, 470)
    rect2 = MIShapes.make_rectangle(origin: origin2, size: size)
    path.add_rectangle(rect2)
    old_json = '[{"elementtype":"pathroundedrectangle",'\
    '"rect":{"origin":{"x":100.23,"y":120},'\
    '"size":{"width":200,"height":350.25}},"radiuses":[32,12,2,12]},'\
    '{"elementtype":"pathrectangle","rect":{"origin":{"x":310,"y":470},'\
    '"size":{"width":200,"height":350.25}}}]'
    assert path.patharray.to_json.eql?(old_json), 'MIPath json different'
  end
  # tests needed for adding bezier and quadratic curves
  # tests needed for lines and triangles
  # tests needed for closesubpath and move_to
  # tests needed for adding ovals and a rounded rectangle.
end

# Test class for shadow hashes
class TestMIShadow < MiniTest::Unit::TestCase
  def test_make_shadow
    shadow = MIShadow.new
    assert shadow.shadowhash.is_a?(Hash), 'The shadow is not a hash'
    assert shadow.shadowhash.size.eql?(0), 'The shadow hash it not zero length'
    shadow.color = MIColor.make_rgbacolor(0.6, 0.3, 0.1)
    shadow.offset = MIShapes.make_size(6, "4 + $verticalshadowoffset")
    shadow.blur = 12
    old_json = '{"fillcolor":{"red":0.6,"green":0.3,"blue":0.1,"alpha":1.0,'\
    '"colorcolorprofilename":"kCGColorSpaceSRGB"},'\
    '"offset":{"width":6,"height":"4 + $verticalshadowoffset"},"blur":12}'
    assert shadow.shadowhash.to_json.eql?(old_json), 'MIShadow json different'
  end
end

class TestMIDrawElement < MiniTest::Unit::TestCase
  def test_make_drawfillrectangleelement
    draw_element = MIDrawElement.new(:fillrectangle)
    draw_element.fillcolor = MIColor.make_rgbacolor(0, 0, 0)
    draw_element.elementdebugname = "TestMIDrawElement.fillrectangle"
    size = MIShapes.make_size(200, 200)
    origin = MIShapes.make_point(100, 100)
    draw_element.rectangle = MIShapes.make_rectangle(origin: origin, size: size)
    affine_transform = MITransformations.make_affinetransform(m22: 2.0)
    draw_element.affinetransform = affine_transform
    draw_element.blendmode = :kCGBlendModeColorDodge
    old_json = '{"elementtype":"fillrectangle","fillcolor":{"red":0,"green":0,'\
    '"blue":0,"alpha":1.0,"colorcolorprofilename":"kCGColorSpaceSRGB"},'\
    '"elementdebugname":"TestMIDrawElement.fillrectangle",'\
    '"rect":{"origin":{"x":100,"y":100},"size":{"width":200,"height":200}},'\
    '"affinetransform":{"m11":1.0,"m12":0.0,"m21":0.0,"m22":2.0,'\
    '"tX":0.0,"tY":0.0},"blendmode":"kCGBlendModeColorDodge"}'
    new_json = draw_element.elementhash.to_json
    assert new_json.eql?(old_json), 'MIDrawElement fillrectangle json different'
  end

  def test_make_drawstrokeovalelement
    draw_element = MIDrawElement.new(:strokeoval)
    draw_element.strokecolor = MIColor.make_rgbacolor(0.2, 0, 1)
    draw_element.elementdebugname = "TestMIDrawElement.strokeoval"
    size = MIShapes.make_size(182.1, 352.25)
    origin = MIShapes.make_point(200, 300)
    draw_element.rectangle = MIShapes.make_rectangle(origin: origin, size: size)
    transformations = MITransformations.make_contexttransformation
    MITransformations.add_scaletransform(transformations, 
                                         MIShapes.make_point(0.5, 0.5))
    draw_element.contexttransformations = transformations
    draw_element.linewidth = 10
    shadow = MIShadow.new
    shadow.color = MIColor.make_rgbacolor(0.6, 0.3, 0.1)
    shadow.offset = MIShapes.make_size(6, "4 + $verticalshadowoffset")
    shadow.blur = 10
    draw_element.shadow = shadow
    old_json = '{"elementtype":"strokeoval","strokecolor":{"red":0.2,'\
    '"green":0,"blue":1,"alpha":1.0,'\
    '"colorcolorprofilename":"kCGColorSpaceSRGB"},'\
    '"elementdebugname":"TestMIDrawElement.strokeoval",'\
    '"rect":{"origin":{"x":200,"y":300},'\
    '"size":{"width":182.1,"height":352.25}},'\
    '"contexttransformation":[{"transformationtype":"scale",'\
    '"scale":{"x":0.5,"y":0.5}}],"linewidth":10,'\
    '"shadow":{"fillcolor":{"red":0.6,"green":0.3,'\
    '"blue":0.1,"alpha":1.0,"colorcolorprofilename":"kCGColorSpaceSRGB"},'\
    '"offset":{"width":6,"height":"4 + $verticalshadowoffset"},"blur":10}}'
    new_json = draw_element.elementhash.to_json
    assert new_json.eql?(old_json), 'MIDrawElement stroke oval json different'
  end
  # Need further tests for
  # * line drawing, linecap, linejoin, miter
  # * lines drawing
  # * arrayofelements
end

# This is not even close to being complete. I've implemented enough so that the
# common part to the 3 other types of draw element objects can be refactored 
# into a common abstract base class.
class TestMIDrawLinearGradientFillElement < MiniTest::Unit::TestCase
  def test_drawlinear_basics
    draw_lineargradientelement = MILinearGradientFillElement.new
    draw_lineargradientelement.blendmode = :kCGBlendModeColorDodge
    variables = { widthoffset: "5.0 + 3 * $widthadjust",
                  redcolorcomponent: "0.2 + 2 * $redcolorcomponentadjust" }
    draw_lineargradientelement.variables = variables
    affine_transform = MITransformations.make_affinetransform(m22: 2.0)
    draw_lineargradientelement.affinetransform = affine_transform
    new_json = draw_lineargradientelement.to_json
    old_jsn = '{"elementtype":"lineargradientfill","startpoint":{"x":0,"y":0},'\
    '"blendmode":"kCGBlendModeColorDodge","variables":'\
    '{"widthoffset":"5.0 + 3 * $widthadjust","redcolorcomponent":'\
    '"0.2 + 2 * $redcolorcomponentadjust"},"affinetransform":{"m11":1.0,'\
    '"m12":0.0,"m21":0.0,"m22":2.0,"tX":0.0,"tY":0.0}}'
    assert new_json.eql?(old_jsn), 'MILinearGradientFillElement json different'
  end
  # Need further tests
  # * Specifying the clipping path.
  # * Specifying array of locations and colors
  # * Specifying the line
  # * Specifying context transformations
end

class TestMIDrawBasicStringElement < MiniTest::Unit::TestCase
  def test_drawbasicstring_basics
    draw_basicstringelement = MIDrawBasicStringElement.new
    draw_basicstringelement.stringtext = "This is the text to draw"
    draw_basicstringelement.point_textdrawnfrom = MIShapes.make_point(20, 20)
    draw_basicstringelement.userinterfacefont = :kCTFontUIFontMiniSystem
    transformations = MITransformations.make_contexttransformation
    MITransformations.add_rotatetransform(transformations, -0.78)
    draw_basicstringelement.contexttransformations = transformations
    element_hash = draw_basicstringelement.elementhash
    new_json = element_hash.to_json
    old_json = '{"elementtype":"drawbasicstring","stringtext":'\
    '"This is the text to draw","point":{"x":20,"y":20},'\
    '"userinterfacefont":"kCTFontUIFontMiniSystem",'\
    '"contexttransformation":[{"transformationtype":"rotate",'\
    '"rotation":-0.78}]}'
    assert new_json.eql?(old_json), 'MIDrawBasicStringElement json different'
  end
  # Need further test
  # * Postscript font names
  # * font size
  # * stroke fonts
  # * stroke and fill fonts
  # * text drawn within shapes.
end

# This is not close to being complete. I've implement enough to test that
# refactoring by moving common methods into an abstract draw base class.
class TestMIDrawImageElement < MiniTest::Unit::TestCase
  def test_drawimage_basics
    draw_imageelement = MIDrawImageElement.new
    smigid = { objecttype: :bitmapcontext,
               objectname: :TestMIDrawImageElement }
    draw_imageelement.set_imagesource(source_object: smigid)
    origin = MIShapes.make_point(0, 0)
    size = MIShapes.make_size(1280, 1024)
    rectangle = MIShapes.make_rectangle(origin: origin, size: size)
    draw_imageelement.destinationrectangle = rectangle
    draw_imageelement.blendmode = :kCGBlendModeNormal
    new_json = draw_imageelement.elementhash.to_json
    old_json = '{"elementtype":"drawimage","sourceobject":{"objecttype"'\
    ':"bitmapcontext","objectname":"TestMIDrawImageElement"},'\
    '"destinationrectangle":{"origin":{"x":0,"y":0},'\
    '"size":{"width":1280,"height":1024}},"blendmode":"kCGBlendModeNormal"}'
    assert new_json.eql?(old_json), 'MIDrawImageElement json different'
  end
  # Need further tests
  # * Specifying affine and context transformations
  # * Specifying source rect
  # * Specifying interpolation quality values
  # * Specifying a shadow
end
