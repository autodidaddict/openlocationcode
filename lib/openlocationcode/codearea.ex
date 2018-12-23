defmodule OpenLocationCode.CodeArea do
    @moduledoc """
    A code area is a region on a map indicated by a lower-left corner---the southernmost latitude and 
    the westernmost longitude. The size of the region is given by the resolution, which is the height 
    and length of the region in degrees.
    """

    @doc """
    Structure representing a code area.
    """
    defstruct south_latitude: 0.0, 
              west_longitude: 0.0, 
              lat_resolution: 0.0,
              long_resolution: 0.0

    @doc """
    Returns the northernmost latitude of a code area 
    """
    def north_latitude(%OpenLocationCode.CodeArea{south_latitude: sl, west_longitude: _, lat_resolution: lr, long_resolution: _ }) do
        sl + lr 
    end

    @doc """
    Returns the easternmost latitude of a code area
    """
    def east_longitude(%OpenLocationCode.CodeArea{south_latitude: _, west_longitude: wl, lat_resolution: _, long_resolution: lr }) do
        wl + lr
    end 

    @doc """
    Returns the center point latitude
    """
    def center_latitude(%OpenLocationCode.CodeArea{south_latitude: sl, west_longitude: _, lat_resolution: _, long_resolution: _} = ca) do
        sl + ((ca |> north_latitude()) / 2)
    end 

    @doc """
    Returns the center point longitude
    """
    def center_longitude(%OpenLocationCode.CodeArea{south_latitude: _, west_longitude: wl, lat_resolution: _, long_resolution: _} = ca) do 
        wl + ((ca |> east_longitude()) / 2)
    end
        
end