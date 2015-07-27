# Copyright (c) 2015 Zukini Ltd.

module MovingImages
  # The wrapper module for all core image related classes.    
  module MICoreImage
    # The MIFilterProperty module is used for making filter properties    
    # Once a filter property is created, it will be added to a list of properties
    # which is part of the definition of a {MIFilter} in a {MIFilterChain}.
    module MIFilterProperty
      # Make an image property, with an optional value which is the source of 
      # the input image.    
      # The key will most often be "inputImage", but
      # can also have values like "backgroundImage".
      # @param key [String] The filter property key used to assign the image.
      # @param value [Hash] The object to get the image from. See {SmigIDHash}
      # @param keep_static [Bool, nil] Keep the image even if source changes.
      #   Defaults to false.
      # @return [Hash] The filter property image hash.
      def self.make_ciimageproperty(key: :inputImage, value: nil, options: nil,
                                    keep_static: nil)
        imageHash = { :cifilterkey => key, :cifiltervalueclass => :CIImage }
        unless value.nil?
          MIFilterProperty.addimagesource_tociimageproperty(imageHash, value,
            imageoptions: options)
        end
        imageHash[:cisourceimagekeepstatic] = keep_static unless keep_static.nil?
        imageHash
      end

      # Add the object to the property hash which provides the image.    
      # @param ciProperty [Hash] The filter property to be assigned the image.
      # @param imageSource [Hash] The object to get image from. See {SmigIDHash}
      # @param imageoptions [Hash] Options for obtaining image from source.
      # @return [Hash] The filter property image hash.
      def self.addimagesource_tociimageproperty(ciProperty, imageSource,
          imageoptions: nil)
        imageSource[:imageoptions] = imageoptions unless imageoptions.nil?
        ciProperty[:cifiltervalue] = imageSource
        return ciProperty
      end

      # Make a core image vector property, taking a string representation.    
      # @param key [String] The filter property to be assigned the vector.
      # @param value [String] A string representing the vector.
      # @return [Hash] The vector filter property hash.
      def self.make_civectorproperty_fromstring(key: "inputExtent",
                                                value: "[ 0 0 100 100 ]")
        return { :cifilterkey => key, :cifiltervalue => value,
                  :cifiltervalueclass => "CIVector" }
      end
  
      # Make a core image vector property without a value.    
      # @param key [String, Symbol] The filter property to be assigned the vector.
      # @return [Hash] The vector filter property hash.
      def self.make_civectorproperty(key: "inputExtent", value: nil)
        property = { :cifilterkey => key, :cifiltervalueclass => "CIVector" }
        property[:cifiltervalue] = value unless value.nil?
        property
      end
  
      # Make a core image vector property, taking an array of Floats.    
      # @param key [String] The filter property key used to assign the vector.
      # @param value [Array<Float>] 
      # @return [Hash] The vector filter property hash.
      def self.make_civectorproperty_fromarray(key: "inputCenter",
                                                    value: [50.0, 50.0])
        stringVal = "["
        value.each { |item| stringVal += " " + item.to_s }
        stringVal += " ]"
        return self.make_civectorproperty_fromstring(key: key, value: stringVal)
      end
  
      # Make a civector property from a rectangle.    
      # @param key [String, Symbol] The filter property key used to assign vector
      # @param value [Hash] A hash as created by {MIShapes.make_rectangle}
      # @return [Hash] The property hash representing the property
      def self.make_civectorproperty_fromrectangle(key: :inputExtent,
                                                   value: { })
        property = { :cifilterkey => key, :cifiltervalueclass => "CIVector" }
        property[:cifiltervalue] = { rect: value }
        property
      end
  
      # Make a civector property from a point.    
      # @param key [String, Symbol] The filter property key used to assign vector
      # @param value [Hash] A hash as created by {MIShapes.make_point}
      # @return [Hash] The property hash representing the property.
      def self.make_civectorproperty_frompoint(key: :inputCenter,
                                               value: { })
        property = { :cifilterkey => key, :cifiltervalueclass => "CIVector" }
        property[:cifiltervalue] = { point: value }
        property
      end
  
      # Make a core image color property without a value.    
      # @param key [String, Symbol] The filter property to be assigned the color
      # @param value [nil, String, Hash] If hash then {MIColor.make_rgbacolor}
      # @return [Hash] The color filter property hash
      def self.make_cicolorproperty(key: "inputColor", value: nil)
        property = { :cifilterkey => key, :cifiltervalueclass => "CIColor" }
        property[:cifiltervalue] = value unless value.nil?
        property
      end
  
      # Make a core image color property, taking a string representation of the 
      # color.    
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
        value.each do |item|
          if isFirst
            stringVal = item.to_s
            isFirst = false
          else
            stringVal = " " + item.to_s
          end
        end
        return self.make_cicolorproperty_fromstring(key: key, value: stringVal)
      end
  
      # Make a CoreImage color property, takes color hash {MIColor.make_rgbacolor}.    
      # Because the profile is specified, when the color is converted to a core 
      # image color it will be converted to a color with a profile: 
      # "kCGColorSpaceGenericRGB" before the filter property is assigned to
      # the filter.
      # @param key [String] The filter property to be assigned the color value.
      # @param value [Hash] RGB color generated using {MIColor.make_rgbacolor}
      # @return [Hash] A core image filter color property hash
      def self.make_cicolorproperty_fromhash(key: "inputColor",
              value: { :red => 1.0, :green => 1.0, :blue => 1.0, :alpha => 1.0,
                        :colorcolorprofilename => "kCGColorSpaceSRGB" })
        return { :cifilterkey => key, :cifiltervalue => value,
                    :cifiltervalueclass => "CIColor" }
      end
  
      # Make a number property.    
      # @param key [String] The filter property to be assigned the numeric value.
      # @param value [Float, String] The numeric value to be assigned.
      # @return [Hash] The core image numeric property hash.
      def self.make_cinumberproperty(key: "inputRadius", value: nil)
        return { :cifilterkey => key, :cifiltervalue => value }
      end
  
      # Make a number property with a min-max range and a default value.    
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
  
      # Assign a integer value to an already created filter property.    
      # Constrain the value to be assigned to within the min/max range if
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
  
      # Assign a float value to an already created filter property.    
      # Constrain the value to be assigned to within the min/max range if
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
  
      # Set the filter property value from the information in the options hash.    
      # Assumes that the value in the options hash is correctly formatted to
      # be assigned to filter property hash
      # @param filter_prop [Hash] The filter property for the value to be assigned
      # @param options [Hash] The options hash as generated from opts.parse.
      # @return [true, false] Whether the value was able to be assigned or not.
      def self.set_propertyvalue_fromoptions(filter_prop, options)
  #      if options[:verbose]
  #        puts JSON.pretty_generate(filter_prop)
  #      end
        value = options[filter_prop[:cifilterkey]]
        return false if value.nil?
        filter_prop[:cifiltervalue] = value
        return true
      end
  
      # Make an affine transform filter property.    
      # @param key [String] Filter property to be assigned the affine transfor
      # @param m11 [Float] The value for the m11 component of the affine transform
      # @param m12 [Float] The value for the m12 component of the affine transform
      # @param m21 [Float] The value for the m21 component of the affine transform
      # @param m22 [Float] The value for the m22 component of the affine transform
      # @param tX [Float] The value for the tX component of the affine transform
      # @param tY [Float] The value for the tY component of the affine transform
      # @return [Hash] The core image filter property representing the transform
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
                :cifiltervalueclass => "AffineTransform" }
      end
      
      # Return the class of the property value.    
      # @param property [Hash] The filter property to get the value class from
      # @return [String, Symbol] The property value class.
      def self.get_propertyvalue_class(property)
        return :NSNumber if property[:cifiltervalueclass].nil?
        return property[:cifiltervalueclass]
      end
    end
  
    # The MIFilter class.    
    # A filter is made up of a filter name which is the core image name for the
    # filter to be created, an optional name id, which is used to identify the 
    # filter so that it can be linked to from later filters in the filter chain.
    # Filters also take a list of input properties. Different filters take 
    # different inputs.
    class MIFilter
      # Initialize a filter object with the filter name and a name identifier.    
      # @param filter [String, Symbol] The core image filter name
      # @param identifier [String] The name of this filter for identification
      def initialize(filter, identifier: nil)
        @filter_hash = { cifiltername: filter }
        @filter_hash[:mifiltername] = identifier unless identifier.nil?
      end
  
      # Return the filter hash representation of the filter object
      # @return [Hash] The hash representation of the filter
      def filterhash
        @filter_hash
      end
  
      # Add a property to the filters list of input properties.    
      # @param filter_property [Hash] Representation of the filter property
      # @return void
      def add_property(filter_property)
        if @filter_hash[:cifilterproperties].nil?
          @filter_hash[:cifilterproperties] = [ filter_property ]
        else
          @filter_hash[:cifilterproperties].push(filter_property)
        end
      end
  
      # Add a list of properties to the filters list of input properties.    
      # @param filter_properties [Array<Hash>] Array of filter property hashes
      # @return void
      def add_properties(filter_properties)
        if @filter_hash[:cifilterproperties].nil?
          @filter_hash[:cifilterproperties] = filter_properties
        else
          @filter_hash[:cifilterproperties] += filter_properties
        end
      end
  
      # Remove the filter property list
      def clear_properties
        @filter_hash.delete(:cifilterproperties)
      end
  
      # Replace any previously assigned filter properties.    
      # @param filter_properties [Array<Hash>] List of filter property hashes
      # @return [Array<Hash>] The assigned properties.
      def properties=(filter_properties)
        @filter_hash[:cifilterproperties] = filter_properties
        filter_properties
      end

      # Add an image property to the list of filter properties.    
      # An image property of a CoreImage filter defines how to obtain the image
      # used as an input image for the core image filter.
      # @param propertykey [String, Symbol] The CoreImage image property key.
      #   Typical values are 'inputImage' or 'inputBackgroundImage'
      # @param image_source [Hash] Specifies the object or the image in the
      #   image collection from which to obtain the image.
      #   See {SmigIDHash.make_objectid}, {SmigIDHash.makeid_withfilternameid}
      #   or, {SmigIDHash.make_imageidentifier}
      # @param options [Hash] Options for obtaining the image from the object.
      #   Pass nil for a bitmap or window context, is optional for an image
      #   importer object which will assume the imageindex property to have
      #   a value of 0. Options is required when an image is obtained from
      #   a movie importer object, which requires the frametime property and
      #   optionally the tracks property.
      # @param keep_static [Bool, nil] Keep the image even if source changes.
      #   Defaults to false. 
      def add_image_property(propertykey, image_source: nil, options: nil,
          keep_static: nil)
        imageProperty = MIFilterProperty.make_ciimageproperty(key: propertykey,
                                                            value: image_source,
                                                          options: options,
                                                      keep_static: keep_static)
        self.add_property(imageProperty)
      end

      # Add the input image obtained from source as the filters input image.    
      # If you pass nil for image source then the property will be created but
      # the value will not be set.
      # @param image_source [Hash] Object, image id, or filter to get image from.
      # @param options [Hash] Options for obtaining the image from the object.
      # @param keep_static [Bool, nil] Keep the image even if source changes.
      #   Defaults to false.
      def add_inputimage_property(image_source, options: nil, keep_static: nil)
        self.add_image_property(:inputImage, image_source: image_source,
                                                  options: options,
                                              keep_static: keep_static)
      end
  
      # Return the property from the property list with key.    
      # @param key [String, Symbol] The key of the property to be returned
      # @return [Hash, nil] The filter property which has key.
      def get_property_withkey(key: :inputImage)
        return nil if @filter_hash[:cifilterproperties].nil?
        key_index = @filter_hash[:cifilterproperties].index do |prop|
          prop[:cifilterkey] == key
        end
        return nil if key_index.nil?
        return @filter_hash[:cifilterproperties][key_index]
      end
  
      # Return the class of the value for the property with key.
      # @param key [String, Symbol] The property key, to get property value class
      # @return [String, Symbol, nil] The class of the property value
      def get_propertyvalueclass_withkey(key: :inputImage)
        theProperty = self.get_property_withkey(key)
        return nil if theProperty.nil?
        return MIFilterProperty.get_propertyvalue_class(theProperty)
      end
  
      # Set the property value for the property with key.
      # @param key [String, Symbol] The key for the property to set the value of
      # @param value [Hash, Fixnum, Float, String] The value to be set.
      def set_propertyvalue_propertywith_key(key, value)
        theProperty = self.get_property_withkey(key: key)
        theProperty[:cifiltervalue] = value unless theProperty.nil?
      end
  
      # Get the first property in the list of properties with an unset value
      # @return [Hash, nil] The property with an unset value.
      def get_property_withunset_value()
        index = @filter_hash[:cifilterproperties].index do |prop|
          prop[:cifiltervalue].nil?
        end
        return nil if index.nil?
        @filter_hash[:cifilterproperties][index]
      end
      
      # Make a filter object with the CoreImage filter name and identifier.
      # @param filtername [String, Symbol] CoreImage name to create object from 
      # @param identifier [String, Symbol] Used to identify filter in filter chain
      # @return [nil, object with name filtername] A filter object.
      def self.make_filter_withname(filtername: :CIBoxBlur, identifier: nil)
        begin
          MIFilters.const_get(filtername).new(identifier)
        rescue RuntimeError => e
          puts "Unrecognized filter name: #{filtername}"
          nil
        end
      end
    end
  
    module MIFilters
      # The transition filter class.    
      class MITransitionFilter < MIFilter
        # Return the list of transition filters.    
        # @return [String] A space delimited string of core image transition filters
        def self.listtransitionfilters
          MIMeta.listfilters(category: CICategoryTransition)
        end
    
        # Initialize a transition filter representation.    
        # @param filter [String, Symbol] The CoreImage filter name
        # @param identifier [String] The filter name identifier
        # @param input_time [Float] The transition time. Range 0.0 .. 1.0.
        # @param input_image_source [Hash] Image source, see {SmigIDHash}
        # @param input_targetimage_source [Hash] Image source, see {SmigIDHash}
        # @return [MITransitionFilter] A transition filter object
        def initialize(filter, identifier: nil, input_time: 0,
                       input_image_source: nil, input_targetimage_source: nil)
          super(filter, identifier: identifier)
          # lets assume for now that input time is within range. 0.0 to 1.0
          timeProperty = MIFilterProperty.make_cinumberproperty(
                                                      key: :inputTime,
                                                      value: input_time)
          self.add_property(timeProperty)
          self.add_inputimage_property(input_image_source)
          imageProperty = MIFilterProperty.make_ciimageproperty(
                                key: :inputTargetImage, value: input_targetimage_source)
          self.add_property(imageProperty)
        end
      end

      # The CIAccordionFolderTransition filter.    
      class CIAccordionFoldTransition < MITransitionFilter
        # Initialize the CIAccordionFolderTransition object.    
        # @param identifier [String] The filter name identifier
        # @return [CIAccordionFoldTransition] The object
        def initialize(identifier)
          super(:CIAccordionFoldTransition, identifier: identifier)
          numberOfFolds = MIFilterProperty.make_cinumberproperty(
                                          key: :inputNumberOfFolds) # range 1..10
          self.add_property(numberOfFolds)
          foldShadowAmount = MIFilterProperty.make_cinumberproperty(
                                          key: :inputFoldShadowAmount) # range 0..1
          self.add_property(foldShadowAmount)
          bottomHeight = MIFilterProperty.make_cinumberproperty(
                                          key: :inputBottomHeight)
          self.add_property(bottomHeight)
          fail "My implementation of accordion fold transition is broken"
        end
      end
    
      # The CIBarsSwipeTransition filter.    
      class CIBarsSwipeTransition < MITransitionFilter
        # Initialize the CIBarsSwipeTransition object.    
        # @param identifier [String] The filter name identifier
        # @return [CIBarsSwipeTransition] The object
        def initialize(identifier)
          super(:CIBarsSwipeTransition, identifier: identifier)
          angle = MIFilterProperty.make_cinumberproperty(
                                          key: :inputAngle) # range 0 - 2π
          self.add_property(angle)
          width = MIFilterProperty.make_cinumberproperty(
                                          key: :inputWidth) # range 2..30
          self.add_property(width)
          barOffset = MIFilterProperty.make_cinumberproperty(
                                          key: :inputBarOffset) # range 1..100
          self.add_property(barOffset)
        end
      end
    
      # The CIRippleTransition filter.    
      class CIRippleTransition < MITransitionFilter
        # Initialize the CIBarsSwipeTransition object.    
        # @param identifier [String] The filter name identifier
        # @return [CIBarsSwipeTransition] The object
        def initialize(identifier)
          super(:CIRippleTransition, identifier: identifier)
          width = MIFilterProperty.make_cinumberproperty(key: :inputWidth) # 2..30
          self.add_property(width)
          extent = MIFilterProperty.make_civectorproperty(key: :inputExtent)
          self.add_property(extent)
          scale = MIFilterProperty.make_cinumberproperty(key: :inputScale) #-50 - 50
          self.add_property(scale)
          center = MIFilterProperty.make_civectorproperty(key: :inputCenter)
          self.add_property(center)
          shadingImage = MIFilterProperty.make_ciimageproperty(
                                          key: :inputShadingImage)
          self.add_property(shadingImage)
        end
      end
    
      # The CISwipeTransition filter.    
      class CISwipeTransition < MITransitionFilter
        # Initialize the CISwipeTransition object.    
        # @param identifier [String] The filter name identifier
        # @return [CISwipeTransition] The object
        def initialize(identifier)
          super(:CISwipeTransition, identifier: identifier)
          angle = MIFilterProperty.make_cinumberproperty(key: :inputAngle) # 0 - π
          self.add_property(angle)
          width = MIFilterProperty.make_cinumberproperty(key: :inputWidth) # 0.1-800
          self.add_property(width)
          color = MIFilterProperty.make_cicolorproperty(key: :inputColor)
          self.add_property(color)
          extent = MIFilterProperty.make_civectorproperty(key: :inputExtent)
          self.add_property(extent)
          opacity = MIFilterProperty.make_cinumberproperty(key: :inputOpacity) #0..1
          self.add_property(opacity)
        end
      end
    
      # The CICopyMachineTransition filter.    
      class CICopyMachineTransition < MITransitionFilter
        # Initialize the CICopyMachineTransition object.    
        # @param identifier [String] The filter name identifier
        # @return [CICopyMachineTransition] The object
        def initialize(identifier)
          super(:CICopyMachineTransition, identifier: identifier)
          angle = MIFilterProperty.make_cinumberproperty(key: :inputAngle) # 0 - π
          self.add_property(angle)
          width = MIFilterProperty.make_cinumberproperty(key: :inputWidth) # 0.1-800
          self.add_property(width)
          color = MIFilterProperty.make_cicolorproperty(key: :inputColor)
          self.add_property(color)
          extent = MIFilterProperty.make_civectorproperty(key: :inputExtent)
          self.add_property(extent)
          opacity = MIFilterProperty.make_cinumberproperty(key: :inputOpacity) #0..1
          self.add_property(opacity)
        end
      end
    
      # The CIDisintegrateWithMaskTransition filter.    
      class CIDisintegrateWithMaskTransition < MITransitionFilter
        # Initialize the CIDisintegrateWithMaskTransition object.    
        # @param identifier [String] The filter name identifier
        # @return [CIDisintegrateWithMaskTransition] The object
        def initialize(identifier)
          super(:CIDisintegrateWithMaskTransition, identifier: identifier)
          # density 0, 0.65, 1.0
          density = MIFilterProperty.make_cinumberproperty(key: :inputShadowDensity)
          self.add_property(density)
          # radius 0, 8, 50
          radius = MIFilterProperty.make_cinumberproperty(key: :inputShadowRadius)
          self.add_property(radius)
          offset = MIFilterProperty.make_civectorproperty(key: :inputShadowOffset)
          self.add_property(offset)
          image_mask = MIFilterProperty.make_ciimageproperty(key: :inputMaskImage)
          self.add_property(image_mask)
        end
      end
    
      # The CIFlashTransition filter.    
      class CIFlashTransition < MITransitionFilter
        # Initialize the CIFlashTransition object.    
        # @param identifier [String] The filter name identifier
        # @return [CIFlashTransition] The object
        def initialize(identifier)
          super(:CIFlashTransition, identifier: identifier)
          # striation strength 0, 0.5, 3.0
          strength = MIFilterProperty.make_cinumberproperty(
                                                    key: :inputStriationStrength)
          self.add_property(strength)
          # fade threshold 0, 0.85, 1.0
          fade = MIFilterProperty.make_cinumberproperty(key: :inputFadeThreshold)
          self.add_property(fade)
          # contrast 0.0, 1.375, 5.0
          contrast = MIFilterProperty.make_cinumberproperty(
                                                      key: :inputStriationContrast)
          self.add_property(contrast)
          color = MIFilterProperty.make_cicolorproperty(key: :inputColor)
          self.add_property(color)
          extent = MIFilterProperty.make_civectorproperty(key: :inputExtent)
          self.add_property(extent)
          center = MIFilterProperty.make_civectorproperty(key: :inputCenter)
          self.add_property(center)
        end
      end
    
      # The CIDissolveTransition filter.    
      class CIDissolveTransition < MITransitionFilter
        # Initialize the CIFlashTransition object.    
        # @param identifier [String] The filter name identifier
        # @return [CIDissolveTransition] The object
        def initialize(identifier)
          super(:CIDissolveTransition, identifier: identifier)
        end
      end
    
      # The CIModTransition filter.    
      class CIModTransition < MITransitionFilter
        # Initialize the CIFlashTransition object.    
        # @param identifier [String] The filter name identifier
        # @return [CIModTransition] The object
        def initialize(identifier)
          super(:CIModTransition, identifier: identifier)
          # angle -2π, 0, 2π
          angle = MIFilterProperty.make_cinumberproperty(key: :inputAngle)
          self.add_property(angle)
          # radius 1, 150, 200
          radius = MIFilterProperty.make_cinumberproperty(key: :inputRadius)
          self.add_property(radius)
          # compression 100, 300, 800
          compression = MIFilterProperty.make_cinumberproperty(
                                                            key: :inputCompression)
          self.add_property(compression)
          center = MIFilterProperty.make_civectorproperty(key: :inputCenter)
          self.add_property(center)
        end
      end
    
      # The CIPageCurlTransition filter.    
      class CIPageCurlTransition < MITransitionFilter
        # Initialize the CIPageCurlTransition object.    
        # @param identifier [String] The filter name identifier
        # @return [CIPageCurlTransition] The object
        def initialize(identifier)
          super(:CIPageCurlTransition, identifier: identifier)
          # angle -π, 0, π
          angle = MIFilterProperty.make_cinumberproperty(key: :inputAngle)
          self.add_property(angle)
          extent = MIFilterProperty.make_civectorproperty(key: :inputExtent)
          self.add_property(extent)
          shadingImage = MIFilterProperty.make_ciimageproperty(
                                                          key: :inputShadingImage)
          self.add_property(shadingImage)
          # radius 0.01, 100, 400
          radius = MIFilterProperty.make_cinumberproperty(key: :inputRadius)
          self.add_property(radius)
          backsideImage = MIFilterProperty.make_ciimageproperty(
                                                        key: :inputBacksideImage)
          self.add_property(backsideImage)
        end
      end
    
      # The CIPageCurlTransition filter.    
      class CIPageCurlWithShadowTransition < MITransitionFilter
        # Initialize the CIPageCurlWithShadowTransition object.    
        # @param identifier [String] The filter name identifier
        # @return [CIPageCurlWithShadowTransition] The object
        def initialize(identifier)
          super(:CIPageCurlWithShadowTransition, identifier: identifier)
          # angle -π, 0, π
          angle = MIFilterProperty.make_cinumberproperty(key: :inputAngle)
          self.add_property(angle)
          extent = MIFilterProperty.make_civectorproperty(key: :inputExtent)
          self.add_property(extent)
          # radius 0.01, 100, 400
          radius = MIFilterProperty.make_cinumberproperty(key: :inputRadius)
          self.add_property(radius)
          # shadow amount 0.0, 0.7, 1.0
          shadowAmount = MIFilterProperty.make_cinumberproperty(
                                                        key: :inputShadowAmount)
          self.add_property(shadowAmount)
          # shadow size 0.0, 0.5, 1.0
          shadowSize = MIFilterProperty.make_cinumberproperty(
                                                        key: :inputShadowSize)
          self.add_property(shadowSize)
          backsideImage = MIFilterProperty.make_ciimageproperty(
                                                        key: :inputBacksideImage)
          self.add_property(backsideImage)
        end
      end
    end
  
    # The filter chain, representing a list of connected filters.    
    # A filter chain can be as short as a single filter, or lengthy containing
    # multiple branches which ultimately end at the last filter in the filter
    # chain which generates the output image. The filter chain object also 
    # specifies the render destination, which is where the last filter in the
    # filter chain renders to, the software render property specifies whether
    # the filter chain is rendered in software rather than on the GPU, and the
    # use_srgprofile property specifies whether the filter chain should work in
    # the srgb color space instead of the generic linear color space which is
    # its default.
    class MIFilterChain
  
      # Initialize the filter chain object.    
      # @param renderDestination [Hash] Destination object {SmigIDHash}
      # @param filterList [Array<Hash>] optional list of filters in filter chain
      # @return [MIFilterChain]
      def initialize(renderDestination, filterList: nil)
        # The hash containing all the properties of the render filter chain.
        @filterChainHash = { :cirenderdestination => renderDestination }
        @filterChainHash[:cifilterlist] = filterList unless filterList.nil?
      end
  
      # Add a filter definition to the filter chain.    
      # @param filter [Hash, #filterhash] Filter to add to the filter chain
      # @return [Hash] The filter chain hash
      def add_filter(filter)
        filter = filter.filterhash if filter.respond_to? "filterhash"
        if @filterChainHash[:cifilterlist].nil?
          @filterChainHash[:cifilterlist] = [ filter ]
        else
          @filterChainHash[:cifilterlist].push(filter)
        end
        return @filterChainHash
      end
  
      # Specify whether the filter chain should be rendered in software.    
      # @param softwareRender [bool] Should filter chain be rendered in software
      # @return [Hash] The filter chain hash
      def softwarerender=(softwareRender)
        @filterChainHash[:softwarerender] = softwareRender
        @filterChainHash
      end
  
      # Should the filter chain be rendered in the sRGB color space.    
      # By default the filter chain is rendered in the generic linear rgb color
      # space. By setting this option, your specifying that the filter chain 
      # should be rendered in the sRGB color space instead.
      # @param useSRGBProfile [bool] Should filter chain be rendered in sRGB
      # @return [Hash] The filter chain hash
      def use_srgbprofile=(useSRGBProfile)
        @filterChainHash[:use_srgbcolorspace] = useSRGBProfile
        @filterChainHash
      end
  
      # Get the filter chain hash.    
      # @return [Hash] The filter chain hash
      def filterchainhash
        return @filterChainHash
      end
  
      # Convert the filter chain hash to json and return the json string.    
      # @return [String] The filter chain hash converted to a json string
      #def to_json
      #  return @filterChainHash.to_json
      #end
    end
  
    # Create a filter chain render property.    
    # When rendering a filter chain, an optional list of render properties can
    # be provided that make it possible to modify the filter properties at
    # render time. The MIFilterRenderProperty module provides methods to create
    # render properties that are associated with filters.
    module MIFilterRenderProperty
      # Create a filter property with a name identifier.    
      # @param key [String, Symbol] the filter property to be set.
      # @param value [String, Float, Fixnum, Hash] The value the filter property
      #   will be assigned to. CIVector and CIColor filter class can both have
      #   a hash as their value.
      # @param filtername_id [String] Identifier for filter in filter chain.
      # @param value_class [String, nil] The CoreImage class name to assign
      # @return [Hash] The created render property.
      def self.make_renderproperty_withfilternameid(key: :inputLevel,
                                                    value: 10.0,
                                                    filtername_id: "blurfilter",
                                                    value_class: nil)
        renderProp =  { :cifilterkey => key, :cifiltervalue => value,
                        :mifiltername => filtername_id }
        renderProp[:cifiltervalueclass] = value_class unless value_class.nil?
        return renderProp
      end
  
      # Create a filter point vector filter property with a filter name id.
      # @param key [String, Symbol] the filter property to be set.
      # @param point [Hash] A point hash to make the render property from.
      # @param filtername_id [String] Identifier for filter in filter chain.
      # @return [Hash] The created render property.
      def self.make_renderproperty_pointvector_withfilternamid(key: :inputCenter,
                                                             point: nil,
                                                     filtername_id: nil)
        pointHash = { point: point }
        return self.make_renderproperty_withfilternameid(key: key,
                                                       value: pointHash,
                                               filtername_id: filtername_id,
                                                 value_class: :CIVector)
      end

      # Create a filter rectangle property with a filter name id.
      # @param key [String, Symbol] the filter property to be set.
      # @param rectangle [Hash] A Rectangle to make the render property from.
      # @param filtername_id [String] Identifier for filter in filter chain.
      # @return [Hash] The created render property.
      def self.make_renderproperty_rectangle_withfilternamid(key: :inputCenter,
                                                       rectangle: nil,
                                                   filtername_id: nil)
        rectHash = { rect: rectangle }
        return self.make_renderproperty_withfilternameid(key: key,
                                                       value: rectHash,
                                               filtername_id: filtername_id,
                                                 value_class: :CIVector)
      end

      # Create a filter property with a filter index.    
      # @param key [String] the filter property to be set.
      # @param value [String, Float, Fixnum, Hash] The value the filter property
      #   will be assigned to. CIVector and CIColor filter class can both have
      #   a hash as their value.
      # @param filter_index [Fixnum] The filter index in the filter chain.
      # @param value_class [String, nil] The CoreImage class name to assign
      # @return [Hash] The created render property.
      def self.make_renderproperty_withfilterindex(key: :inputRadius,
                                                 value: 100.0,
                                          filter_index: 1,
                                           value_class: nil)
        renderProp =  { :cifilterkey => key, :cifiltervalue => value,
                        :cifilterindex => filter_index }
        renderProp[:cifiltervalueclass] = value_class unless value_class.nil?
        return renderProp
      end

      # Create a filter point vector filter property with a filter index.
      # @param key [String, Symbol] the filter property to be set.
      # @param point [Hash] A point hash to make the render property from.
      # @param filter_index [Fixnum] The filter index in the filter chain.
      # @return [Hash] The created render property.
      def self.make_renderproperty_pointvector_withfilterindex(key: :inputCenter,
                                                             point: nil,
                                                      filter_index: 1)
        pointHash = { point: point }
        return self.make_renderproperty_withfilterindex(key: key,
                                                      value: pointHash,
                                               filter_index: filter_index,
                                                value_class: :CIVector)
      end

      # Create a filter rectangle property with a filter index.
      # @param key [String, Symbol] the filter property to be set.
      # @param rectangle [Hash] A Rectangle to make the render property from.
      # @param filter_index [Fixnum] The filter index in the filter chain.
      # @return [Hash] The created render property.
      def self.make_renderproperty_rectangle_withfilterindex(key: :inputCenter,
                                                       rectangle: nil,
                                                    filter_index: nil)
        rectHash = { rect: rectangle }
        return self.make_renderproperty_withfilternameid(key: key,
                                                       value: rectHash,
                                                filter_index: filter_index,
                                                 value_class: :CIVector)
      end


      # Make a keep image, image filter chain render property.    
      # If keep_static is true then once the input image for the filter is
      # obtained for the first time, then that image will not be replaced even
      # if the source providing the image has changed. False which is the
      # default means that if the source image has changed then a new image
      # will be requested when the filter chain renders. This changes the
      # behaviour for any future filter chain renders until next time the
      # keep image property is changed.    
      # One of filtername_id or filter_index needs to be set for the filter
      # to have a property modified to be identified.
      # @param key [String, Symbol] The image filter property to be modified
      # @param filtername_id [String, nil] The name identifier of the filter
      # @param filter_index [Fixnum] The index into the filter chain.
      # @param keep_static [bool] The 
      def self.make_renderproperty_keepimage_static(key: :inputImage,
                                                    filtername_id: nil,
                                                    filter_index: nil,
                                                    keep_static: false)
        render_prop = { cifilterkey: key,
                        cisourceimagekeepstatic: keep_static }
        render_prop[:cifilterindex] = filter_index unless filter_index.nil?
        render_prop[:mifiltername] = filtername_id unless filtername_id.nil?
        render_prop
      end
  
      # Make a force the image to be updated no matter what property.    
      # When this property is added to the list of render properties, then
      # the image it refers to will be updated before the filter chain renders.
      # 
      # One of filtername_id or filter_index needs to be set for the filter
      # to have a property modified to be identified.
      # @param key [String, Symbol] The image filter property to be modified
      # @param filtername_id [String, nil] The name identifier of the filter
      # @param filter_index [Fixnum] The index into the filter chain.
      def self.make_renderproperty_updateimage_now(key: :inputImage,
                                                   filtername_id: nil,
                                                   filter_index: nil)
        render_prop = { cifilterkey: key,
                        cisourceimageforceupdate: true }
        render_prop[:cifilterindex] = filter_index unless filter_index.nil?
        render_prop[:mifiltername] = filtername_id unless filtername_id.nil?
        render_prop
      end
    end
  
    # Render the filter chain object.    
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
  
      # Assign the render hash to an empty hash object.    
      def initialize()
        # The render hash that holds the configuration options for the render
        @renderHash = {}
      end
  
      # Add a source rectangle to the render hash.    
      # @param sourceRect [Hash] A hash representing a rectangle
      # @return [Hash] the render hash
      def sourcerectangle=(sourceRect)
        @renderHash[:sourcerectangle] = sourceRect
      end
  
      # Add a destination rectangle to the render hash.    
      # @param destinationRect [Hash] A hash representing a rectangle
      # @return [Hash] the render hash
      def destinationrectangle=(destinationRect)
        @renderHash[:destinationrectangle] = destinationRect
      end
  
      # Set a list of filter properties to the render hash.    
      # @param renderFilterProperties [Array<Hash>] The filter properties.
      # @return [Hash] the render hash.
      def filterproperties=(renderFilterProperties)
        @renderHash[:cifilterproperties] = renderFilterProperties
      end
  
      # Add a filter property to the list of properties in the render hash.    
      # @param renderFilterProperty [Hash] The property to be added to the list.
      # @return [Array] the list of properties that the property has been added to
      def add_filterproperty(renderFilterProperty)
        if @renderHash[:cifilterproperties].nil?
          @renderHash[:cifilterproperties] = [ renderFilterProperty ]
        else
          @renderHash[:cifilterproperties].push(renderFilterProperty)
        end
      end

      # Get the render filter chain hash
      # @return The filter chain hash.
      def renderfilterchainhash
        return @renderHash
      end
  
      # Convert the render filter chain object to json.    
      # @return [String] A string representing a json object
      def to_json()
        return @renderHash.to_json
      end
    end
  end
end
