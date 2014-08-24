module Hutils
  class Stripper
    def initialize(messages, ignore)
      @messages = messages
      @ignore = ignore
    end

    def run
      @messages.each do |message|
        message.reject! { |k, _| @ignore.include?(k) }
      end
    end
  end
end
