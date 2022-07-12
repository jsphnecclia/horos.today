require 'ffi'

class Rueph < RuephBase
  SIGNS = ['ARIES', 'TAURUS', 'GEMINI', 'CANCER', 'LEO',
           'VIRGO', 'LIBRA', 'SCORPIO', 'SAGITTARIUS',
           'CAPRICORN', 'AQUARIUS', 'PISCES']

  PLANETS = ['SUN', 'MOON', 'MERCURY', 'VENUS', 'MARS', 
             'JUPITER', 'SATURN', 'URANUS', 'NEPTUNE', 'PLUTO']

  def self.time_to_array(time)
    array = [time.year, time.month, time.day, time.hour + (time.min/60.0)]
  end

  def self.time_from_array(array)
    Time.new(array[0], array[1], array[2]) + (array[3]*60*60)
  end


  def self.off_set_time_array(time_array, offset)
    time_array[3] -= offset
    return time_array
  end

  def self.reset_time_array(time_array, offset)
    time_array[3] += offset
    return time_array
  end

  def self.deg_to_sign(deg)
    return SIGNS[(deg / 30.0).floor()]
  end

  # 3.5.  Error handling and return values
  # swe_calc() (as well as swe_calc_ut(), swe_fixstar(), and 
  # swe_fixstar_ut()) returns a 32-bit integer value. This value is >= 0, 
  # if the function call was successful, and < 0,
  # if a fatal error has occurred. In addition an error string 
  # or a warning can be returned in the string parameter serr.

  def self.calc(time_array, planet, flags = FLG_SWIEPH + FLG_SPEED)
    #time_array = self.time_to_array(time_array) if time_array.is_a? Time
    # Calculates Julian Day from time array
    julday = Rueph.julday(time_array[0], time_array[1],
                          time_array[2], time_array[3], GREG_CAL)
    
    # Establishes a pointer for calc_ut's results
    # and a pointer to its error string
    retpntr = FFI::MemoryPointer.new(:double, 6)
    errstring = FFI::MemoryPointer.new(:char, 255)
    iflgret = Rueph.calc_ut(julday, planet, flags, retpntr, errstring)

    # Gets data from the pointer
    # then frees the memory
    ret_errstr = errstring.read_string
    errstring.free

    ret_array = retpntr.read_array_of_double(6)
    retpntr.free

    #TODO: what to do here
    #return iflgret
    #return ret_errstr
    return ret_array
  end

  # REQUIRES SEFSTARS.TXT FOR FUNCTION FIXSTAR
  def self.fixstar(time_array, star, bulk = false, flags = FLG_SWIEPH)
    time_array = self.time_to_array(time_array) if time_array.is_a? Time
    # Calculates Julian Day from time array
    julday = Rueph.julday(time_array[0], time_array[1],
                          time_array[2], time_array[3], GREG_CAL)
    
    # Establishes pointers for fixstar
    star_str = FFI::MemoryPointer.new(:char, 40)
    star_str = star_str.write_string(star)
    retpntr = FFI::MemoryPointer.new(:double, 6)
    errstring = FFI::MemoryPointer.new(:char, 255)

    if bulk
      # Using bulk has the side effect of making star names
      # harder to find automatically. While case is still insensitive,
      # You must put a % at the end of the star_str, as a wild card
      iflgret = Rueph.fixstar2_ut(star_str, julday, flags, retpntr, errstring)
    else
      iflgret = Rueph.fixstar_ut(star_str, julday, flags, retpntr, errstring)
    end

    # frees pointers

    ret_errstr = errstring.read_string
    errstring.free

    ret_starstr = star_str.read_string
    star_str.free

    ret_array = retpntr.read_array_of_double(6)
    retpntr.free
    
    
    return ret_array
  end

  def self.isRetrograde?(time, planet)
    if (self.calc(time, planet)[3] < 0)
      return true
    else # speed >= 0
      return false
    end
  end

  def self.sign_of(time, planet)
    return deg_to_sign(calc(time, planet)[0])
  end

#### The following section deals with pointers
#### used as strings in the base library
  def self.get_library_path
    retpntr = FFI::MemoryPointer.new(:char, 255)

    RuephBase.get_library_path(retpntr)

    ret_str = retpntr.read_string
    retpntr.free

    return ret_str
  end

  def self.get_body_name(body_number)
    retpntr = FFI::MemoryPointer.new(:char, 255)

    RuephBase.get_body_name(body_number, retpntr)

    ret_str = retpntr.read_string
    retpntr.free

    return ret_str
  end


end
