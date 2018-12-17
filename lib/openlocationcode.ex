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

      iex> OpenLocationCode.encode(20.3700625,2.7821875)
      "7FG49QCJ+2V"      
    
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
    place_value = (digit_count / 2)
                  |> floor                  
                  |> resolution_for_pos
      
    {ncode, adj_latitude} = append_code(code, adj_latitude, place_value)
    digit_count = digit_count + 1
    
    {ncode, adj_longitude} = append_code(ncode, adj_longitude, place_value)
    digit_count = digit_count + 1

    # Should we add a separator here?
    ncode = if digit_count == @separator_position and digit_count < code_length do
      ncode <> @separator
    else 
      ncode        
    end
    
    encode_pairs(adj_latitude, adj_longitude, code_length, ncode, digit_count)    
  end

  defp append_code(code, adj_coord, place_value) do
    digit_value = floor(adj_coord / place_value)
    adj_coord = adj_coord - (digit_value * place_value)
    code = code <> String.at(@code_alphabet, digit_value)
    { code, adj_coord }
  end  

  defp encode_pairs(latitude, longitude, code_length, code, digit_count) when digit_count == code_length do   
    code 
      |> pad_trailing 
      |> ensure_separator
  end 

  defp pad_trailing(code) do   
    if String.length(code) < @separator_position do
      String.pad_trailing(code, @separator_position, @padding)      
    else
      code
    end    
  end  

  defp ensure_separator(code) do 
    if String.length(code) == @separator_position do
      code <> @separator
    else 
      code
    end    
  end
  
  defp floor(num) when is_number(num) do 
    Kernel.trunc(:math.floor(num))
  end 

  defp resolution_for_pos(position) do
    Enum.at(@pair_resolutions, position)
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
