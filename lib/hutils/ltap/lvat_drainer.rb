require "json"
require "zlib"

module Hutils::Ltap
  class LvatDrainer
    def initialize(earliest:, key:, timeout:, query:, timestamps:, url:, verbose:)
      @query = query

      if timestamps
        raise ArgumentError, "lvat does not supported `timestamps` option"
      end

      @api = Excon.new(url,
        headers: {
          "Accept-Encoding" => "gzip"
        },
        read_timeout: timeout
      )
    end

    def run
      resp = @api.get(
        path: "/messages",
        expects: [200, 404],
        query: {
          query: @query
        })

      return [] if resp.status == 404

      encoding = resp.headers["Content-Encoding"]
      str = if encoding && encoding.include?("gzip")
        reader = Zlib::GzipReader.new(StringIO.new(resp.body))
        reader.read
      else
        resp.body
      end

      str.split("\n")
    end
  end
end
