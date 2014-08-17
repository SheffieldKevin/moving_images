
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

    # Find image files with optional file type in an optional directory.    
    # If no file type is specified then images belonging to all file types will
    # be returned.
    # @param filetype [String, Symbol, nil] The image file type
    # @param onlyin [String, nil] Path to directory to find files in
    # @return [Array<String>] An array of paths to image files
    def self.find_imagefiles(filetype: nil, onlyin: nil)
      the_command = [ "mdfind" ]
      unless onlyin.nil?
        onlyin = File.expand_path(onlyin)
        the_command.push('-onlyin', onlyin)
      end
      the_command.push(self.make_contenttypepartofquery(filetype))
      self.runquerycommand(the_command)
    end

    # Collect images files and organize into list of image with same dimensions.    
    # If no file type is specified then images belonging to all file types will
    # be returned.
    # @param filetype [String, Symbol, nil] The image file type
    # @param onlyin [String, nil] Path to directory to find files in
    # @return [Array<Hash>] Array of hashes with keys: :width, :height, :files
    def self.collect_imagefiles_bydimension(filetype: nil, onlyin: nil)
      start_time = Time.now
      the_files = self.find_imagefiles(filetype: filetype, onlyin: onlyin)
      collected_lists = []
      the_files.each do |image_file|
        dimensions = self.get_imagedimensions(image_file)
        found_list = nil
        collected_lists.each do |file_list|
          if file_list[:width].eql?(dimensions[:width]) &&
                                  file_list[:height].eql?(dimensions[:height])
              found_list = file_list
              break
          end
        end
        if found_list.nil?
          new_list = { files: [ image_file ],
                       width: dimensions[:width],
                      height: dimensions[:height] }
          collected_lists.push(new_list)
        else
          found_list[:files].push(image_file)
        end
      end
      puts "Time to process: #{Time.now - start_time}"
      collected_lists
    end

    # Print information about the image file collections.    
    # @param collected_images [Array<Hash>] list of list of images by dimensions
    # @return nil
    def self.print_infoabout_collectedimages(collected_images)
      puts "Number of collections: #{collected_images.length}"
      collected_images.each do |collection|
        puts "Width: #{collection[:width]} height: #{collection[:height]} "\
             "number of images: #{collection[:files].length}"
      end
      nil
    end

    # Get the list of images from the collection which have dimensions.    
    # @param collected_images [Hash] Returned collect_imagefiles_bydimension
    # @param dimensions [Hash] The dimension to find the list of from collection
    # @return [Hash] A hash with keys: :width :height and :files
    def self.get_imagefilelist_fromcollection(collected_images,
                                              dimensions: {} )
      collected_images.each do |image_list|
        if image_list[:width].eql?(dimensions[:width]) &&
                                  image_list[:height].eql?(dimensions[:height])
          return image_list
        end
      end
      return nil
    end

    # Find image files using spotlight which have specific pixel dimensions, and 
    # a particular file type, with an option to limit the search to be within a
    # directory. To allow any image file type specify "public.image" for 
    # filetype instead of a value like "public.jpeg". The returned hash contains
    # three attributes, a :width and :height attribute plus a :files attribute. 
    # The files attribute value is an array of file paths.
    # @param width [Fixnum] The width of the image
    # @param height [Fixnum] The height of the image
    # @param filetype [String, Symbol] The image uti file type
    # @param onlyin [nil, String] Option directory to find files within.
    # @return [Hash] With keys :width, :height, :files.
    def self.find_imagefiles_withdimensions(width: 800, height: 600,
                             filetype: "public.image", onlyin: nil)
      theCommand = [ "mdfind" ]
      theCommand.push('-onlyin', onlyin) unless onlyin.nil?
      query = self.make_contenttypepartofquery(filetype) + " && "
      query += "kMDItemPixelWidth == #{width} && "
      query += "kMDItemPixelHeight == #{height}"
      file_list = self.runquerycommand(theCommand.push(query))
      return { width: width, height: height, files: file_list }
    end

    # Find image files with dimensions greater than the height & width specified
    # @param width [Fixnum] Find image files which are wider than width.
    # @param height [Fixnum] Find image files which are taller than height.
    # @param fileType [String] Find image files with file type fileType
    # @param onlyin_dirpath [String] Option directory to find files within.
    # @return [Array<String>] A list of paths, one path per result.
    def self.find_imagefiles_largerthan(width: 800, height: 600,
                                  filetype: "public.image", onlyin: nil)
      theCommand = [ "mdfind" ]
      theCommand.push('-onlyin', onlyin) unless onlyin.nil?
      query = self.make_contenttypepartofquery(filetype) + " && "
      query += "kMDItemPixelWidth >= #{width} && "
      query += "kMDItemPixelHeight >= #{height}"
      self.runquerycommand(theCommand.push(query))
    end

    # Find image files created monthsAgo number of months ago.    
    # @param months_ago [Fixnum] How long ago (months) an image file was created
    # @param fileType [String] Find image files with type. Default is any
    # @param onlyin [String] Option directory to find files within.
    # @return [Array<String>] A list of path, one path per result.
    def self.find_imagefilescreated(months_ago: 3, filetype: "public.image",
                                      onlyin: nil)
      months_ago = - months_ago
      monthsAgoP1 = monthsAgo + 1

      the_command = [ "mdfind" ]
      the_command.push('-onlyin', onlyin) unless onlyin.nil?

      query = self.make_contenttypepartofquery(filetype) + " && "
      query += "kMDItemContentCreationDate > $time.this_month(#{(months_ago)})"+
        " && kMDItemContentCreationDate < $time.this_month(#{(monthsAgoP1)}))"
      the_command.push(query)
      return self.runquerycommand(the_command)
    end

    # Find image files created since number of days days_ago.    
    # Unlike the months ago find files which finds files created within a month, 
    # this finds all files created since some day in the past until today using
    # spotlight.
    # @param days_ago [Fixnum] How long ago in months an image file was created
    # @param filetype [String] Find image files with type. Default is any
    # @param onlyin  [String] Option directory to find files within
    # @return [Array<String>] A list of path, one path per result
    def self.find_imagefilescreatedsince(days_ago: 20, filetype: nil,
                                                                  onlyin: nil)
      theCommand = [ "mdfind" ]
      theCommand.push('-onlyin', onlyin) unless onlyin.nil?
      query = self.make_contenttypepartofquery(filetype) + " && "
      query += "kMDItemContentCreationDate >= $time.today(#{(-days_ago)})"
      theCommand.push(query)
      return self.runquerycommand(theCommand)
    end
  end
end
