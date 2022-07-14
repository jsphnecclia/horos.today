#!/usr/bin/env ruby
require_relative 'lib/RuephBase.rb'
require_relative 'lib/Rueph.rb'
require_relative 'lib/horostoday.rb'
require 'time'
require 'sinatra/base'
require 'timezone'
require 'sinatra/cookies'
require 'sanitize'
require 'geocoder'

class HorosTodayServer < Sinatra::Application
  #TODO: wheneverize 0 0 * * * * or whatever the range calculation daily
  # https://medium.com/@davidjtomczyk/scheduling-jobs-with-whenever-f1fc7b401733

  #TODO: https://www.simon-neutert.de/2017/persistend-cookies-with-sinatra/

  set :bind, '0.0.0.0'

  HorosToday.set_ephe_path('ephe')
  daily_hash = {}
  
  get '/' do

    tz = request.cookies['tz']
    

    if tz
      @tz_offset = Integer(tz[1] || '')
      begin
        #@tz_offset = Integer(tz || '')
      #TODO: Fix ArgumentError raising
      rescue ArgumentError
        nil
      else
        if daily_hash[@tz_offset].nil?
          
          if Time.now.utc.day != Time.now.getlocal(@tz_offset*60*60).day
            t = [Time.now.utc.year, Time.now.utc.month, Time.now.utc.day - 1, 12]
          else
          # check if utc.day matches tz_offset + utc.minutes
            t = [Time.now.utc.year, Time.now.utc.month, Time.now.utc.day, 12]
          end

          daily_hash[@tz_offset] = { sun: HorosToday.sign_of(t, HorosToday::SUN),
                              aspects: HorosToday.get_daily_planet_aspects_exact(HorosToday::MOON, t, @tz_offset) }
          
          daily_hash[@tz_offset][:aspect_list] = []
          daily_hash[@tz_offset][:aspects].each do |aspect|
            daily_hash[@tz_offset][:aspect_list].append [aspect[0], aspect[1][0]]
          end


          daily_hash[@tz_offset][:lunar_transit] = HorosToday.moon_void_print(HorosToday.moon_void(daily_hash[@tz_offset][:aspects], t, @tz_offset))

        end
      end

      @daily_hash = daily_hash
       
      @sun = @daily_hash[@tz_offset][:sun]
      @aspects = @daily_hash[@tz_offset][:aspects]
      @lunar_transit = @daily_hash[@tz_offset][:lunar_transit]
      @aspect_list = @daily_hash[@tz_offset][:aspect_list]

      @location = tz[0]


    else
      redirect to('/get_tz')
    end
    erb :index
  end

  get '/get_tz' do
    erb :get_tz
  end

  post '/' do
    results = Geocoder.search(Sanitize.fragment(params[:geolocation]))
    Timezone::Lookup.config(:geonames) do |c|
      c.username = 'prkrmcgwn'
    end
    tz = Timezone.lookup(results.first.coordinates[0], results.first.coordinates[1])
    response.set_cookie("tz", {
      :value => [params[:geolocation], tz.utc_offset/(60*60)],
      :max_age => "2592000",
      :path => '/'
    })
    redirect to('/')
  end
end
