require 'minitest/autorun'
require 'json'

require_relative '../lib/moving_images/midrawing'
require_relative '../lib/moving_images/smigobjectid'

include MovingImages

# Test class for creating shape hashes
class TestMIShapes < MiniTest::Test
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
class TestMITransformations < MiniTest::Test
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
class TestMIColor < MiniTest::Test
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
class TestMIPath < MiniTest::Test
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
class TestMIShadow < MiniTest::Test
  def test_make_shadow
    shadow = MIShadow.new
    assert shadow.shadowhash.is_a?(Hash), 'The shadow is not a hash'
    assert shadow.shadowhash.size.eql?(0), 'The shadow hash it not zero length'
    shadow.color = MIColor.make_rgbacolor(0.6, 0.3, 0.1)
    shadow.offset = MIShapes.make_size(6, '4 + $verticalshadowoffset')
    shadow.blur = 12
    old_json = '{"fillcolor":{"red":0.6,"green":0.3,"blue":0.1,"alpha":1.0,'\
    '"colorcolorprofilename":"kCGColorSpaceSRGB"},'\
    '"offset":{"width":6,"height":"4 + $verticalshadowoffset"},"blur":12}'
    assert shadow.shadowhash.to_json.eql?(old_json), 'MIShadow json different'
  end
end

# Test class for draw element
class TestMIDrawElement < MiniTest::Test
  # Test that a draw fill rectangle element produces correct json
  def test_make_drawfillrectangleelement
    draw_element = MIDrawElement.new(:fillrectangle)
    draw_element.fillcolor = MIColor.make_rgbacolor(0, 0, 0)
    draw_element.elementdebugname = 'TestMIDrawElement.fillrectangle'
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

  # Test that a draw stroke oval element produces correct json
  def test_make_drawstrokeovalelement
    draw_element = MIDrawElement.new(:strokeoval)
    draw_element.strokecolor = MIColor.make_rgbacolor(0.2, 0, 1)
    draw_element.elementdebugname = 'TestMIDrawElement.strokeoval'
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
    shadow.offset = MIShapes.make_size(6, '4 + $verticalshadowoffset')
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

# This is not close to being complete. I've completed enough to to test that
# refactoring by moving common methods into an abstract base class works.
# Tests that draw basic string element produces correct json.
class TestMIDrawBasicStringElement < MiniTest::Test
  # Test that a draw basic string produces the correct json output
  def test_drawbasicstring_basics
    draw_basicstringelement = MIDrawBasicStringElement.new
    draw_basicstringelement.stringtext = 'This is the text to draw'
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
class TestMIDrawImageElement < MiniTest::Test
  # Test that the draw image element produces correct json output.
  def test_drawimage_basics
    draw_imageelement = MIDrawImageElement.new
    smigid = { objecttype: :bitmapcontext,
               objectname: :TestMIDrawImageElement }
    draw_imageelement.set_bitmap_imagesource(source_object: smigid)
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
  
  def test_drawmovieframe
    draw_imageelement = MIDrawImageElement.new
    smigid = SmigIDHash.make_objectid(objecttype: :movieimporter,
                                      objectname: :TestDrawImageMovieImporter)
    frameTime = { time: 5.0 }
    draw_imageelement.set_moviefile_imagesource(source_object: smigid,
                                                 frametime: frameTime)
    origin = MIShapes.make_point(0, 0)
    size = MIShapes.make_size(400, 300)
    rectangle = MIShapes.make_rectangle(origin: origin, size: size)
    draw_imageelement.destinationrectangle = rectangle
    draw_imageelement.blendmode = :kCGBlendModeNormal
    new_json = draw_imageelement.elementhash.to_json
    # puts new_json
    old_json = '{"elementtype":"drawimage","sourceobject":{"objecttype"'\
    ':"movieimporter","objectname":"TestDrawImageMovieImporter"},"imageoptions"'\
    ':{"frametime":{"time":5.0}},"destinationrectangle":{"origin":{"x":0,"y":0},'\
    '"size":{"width":400,"height":300}},"blendmode":"kCGBlendModeNormal"}'
    assert new_json.eql?(old_json), 'MIDrawImageElement movie frame json different'
  end

  def test_drawtrackmovieframe
    draw_imageelement = MIDrawImageElement.new
    smigid = SmigIDHash.make_objectid(objecttype: :movieimporter,
                                      objectname: :TestDrawImageMovieImporter)
    frameTime = { time: 2.0 }
    tracks = [ { mediatype: :soun, trackindex: 0} ]
    draw_imageelement.set_moviefile_imagesource(source_object: smigid,
                                                 frametime: frameTime,
                                                 tracks: tracks)
    origin = MIShapes.make_point(0, 0)
    size = MIShapes.make_size(400, 300)
    rectangle = MIShapes.make_rectangle(origin: origin, size: size)
    draw_imageelement.destinationrectangle = rectangle
    draw_imageelement.blendmode = :kCGBlendModeNormal
    new_json = draw_imageelement.elementhash.to_json
    # puts new_json
    old_json = '{"elementtype":"drawimage","sourceobject":{"objecttype":'\
    '"movieimporter","objectname":"TestDrawImageMovieImporter"},"imageoptions":'\
    '{"frametime":{"time":2.0},"tracks"'\
    ':[{"mediatype":"soun","trackindex":0}]},"destinationrectangle":'\
    '{"origin":{"x":0,"y":0},"size":{"width":400,"height":300}},"blendmode"'\
    ':"kCGBlendModeNormal"}'
    assert new_json.eql?(old_json), 'MIDrawImageElement movie track frame json different'
  end

  # Need further tests
  # * Specifying affine and context transformations
  # * Specifying source rect
  # * Specifying interpolation quality values
  # * Specifying a shadow
