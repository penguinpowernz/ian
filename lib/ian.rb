require 'ian/version'
require 'fileutils'

module Ian

  class << self
    
    def create(name)
      FileUtils.mkdir(name)
      init(name)
    end

    def init(path)
      Ian::Control.new("#{path}/control").save
    
      File.write("#{path}/postinst", "#!/bin/bash\n\n\nexit 0;")
      FileUtils.chmod(0755, "#{path}/postinst")   
    end
    
    def control(path)
      Ian::Control.new(path)
    end
    
    def build_package(path)
    
    end
    
  end

end
