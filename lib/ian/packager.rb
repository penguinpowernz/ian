require 'tmpdir'

module Ian
  class Packager
    def initialize(path, ctrl, log)
      @path = path
      @ctrl = ctrl
      @log = log
    end

    # run the packager
    def run
      @dir = Dir.tmpdir

      if copy_contents
        @log.info("Copied files for packaging to #{@dir}")
      else
        raise StandardError, "Failed to copy files for packaging"
      end

      move_root_files
      success, output = *build

      if !success
        @log.error "Failed to build package"
        @log.error output
      end
    end

    # copy the contents to a tmp dir
    def copy_contents
      cmd = rsync_cmd

      @log.debug "Copying contents with: #{cmd}"

      %x[#{cmd}]
      $?.success?
    end

    # move extraneous stuff like README and CHANGELOG to /usr/share/doc
    def move_root_files
      docs  = "#{@dir}/usr/share/docs/#{pkgname}"
      files = %x[find #{@dir} -type f].lines.map {|l| l.chomp}

      FileUtils.mkdir_p(docs)

      # move all the files from the root of the package
      files.each do |file|
        next unless File.exist?(file)
        FileUtils.mv(file, docs)
        @log.info "#{file} => usr/share/docs/#{pkgname}"
      end
    end

    # build the package out of the temp dir
    def build
      pkg    = File.join(@path, "#{pkgname}.deb")
      output = %x[dpkg-deb -b #{@dir} #{pkg}]

      return [$?.success?, output]
    end

    private

    def pkgname
      parts = [
        @ctrl[:package],
        @ctrl[:version],
        @ctrl[:arch]
      ]

      "%s_%s_%s" % parts
    end

    # generate the rsync command
    def rsync_cmd
      cmd = "rsync -ra #{@path}/* #{@dir}"

      # exclude the files
      excludes.each do |x|
        cmd << " --exclude=#{x}"
      end

      cmd
    end

    def excludes
      %w[.git .gitignore .ianignore]
    end

  end
end
