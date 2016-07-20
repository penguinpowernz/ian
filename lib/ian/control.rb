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

    # allow setting fields directly
    def []=(field, value)
      raise ArgumentError, "Invalid field: #{field}" unless defaults.keys.include?(field)
      @fields[field] = value
    end

    # allow reading fields directly
    def [](field)
      @fields[field]
    end

    # parse this control file into the fields hash
    def parse
      text = File.read(@path)

      @fields = {}

      fields.each do |f, name|
        m = text.match(/^#{name}: (.*)$/)
        next unless m
        @fields[f] = m[1]
      end

      # for the relations fields, split the string out into an array
      relationship_fields.each do |key|
        next unless @fields[key]
        @fields[key] = @fields[key].split(",").map! {|d| d.strip }
      end

      @fields[:long_desc] = text.scan(/^  (.*)$/).flatten
    end

    # update a bunch of fields
    def update(hash)
      hash.each do |k, v|
        if fields.keys.include?(k) and v
          @fields[k] = v
        end
      end
    end

    # output the control file as a string
    def to_s
      lines = []

      [:package, :version, :section, :priority, :arch, :essential, :size, :maintainer, :homepage].each do |key|
        lines << "#{fields[key]}: #{@fields[key]}"
      end

      # build the relationship fields that have been exploded into an array
      relationship_fields.each do |key|
        next unless @fields[key] and @fields[key].any?
        lines << "%s: %s" % [ fields[key], @fields[key].join(", ") ]
      end

      lines << "Description: #{@fields[:desc]}"

      lines += @fields[:long_desc].map do |ld|
        "  #{ld}"
      end

      lines << "" # blank line as per debian control spec
      lines.join("\n")
    end

    # save the control file to disk
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

    # default values for a new control file
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
        replaces:         [],
        conflicts:        [],
        breaks:           [],
        recommends:       [],
        suggests:         [],
        enhances:         [],
        predepends:       [],
        depends:          [],
        desc:            "This is a description",
        long_desc:       [
          "This is a longer description that can take",
          "up multiple lines"
        ]
      }
    end

    # a map of field symbols to field names
    def fields
      {
        package:     "Package",
        depends:     "Depends",
        replaces:    "Replaces",
        breaks:      "Breaks",
        conflicts:   "Conflicts",
        recommends:  "Recommends",
        suggests:    "Suggests",
        enhances:    "Enhances",
        predepends:  "Pre-Depends",
        version:     "Version",
        priority:    "Priority",
        section:     "Section",
        essential:   "Essential",
        size:        "Installed-Size",
        maintainer:  "Maintainer",
        homepage:    "Homepage",
        arch:        "Architecture",
        desc:        "Description"
      }
    end

    def relationship_fields
      [:replaces :conflicts :recommends :suggests :enhances :predepends :depends, :breaks]
    end

  end
end
