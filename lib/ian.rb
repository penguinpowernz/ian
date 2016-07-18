
require 'ian/version'
require 'ian/control'

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

    def init(path)
      Ian::Control.new(ctrlpath(path)).save
    
      File.write("#{path}/postinst", "#!/bin/bash\n\n\nexit 0;")
      FileUtils.chmod(0755, "#{path}/postinst")   
    end
    
    def control(path)
      Ian::Control.new(ctrlpath(path))
    end
    
    def build_package(path)
    
    end
    
  end

end
