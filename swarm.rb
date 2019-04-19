require "pry" # TODO remove
require "cgi"
require "httparty"
require "dotenv"

Dotenv.load(".env", "~/.env")

class Swarm
  CLIENT_ID = ENV["SWARM_CLIENT_ID"]
  CLIENT_SECRET = ENV["SWARM_CLIENT_SECRET"]
  ACCESS_TOKEN = ENV["SWARM_ACCESS_TOKEN"]
  HOME_COUNTRY = "GB"
  MAX_QUERY_LIMIT = 250

  class << self
    def list_checkins_abroad
      # total_count = api_request(limit: 1)[:checkins][:count]
      total_count = 500
      progression_count = 0
      offset = 0
      checkins_abroad = []

      while progression_count < total_count
        checkins = api_request(offset: offset)[:checkins][:items]
        progression_count += checkins.count
        offset += MAX_QUERY_LIMIT
        checkins.reject! { |checkin| checkin[:venue][:location][:cc] == HOME_COUNTRY }
        checkins_abroad.push(*checkins)
      end

      formatted_checkins = []

      checkins_abroad.each do |checkin|
        time = Time.at(checkin[:createdAt]).utc + (checkin[:timeZoneOffset] * 60)
        time = time.strftime("%d/%m/%Y %H:%M")
        venue = checkin[:venue]
        venue = [venue[:name], venue[:location][:city], venue[:location][:country]].compact.join(", ")
        item = [time, venue].join(" – ")
        formatted_checkins << item
      end

      formatted_checkins
    end

    # private

    def api_request(limit: MAX_QUERY_LIMIT, offset: 0)
      base_url = "https://api.foursquare.com/v2/users/self/checkins"
      params = "?oauth_token=#{ACCESS_TOKEN}\
      &v=#{Time.now.utc.strftime("%Y%m%d")}\
      &sort=newestfirst\
      &limit=#{limit}\
      &offset=#{offset}"
      response = HTTParty.get(base_url + params, format: :plain)
      JSON.parse(response, symbolize_names: true)[:response]
    end

    private :api_request
  end
end

# $ ruby swarm.rb
puts Swarm.list_checkins_abroad
