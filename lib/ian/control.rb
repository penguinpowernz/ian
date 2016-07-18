module Ian
  class Control
    attr_reader :path
  
    def initialize(path)
      @path = path
      
      if File.exist?(@path)
        parse
      else
        @fields = defaults
      end
    end
  
    def deps
      []
    end
  
    def []=(field, value)
      raise ArgumentError, "Invalid field: #{field}" unless defaults.keys.include?(field)
      @fields[field] = value
    end
    
    def [](field)
      @fields[field]
    end
  
    def parse
      text = File.read(@path)
      
      fields.each do |f, name|
        m = text.match(/^#{name}: (.*)$/)
        next unless m
        @fields[f] = m[1]
      end
      
      if @fields[:depends]
        @fields[:depends] = @fields[:depends].split(",").map! {|d| d.strip }
      end
      
      @feilds[:long_description] = text.scan(/^  (.*)$/)
    end
  
    def to_s
      lines = []
      lines << "Package: #{@fields[:package]}"
      lines << "Version: #{@fields[:version]}"
      lines << "Depends: #{@fields[:depends]}" if @fields[:dependencies]
      lines << "Description: #{@fields[:description]}"
      
      lines += @fields[:long_description].map do |ld|
        "  #{ld}"
      end
      
      lines.join("\n")
    end

    private

    def defaults
      {
        :package => "name",
        :version => "0.0.1",
        :dependencies => [],
        :description => "This is a description",
        :long_description => [
          "This is a longer description that can take",
          "up multiple lines"
        ]
      }
    end

    def fields
      {
        package: "Package",
        depends: "Depends",
        version: "Version",
        description: "Description"
      }
    end

  end
end
