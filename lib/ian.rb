
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

    def create(name)
      FileUtils.mkdir(name)

      init(name)
    end

    def init(path, log)
      FileUtils.mkdir(debpath(path))

      control(path).save
      log.info "Generated #{path}"

      pi = "#{debpath(path)}/postinst"

      File.write(pi, "#!/bin/bash\n\n\nexit 0;")
      log.info "Generated #{pi}"

      FileUtils.chmod(0755, Dir["#{debpath(path)}/*"])
      FileUtils.chmod(0755, debpath(path))

      #cfg = {}

      #File.write("#{path}/ian.yml", cfg.to_yaml)
      #log.info "Generated ian.yml"

      File.write("#{path}/.ianignore", "*.deb\n")
      log.info "Generated .ianignore"
    end

    def control(path)
      Ian::Control.new(ctrlpath(path))
    end

    def build_package(path, log)
      c = control(path)
      c[:size] = Utils.determine_installed_size(path)
      c.save

      pkgr = Ian::Packager.new(path, c, log)
      pkgr.run
    end


  end

end
