require "dotenv"
require "httparty"

Dotenv.load(".env", "~/.env")

class Swarm
  CLIENT_ID = ENV["SWARM_CLIENT_ID"]
  CLIENT_SECRET = ENV["SWARM_CLIENT_SECRET"]
  ACCESS_TOKEN = ENV["SWARM_ACCESS_TOKEN"]
  HOME_COUNTRY_CODE = "GB"
  MAX_QUERY_LIMIT = 250
  OUTPUT_FILE= "checkins-abroad.md"

  class << self
    def list_checkins_abroad
      total_count = api_request(limit: 1)[:checkins][:count]
      progression_count, offset, last_cc = 0, 0, nil
      trips, formatted_trips = [], []

      puts "Retrieving and processing #{total_count} check-ins."

      while progression_count < total_count
        checkins = api_request(offset: offset)[:checkins][:items]
        progression_count += checkins.count
        offset += MAX_QUERY_LIMIT

        checkins.each do |raw_checkin|
          current_cc = raw_checkin[:venue][:location][:cc]
          same_country = last_cc ? current_cc == last_cc : false
          checkin = serialised(raw_checkin)
          venue = [checkin[:venue], checkin[:city]].compact.join(", ")
          item = [checkin[:time].strftime("%d/%m/%Y %H:%M"), venue].join(" – ")

          unless current_cc == HOME_COUNTRY_CODE
            same_country ? trips.last.last.push(item) : trips.push([checkin[:country], [item]])
          end

          last_cc = current_cc
        rescue
          puts "NoDataError: missing required fields for #{raw_checkin}"
        end

        print "Progress: #{progression_count}/#{total_count} "
        puts "(#{trips.sum { |trip| trip.last.count }} abroad)"
      end

      trips.each do |trip|
        formatted_trip = "#{trip.first}:\n"
        trip.last.each { |checkin| formatted_trip << "  * #{checkin}\n" }
        formatted_trips << formatted_trip
      end

      File.open("./" + OUTPUT_FILE, "w") { |f| f.write(formatted_trips.join("\n\n"))  }

      print "Generated a list of #{formatted_trips.count} trips abroad in: "
      puts Dir.pwd + OUTPUT_FILE
    end

    # private

    def serialised(checkin)
      {
        time: Time.at(checkin[:createdAt]).utc + (checkin[:timeZoneOffset] * 60),
        venue: checkin[:venue][:name],
        city: checkin[:venue][:location][:city],
        country: checkin[:venue][:location][:country]
      }
    end

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

    private :api_request, :serialised
  end
end

Swarm.list_checkins_abroad
