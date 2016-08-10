
require 'ian/version'
require 'ian/control'
require 'ian/packager'
require 'ian/utils'

require 'fileutils'

module Ian

  class << self

    def debpath(path)
      "#{path}/DEBIAN"
    end

    def ctrlpath(path)
      "#{debpath(path)}/control"
    end

    # create a new DEBIAN package
    def create(name, log)
      path = File.expand_path(name)
      FileUtils.mkdir(path)

      init(path, log)
    end

    # initialize a new DEBIAN package
    def init(path, log)
      dpath = debpath(path)
      cpath = ctrlpath(path)

      FileUtils.mkdir_p(dpath)
      log.info "Created DEBIAN folder"

      c = Control.default
      c[:package] = File.basename(path)
      Control.save(c, cpath)
      log.info "Generated #{cpath}"

      pi = "#{dpath}/postinst"

      File.write(pi, "#!/bin/bash\n\n\nexit 0;")
      log.info "Generated #{pi}"

      FileUtils.chmod(0755, Dir["#{dpath}/*"])
      FileUtils.chmod(0755, dpath)

      #cfg = {}

      #File.write("#{path}/ian.yml", cfg.to_yaml)
      #log.info "Generated ian.yml"

      File.write("#{path}/.ianignore", "pkg\n")
      log.info "Generated .ianignore"
    end

    def control(path=nil)
      if path.nil?
        return Control.default
      else
        path = ctrlpath(path) if File.basename(path) != "DEBIAN"
        return Control.load_file(path)
      end
    end

    def build_package(path, log)
      c = control(path)
      c[:size] = Utils.determine_installed_size(path)
      Ian::Control.save(c, path)

      pkgr = Ian::Packager.new(path, c, log)
      pkgr.run
    end

  end

end
