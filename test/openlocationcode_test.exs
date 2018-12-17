defmodule OpenlocationcodeTest do
  use ExUnit.Case
  doctest OpenLocationCode

  test "handles standard cases from CSV" do
    assert OpenLocationCode.encode(-41.2730625,174.7859375) === "4VCPPQGP+Q9"
    assert OpenLocationCode.encode(-89.5,-179.5, 4) === "22220000+"
    assert OpenLocationCode.encode(-89.9999375,-179.9999375) === "22222222+22"
    assert OpenLocationCode.encode(0.5,179.5, 4) === "6VGX0000+"
    assert OpenLocationCode.encode(1,1) === "6FH32222+22"
  end

  test "handles edge cases from CSV" do
    assert OpenLocationCode.encode(90,1, 4) === "CFX30000+"
    assert OpenLocationCode.encode(92, 1, 4) === "CFX30000+"

    #assert OpenLocationCode.encode(1,180, 4) === "62H20000+"
    #assert OpenLocationCode.encode(1,181, 4) === "62H20000+"
    
    assert OpenLocationCode.encode(90,1) === "CFX3X2X2+X2"
    assert OpenLocationCode.encode(1.2,3.4) === "6FH56C22+22"
  end
  
end
