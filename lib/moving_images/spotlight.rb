
require 'Open3'

module MovingImages
  # A collection of methods for accessing the spotlight command tools in 
  # relation to getting information about image files, and finding image files 
  # which match certain criteria.
  module SpotlightCommand

    # Get the image dimensions and return as a hash with attributes 
    # :width,:height
    # @param imageFilePath [String] Path to file to get dimensions from.
    # @return [Hash] the dimensions stored in a hash.
    def self.get_imagedimensions(imageFilePath)
      finalResult = {}
      resultStr, exitVal = Open3.capture2("mdls", "-name", "kMDItemPixelWidth",
                                 "-name", "kMDItemPixelHeight", imageFilePath)
      return {} unless exitVal.exitstatus.zero? || !resultStr.include?('null')
      resultStr.split("\n").each do |item|
        if item.include?('kMDItemPixelWidth')
          finalResult[:width] = item.partition(' = ').last.to_i # width
        else
          finalResult[:height] = item.partition(' = ').last.to_i # height
        end
      end
      finalResult
    end

    # Get the image file type and return as a string.
    # @param imageFilePath [String] Path to file to get dimensions from.
    # @return [String] the image file type.
    def self.get_imagefiletype(imageFilePath)
      resultStr, exitVal = Open3.capture2("mdls", "-name", "kMDItemContentType",
                                          imageFilePath)
      return "" unless exitVal.exitstatus.zero? || !resultStr.include?('null')
      return resultStr.split("\"")[1]
    end

    # essentially a private module method, though I've not found a easy solution 
    # to hide private methods.
    def self.make_contenttypepartofquery(fileType)
      typesHash = { :"public.jpeg" => "public.jpeg",
                  :"public.png" => "public.png",
                  :"public.tiff" => "public.tiff",
                  :"com.compuserve.gif" => "com.compuserve.gif" }

      fileType = typesHash[fileType.intern] unless fileType.nil?
      contentTypeQueryPart = if fileType.nil?
                               "kMDItemContentTypeTree == public.image"
                             else
                               "kMDItemContentType == " + fileType
                             end
      return contentTypeQueryPart
    end


    # essentially a private module method, though I've not found a nice solution
    # to hide private methods
    def self.runquerycommand(theCommand)
      theOutput = ""
      IO.popen(theCommand, encoding: 'UTF-8') { |io| theOutput = io.read }
      theOutput = theOutput.split("\n")
      return theOutput
    end

    # Find image files using spotlight which have specific pixel dimensions, and a
    # particular file type, with an option to limit the search to be within a
    # directory. To allow any image file type specify "public.image" for 
    # fileType instead of a value like "public.jpeg".
    # @param width [Fixnum] The width of the image
    # @param height [Fixnum] The height of the image
    # @param fileType [Fixnum] The image uti file type
    # @param onlyInDirPath [String] Option directory to find files within.
    # @return [Array<String>] An array of paths, one path per result.
    def self.find_imagefiles(width: 800, height: 600,
                             fileType: "public.image", onlyInDirPath: nil)
      theCommand = [ "mdfind" ]
      theCommand.push('-onlyin', onlyInDirPath) unless onlyInDirPath.nil?
      query = self.make_contenttypepartofquery(fileType) + " && "
      query += "kMDItemPixelWidth == #{width} && "
      query += "kMDItemPixelHeight == #{height}"
      self.runquerycommand(theCommand.push(query))
    end

    # Find image files with dimensions greater than the height & width specified
    # @param width [Fixnum] Find image files which are wider than width.
    # @param height [Fixnum] Find image files which are taller than height.
    # @param fileType [String] Find image files with file type fileType
    # @param onlyInDirPath [String] Option directory to find files within.
    # @return [Array<String>] A list of paths, one path per result.
    def self.find_imagefiles_largerthan(width: 800, height: 600,
                                  fileType: "public.image", onlyInDirPath: nil)
      theCommand = [ "mdfind" ]
      theCommand.push('-onlyin', onlyInDirPath) unless onlyInDirPath.nil?
      query = self.make_contenttypepartofquery(fileType) + " && "
      query += "kMDItemPixelWidth >= #{width} && "
      query += "kMDItemPixelHeight >= #{height}"
      self.runquerycommand(theCommand.push(query))
    end

    # Find image files created monthsAgo number of months ago.
    # @param monthsAgo [Fixnum] How long ago in months an image file was created
    # @param fileType [String] Find image files with type. Default is any
    # @param onlyInDirPath  [String] Option directory to find files within.
    # @return [Array<String>] A list of path, one path per result.
    def self.find_imagefilescreated(monthsAgo: 3, fileType: "public.image",
                                      onlyInDirPath: nil)
      monthsAgo = - monthsAgo
      monthsAgoP1 = monthsAgo + 1

      theCommand = [ "mdfind" ]
      theCommand.push('-onlyin', onlyInDirPath) unless onlyInDirPath.nil?

      query = self.make_contenttypepartofquery(fileType) + " && "
      query += "kMDItemContentCreationDate > $time.this_month(#{(monthsAgo)})" +
        " && kMDItemContentCreationDate < $time.this_month(#{(monthsAgoP1)}))"
      theCommand.push(query)
      return self.runquerycommand(theCommand)
    end

    # Find image files created since number of days daysAgo.
    # Unlike the months ago find files which finds files created within a month, 
    # this finds all files created since some day in the past until today using
    # spotlight.
    # @param daysAgo [Fixnum] How long ago in months an image file was created
    # @param fileType [String] Find image files with type. Default is any
    # @param onlyInDirPath  [String] Option directory to find files within
    # @return [Array<String>] A list of path, one path per result
    def self.find_imagefilescreatedsince(daysAgo: 20, fileType: nil, 
                                                        onlyInDirPath: nil)
      theCommand = [ "mdfind" ]
      theCommand.push('-onlyin', onlyInDirPath) unless onlyInDirPath.nil?
      query = self.make_contenttypepartofquery(fileType) + " && "
      query += "kMDItemContentCreationDate >= $time.today(#{(-daysAgo)})"
      theCommand.push(query)
      return self.runquerycommand(theCommand)
    end
  end
end
