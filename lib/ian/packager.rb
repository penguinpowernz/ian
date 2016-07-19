require 'tmpdir'
require 'fileutils'

module Ian
  class Packager
    def initialize(path, ctrl, log)
      @path = path
      @ctrl = ctrl
      @log = log
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
      docs  = "#{@dir}/usr/share/docs/#{pkgname}"
      files = %x[find #{@dir} -type f -maxdepth 1].lines.map {|l| l.chomp}
      raise RuntimeError, "Unable to copy root files" unless $?.success?

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
      pkgdir = File.join(@path, "pkg")
      FileUtils.mkdir_p pkgdir
    
      FileUtils.chmod(0755, Dir["#{Ian.debpath(@dir)}/*"])
      FileUtils.chmod(0755, Ian.debpath(@dir))

      pkg    = File.join(pkgdir, "#{pkgname}.deb")
      output = %x[dpkg-deb -b #{@dir} #{pkg}]

      return [$?.success?, pkg, output]
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
      files = %w[.git .gitignore .ianignore]
      
      File.read(File.join(@path, ".ianignore")).lines.each do |ign|
        next if ign.start_with? "#"
        
        ign.chomp!
        igns = Dir["#{@path}/#{ign}"]
        next if igns.empty?
        
        files+= igns
      end
    end

  end
end
