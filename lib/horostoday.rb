class HorosToday < Rueph
  def self.daily_lunar_transit(time, tz_offset)
    start_array = time.dup
    end_array = start_array.dup
    start_array[3] = 0
    end_array[3] = 24
    start_array = Rueph.off_set_time_array(start_array, tz_offset)
    end_array = Rueph.off_set_time_array(end_array, tz_offset)

    lres = Rueph.calc(start_array, Rueph::MOON)
    rres = Rueph.calc(end_array, Rueph::MOON)

    if Rueph.deg_to_sign(lres[0]) == Rueph.deg_to_sign(rres[0])
      return [false, Rueph.deg_to_sign(lres[0])]
    else
      left_array = start_array.dup
      right_array = end_array.dup
      mid_array = start_array
      # Setting the mid_array through += allows us to reach
      # the center of the left and right arrays, which have
      # been offset by some hours for tz correction
      mid_array[3] += 12.0
      i = 6.0
      while (i > 3.0/128.0) do
        mres = Rueph.calc(mid_array, Rueph::MOON)

        if Rueph.deg_to_sign(mres[0]) == Rueph.deg_to_sign(lres[0])
          left_array = mid_array
          mid_array[3] = mid_array[3] + i
        else
          right_array = mid_array
          mid_array[3] = mid_array[3] - i
        end

        i = i/2.0
      end
      return_array = Rueph.reset_time_array(mid_array, tz_offset)
      return [return_array, Rueph.deg_to_sign(lres[0]), Rueph.deg_to_sign(rres[0])]
    end
  end

  def self.planet_aspect_with(planet1, planet2, time_array)
    planet1_pos = Rueph.calc(time_array, planet1)
    planet2_pos = Rueph.calc(time_array, planet2)

    difference = (planet1_pos[0] - planet2_pos[0]).abs

    if (difference <= 0.01 or difference >= 359.99)
      return "conjunction"
    elsif ((difference >= 59.99 and difference <= 60.01) or (difference >= 299.99 and difference <= 300.01))
      return "sextile"
    elsif ((difference >= 89.99 and difference <= 90.01) or (difference >= 269.99 and difference <= 270.01))
      return "square"
    elsif ((difference >= 119.99 and difference <= 120.01) or (difference >= 239.99 and difference <= 240.01))
      return "trine"
    elsif (difference >= 179.99 and difference <= 180.01)
      return "opposition"
    else
      return "No Aspect"
    end
  end

  #TODO: tz_offset
  def self.get_daily_planet_aspects_exact(planet, time_array, tz_offset)
    planet_aspects = {}

    # Copied from horoscli
    starts_with = time_array.dup
    starts_with[3] = 0
    starts_with = Rueph.off_set_time_array(starts_with, tz_offset)

    Rueph::PLANETS.each_with_index do |planet2, index|
      #cur_time = time_array.dup
      #cur_time[3] = 0
      #cur_time = Rueph.off_set_time_array(cur_time, tz_offset)
      #cur_time_cpy = cur_time.dup

      cur_time = starts_with.dup

      cur_aspect = "No Aspect"
      prev_aspect = "No Aspect"

      if planet != index
        while (cur_time[3] < (24.0 + starts_with[3])) do
          cur_aspect = planet_aspect_with(planet, index, cur_time)
          if ((cur_aspect != prev_aspect) && (prev_aspect == "No Aspect"))
            aspect_time_TZ = Rueph.reset_time_array(cur_time.dup, tz_offset)
            planet_aspects[index] = [cur_aspect, aspect_time_TZ]
          end
          cur_time[3] += (1.0/240.0)
          prev_aspect = cur_aspect
        end
      end
    end

    return planet_aspects.sort_by {|key, val| val[1][3]}
  end

  def self.moon_void(planet_aspects, time, tz_offset)
    cur_date = time.dup

    moon_transit = daily_lunar_transit(cur_date.dup, tz_offset)

    # changed to adding day instead of 24 hours to
    # get around a bug - note this happened if
    # other things fall apart
    #
    #
    # TODO: Refactor transits to only be calculated when they are needed
    #

    cur_date = Rueph.off_set_time_array(cur_date, tz_offset)
    lunar_aspects = planet_aspects.reverse
    
    tomorrow_date = time.dup
    tomorrow_date[2] += 1
    moon_transit_tomorrow = daily_lunar_transit(tomorrow_date.dup, tz_offset)

    two_days_date = tomorrow_date.dup
    two_days_date[2] += 1
    moon_transit_two_days = daily_lunar_transit(two_days_date.dup, tz_offset)

    if (moon_transit[0])
      lunar_aspects.each do |planet, aspect|
        if (aspect[1][3] <= moon_transit[0][3])
          return [1, aspect[1][3], moon_transit[0][3], moon_transit]
        end
      end
      return [2, moon_transit[0][3], moon_transit]
    else

      tomorrow_moon_aspects = get_daily_planet_aspects_exact(Rueph::MOON, tomorrow_date, tz_offset).reverse

      if (moon_transit_tomorrow[0])
        tomorrow_moon_aspects.each do |planet, aspect|
          if (aspect[1][3] <= moon_transit_tomorrow[0][3])
            return [0, Rueph.calc(cur_date, Rueph::MOON)[0]]
          end
        end
        unless lunar_aspects.empty?
          return [3, lunar_aspects[0][1][1][3], moon_transit_tomorrow]
      # NOTE: no idea
        else
          return [4]
        end
      else

        two_days_moon_aspects = get_daily_planet_aspects_exact(Rueph::MOON, two_days_date, tz_offset).reverse

        if (moon_transit_two_days[0])
          two_days_moon_aspects.each do |planet, aspect|
          if (aspect[1][3] <= moon_transit_two_days[0][3])
            return [0, Rueph.calc(cur_date, Rueph::MOON)[0]]
          end
        end
        unless tomorrow_moon_aspects.empty?
          return [0, Rueph.calc(cur_date, Rueph::MOON)[0]]
        else
          unless lunar_aspects.empty?
            return [3, lunar_aspects[0][1][1][3], moon_transit_tomorrow]
          else
            puts "Error has occurred, lunar_aspects empty"
            return [0, Rueph.calc(cur_date, Rueph::MOON)[0]]
          end
        end
        else
      #puts "Current Date Array"
      #p cur_date
      #
      #cur_date = Rueph.off_set_time_array(cur_date, tz_offset)
      #NOTE
          return [0, Rueph.calc(cur_date, Rueph::MOON)[0]]
      #return [0, moon_transit[1]]
        end
      end
    end
  end

  def self.moon_void_print(void_array)
    if void_array[0] != 0
      if void_array[0] == 1
        return "#{void_array[3][1]} --#{Time.at(void_array[1]*3600).utc.strftime("%H:%M")}-> V/C --#{Time.at(void_array[2]*3600).utc.strftime("%H:%M")}-> #{void_array[3][2]}"
      elsif void_array[0] == 2
        return "V/C --#{Time.at(void_array[2][0][3]*3600).utc.strftime("%H:%M")}-> #{void_array[2][2]}"
      elsif void_array[0] == 3
        return "#{void_array[2][1]} --#{Time.at(void_array[1]*3600).utc.strftime("%H:%M")}-> V/C "
      elsif void_array[0] == 4
        return "V/C"
      end
    else
      return "MOON in #{Rueph.deg_to_sign(void_array[1])}"
    end
  end
end
