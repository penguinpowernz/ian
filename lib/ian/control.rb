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
      
      @fields = {}
      
      fields.each do |f, name|
        m = text.match(/^#{name}: (.*)$/)
        next unless m
        @fields[f] = m[1]
      end
      
      if @fields[:depends]
        @fields[:depends] = @fields[:depends].split(",").map! {|d| d.strip }
      end
      
      @fields[:long_description] = text.scan(/^  (.*)$/).flatten
    end
  
    def to_s
      lines = []
      
      [:package, :version, :section, :priority, :arch, :essential, :size, :maintainer, :homepage].each do |key|
        lines << "#{fields[key]}: #{@fields[key]}"
      end
      
      if @fields[:depends] and @fields[:depends].any?
        lines << "Depends: #{@fields[:depends].join(", ")}"
      end
      
      lines << "Description: #{@fields[:description]}"
      
      lines += @fields[:long_description].map do |ld|
        "  #{ld}"
      end
      
      lines.join("\n")
    end

    def save
      File.write(@path, to_s)
    end

    # TODO: move this out of here
    def guess_maintainer
      text = File.read("#{ENV['HOME']}/.gitconfig")
      name = text.match(/name = (.*)$/)[1]
      email = text.match(/email = (.*)$/)[1]
      
      "#{name} <#{email}>"
    rescue
      return ""
    end

    def defaults
      {
        package:          "name",
        priority:         "optional",
        section:          "misc",
        essential:        "no",
        size:             0,
        maintainer:       guess_maintainer,
        homepage:         "http://example.com",
        arch:             "all",
        version:          "0.0.1",
        depends:          [],
        description:      "This is a description",
        long_description: [
          "This is a longer description that can take",
          "up multiple lines"
        ]
      }
    end

    def fields
      {
        package:     "Package",
        depends:     "Depends",
        version:     "Version",
        priority:    "Priority",
        section:     "Section",
        essential:   "Essential",
        size:        "Installed-Size",
        maintainer:  "Maintainer",
        homepage:    "Homepage",
        arch:        "Architecture",
        description: "Description"
      }
    end

  end
end
