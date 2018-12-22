defmodule OpenLocationCode.Codec do
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
  

    def encode_pairs(adj_latitude, adj_longitude, code_length, code, digit_count) when digit_count < code_length do
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

      def encode_pairs(latitude, longitude, code_length, code, digit_count) when digit_count == code_length do   
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
      
      defp floor(num) when is_number(num) do 
        Kernel.trunc(:math.floor(num))
      end 
    
      defp resolution_for_pos(position) do
        Enum.at(@pair_resolutions, position)
      end
    
      def clip_latitude(latitude) do
        Kernel.min(90, Kernel.max(-90, latitude))
      end
    
      def normalize_longitude(longitude) do
        case longitude do
          l when l < -180 -> normalize_longitude(l + 360)
          l when l > 180 -> normalize_longitude(l - 360)
          l -> l
        end
      end
    
      def precision_by_length(code_length) do
          precision =
          if code_length <= @pair_code_length do
            :math.pow(20, (div(code_length,-2)) + 2)
          else
            :math.pow(20,-3) / (:math.pow(5,(code_length - @pair_code_length)))
          end      
      end

      def clean_code(code) do 
        code |> String.replace(@separator, "") |> String.replace_trailing(@padding, "")
      end      

      def decode_location(code) do
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

      defp _decode_location(digit, code, code_length, south_lat, west_long, lat_res, long_res) when digit == code_length do 
        {south_lat, west_long, lat_res, long_res}
      end 

      defp index_of_codechar(codechar) do 
        {index, length} = :binary.match(@code_alphabet, codechar)
        index 
      end 

end