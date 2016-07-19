module Ian
  module Utils
    extend self

    def determine_installed_size(path)
      %x[du #{path} -ks --exclude=".git"].split.first
    end

  end
end
