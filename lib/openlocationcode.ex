defmodule OpenLocationCode do
  import OpenLocationCode.Codec
  import OpenLocationCode.CodeArea

  @pair_code_length   10
  @latitude_max       90
  @longitude_max      180

  
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

  @doc """
  Decodes a code string 
  """
  def decode(olcstring) do 
    code = clean_code(olcstring)

    {south_lat, west_long, lat_res, long_res} = decode_location(code)
    %OpenLocationCode.CodeArea{south_latitude: south_lat, 
              west_longitude: west_long, 
              lat_resolution: lat_res, 
              long_resolution: long_res}
  end

end 
