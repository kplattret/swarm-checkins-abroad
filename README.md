# Swarm check-ins abroad

This is a simple Ruby script that can be used to get your check-ins made abroad using the Swarm
mobile app. It uses [HTTParty](https://github.com/jnunemaker/httparty) to interact with the
[Foursquare API](https://developer.foursquare.com/docs/api/users/checkins) and filters out the
check-ins made in your home country if you set the constant appropriately.