end

class TestMIPathWithArcs < MiniTest::Test
  def test_make_mipath_witharcs
    path = MIPath.new

    size = MIShapes.make_size(200, 350.25)
    circleCenter = MIShapes.make_point(200.23, 199.25)
    path.add_arc(centerPoint: circleCenter,
                      radius: 51.07, 
                  startAngle: 0.0,
                    endAngle: Math::PI * 0.25,
                 isClockwise: false)
#    puts path.patharray.to_json
    old_json = '[{"elementtype":"patharc","centerpoint"'\
    ':{"x":200.23,"y":199.25},"radius":51.07,"startangle"'\
    ':0.0,"endangle":0.7853981633974483,"clockwise":false}]'
    assert path.patharray.to_json.eql?(old_json), 'MIPath arc json different'
    
    path2 = MIPath.new
    path2.add_arc_topoint_onpath(tangentPoint1: { x: 40.5, y: 350.5 },
                                 tangentPoint2: { x: 140.5, y: 350.5 },
                                        radius: 100.0)
    old_json = '[{"elementtype":"pathaddarctopoint","tangentpoint1":{"x"'\
    ':40.5,"y":350.5},"tangentpoint2":{"x":140.5,"y":350.5},"radius":100.0}]'
    assert path2.patharray.to_json.eql?(old_json), 'MIPath arcpoint json diff'
  end
end

class TestMIClip < MiniTest::Test
  def test_make_drawingclipper
    theClip = MIClip.new
    theClip.startpoint = { x: 0.0, y: 0.0 }
    roundedRect = MIPath.new
    rectSize = MIShapes.make_size(399, 299)
    rectOrigin = MIShapes.make_point(100.5, 75.5)
    theRect = MIShapes.make_rectangle(size: rectSize, origin: rectOrigin)
    roundedRect.add_roundedrectangle_withradiuses(theRect,
                                          radiuses: [4.0, 8.0, 16.0, 32.0])
    theClip.arrayofpathelements = roundedRect
    old_json = '{"startpoint":{"x":0.0,"y":0.0},"arrayofpathelements":[{'\
    '"elementtype":"pathroundedrectangle","rect":{"origin":{"x":100.5,"y"'\
    ':75.5},"size":{"width":399,"height":299}},"radiuses":[4.0,8.0,16.0,32.0]}]}'
    assert theClip.clippinghash.to_json.eql?(old_json), 'MIClip is modified.'
  end
end
