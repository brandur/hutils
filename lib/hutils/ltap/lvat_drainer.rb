require "json"

module Hutils::Ltap
  class LvatDrainer
    def initialize(earliest:, key:, timeout:, query:, timestamps:, url:, verbose:)
      @query = query

      if timestamps
        raise ArgumentError, "lvat does not supported `timestamps` option"
      end

      @api = Excon.new(url, read_timeout: timeout)
    end

    def run
      resp = @api.get(
        path: "/messages",
        expects: [200, 404],
        query: {
          query: @query
        })

      return [] if resp.status == 404

      resp.body.split("\n")
    end
  end
end
