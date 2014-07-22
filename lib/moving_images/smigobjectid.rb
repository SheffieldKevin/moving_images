
module MovingImages
  # == Making Ruby hashes that identify MovingImage's objects and filters    
  # The three methods, makeid_withobjectreference, makeid_withobjectypeandname,
  # & makeid_withfilternameid create a ruby hash that identifies a base object.
  # The hash objects are used for identifying an object for when we want to
  # send messages to the object via methods, or when the object is a source for
  # an image that can be used for drawing into a context, adding to an image 
  # exporter object or as an input image for a filter in a filter chain. Since
  # a filter's output image in a filter chain can be an input image for another
  # filter in the same filter chain the two methods makeid_withfilternameid, and
  # makeid_withfilterindex allow a filter to be identified so that it's output
  # image can be used as an input image for another filter in the same filter
  # filter chain.
  module SmigIDHash
    # Make an object identifier taking an object type and a name
    # @param type [String, Symbol] The type of object to refer to
    # @param name [String] The name of the object to refer to.
    # @return [Hash] A ruby hash identifying a MovingImages object.
    def self.makeid_withobjecttypeandname(type, name)
      return { :objecttype => type, :objectname => name }
    end

    # Makes an object identifier using named paramters.
    # Since there is a preferred order to identify objects, this method tries to
    # create an object identifier in the preferred order based on which named
    # parameters have been assigned values that are not nil.
    # @param objectreference [Fixnum, #to_i] Reference returned when created
    # @param objecttype [String, Symbol] One half of a pair to identify object
    # @param objectname [String] Paired with objecttype for referencing object
    # @param objectindex [Fixnum] Paired with objecttype for referencing object
    # @return [Hash] An object identifier
    def self.make_objectid(objectreference: nil, objecttype: nil,
                           objectname: nil, objectindex: nil)
      return { :objectreference => objectreference } unless objectreference.nil?
      return nil if objecttype.nil?
      return { :objecttype => objecttype,
                              :objectname => objectname } unless objectname.nil?
      return { :objecttype => objecttype,
                          :objectindex => objectindex } unless objectindex.nil?
      return nil
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
  end
end
