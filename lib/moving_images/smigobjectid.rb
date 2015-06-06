# Copyright (c) 2015 Zukini Ltd.

module MovingImages
  # Making Ruby hashes that identify MovingImage's objects and filters.    
  # The method makeid_withobjectreference creates an object identifier which
  # we can use to refer to the object with. Since the object reference is the
  # most efficient way to refer to an object it is the preferred way and so
  # it is the first method checked for when creating the object identifier.
  # The methods, makeid_withobjectypeandname, & makeid_withfilternameid
  # create a ruby hash that identifies a filter in a filter chain.
  # The base object hashes are used for identifying an object for when we want to
  # send messages to the object via methods, or when the object is a source for
  # an image that can be used for drawing into a context, adding to an image 
  # exporter object or as an input image for a filter in a filter chain. Since
  # a filter's output image in a filter chain can be an input image for another
  # filter in the same filter chain the two methods makeid_withfilternameid, and
  # makeid_withfilterindex allow a filter to be identified so that it's output
  # image can be used as an input image for another filter in the same filter
  # filter chain.
  module SmigIDHash
    # Makes an object identifier using named paramters.    
    # Since there is a preferred order to identify objects, this method tries to
    # create an object identifier in the preferred order based on which named
    # parameters have been assigned values that are not nil. If a required
    # combination of parameters are not supplied it will throw.
    # @param objectreference [Fixnum, #to_i, nil] Reference returned when object
    #   was created
    # @param objecttype [String, Symbol] One half of a pair to identify object.
    #   If objecttype is defined then one of objectname, objectindex is required
    # @param objectname [String] Paired with objecttype for referencing object
    # @param objectindex [Fixnum, nil] Paired with objecttype for
    #   referencing the object
    # @return [Hash] An object identifier
    def self.make_objectid(objectreference: nil, objecttype: nil,
                           objectname: nil, objectindex: nil)
      objectid = {}
      
      unless objectreference.nil?
        objectid[:objectreference] = objectreference
        return objectid
      end

      fail "objecttype and objectreference both nil" if objecttype.nil?

      objectid[:objecttype] = objecttype
      unless objectname.nil?
        objectid[:objectname] = objectname
        return objectid
      end

      fail "objectname and objectindex both nil" if objectindex.nil?
      objectid[:objectindex] = objectindex
      objectid
    end

    # Make a filter identifier for a filter in a filter chain.    
    # @param filtername_id [String] The name of the filter in the filter chain.
    # @return [Hash] A ruby hash identifying a filter in a filter chain.
    def self.makeid_withfilternameid(filtername_id)
      return { :mifiltername => filtername_id }
    end

    # Make a filter identifier for a filter in a filter chain.    
    # @param filterIndex [Fixnum] The index of the filter in the filter chain.
    # @return [Hash] A ruby hash identifying a filter in a filter chain.
    def self.makeid_withfilterindex(filterIndex)
      return { :cifilterindex => filterIndex.to_i }
    end

    # Make an image identifier of an image in the collection as input for a filter.
    # @param identifier [String] The identifier for the image in the collection.
    def self.make_imageidentifier(identifier)
      return { :imageidentifier => identifier }
    end
  end
end
