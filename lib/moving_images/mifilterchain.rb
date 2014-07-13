
module MovingImages

  # ==The MIFilterProperty module is used for making filter properties
  # Once a filter property is created, it will be added to a list of properties
  # which is part of the definition of a {MIFilter} in a {MIFilterChain}.
  module MIFilterProperty
    # Make an image property, with an optional value which is the source of 
    # the input image. The key will most often be "inputImage", but
    # can also have values like "backgroundImage".
    # @param key [String] The filter property key used to assign the image.
    # @param value [Hash] The object to get the image from. See {SmigIDHash}
    # @return [Hash] The filter property image hash.
    def self.make_ciimageproperty(key: :inputImage, value: nil)
      imageHash = { :cifilterkey => key, :cifiltervalueclass => :CIImage }
      imageHash[:cifiltervalue] = value unless value.nil?
      imageHash
    end

    # Add the object to the property hash which provides the image
    # @param ciProperty [Hash] The filter property to be assigned the image.
    # @param imageSource [Hash] The object to get image from. See {SmigIDHash}
    # @return [Hash] The filter property image hash.
    def self.addimagesource_tociimageproperty(ciProperty, imageSource)
      ciProperty[:cifiltervalue] = imageSource
      return ciProperty
    end

    # Make a core image vector property, taking a string representing the vector
    # @param key [String] The filter property to be assigned the vector.
    # @param value [String] A string representing the vector.
    # @return [Hash] The vector filter property hash.
    def self.make_civectorproperty_fromstring(key: "inputExtent",
                                              value: "[ 0 0 100 100 ]")
      return { :cifilterkey => key, :cifiltervalue => stringVal,
                :cifiltervalueclass => "CIVector" }
    end

    # Make a core image vector property, taking an array of Floats.
    # @param key [String] The filter property key used to assign the vector.
    # @param value [Array<Float>] 
    # @return [Hash] The vector filter property hash.
    def self.make_civectorproperty_fromarray(key: "inputCenter",
                                                  value: [50.0, 50.0])
      stringVal = "["
      value.each { |item|
        stringVal += " " + item.to_s
      }
      stringVal += " ]"
      return self.make_civectorproperty_fromstring(key: key, value: stringVal)
    end

    # Make a core image color property, taking a string representation of the 
    # color    
    # The color needs to be a rgb color with alpha in kCGColorSpaceGenericRGB
    # color space.
    # @param key [String] The filter property to be assigned the color
    # @param value [String] A string representation of the color
    # @return [Hash] The color filter property hash
    def self.make_cicolorproperty_fromstring(key: "inputColor",
                                             value: "0 0 1 0")
      return { :cifilterkey => key, :cifiltervalue => value,
                :cifiltervalueclass => "CIColor" }
    end

    # Make a core image color property, taking an array of color components.
    # The array order is: [ red, green, blue, alpha ] and the color needs to be
    # defined with the profile kCGColorSpaceGenericRGB
    # @param key [String] The filter property to be assigned the color value.
    # @param value [Array<Float>] An array of numbers [r, g, b, a]
    # @return [Hash] A core image filter color property hash
    def self.make_cicolorproperty_fromarray(key: "inputColor", value: [0,0,0,1])
      stringVal = ""
      isFirst = true
      arrayVal.each { |item|
        if isFirst
          stringVal = item.to_s
          isFirst = false
        else
          stringVal = " " + item.to_s
        end
      }
      return self.make_cicolorproperty_fromstring(key: key, value: stringVal)
    end

    # Make a core image color property, taking a color hash, see {MIColor}
    # Because the profile is specified, when the color is converted to a core 
    # image color it will be converted to a color with a profile: 
    # "kCGColorSpaceGenericRGB" before the filter property is assigned to
    # the filter.
    # @param key [String] The filter property to be assigned the color value.
    # @param value [Hash] RGB color generated using {MIColor}
    # @return [Hash] A core image filter color property hash
    def self.make_cicolorproperty_fromhash(key: "inputColor",
            value: { :red => 1.0, :green => 1.0, :blue => 1.0, :alpha => 1.0,
                      :colorcolorprofilename => "kCGColorSpaceSRGB" })
      return { :cifilterkey => key, :cifiltervalue => value,
                  :cifiltervalueclass => "CIColor" }
    end

    # Make a number property
    # @param key [String] The filter property to be assigned the numeric value.
    # @param value [Float] The numeric value to be assigned.
    # @return [Hash] The core image numeric property hash.
    def self.make_cinumberproperty(key: "inputRadius", value: 100.0)
      return { :cifilterkey => key, :cifiltervalue => value }
    end

    # Make a number property with a min-max range and a default value
    # @param key [String] The filter property to be assigned the numeric value.
    # @param min [Float, Fixnum] The min value to be assigned to the property.
    # @param max [Float, Fixnum] The max value to be assigned to the property.
    # @param default [Float, Fixnum] The default value assigned to the property.
    # @return [Hash] The core image numeric property hash.
    def self.make_cinumberproperty_withmin_max_default(key: "inputAngle",
                                                       min: 0.0,
                                                       max: Math::PI * 2.0, 
                                                       default: Math::PI)
      return { :cifilterkey => key, :cifiltervalue => default, :max => max,
                :min => min, :default => default }
    end

    # Assign a integer value to an already created filter property
    # Constrain the the value to be assigned to within the min/max range if
    # those values exist in the filter property hash.
    # @param numberProperty [Hash] The property to assign the property value to.
    # @param theVal [Integer, #to_i] The integer value to be assigned.
    # @return [Hash] The filter property with the assigned value.
    def self.assigninteger_tonumberproperty(numberProperty: {}, theVal: 1)
      theVal = theVal.to_i if theVal.responds_to? "to_i"
      unless (numberProperty[:min].nil? && (theVal >= numberProperty[:min]))
        theVal = numberProperty[:min]
      end
  
      unless (numberProperty[:max].nil? && (theVal <= numberProperty[:max]))
        theVal = numberProperty[:max]
      end
      numberProperty[:cifiltervalue] = theVal
      numberProperty
    end

    # Assign a float value to an already created filter property
    # Constrain the the value to be assigned to within the min/max range if
    # those values exist in the filter property hash.
    # @param numberProperty [Hash] The property to assign the property value to.
    # @param theVal [Float, #to_f] The float value to be assigned.
    # @return [Hash] The filter property with the assigned value.
    def self.assignfloat_tonumberproperty(numberProperty, theVal)
      theVal = theVal.to_f if theVal.responds_to? "to_f"
      unless (numberProperty[:min].nil? && (theVal >= numberProperty[:min]))
        theVal = numberProperty[:min]
      end
  
      unless (numberProperty[:max].nil? && (theVal <= numberProperty[:max]))
        theVal = numberProperty[:max]
      end
      numberProperty[:cifiltervalue] = theVal
      numberProperty
    end

    # Make an affine transform filter property.
    # @param key [String] The filter property to be assigned the affine transform.
    # @param m11 [Float] The value for the m11 component of the affine transform.
    # @param m12 [Float] The value for the m12 component of the affine transform.
    # @param m21 [Float] The value for the m21 component of the affine transform.
    # @param m22 [Float] The value for the m22 component of the affine transform.
    # @param tX [Float] The value for the tX component of the affine transform.
    # @param tY [Float] The value for the tY component of the affine transform.
    # @return [Hash] The core image filter property representing the transform.
    def self.make_affinetransformproperty(key: "inputTransform",
                                          m11: 1.0,
                                          m12: 0.0,
                                          m21: 0.0,
                                          m22: 1.0,
                                          tX: 0.0,
                                          tY: 0.0)
      affineHash = { :m11 => m11.to_f, :m12 => m12.to_f, :m21 => m21.to_f,
                      :m22 => m22.to_f, :tX => tX, :tY => tY }
      return { :cifilterkey => key, :cifiltervalue => affineHash,
              :cifiltervalueclass => "NSAffineTransform" }
    end
  end

  # ==The MIFilter module is used for making filter hash objects
  # A filter is made up of a filter name which is the core image name for the
  # filter to be created, an optional name id, which is used to identify the 
  # filter so that it can be linked to from later filters in the filter chain.
  module MIFilter
    # Assign a list of filter properties to the filter object hash.
    # @param filterObject [Hash] The filter object hash to assign properties to.
    # @param theProperties [Array<Hash>] The properties to be assigned
    # @return [Hash] The core image filter object hash.
    def self.assignproperties_tocifilter(filterObject: {}, theProperties: [])
      filterObject[:cifilterproperties] = theProperties
      filterObject
    end

    # Add a property to the list of filter properties in the filter object hash.
    # If the filter property list doesn't yet exist, then a new property list
    # will be created, otherwise the filter property will be added to the already
    # existing list of properties.
    # @param filterObject [Hash] The filter object hash to assign the property to.
    # @param theProperty [Hash] The property to be assigned {MIFilterProperty}
    # @return [Hash] The core image filter object hash.
    def self.addproperty_tocifilter(filterObject: {}, theProperty: {})
      if filterObject[:cifilterproperties].nil?
        filterObject[:cifilterproperties] = [ theProperty ]
      else
        filterObject[:cifilterproperties].push(theProperty)
      end
      filterObject
    end

    # Add properties to the list of filter properties in the filter object hash.
    # If the filter property list doesn't yet exist, a new property list will
    # be created, otherwise the filter property will be added to the already
    # existing list of properties.
    # @param filterObject [Hash] The filter object hash to assign properties to.
    # @param theProperties [Array<Hash>] The properties to be assigned
    # @return [Hash] The core image filter object hash.
    def self.addproperties_tocifilter(filterObject: {}, theProperties: [])
      if filterObject[:cifilterproperties].nil?
        filterObject[:cifilterproperties] = theProperties
      else
        filterObject[:cifilterproperties] += theProperties
      end
      filterObject
    end

    # Make a filter object which has no inputs.
    # A small number of core image filters require no properties. They can
    # therefore be defined solely by their core image filter name, and a filter
    # name identifier.
    # @param filter [String] The core image name of the filter to be created.
    # @param filterIdentifier [String] Filter identifier for the filter chain.
    # @return [Hash] The core image filter object hash.
    def self.makefilter_noinputs(filter: "CIRandomGenerator",
                                  filterIdentifier: "")
      filterHash = { :cifiltername => filter, :cifilterproperties => [] }
      filterHash[:mifiltername] = filterIdentifier unless filterIdentifier.nil?
      filterHash
    end

    # Make a filter object with an input image.
    # @param filter [String] The core image name of the filter to be created.
    # @param filterIdentifier [String] Filter identifier for the filter chain.
    # @param inputImage [Hash] The object identifier hash, see {SmigIDHash}
    # @return [Hash] The core image filter object hash.
    def self.makefilter(filter: "CIComicEffect", filterIdentifier: "",
                                                    inputImage: {} )
      inputImageProp = { :cifilterkey => "inputImage",
                          :cifiltervalueclass => "CIImage",
                          :cifiltervalue => inputImage }
      filterHash = { :cifiltername => filter, :mifiltername => filterIdentifier,
                      :cifilterproperties => [ inputImageProp ] }
      return filterHash
    end

    # Make a filter object with a list of filter properties.
    # @param filter [String] The core image name of the filter to be created.
    # @param filterIdentifier [String] Filter identifier for the filter chain.
    # @param theProperties [Array<Hash>] List of filter properties.
    # @return [Hash] The core image filter object hash.
    def self.makefilter_withproperties(filter: "CIFlashTransition",
                              filterIdentifier: nil, theProperties: [] )
      filterHash = { :cifiltername => filter,
                    :cifilterproperties => theProperties }
      filterHash[:mifiltername] = filterIdentifier unless filterIdentifier.nil?
      filterHash
    end
  end

  # ==The filter chain, representing a list of connected filters
  # A filter chain can be as short as a single filter, or lengthy including
  # containing multiple branches which ultimately end at the last filter in the
  # filter chain which generates the output image. The filter chain object
  # also specifies the render destination, which is where the last filter
  # in the filter chain renders to, the software render property specifies
  # whether the filter chain is rendered in software rather than on the GPU, and
  # whether the filter chain should work in the srgb color space instead of the
  # generic linear color space which is its default.
  class MIFilterChain
    # The hash containing all the properties of the render filter chain.
    @filterChainHash

    # Initialize the filter chain object
    # @param renderDestination [Hash] Destination object {SmigIDHash}
    # @param filterList [Array<Hash>] optional list of filters in filter chain
    # @return [MIFilterChain]
    def initialize(renderDestination, filterList: nil)
      @filterChainHash = { :cirenderdestination => renderDestination }
      @filterChainHash[:cifilterlist] = filterList unless filterList.nil?
    end

    # Add a filter definition to the filter chain
    # @param filterObject [Hash] The filter definition to add to the filter chain
    # @return [Hash] The filter chain hash
    def add_filter_tofilterchain(filterObject: {})
      if @filterChainHash[:cifilterlist].nil?
        @filterChainHash[:cifilterlist] = [ filterObject ]
      else
        @filterChainHash[:cifilterlist].push(filterObject)
      end
      return @filterChainHash
    end

    # Specify whether the filter chain should be rendered in software
    # @param softwareRender [bool] Should filter chain be rendered in software
    # @return [Hash] The filter chain hash
    def set_softwarerender(softwareRender)
      @filterChainHash[:coreimagesoftwarerender] = softwareRender
      @filterChainHash
    end

    # Should the filter chain be rendered in the sRGB color space
    # By default the filter chain is rendered in the generic linear rgb color
    # space. By setting this option, your specifying that the filter chain 
    # should be rendered in the sRGB color space instead.
    # @param useSRGBProfile [bool] Should filter chain be rendered in sRGB
    # @return [Hash] The filter chain hash
    def set_use_srgbprofile(useSRGBProfile)
      @filterChainHash[:use_srgbcolorspace] = useSRGBProfile
      @filterChainHash
    end

    # Get the filter chain hash.
    # @return [Hash] The filter chain hash
    def get_filterchainhash()
      return @filterChainHash
    end

    # Convert the filter chain hash to json and return the json string
    # @return [String] The filter chain hash converted to a json string.
    #def to_json
    #  return @filterChainHash.to_json
    #end
  end

  # == Create a filter chain render property
  # When rendering a filter chain, an optional list of render properties can
  # be provided that make it possible to modify the filter properties at
  # render time. The MIFilterRenderProperty module provides methods to create
  # render properties that are associated with filters.
  module MIFilterRenderProperty
    # Create a filter property with a name identifier.
    # @param key [String] the filter property to be set.
    # @param value [String, Float, Fixnum] The value the filter property set to.
    # @param filterNameID [String] Identifier for filter in filter chain.
    # @param valueClass [String, nil] The CoreImage class name to assign
    # @return [Hash] The created render property.
    def self.make_renderproperty_withfilternameid(key: "inputLevel",
                                                  value: 10.0,
                                                  filterNameID: "blurfilter",
                                                  valueClass: nil)
      renderProp =  { :cifilterkey => key, :cifiltervalue => value,
                      :mifiltername => filterNameID }
      renderProp[:cifiltervalueclass] = valueClass unless valueClass.nil?
      return renderProp
    end

    # Create a filter property with a filter index.
    # @param key [String] the filter property to be set.
    # @param value [String, Float, Fixnum] The value the filter property set to.
    # @param filterIndex [Fixnum] The filter index in the filter chain.
    # @param valueClass [String, nil] The CoreImage class name to assign
    # @return [Hash] The created render property.
    def self.make_renderproperty_withfilterindex(key: "inputRadius",
                                                 value: 100.0,
                                                 filterIndex: 1,
                                                 valueClass: nil)
      renderProp =  { :cifilterkey => key, :cifiltervalue => value,
                      :cifilterindex => filterIndex }
      renderProp[:cifiltervalueclass] = valueClass unless valueClass.nil?
      return renderProp
    end
  end

  # == Render the filter chain object
  # When rendering the filter chain, the render command can take an optional
  # render filter chain hash. The render filter chain hash takes a source 
  # rectangle which allows you to crop the output of the render filter chain, 
  # a destination rectangle which allows you to specify where in the destination
  # context the filter chain will render. If the source rect is not specified
  # then the default is to not crop the output image, if the destination 
  # rectangle is not specified then the output is rendered to the dimensions of
  # the render destination object. The filter properties allow the properties of
  # the filters to be modified immediately before the filter chain is rendered.
  class MIFilterChainRender
    # The render hash that holds the configuration options for the render
    @renderHash

    # Assign the render hash to an empty hash object.
    def initialize()
      @renderHash = { }
    end

    # Add a source rectangle to the render hash
    # @param sourceRect [Hash] A hash representing a rectangle
    # @return [Hash] the render hash
    def set_sourcerectangle(sourceRect)
      @renderHash[:sourcerectangle] = sourceRect
    end

    # Add a destination rectangle to the render hash
    # @param destinationRect [Hash] A hash representing a rectangle
    # @return [Hash] the render hash
    def destinationrectangle=(destinationRect)
      @renderHash[:destinationrectangle] = destinationRect
    end

    # Set a list of filter properties to the render hash
    # @param renderFilterProperties [Array<Hash>] The filter properties.
    # @return [Hash] the render hash.
    def set_filterproperties(renderFilterProperties)
      @renderHash[:cifilterproperties] = renderFilterProperties
    end

    # Add a filter property to the list of properties in the render hash
    # @param renderFilterProperty [Hash] The property to be added to the list.
    # @return [Array] the list of properties that the property has been added to
    def add_filterproperty(renderFilterProperty)
      if @renderHash[:cifilterproperties].nil?
        @renderHash[:cifilterproperties] = [ renderFilterProperty ]
      else
        @renderHash[:cifilterproperties].push(renderFilterPropery)
      end
    end

    # Set the render filter chain variables
    # @param theVariables [Hash] The variables
    def variables=(theVariables)
      @renderHash[:variables] = theVariables
    end

    # Get the render filter chain hash
    # @return The filter chain hash.
    def get_renderfilterchainhash()
      return @renderHash
    end

    # Convert the render filter chain object to json.
    # @return [String] A string representing a json object.
    def to_json()
      return @renderHash.to_json
    end
  end

end