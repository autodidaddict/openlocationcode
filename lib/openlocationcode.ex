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
  Open Location Code (OLC) is a geocoding system for identifying an area anywhere on planet Earth. Originally developed in
  2014, OLCs are also called "plus codes". Nearby locations have similar codes, and they can be encoded and decoded offline.
  As blocks are refined to a smaller and smaller area, the number of trailing zeros in a plus code will shrink.

  For more information on the OLC specification, check the [OLC Wikipedia entry](https://en.wikipedia.org/wiki/Open_Location_Code)

  There are two main functions in this module--encoding and decoding.

  """

  @doc """
  Encodes a location into an Open Location Code string.

  Produces a code of the specified length, or the default length if no length
  is provided. The length determines the accuracy of the code. The default length is
  10 characters, returning a code of approximately 13.5x13.5 meters. Longer
  codes represent smaller areas, but lengths > 14 refer to areas smaller than the accuracy of
  most devices.

  Latitude is in signed decimal degrees and will be clipped to the range -90 to 90. Longitude
  is in signed decimal degrees and will be clipped to the range -180 to 180.

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
  Decodes a code string into an `OpenLocationCode.CodeArea` struct

  ## Examples

      iex> OpenLocationCode.decode("6PH57VP3+PR")
      %OpenLocationCode.CodeArea{lat_resolution: 1.25e-4,
          long_resolution: 1.25e-4,
          south_latitude: 1.2867499999999998,
          west_longitude: 103.85449999999999}

  """
  def decode(olcstring) do
    code = clean_code(olcstring)

    {south_lat, west_long, lat_res, long_res} = decode_location(code)
    %OpenLocationCode.CodeArea{south_latitude: south_lat,
              west_longitude: west_long,
              lat_resolution: lat_res,
              long_resolution: long_res}
  end


  # Codec functions
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

  defp encode_pairs(_, _, code_length, code, digit_count) when digit_count == code_length do
    code
      |> pad_trailing
      |> ensure_separator
  end

  defp append_code(code, adj_coord, place_value) do
    digit_value = floor(adj_coord / place_value)
    adj_coord = adj_coord - (digit_value * place_value)
    code = code <> String.at(@code_alphabet, digit_value)
    { code, adj_coord }
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
      if code_length <= @pair_code_length do
        :math.pow(20, (div(code_length,-2)) + 2)
      else
        :math.pow(20,-3) / (:math.pow(5,(code_length - @pair_code_length)))
      end
  end

  defp clean_code(code) do
    code |> String.replace(@separator, "") |> String.replace_trailing(@padding, "")
  end

  defp decode_location(code) do
      _decode_location(0, code, String.length(code), -90.0, -180.0, 400.0, 400.0)
  end

  defp _decode_location(digit, code, code_length, south_lat, west_long, lat_res, long_res) when digit < code_length do
    code_at_digit = String.at(code, digit)

    if digit < @pair_code_length do
        code_at_digit1 = String.at(code, digit+1)
        lat_res = lat_res / 20
        long_res = long_res / 20
        south_lat = south_lat + (lat_res * index_of_codechar(code_at_digit))
        west_long = west_long + (long_res * index_of_codechar(code_at_digit1))
        _decode_location(digit + 2, code, code_length, south_lat, west_long, lat_res, long_res)
    else
        lat_res = lat_res / 5
        long_res = long_res / 4
        row = index_of_codechar(code_at_digit) / 4
        col = rem(index_of_codechar(code_at_digit), 4)
        south_lat = south_lat + (lat_res * row)
        west_long = west_long + (long_res * col)
        _decode_location(digit + 1, code, code_length, south_lat, west_long, lat_res, long_res)
    end

  end

  defp _decode_location(digit, _, code_length, south_lat, west_long, lat_res, long_res) when digit == code_length do
    {south_lat, west_long, lat_res, long_res}
  end

  defp index_of_codechar(codechar) do
    {index, _} = :binary.match(@code_alphabet, codechar)
    index
  end

end
