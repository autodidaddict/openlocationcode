defmodule OpenLocationCode do
  @pair_code_length   10
  @separator          "+"
  @separator_position 8
  @padding            "0"
  @latitude_max       90
  @longitude_max      180

  @code_alphabet      "23456789CFGHJMPQRVWX"

  #The resolution values in degrees for each position in the lat/lng pair
  #encoding. These give the place value of each position, and therefore the
  #dimensions of the resulting area.
  @pair_resolutions  [20.0, 1.0, 0.05, 0.0025, 0.000125]
  
  
  @moduledoc """
  Documentation for OpenLocationCode.
  """
  
  @doc """ 
    Encodes a location into an Open Location Code.

    Produces a code of the specified length, or the default length if no length
    is provided. The length determines the accuracy of the code. The default length is
    10 characters, returning a code of approximately 13.5x13.5 meters. Longer
    codes represent smaller areas, but lengths > 14 refer to areas smaller than the accuracy of
    most devices.

    Args:
      latitude: A latitude in signed decimal degrees. Will be clipped to the
          range -90 to 90.
      longitude: A longitude in signed decimal degrees. Will be normalised to
          the range -180 to 180.
      codeLength: The number of significant digits in the output code, not

   ## Examples

      iex> OpenLocationCode.encode(20.375,2.775, 6)      
      "7FG49Q00+"
    
  """
  def encode(latitude, longitude, code_length \\ @pair_code_length) do
    latitude = clip_latitude(latitude)
    longitude = normalize_longitude(longitude)
    latitude = if latitude == 90 do
      latitude - precision_by_length(code_length)
    else
      latitude 
    end    

    encode_pairs(latitude + @latitude_max, longitude + @longitude_max, code_length, "", 0)

  end

  defp encode_pairs(adj_latitude, adj_longitude, code_length, code, digit_count) when digit_count < code_length do
    place_value = Enum.at(@pair_resolutions, Kernel.trunc(:math.floor(digit_count / 2)))
    
    digit_value = Kernel.trunc(:math.floor(adj_latitude / place_value))
    adj_latitude = adj_latitude - (digit_value * place_value)

    code = code <> String.at(@code_alphabet, digit_value) # lat pair code

    digit_count = digit_count + 1

    digit_value = Kernel.trunc(:math.floor(adj_longitude / place_value))
    adj_longitude = adj_longitude - (digit_value * place_value)
    
    code = code <> String.at(@code_alphabet, digit_value) # long pair code 

    digit_count = digit_count + 1

    # Should we add a separator here?
    if digit_count == @separator_position and digit_count < code_length do
        code = code <> @separator
    end
    
    encode_pairs(adj_latitude, adj_longitude, code_length, code, digit_count)    
  end

  defp encode_pairs(latitude, longitude, code_length, code, digit_count) when digit_count == code_length do   
    ncode =
      if String.length(code) < @separator_position do      
        String.pad_trailing(code, @separator_position, @padding)
      else
        code 
      end
    ncode = if String.length(ncode) == @separator_position do
      ncode <> @separator
    else 
      ncode
    end   
    ncode 
  end 

  
  defp clip_latitude(latitude) do
    Kernel.min(90, Kernel.max(-90, latitude))
  end

  defp normalize_longitude(longitude) do
    case longitude do
      l when l < -180 -> normalize_longitude(l + 360)
      l when l > 180 -> normalize_longitude(l - 360)
      l -> l
    end
  end

  defp precision_by_length(code_length) do
      precision =
      if code_length <= @pair_code_length do
        :math.pow(20, (div(code_length,-2)) + 2)
      else
        :math.pow(20,-3) / (:math.pow(5,(code_length - @pair_code_length)))
      end      
  end

end 
