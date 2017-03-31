module Ian
  module Utils
    extend self

    def determine_installed_size(path)
      %x[du #{path} -ks --exclude=".git" --exclude="pkg"].split.first
    end

    # try to guess the maintainer by reading the git config file
    def guess_maintainer
      text = File.read(File.join(ENV['HOME'], ".gitconfig"))
      name = text.match(/name = (.*)$/)[1]
      email = text.match(/email = (.*)$/)[1]

      "#{name} <#{email}>"
    rescue Errno::ENOENT
      return ""
    end

  end
end
