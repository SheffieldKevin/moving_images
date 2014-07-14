
module MovingImages
  # == A collection of methods for creating and modifying simple shapes
  module MIShapes
    # Make a point hash    
    # Can be created from Floats, integers or string. Strings will represent
    # equations and {#point_addxy} will not work and will raise an exception.
    # @param x [Float, Fixnum, String] The horizontal position of the point.
    # @param y [Float, Fixnum, String] The vertical position of the point
    # @return [Hash] A point hash containing the x, y coordinates.
    def self.make_point(x, y)
      { :x => x, :y => y }
    end

    # Modify a points location by adding to the coordinates.    
    # Will raise an exception if point attributes are not floats
    # @param thePoint [Hash] A previously created point hash to be modified.
    # @param x [Float, #to_f] The amount to modify the horizontal position by.
    # @param y [Float, #to_f] The amount to modify the vertical position by.
    # @return [Hash] The modified point hash.
    def self.point_addxy(thePoint, x: 0.0, y: 0.0)
      unless thePoint[:x].is_a?(Numeric)
        fail "can't add when :x attribute is not a float"
      end
      unless thePoint[:y].is_a?(Numeric)
        fail "can't add when :y attribute is not a float"
      end
      thePoint[:x] += x.to_f
      thePoint[:y] += y.to_f
      thePoint
    end

    # Set the x coordinate to a formula.
    # @param thePoint [Hash] A previously created point.
    # @param theEquation [String] The equation to assign to the x-coordinate
    # @return [Hash] The modified point hash.
    def self.point_setx_equation(thePoint, theEquation)
      thePoint[:x] = theEquation
      thePoint
    end

    # Set the y coordinate to a formula.
    # @param thePoint [Hash] A previously created point.
    # @param theEquation [String] The equation to assign to the y-coordinate
    # @return [Hash] The modified point hash.
    def self.point_sety_equation(thePoint, theEquation)
      thePoint[:y] = theEquation
      thePoint
    end

    # Make a size hash    
    # If strings are assigned then width/height will represent an equation.
    # @param width [Float, Fixnum, String] The width to assign to the size hash.
    # @param height [Float, Fixnum, String] Height to assign to the size hash
    # @return [Hash] The created size hash containing the width and height.
    def self.make_size(width, height)
      return { :width => width, :height => height }
    end

    # Modify a size hash by adding the width and height
    # @param theSize [Hash] A previously created size hash to be modified
    # @param width [Float, #to_f] The amount to add to the width
    # @param height [Float, #to_f] The amount to add to height of the size hash
    # @return [Hash] The modified size hash.
    def self.size_addwidthheight(theSize, width: 0.0, height: 0.0)
      unless theSize[:width].is_a?(Numeric)
        fail "can't add when :width attribute is not a float"
      end
      unless theSize[:height].is_a?(Numeric)
        fail "can't add when :height attribute is not a float"
      end
      theSize[:width] += width.to_f
      theSize[:height] += height.to_f
      theSize
    end

    # Set the width dimension to a formula.
    # @param theSize [Hash] A previously created size hash.
    # @param theEquation [String] The equation to assign to the width
    # @return [Hash] The modified size hash.
    def self.size_setwidth_equation(theSize, theEquation)
      theSize[:width] = theEquation
      theSize
    end

    # Set the height dimension to a formula.
    # @param theSize [Hash] A previously created size hash.
    # @param theEquation [String] The equation to assign to the height
    # @return [Hash] The modified size hash.
    def self.size_setheight_equation(theSize, theEquation)
      theSize[:height] = theEquation
      theSize
    end

    # Make a rectangle, taking origin and size, or width, height, x & y location
    # All the parameters are optional, if none are specified then you'll get a
    # rectangle back with the origin at [0,0] and with dimensions of [100,100].
    # If origin is specified then xloc and yloc will be ignored if they are
    # are specified. If size is specified then width and height will be ignored.
    # Any individual values can be expressed as an equation, which is why the
    # parameters width, height, xloc and yloc can be Strings.
    # @param origin [Hash] The location of the bottom left corner of a rectangle
    # @param size [Hash] The size of the rectangle specified
    # @param width [Float, Fixnum, String] The width of the rectangle
    # @param height [Float, Fixnum, String] The height of the rectangle
    # @param xloc [Float, Fixnum, String] The horizontal position of the rect
    # @param yloc [Float, Fixnum, String] The vertical position of the rectangle
    def self.make_rectangle(origin: nil, size: nil,
                            width: nil, height: nil, xloc: nil, yloc: nil)
      theOrigin = origin
      if theOrigin.nil?
        theOrigin = {}
        theOrigin[:x] = 0.0 if xloc.nil?
        theOrigin[:x] = xloc unless xloc.nil?
        theOrigin[:y] = 0.0 if yloc.nil?
        theOrigin[:y] = yloc unless yloc.nil?
      end
      theSize = size
      if theSize.nil?
        theSize = {}
        theSize[:width] = 100.0 if width.nil?
        theSize[:width] = width unless width.nil?
        theSize[:height] = 100.0 if height.nil?
        theSize[:height] = height unless height.nil?
      end
      { :origin => theOrigin, :size => theSize }
    end

    # Set the width of the rectangle to a formula.
    # @param theRect [Hash] A previously created rect hash.
    # @param theEquation [String] The equation to assign to the width
    # @return [Hash] The modified rect hash.
    def self.rect_setwidth_toequation(theRect, theEquation)
      theRect[:size][:width] = theEquation
      theRect
    end

    # Set the height of the rectangle to a formula.
    # @param theRect [Hash] A previously created rect hash.
    # @param theEquation [String] The equation to assign to the height
    # @return [Hash] The modified rect hash.
    def self.rect_setheight_toequation(theRect, theEquation)
      theRect[:size][:height] = theEquation
      theRect
    end

    # Set the x location of the rectangle to a formula.
    # @param theRect [Hash] A previously created rect hash.
    # @param theEquation [String] The equation to assign to the x co-ordinate
    # @return [Hash] The modified rect hash.
    def self.rect_setx_toequation(theRect, theEquation)
      theRect[:origin][:x] = theEquation
      theRect
    end

    # Set the y location of the rectangle to a formula.
    # @param theRect [Hash] A previously created rect hash.
    # @param theEquation [String] The equation to assign to the y co-ordinate
    # @return [Hash] The modified rect hash.
    def self.rect_sety_toequation(theRect, theEquation)
      theRect[:origin][:y] = theEquation
      theRect
    end

    # Inset a rect for stroking so lines are drawn aligned with pixels.
    # When stroking rectangles in a untransformed context with a line thickness
    # of 1 pixel, the lines of the stroke will be blurred over 2 pixels. By
    # offsetting the position by half a pixel the line will be drawn pixel
    # aligned making it look sharp. To keep the behaviour consistent with 
    # fill drawing of a rectangle the stroking of the rectangle is inset
    # within the rectangle. For a discussion of this issue see this orange juice
    # liberation blog post (@uliwitness): {http://t.co/1jpbjSdwHf Blurred lines}
    # @param theRect [Hash] An already created rectangle to be inset.
    # @return [Hash] The modified rectangle
    def self.rect_inset_forstroking(theRect)
      theRect[:origin][:x] += 0.5
      theRect[:origin][:y] += 0.5
      width = theRect[:size][:width]
      height = theRect[:size][:height]

      if (width > 1.0)
        theRect[:size][:width] = width - 1
      end
    
      if (height > 1.0)
        theRect[:size][:height] = height - 1
      end
      return theRect
    end

    # Make a line taking two previously defined points.
    # @param startPoint [Hash] The line start point.
    # @param endPoint [Hash] The line end point.
    # @return [Hash] A line defined by a start and an end point.
    def self.make_line(startPoint, endPoint)
      return { :startpoint => startPoint, :endpoint => endPoint }
    end
  end

  # == A collection of methods for creating transformation hashes
  module MITransformations
    # Make a context transformation object ready to be added to.
    # @return [Array] An array object.
    def self.make_contexttransformation()
      return []
    end

    # Add a translation transform to the context transformation
    # @param transformations [Array] The transformations to add translate to
    # @param point [Hash] A point to translate the context by.
    # @return [Array] The transformation array with translation transform added
    def self.add_translatetransform(transformations, point)
      translate = { :transformationtype => "translate",
                      :translation => point }
      transformations.push(translate)
      return transformations
    end

    # Add a scale transform to the context transformations
    # @param transformations [Array] The transformations to add transform to
    # @param scaleXY [Hash] A point hash to scale the context by.
    # @return [Array] The transformation array with translation transform added
    def self.add_scaletransform(transformations, scaleXY)
      scale = { :transformationtype => "scale", :scale => scaleXY }
      transformations.push(scale)
      return transformations
    end

    # Add a rotate transform to the context transformations
    # @param transformations [Array] The transformations to add rotate transform
    # @param rotation [Float] The rotation in radians to rotate the context by.
    # @return [Array] The transformation array with rotation transform added
    def self.add_rotatetransform(transformations, rotation)
      rotate = { :transformationtype => "rotate",
                  :rotation => rotation }
      transformations.push(rotate)
      return transformations
    end

    # Make an affine transform    
    # @param m11 [Float] The m11 component of affine transform.
    # @param m12 [Float] The m12 component of affine transform.
    # @param m21 [Float] The m21 component of affine transform.
    # @param m22 [Float] The m22 component of affine transform.
    # @param tX [Numeric] The tX component of affine transform.
    # @param tY [Numeric] The tY component of affine transform.
    # @return [Hash] The created affine transform.
    def self.make_affinetransform(m11: 1.0, m12: 0.0, m21: 0.0,
                                  m22: 1.0,  tX: 0.0,  tY: 0.0)
      return { :m11 => m11.to_f, :m12 => m12.to_f, :m21 => m21.to_f,
                      :m22 => m22.to_f, :tX => tX, :tY => tY }
    end
  end

  # == A collection of methods for creating colors and getting profile names
  module MIColor
    # Creates an rgba color with profile. The profile is optional & if not set 
    # then the srgb color profile will be used. Any of the color components can
    # be set to an equation which is why String is an option.
    # @param r [Float, Fixnum, String] The red component of the color
    # @param g [Float, Fixnum, String] The green component of the color
    # @param b [Float, Fixnum, String] The blue component of the color
    # @param a [Float, Fixnum, String] Alpha component of color (transparency)
    # @param profile [String] The name of the color profile for the color
    # @return [Hash] A representation of the rgb color with alpha and profile.
    def self.make_rgbacolor(r, g, b, a: 1.0, profile: nil)
      profile = "kCGColorSpaceSRGB" if profile.nil?
      return { :red => r, :green => g, :blue => b,
                :alpha => a, :colorcolorprofilename => profile }
    end

    # Set the red component of a rgba color to a formula.
    # The equations are maths like and functions like sin and cos work
    # as you would expect. Variables are identified by starting with a $ sign.
    # So a simple equation looks like: "10.0 + $xadjust"
    # @param theColor [Hash] A previously created rgba color hash.
    # @param theEquation [String] The equation to assign to the red component
    # @return [Hash] The modified rgba color hash.
    def self.rgbacolor_setred_toequation(theColor, theEquation)
      theColor[:red] = theEquation
      theColor
    end

    # Set the green component of a rgba color to a formula.
    # @param theColor [Hash] A previously created rgba color hash.
    # @param theEquation [String] The equation to assign to the green component
    # @return [Hash] The modified rgba color hash.
    def self.rgbacolor_setgreen_toequation(theColor, theEquation)
      theColor[:green] = theEquation
      theColor
    end

    # Set the blue component of a rgba color to a formula.
    # @param theColor [Hash] A previously created rgba color hash.
    # @param theEquation [String] The equation to assign to the blue component
    # @return [Hash] The modified rgba color hash.
    def self.rgbacolor_setblue_toequation(theColor, theEquation)
      theColor[:blue] = theEquation
      theColor
    end

    # Set the alpha component of a rgba or gray color to a formula.
    # @param theColor [Hash] A previously created rgba or gray color hash.
    # @param theEquation [String] The equation to assign to the alpha component
    # @return [Hash] The modified color hash.
    def self.color_setalpha_toequation(theColor, theEquation)
      theColor[:alpha] = theEquation
      theColor
    end

    # Creates a gray color with profile. If profile is not included or set to
    # nil, then the generic gray profile will be used. Possible profile.
    # @param g [Float, #to_f] The grayscale value of the color
    # @param a [Float, #to_f] The alpha component of the color (transparency)
    # @param profile [String] The name of the profile for the grayscale color
    # @return [Hash] A representation of the gray color with alpha and profile.
    def self.make_graycolor(g, a: 1.0, profile: nil)
      profile = "kCGColorSpaceGenericGray" if profile.nil?
      return { :gray => g, :alpha => a, :profile => profile }
    end

    # Set the gray value of a gray color to a formula.
    # @param theColor [Hash] A previously created rgba color hash.
    # @param theEquation [String] The equation to assign to the gray component
    # @return [Hash] The modified gray color hash.
    def self.graycolor_setgray_toequation(theColor, theEquation)
      theColor[:gray] = theEquation
      theColor
    end

    # Creates an cmyk color. Core Graphics only supplies one named CMYK
    # color profile, so that profile is assigned.
    # @param c [Float, #to_f] The cyan component of the cmyk color
    # @param m [Float, #to_f] The magenta component of the cmyk color
    # @param y [Float, #to_f] The yellow component of the cmyk color
    # @param k [Float, #to_f] The cmyk black component of the color
    # @return [Hash] A representation of a cmyk color.
    def self.make_cmykcolor(c, m, y, k)
      return { :cyan => c, :magenta => m, :yellow => y, :cmykblack => k, 
                :colorcolorprofilename => "kCGColorSpaceGenericCMYK" }
    end

    # Get the list of named rgb color profiles built in to CoreGraphics
    # @return [Array<String>] An array of rgb color profile names.
    def self.rgbprofiles
      return ['kCGColorSpaceGenericRGB', 'kCGColorSpaceGenericRGBLinear',
                'kCGColorSpaceSRGB', 'kCGColorSpaceAdobeRGB1998']
    end

    # Get the list of named grayscale profiles built into CoreGraphics
    # @return [Array<String>] An array of grayscale profile names.
    def self.grayprofiles
      return ['kCGColorSpaceGenericGray', 'kCGColorSpaceGenericGrayGamma2_2']
    end
  end

  # == Wrap an array of path elements
  # As core graphics works with the concept of the current point, when a path
  # is first started a point is supplied which is the starting point for the
  # path. From then on with the addition of each path component the current
  # point moves to the end point of the last path element added. After adding
  # path elements like a rectangle, or an oval you can specify where the 
  # current point will be without adding to the path by using the moveto
  # method rather than trying to guess where the current point might have
  # finished.
  class MIPath
    # Initialize a MIPath object which sets @pathArray to an empty list
    # @return [MIPath]
    def initialize()
      # The path array containing all the path elements.
      @pathArray = []
    end

    # Get the list of path elements
    # @return [Array<Hash>] list of path elements
    def patharray
      return @pathArray
    end

    # Add a rectangle to the list of path elements.
    # @param theRect [Hash] A hash representation of a rectangle.
    # @return [Array<Hash>] list of path elements
    def add_rect(theRect)
      pathElement = { :elementtype => "pathrectangle", :rect => theRect }
      @pathArray.push(pathElement)
      @pathArray
    end

    # Add a rounded rectangle to the list of path elements.
    # @param theRect [Hash] A hash representation of a rectangle.
    # @param radius [Float, #to_f] The radius of the rounded corners of the rect
    # @return [Array<Hash>] list of path elements
    def add_roundedrectangle(theRect, radius: 10.0)
      pathElement = { :elementtype => "pathroundedrectangle",
                          :rect => theRect, :radius => radius.to_f }
      @pathArray.push(pathElement)
      @pathArray
    end

    # Add a rounded rectangle to the list of path elements.
    # @param theRect [Hash] A hash representation of a rectangle.
    # @param radiuses [Array<Float>] A radius for each corner of the rectangle.
    # @return [Array<Hash>] list of path elements
    def add_roundedrectangle_withradiuses(theRect,
                                          radiuses: [2.0, 4.0, 8.0, 16.0])
      pathElement = { :elementtype => "pathroundedrectangle",
                      :rect => theRect, :radiuses => radiuses }
      @pathArray.push(pathElement)
      @pathArray
    end

    # Add an oval to the list of path elements.
    # @param ovalBounds [Hash] A representation of a rect that bounds the oval.
    # @return [Array<Hash>] list of path elements
    def add_oval(ovalBounds)
      pathElement = { :elementtype => "pathoval", :rect => ovalBounds }
      @pathArray.push(pathElement)
      @pathArray
    end

    # Add a bezier curve to the list of path elements.
    # @param controlPoint1 [Hash] First control point of a bezier curve
    # @param controlPoint2 [Hash] Second control point of a bezier curve
    # @param endPoint [Hash] The end point of the bezier curve
    # @return [Array<Hash>] list of path elements
    def add_bezierpath_withcp1_cp2_endpoint(controlPoint1: { :x => 0.0,
                                                             :y => 0.0 }, 
                                            controlPoint2: { :x => 9.0,
                                                             :y => 9.0 }, 
                                            endPoint: { :x => 10.0,
                                                        :y => 20.0 })
      pathElement = { :elementtype => "pathbeziercurve",
                        :controlpoint1 => controlPoint1,
                        :controlpoint2 => controlPoint2,
                        :endpoint => endPoint }
      @pathArray.push(pathElement)
      @pathArray
    end

    # Add a bezier curve to the list of path elements.
    # @param controlPoint1 [Hash] The quadratic curve control point
    # @param endPoint [Hash] The quadratic curve end point
    # @return [Array<Hash>] list of path elements
    def add_quadraticpath(controlPoint1: { :x => 0.0, :y => 0.0 }, 
                          endPoint: { :x => 10.0, :y => 20.0 })
      pathElement = { :elementtype => "pathquadraticcurve",
                      :controlpoint1 => controlPoint1,
                      :endpoint => endPoint }
      @pathArray.push(pathElement)
      @pathArray
    end

    # Add a line to the list of path elements.
    # @param endPoint [Hash] Point defining the end of the line
    # @return [Array<Hash>] list of path elements
    def add_lineto(endPoint)
      pathElement = { :elementtype => "pathlineto", :endpoint => endPoint }
      @pathArray.push(pathElement)
      @pathArray
    end

    # Move to a new location without adding a path element.
    # @param endPoint [Hash] Point defining the new location for the path.
    # @return [Array<Hash>] list of path elements
    def add_moveto(endPoint)
      pathElement = { :elementtype => "pathmoveto", :point => endPoint }
      @pathArray.push(pathElement)
      @pathArray
    end

    # Close the sub path.
    # The close sub path is just treated as another path element in the list
    # of path elements.
    # @return [Array<Hash>] list of path elements
    def add_closesubpath()
      @pathArray.push({ :elementtype => "pathclosesubpath" })
      @pathArray
    end

    # Add a triangle shape to the path.
    # @param points [Array<Hash>] A list of 3 points
    def add_triangle(points: nil)
      fail "Needs an array of 3 points" if points.nil?
      fail "Needs an array of 3 points" unless points.length.eql? 3

      self.add_moveto(points[0])
      self.add_lineto(points[1])
      self.add_lineto(points[2])
      self.add_lineto(points[0])
      self.add_closesubpath()
    end
  end

  # == MIShadow objects describe the form a shadow takes. Applied to drawing.
  class MIShadow
  
    # Initialize a MIShadow object, basically setting @shadownHash
    def initialize()
      # The shadow hash, holding all the properties of the shadow
      @shadowHash = {}
    end
  
    # Get the shadow hash
    # @return [Hash] The hash representation of the shadow
    def shadowhash
      return @shadowHash
    end

    # Set the color used to draw the shadow with.
    # @param theColor [Hash] The shadow color.
    def color=(theColor)
      @shadowHash[:fillcolor] = theColor
    end
  
    # Set the shadow offset
    # @param theOffset [Hash] A size { :width, :height } hash.
    def offset=(theOffset)
      @shadowHash[:offset] = theOffset
    end
  
    # Set the blur to apply to the shadow
    # @param theBlur [Float, String] The blur width. String allows a formula
    def blur=(theBlur)
      @shadowHash[:blur] = theBlur
    end
  end

  # == Objects of the draw element class manage basic drawing
  # All shape drawing including drawing of path objects is done through objects
  # of the MIDrawElement class. Objects of this class also manage the drawing
  # of an array of draw elements. Drawing that is not managed by objects of this
  # class are, drawing of images, drawing of text, drawing of linear color
  # gradients.
  class MIDrawElement
    
    # Initialize a new MIDrawElement object with the element type.
    # @param elementType [String] The type of draw element command
    # @return [MIDrawElement] the newly created object
    def initialize(elementType)
      # The hash should contain all the information needed to do the drawing 
      @elementHash = { :elementtype => elementType }
    end

    # reset the element type, most useful when you want to use the same element
    # for drawing fill and stroking. Be careful though, due to the way ruby
    # passes objects by reference you might end up modifying an already setup
    # draw element command that you thought was finalized.
    # @param elementType [String] The type of draw element command.
    # @return [Hash] The draw element hash
    def elementtype=(elementType)
      @elementHash[:elementtype] = elementType
    end

    # Set the variables property of the drawing instruction to variablesHash
    # The property keys for the input variables hash are variable names, and 
    # the property values are the values to be assigned to the variables.
    # @param theVariables [Hash] keys are variable names.
    # @return [Hash] The updated hash with variables assigned.
    def variables=(theVariables)
      @elementHash[:variables] = theVariables
    end

    # Convert the draw element hash to a json string.
    # @return [String] A json string representing the hash.
    def to_json()
      @elementHash.to_json
    end

    # Get the draw element hash
    # @return [Hash] The hash of the draw element object.
    def elementhash
      @elementHash
    end

    # Set the rectangle
    # @param theRect [Hash] Assign a rectangle for draw rect and oval elements
    # @return [Hash] The hash of the draw element object
    def rectangle=(theRect)
      @elementHash[:rect] = theRect
    end
  
    # Set the fill color used in draw fill element commands
    # @param fillColor [Hash] A hash representation of a color see {MIColor}
    # @return [Hash] The hash of the draw element object
    def fillcolor=(fillColor)
      @elementHash[:fillcolor] = fillColor
    end

    # Set the stroke color used in draw stroke element commands
    # @param strokeColor [Hash] A hash representation of a color see {MIColor}
    # @return [Hash] The hash of the draw element object
    def strokecolor=(strokeColor)
      @elementHash[:strokecolor] = strokeColor
    end

    # Set the line used used in draw stroke element commands
    # @param lineWidth [Float, String] The stroke draw width
    # @return [Hash] The hash of the draw element object
    def linewidth=(lineWidth)
      @elementHash[:linewidth] = lineWidth
    end

    # Set the shadow to be applied to the drawing.
    # @param theShadow [Hash, #shadowhash] The shadow to apply to the drawing
    def shadow=(theShadow)
      if theShadow.respond_to? "shadowhash"
        theShadow = theShadow.shadowhash
      end
      @elementHash[:shadow] = theShadow
    end

    # Set the debug name for this draw element command
    # Keeping track of draw commands to track down bugs can be difficult, by
    # giving a draw element command a debug name the debug name will be returned
    # if a draw command error occurred whilst processing a draw element which 
    # has a debug name specified.
    # @param debugName [String] The debug name
    # @return [Hash] The hash of the draw element object
    def elementdebugname=(debugName)
      @elementHash[:elementdebugname] = debugName
    end

    # Set the context transformation for the draw element.
    # If an affine transform was previously set, it is deleted from the
    # the draw element hash. If there was a previous context transformation set
    # it is replaced.
    # @param transformation [Array<Hash>] An ordered list of context transforms
    # @return [Hash] The hash of the draw element object
    def contexttransformations=(transformation)
      @elementHash.delete(:affinetransform)
      @elementHash[:contexttransformation] = transformation
    end

    # Set the affine transform for the draw element.
    # If a context transformation was previously set, it is deleted from the
    # draw element hash. If there was a previous affine transform set then it is
    # replaced.
    # @param affineTransform [Hash] Representation of an affine transform
    # @return [Hash] The hash of the draw element object
    def affinetransform=(affineTransform)
      @elementHash.delete(:contexttransformation)
      @elementHash[:affinetransform] = affineTransform
    end

    # Assign a line hash to the draw element hash
    # @param theLine [Hash] A start and end point, See {MIShapes.make_line}
    # return [Hash] the line hash assigned to the draw element hash.
    def line=(theLine)
      @elementHash[:line] = theLine
    end

    # Set an array of points, used in the draw lines draw element command.
    # @param arrayOfPoints [Array<Hash>] A list of points for drawing lines.
    # @return [Hash] The hash of the draw element object
    def points=(arrayOfPoints)
      @elementHash[:points] = arrayOfPoints
    end

    # Set the linecap which defines how the ends of a line are drawn
    # For values see {linecap_list}
    # @param lineCap [String] One of: {linecap_list}
    # @return [Hash] The hash of the draw element object
    def linecap=(lineCap)
      @elementHash[:linecap] = lineCap
    end

    # Set the line join which defines how lines are joined in a path
    # For values see {linejoin_list}
    # @param lineJoin [String] One of: {linejoin_list}
    # @return [Hash] The hash of the draw element object
    def linejoin=(lineJoin)
      @elementHash[:linejoin] = lineJoin
    end

    # Set the miter limit. The miter limit is described in the painting a path
    # section of Apple's Quarzt 2D Programming Guide. I'm providing a link but
    # Apple does move its documentation around so the link can become stale:
    # {https://t.co/0zBEVpD7YZ Painting paths section of Quartz 2D Programming}
    # @param miterVal [Float, #to_f] The miter value.
    # @return [Hash] The hash of the draw element object
    def miter=(miterVal)
      @elementHash[:miter] = miterVal.to_f
    end

    # The radius to use for a rounded rectangle
    # @param radius [Float, String] The radius to draw the rectangle's corners
    # @return [Hash] The hash of the draw element object
    def radius=(radius)
      @elementHash[:radius] = radius
    end

    # The radius to use for each corner of a rounded rectangle. First radius
    # is for the bottom right corner of the rectangle, and then each next value
    # is for the next corner in an anti-clockwise direction.
    # @param radiuses [Array<Float, String>] One value for each corner
    # @return [Hash] The hash of the draw element object
    def radiuses=(radiuses)
      @elementHash[:radiuses] = radiuses # radiuses is an array of floats.
    end

    # Add the draw element to the array of elements to be drawn
    # When the draw element is array of elements, then what is drawn is
    # in a list of draw elements. This methods adds a draw element to the
    # list of draw elements.
    # @param drawElement [Hash] The element to be added to the list of elements.
    # @return [Hash] The hash of the draw element object
    def add_drawelement_toarrayofelements(drawElement)
      unless @elementHash[:elementtype].intern.eql? :arrayofelements
        fail "Can only add a drawElement to \"elementtype\"" +
              " \"arrayofelements\""
      end
      if drawElement.respond_to? "elementhash"
        drawElement = drawElement.elementhash
      end

      if @elementHash[:arrayofelements].nil?
        @elementHash[:arrayofelements] = [ drawElement ]
      else
        @elementHash[:arrayofelements].push(drawElement)
      end
    end

    # Set the array of path elements used when the draw element is stroke path
    # or fill path, or fill and stroke path.
    # @param thePath [Array<Hash>] The array of path elements defining the path.
    # @return [Array] The array of path elements assign draw element.
    def arrayofpathelements=(thePath)
      unless (@elementHash[:elementtype].intern.eql? :strokepath) ||
               (@elementHash[:elementtype].intern.eql? :fillpath) ||
               (@elementHash[:elementtype].intern.eql? :fillandstrokepath)
        fail "Allowed elementtype are: strokepath, fillpath, fillandstrokepath"
      end
      thePath = thePath.patharray if thePath.respond_to? "patharray"
      @elementHash[:arrayofpathelements] = thePath
    end

    # Set the point for the start of the array of path elements.
    # @param startPoint [Hash] The path starting point. {MIShapes.make_point}
    # @return [Hash] The start point added to the draw element.
    def startpoint=(startPoint)
      @elementHash[:startpoint] = startPoint
    end

    # Set the drawing blend mode
    # @param blendMode [String] see {MIMeta.cgblendmodes} for list of values
    # @return [Hash] The hash of the draw element object
    def blendmode=(blendMode)
      @elementHash[:blendmode] = blendMode
    end

  # Class methods follow

    # Get the list of draw element types
    # @return [Array<String>] The list of possible draw element types
    def self.elementtype_list
      return ['fillrectangle', 'strokerectangle', 'filloval', 'strokeoval',
                'drawline', 'drawlines', 'fillroundedrectangle',
                'strokeroundedrectangle', 'fillpath', 'strokepath',
                'fillandstrokepath', 'drawbasicstring', 'lineargradientfill',
                'drawimage', 'arrayofelements']
    end

    # Get the list of path element types
    # @return [Array<String>] The list of possible path element types
    def self.pathelementtype_list
      return ['pathmoveto', 'pathlineto', 'pathbeziercurve',
               'pathquadraticcurve', 'pathrectangle',
               'pathroundedrectangle', 'pathoval', 'pathclosesubpath']
    end
  
    # Get the list of line cap definitions
    # The linecap is described in the drawing paths section of Apple's 
    # Quartz 2D Programming guide. I'm providing the link here but apple
    # moves it's documentation around so this link might become stale.
    # {https://t.co/0zBEVpD7YZ Painting paths section of Quartz 2D Programming}
    # @return [Array<String>] The list of line cap values
    def self.linecap_list
      return %w(kCGLineCapButt kCGLineCapRound kCGLineCapSquare)
    end

    # Get the list of line join definitions
    # The linejoin is described in the drawing paths section of Apple's 
    # Quartz 2D Programming guide. I'm providing the link here but apple
    # moves it's documentation around so this link might become stale.
    # {https://t.co/0zBEVpD7YZ Painting paths section of Quartz 2D Programming}
    # @return [Array<String>] The list of line join values
    def self.linejoin_list
      return %w(kCGLineJoinMiter kCGLineJoinRound kCGLineJoinBevel)
    end
  end

  # Objects of the linear gradient fill element class contain the information
  # needed to draw a linear gradient fill in a context. Required properties are
  # the line, array of path elements, the start point for the array of path
  # elements, an array of locations on the line, and the colors to go with them.
  class MILinearGradientFillElement

    def initialize()
      # The hash that will contain all the information needed to do the drawing 
      @elementHash = {}
      @elementHash[:elementtype] = :lineargradientfill
      # Assign the start point for the array of path elements which defines
      # the shape within which the gradient fill is drawn. If the list of 
      # path elements is a single item like a rectangle, or oval etc. then
      # it would be nice to have a default starting point.
      @elementHash[:startpoint] = MIShapes.make_point(0, 0)
    end

    # Get the draw element hash
    # @return [Hash] The hash of the draw element object.
    def elementhash
      return @elementHash
    end

    # Convert the draw element linear gradient hash to a json string.
    # @return [String] A json string representing the hash.
    def to_json()
      return @elementHash.to_json
    end

    # Assign a line hash to the draw element hash
    # @param theLine [Hash] A start and end point, See {MIShapes.make_line}
    # return [Hash] the line hash assigned to the draw element hash.
    def line=(theLine)
      @elementHash[:line] = theLine
    end

    # Set the array of path elements to clip the drawing of the gradient fill
    # @param pathElements [Array<Hash>] The list of path elements
    # @return [Hash] The representation of the draw element object.
    def arrayofpathelements=(pathElements)
      arrayOfPathElements = pathElements
      if arrayOfPathElements.respond_to? "patharray"
        arrayOfPathElements = arrayOfPathElements.patharray
      end
      @elementHash[:arrayofpathelements] = arrayOfPathElements
    end

    # Set the start point for the start of the array of path elements.
    # @param startPoint [Hash] The initial point for creating the path.
    def startpoint=(startPoint)
      @elementHash[:startpoint] = startPoint
    end

    # The two arrays need to be the same length. The locations is an array
    # of positions along the gradient line at which the colors are defined. The
    # gradient fill interpolates the color between each defined point along the
    # line. The array of locations represents the position along the gradient
    # line. A value of 0.0 is the starting point of the line, a value of 1.0
    # is the end point of the line and any value in between interpolates a
    # position along the line
    # @param locations [Array<Float>] positions along the defined line.
    # @param colors [Array<Hash>] An list of colors, one for each location.
    # @return [Hash] The representation of the draw element object.
    def set_arrayoflocations_andarrayofcolors(locations, colors)
      if locations.length != colors.length
        fail "Linear gradient fill needs a color for each location."
      end
      @elementHash[:arrayoflocations] = locations
      @elementHash[:arrayofcolors] = colors
    end

    # Set the blend mode to draw the gradient fill
    # @param blendMode [String] A blend mode, one of {MIMeta.cgblendmodes}
    # @return [Hash] The representation of the draw element object.
    def blendmode=(blendMode)
      @elementHash[:blendmode] = blendMode
    end

    # Set the context transformation to draw the gradient fill. Scrubs any
    # possible defined affine transform.
    # @param transformation [Array<Hash>] Ordered array of transforms
    # @return [Hash] The representation of the draw element object.
    def contexttransformations=(transformation)
      @elementHash.delete(:affinetransform)
      @elementHash[:contexttransformation] = transformation
    end

    # Set the affine transform to draw the gradient fill. Scrubs any
    # possible defined context transformation.
    # @param affineTransform [Hash] The affine transform representation
    # @return [Hash] The representation of the draw element object.
    def affinetransform=(affineTransform)
      @elementHash.delete(:contexttransformation)
      @elementHash[:affinetransform] = affineTransform
    end
  end


  # Objects of the draw basic string element class contain the information
  # needed to draw text in a context. Required properties are the text, and the 
  # point where to draw the text. The font to use to draw the text and the text
  # size can either be defined by setting the postscript font name and font
  # size, or by setting the user interface font. There are a number of optional
  # properties that can be set to configure how the text should be drawn.
  class MIDrawBasicStringElement
  
    # Initialize a new draw string element object
    def initialize()
      # The hash that will contain all the information needed to do the drawing 
      @elementHash = {}
      @elementHash[:elementtype] = :drawbasicstring
    end

    # Get the draw element hash
    # @return [Hash] The hash of the draw element object.
    def elementhash
      return @elementHash
    end

    # Convert the draw element hash to a json string.
    # @return [String] A json string representing the hash.
    def to_json()
      return @elementHash.to_json
    end
  
    # Set the text to be drawn. Required.
    # @param textToDraw [String] The text to be drawn.
    # @return [Hash] The representation of the draw string command
    def stringtext=(textToDraw)
      @elementHash[:stringtext] = textToDraw
    end

    # Set the bottom left position of where the text is to be drawn. Required.
    # If for example the array of path elements contains a single rectangle
    # element within which to contain the text, then this point will be ignored.
    # If the array of path elements starts with a line or curve then this point
    # will be used as the starting point for the path.
    # @param drawPoint [Hash] A point created by {MIShapes.make_point}
    # @return [Hash] The representation of the draw string command
    def point_textdrawnfrom=(drawPoint)
      @elementHash[:point] = drawPoint
    end

    # Set the postscript name of the font you want to use to draw the text.
    # Also clear any reference to a user interface font.
    # @param postscriptFontName [String] The postscript name of the font to use
    # @return [Hash] The representation of the draw string command
    def postscriptfontname=(postscriptFontName)
      @elementHash[:postscriptfontname] = postscriptFontName
      @elementHash.delete(:userinterfacefont)
    end

    # Set the user interface to draw the text with. A user interface font also
    # defines a font size, but this can be over riden by setting the font size.
    # Use {MIMeta.listofuserinterfacefonts} to get user interface font list
    # @param userInterfaceFont [String] The user interface font to draw the text
    # @return [Hash] The representation of the draw string command
    def userinterfacefont=(userInterfaceFont)
      @elementHash[:userinterfacefont] = userInterfaceFont
      @elementHash.delete(:postscriptfontname)
    end

    # Set the font size to use to draw the text. A required option if drawing
    # text using a post script font name, or an optional property if drawing
    # the text using a user interface font.
    # @param fontSize [Float, #to_f] The user interface font to draw the text
    # @return [Hash] The representation of the draw string command
    def fontsize=(fontSize)
      @elementHash[:fontsize] = fontSize.to_f
    end

    # Set the color for drawing the text
    # @param fillColor [Hash] The color to draw text with created with {MIColor}
    # @return [Hash] The representation of the draw string command
    def fillcolor=(fillColor)
      @elementHash[:fillcolor] = fillColor
    end

    # Set the path within which the text will be drawn.
    # @param pathElements [Array<Hash>] Array of path elements. See {MIPath}
    # @return [Hash] The representation of the draw string command
    def arrayofpathelements=(pathElements)
      arrayOfPathElements = pathElements
      if arrayOfPathElements.respond_to? "patharray"
        arrayOfPathElements = arrayOfPathElements.patharray
      end
      @elementHash[:arrayofpathelements] = arrayOfPathElements
    end

    # Set the text alignment when drawing the text
    # possible values are: kCTTextAlignmentLeft, kCTTextAlignmentRight,
    # kCTTextAlignmentCenter, kCTTextAlignmentJustified, kCTTextAlignmentNatural
    # @param textAlignment [String] Alignment. Default "kCTTextAlignmentNatural"
    # @return [Hash] The representation of the draw string command
    def textalignment=(textAlignment)
      @elementHash[:textalignment] = textAlignment
    end

    # Set the stroke color for stroking text.
    # @param strokeColor [Hash] The color to stroke text with, see {MIColor}
    # @return [Hash] The representation of the draw string command
    def strokecolor=(strokeColor)
      @elementHash[:strokecolor] = strokeColor
    end

    # Set stroke width.
    # If this property is not set then text will be drawn with the fill color
    # If this property is set with a positive value then text will be stroked
    # using the stroke color and not filled. If this property is set with a
    # negative value, then the text will be draw filled with the fill color and
    # then stroked using the stroke color with a stroke width of the absolute
    # value of the stroke width.
    # @param stringStrokeWidth [Float, #to_f] The width for stroking the text.
    # @return [Hash] The representation of the draw string command
    def stringstrokewidth=(stringStrokeWidth)
      @elementHash[:stringstrokewidth] = stringStrokeWidth.to_f
    end

    # Set the blend mode for drawing the text.
    # @param blendMode [String] See {MIMeta.cgblendmodes} for possible modes
    # @return [Hash] The representation of the draw string command
    def blendmode=(blendMode)
      @elementHash[:blendmode] = blendMode
    end

    # Set the shadow to be applied to the drawn text.
    # @param theShadow [Hash, #shadowhash] The shadow to apply.
    def shadow=(theShadow)
      if theShadow.respond_to? "shadowhash"
        theShadow = theShadow.shadowhash
      end
      @elementHash[:shadow] = theShadow
    end

    # Set the context transformation when drawing the text. Allows you to scale,
    # or rotate or position the text when drawing. See {MITransformations}.
    # Only one of context transformation, or affine transform is allowed.
    # @param transformation [Array<Hash>] A list of ordered context transforms.
    # @return [Hash] The representation of the draw string command
    def contexttransformations=(transformation)
      @elementHash.delete(:affinetransform)
      @elementHash[:contexttransformation] = transformation
    end

    # Set the affine transform when drawing the text. See {MITransformations}
    # Only one of context transformations, or affine transforms is allowed.
    # @param affineTransform [Hash] The affine transform to be set.
    # @return [Hash] The representation of the draw string command
    def affinetransform=(affineTransform)
      @elementHash.delete(:contexttransformation)
      @elementHash[:affinetransform] = affineTransform
    end
  end

  # Objects of the draw image element class contain the information needed to
  # draw an image into a context. Required info is the image source and
  # the destination rectangle. Options info is the source image, blend mode,
  # and interpolation quality.
  class MIDrawImageElement

    # Initialize a new draw image element object.
    def initialize()
      # The hash that will contain all the information needed to do the drawing 
      @elementHash = {}
      @elementHash[:elementtype] = :drawimage
    end

    # Get the draw element hash
    # @return [Hash] The hash of the draw element object.
    def elementhash
      return @elementHash
    end

    # Convert the draw element hash to a json string.
    # @return [String] A json string representing the hash.
    def to_json()
      return @elementHash.to_json
    end

    # Set the object from which to source the image and optionally provide 
    # an image index.
    # @param sourceObject [Hash] The source object, see {SmigIDHash} methods
    # @param imageIndex [Fixnum, nil] Optional index into a list of images.
    # @return [Hash] The representation of the draw image command
    def set_imagesource(sourceObject: {}, imageIndex: nil)
      @elementHash[:sourceobject] = sourceObject
      @elementHash[:imageindex] = imageIndex unless imageIndex.nil?
    end

    # Set the destination rectangle within  coordinate system of the context's
    # current transformation where the image will be drawn
    # @param destRect [Hash] A rectangle created using {MIShapes.make_rectangle}
    # @return [Hash] The representation of the draw image command
    def destinationrectangle=(destRect)
      @elementHash[:destinationrectangle] = destRect
    end

    # Set the source rectangle within the frame of the source image within which
    # to crop the source image.
    # @param sourceRect [Hash] A rectangle see {MIShapes.make_rectangle}
    # @return [Hash] The representation of the draw image command
    def sourcerectangle=(sourceRect)
      @elementHash[:sourcerectangle] = sourceRect
    end

    # Set the interpolation quality option, will be used when drawing the image
    # is not a straight one to one mapping, when the transform is not an
    # identity transform.
    # See {MIDrawImageElement.listofinterpolationqualityoptions} for 
    # possible values.
    # @param interpolationQuality [String] An interpolation quality value.
    # @return [Hash] The representation of the draw image command
    def interpolationquality(interpolationQuality)
      @elementHash[:interpolationquality] = interpolationQuality
    end
  
    # Set the blend mode for drawing the image.
    # @param blendMode [String] See {MIMeta.cgblendmodes} for possible modes
    # @return [Hash] The representation of the draw string command
    def blendmode=(blendMode)
      @elementHash[:blendmode] = blendMode
    end

    # Set the shadow to be applied to the drawing.
    # @param theShadow [Hash, #shadowhash] The shadow to apply
    def shadow=(theShadow)
      if theShadow.respond_to? "shadowhash"
        theShadow = theShadow.shadowhash
      end
      @elementHash[:shadow] = theShadow
    end

    # Set context transformation when drawing the image. Allows you to scale,
    # or rotate or position the text when drawing. See {MITransformations}.
    # Only one of context transformation, or affine transform is allowed.
    # @param transformation [Array<Hash>] A list of ordered context transforms.
    # @return [Hash] The representation of the draw string command
    def contexttransformations=(transformation)
      @elementHash.delete(:affinetransform)
      @elementHash[:contexttransformation] = transformation
    end

    # Set the affine transform when drawing the image. See {MITransformations}
    # Only one of context transformations, or affine transforms is allowed.
    # @param affineTransform [Hash] The affine transform to be set.
    # @return [Hash] The representation of the draw string command
    def affinetransform=(affineTransform)
      @elementHash.delete(:contexttransformation)
      @elementHash[:affinetransform] = affineTransform
    end
  
    # Class methods.
  
    # Return the list of interpolation quality strings.
    # @return [Array<String>] A list of interpolation quality strings.
    def self.listofinterpolationqualityoptions
      return ['kCGInterpolationDefault', 'kCGInterpolationNone',
                'kCGInterpolationLow', 'kCGInterpolationMedium',
                'kCGInterpolationHigh']
    end
  end

end
