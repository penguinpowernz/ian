require 'tmpdir'
require 'fileutils'

module Ian
  class Packager
    def initialize(path, ctrl, log)
      @path = path  # this is the source path that the files to package are copied from
      @ctrl = ctrl
      @log  = log
      @dir  = nil   # this is the tmp directory that the package is built from
    end

    # run the packager
    def run
      @dir = Dir.mktmpdir

      success = copy_contents

      if success
        @log.info("Copied files for packaging to #{@dir}")
      else
        raise StandardError, "Failed to copy files for packaging"
      end

      move_root_files
      generate_md5sums
      success, pkg, output = *build

      raise RuntimeError, "Failed to build package: #{output}" unless success

      pkg
    ensure
      FileUtils.rm_rf @dir if File.exist? @dir
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
      docs  = "#{@dir}/usr/share/doc/#{@ctrl[:package]}"
      files = Dir.entries(@dir).select {|f| !File.directory?(f) }
      return unless files.any?

      FileUtils.mkdir_p(docs)

      # move all the files from the root of the package
      files.each do |file|
        file = File.join(@dir, file)
        next unless File.exist?(file)

        FileUtils.mv(file, docs)
        @log.info "#{file} => usr/share/doc/#{pkgname}"
      end
    end

    # build the package out of the temp dir
    def build
      @log.info "Packaging files"
      pkgdir = File.join(@path, "pkg")
      FileUtils.mkdir_p pkgdir

      FileUtils.chmod(0755, Dir["#{Ian.debpath(@dir)}/*"])
      FileUtils.chmod(0755, Ian.debpath(@dir))

      pkg    = File.join(pkgdir, "#{pkgname}.deb")
      output = %x[fakeroot dpkg-deb -b #{@dir} #{pkg}]

      return [$?.success?, pkg, output]
    end

    private

    def pkgname
      @ctrl.pkgname
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

    def generate_md5sums
      @log.debug "Generating md5sums"
      sums = `find #{@dir} -type f|sort|xargs md5sum|grep -v DEBIAN`
      sums.gsub!(/#{@dir}\//, "")
      File.write(File.join(@dir, "DEBIAN", "md5sums"), sums)
      File.write(File.join(@path, "DEBIAN", "md5sums"), sums)
    end

    def excludes
      files      = %w[.git .gitignore .ianignore]
      ignorefile = File.join(@path, ".ianignore")

      return files unless File.exist?(ignorefile)

      File.read(ignorefile).lines.each do |ign|
        next if ign.start_with? "#"
        files << ign.chomp
      end

      files.each {|f| @log.debug "Ignoring file: %s" % f }

      files
    end

  end
end
