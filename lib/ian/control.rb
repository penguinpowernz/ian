require 'ian/utils'

module Ian
  class ValidationError < StandardError; end

  class Control
    def initialize(**fields)
      @fields = fields
    end

    # allow setting fields directly
    def []=(field, value)
      valid_field!(field)
      @fields[field] = value
    end

    # allow reading fields directly
    def [](field)
      @fields[field]
    end

    def pkgname
      parts = [
        @fields[:package],
        @fields[:version],
        @fields[:arch]
      ]

      "%s_%s_%s" % parts
    end

    # deletes a field from the hash
    def delete(field)
      field.to_sym if field.is_a? String
      valid_field!(field)
      raise ArgumentError, "Cannot remove mandatory field #{field.to_s}" if mandatory_fields.include?(field)
      @fields.delete(field)
    end

    # update a bunch of fields at a time
    def update(hash)
      hash.each do |key, value|
        valid_field!(key)
        raise ArgumentError, "Value for #{key} was empty" if value.nil? or value == ""

        if self.class.relationship_fields.include?(key)
          @fields[key] = value.split(",").map {|d| d.strip }
        else
          @fields[key] = value
        end
      end
    end

    # output the control file as a string
    def to_s
      lines = []

      # build the standard fields
      [:package, :version, :section, :priority, :arch, :essential, :size, :maintainer, :homepage].each do |key|
        lines << "#{fields[key]}: #{@fields[key]}"
      end

      # build the relationship fields that have been exploded into an array
      self.class.relationship_fields.each do |key|
        next unless @fields[key] and @fields[key].any?
        lines << "%s: %s" % [ self.class.fields[key], @fields[key].join(", ") ]
      end

      lines << "Description: #{@fields[:desc]}"

      # build the long description with the double space at the start for each line
      lines += @fields[:long_desc].map do |ld|
        "  #{ld}"
      end

      lines << "" # blank line as per debian control spec
      lines.join("\n")
    end

    # save the control file to disk
    # raises Ian::ValidationError
    def self.save(ctrl, path)
      ctrl.valid!
      File.write(path, ctrl.to_s)
    end

    # default values for a new control file
    def self.defaults
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
    def self.fields
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
        desc:        "Description",
        long_desc:   "  "
      }
    end

    def fields; self.class.fields; end

    def self.relationship_fields
      [:replaces, :conflicts, :recommends, :suggests, :enhances, :predepends, :depends, :breaks]
    end

    # return the mandatory fields that are missing from the control file
    def missing_mandatory_fields
      mandatory_fields.map do |f|
        return f unless @fields.keys.include?(f)
      end.reject {|f| f.nil? }
    end

    # an array of mandatory fields for a control file
    def mandatory_fields
      [:package, :version, :arch, :maintainer, :desc, :long_desc]
    end

    # checks if the control file is valid
    def valid?
      missing_mandatory_fields.empty?
    end

    def valid!
      raise ValidationError, "Missing mandatory control fields: #{missing_mandatory_fields.join(",")}" unless valid?
    end

    def valid_field?(key)
      self.class.fields.keys.include? key
    end

    def valid_field!(key)
      raise ArgumentError, "Invalid field: #{key}" unless valid_field?(key)
    end

    def self.load_file(path)
      self.new(self.parse(File.read(path)))
    end

    # parse this control file into the fields hash
    def self.parse(text)
      fields = {}

      self.fields.each do |f, name|
        m = text.match(/^#{name}: (.*)$/)
        next unless m
        fields[f] = m[1]
      end

      # for the relations fields, split the string out into an array
      self.relationship_fields.each do |key|
        next unless fields[key]
        fields[key] = fields[key].split(",").map! {|d| d.strip }
      end

      fields[:long_desc] = text.scan(/^  (.*)$/).flatten

      return fields
    end

    def self.default
      self.new(self.defaults)
    end

  end
end
