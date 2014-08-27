require "csv"
require "excon"
require "json"
require "time"
require "uri"

module Hutils::Ltap
  class SplunkDrainer
    def initialize(earliest:, key:, timeout:, query:, timestamps:, url:, verbose:)
      @earliest = earliest
      @timeout = timeout
      @query = query
      @timestamps = timestamps
      @verbose = verbose

      @user = URI.parse(url).user
      @api = Excon.new(url)
    end

    def run
      create_job(@query)
      start = Time.now

      loop do
        sleep(2)
        break if job_finished?

        # finalize the job if we've broken our timeout point
        if (Time.now - start).to_i > @timeout
          debug("breaking: reached timeout")
          finalize_job
          break
        end
      end

      get_job_results
    end

    def cancel_job
      return unless @job_id
      @api.post(
        path: "/servicesNS/#{@user}/search/search/jobs/#{@job_id}/control",
        expects: 200,
        body: URI.encode_www_form({
          action: "cancel"
        })
      )
      debug("cancelled")
    end

    private

    def create_job(query)
      resp = @api.post(
        path: "/servicesNS/#{@user}/search/search/jobs",
        expects: 201,
        body: URI.encode_www_form({
          earliest_time: @earliest.iso8601,
          output_mode: "json",
          search: "search #{query}"
        })
      )
      @job_id = JSON.parse(resp.body)["sid"]
      debug "job: #{@job_id}"
    end

    def debug(str)
      if @verbose
        puts str
      end
    end

    def finalize_job
      @api.post(
        path: "/servicesNS/#{@user}/search/search/jobs/#{@job_id}/control",
        expects: 200,
        body: URI.encode_www_form({
          action: "finalize"
        })
      )
      debug("finalized")
    end

    def get_job_results
      # get results as CSV because the JSON version just mixes everything together
      # into a giant difficult-to-use blob
      resp = @api.get(
        path: "/servicesNS/#{@user}/search/search/jobs/#{@job_id}/results",
        # 204 if no results available
        expects: [200, 204],
        body: URI.encode_www_form({
          action: "finalize",
          # tell Splunk to give us all results
          count: 0,
          output_mode: "csv"
        })
      )

      return [] if resp.status == 204

      rows = CSV.parse(resp.body)
      return [] if rows.count < 1
      raw_field = rows[0].index("_raw") || raise("no _raw field detected in Splunk response")
      time_field = rows[0].index("_time") || raise("no _time field detected in Splunk response")

      # skip the first line as its used for CSV headers
      rows[1..-1].
        map { |l| [l[raw_field], l[time_field]] }.
        # 2014-08-15T19:01:15.476590+00:00 54.197.117.24 local0.notice
        # api-web-1[23399]: - api.108080@heroku.com ...
        map { |l, t| [l.gsub(/^.*: - /, ""), t] }.
        map { |l, t| [l.strip, t] }.
        # format timestamps consistently (+00:00 --> Z)
        map { |l, t| [l, Time.parse(t).getutc.iso8601] }.
        map { |l, t| @timestamps ? "#{t}: #{l}" : l }.
        # results come in from newest to oldest; flip that
        reverse
    end

    def job_finished?
      resp = @api.get(
        path: "/servicesNS/#{@user}/search/search/jobs/#{@job_id}",
        expects: 200,
        body: URI.encode_www_form({
          output_mode: "json"
        })
      )
      # Splunk may not be winning any awards for cleanest API anytime soon
      state = JSON.parse(resp.body)["entry"][0]["content"]["dispatchState"]
      debug("state: #{state}")
      state == "DONE"
    end
  end
end
