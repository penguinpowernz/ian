require 'ian/utils'

module Ian
  class ValidationError < StandardError; end

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

    def delete(field)
      field.to_sym if field.is_a? String
      valid_field!(field)
      raise ArgumentError, "Cannot remove mandatory field #{field.to_s}" if mandatory_fields.include?(field)
      @fields.delete(field)
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
    # raises Ian::ValidationError
    def save
      valid!
      File.write(@path, to_s)
    end

    # default values for a new control file
    def defaults
      {
        package:          "name",
        priority:         "optional",
        section:          "misc",
        essential:        "no",
        size:             0,
        maintainer:       Utils.guess_maintainer,   # TODO: pass the maintainer in somehow
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

    # return the mandatory fields that are missing from the control file
    def missing_mandatory_fields
      mandatory_fields.map do |f|
        return f unless @fields.keys.include?(f)
      end
    end

    # an array of mandatory fields for a control file
    def mandatory_fields
      [:package, :version, :architecture, :maintainer, :desc, :long_desc]
    end

    # checks if the control file is valid
    def valid?
      missing_mandatory_fields.any?
    end

    def valid!
      raise ValidationError, "Missing mandatory control fields: #{missing_mandatory_fields.join(",")}" unless valid?
    end

    def valid_field?(key)
      fields.include? key
    end

    def valid_field!(key)
      raise ArgumentError, "Invalid field: #{key}" unless valid_field?(key)
    end
  end
end
