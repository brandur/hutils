require "inifile"

module Hutils::Ltap
  class Conf
    attr_accessor :earliest
    attr_accessor :key
    attr_accessor :profile
    attr_accessor :timeout
    attr_accessor :timestamps
    attr_accessor :type
    attr_accessor :url
    attr_accessor :verbose

    def initialize
      @ini = IniFile.load(ENV["HOME"] + "/.ltap")
      self.earliest = "-24h"
      self.timeout = 60
      self.timestamps = false
      self.verbose = false
    end

    def load
      load_section("global")
    end

    def load_section(name)
      if section = @ini && @ini[name]
        load_value(section, :earliest)
        load_value(section, :key)
        load_value(section, :profile)
        load_value(section, :timeout)
        load_value(section, :timestamps)
        load_value(section, :type)
        load_value(section, :url)
        load_value(section, :verbose)
      end
    end

    private

    def load_value(section, name)
      if value = section[name.to_s]
        send("#{name}=", value)
      end
    end
  end
end
