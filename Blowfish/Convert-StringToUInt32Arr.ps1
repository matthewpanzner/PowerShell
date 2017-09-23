Function Convert-StringToUInt32Arr{
    Param(
        [string]$Str = "00000000"
    )

    if($Str.Length % 8 -ne 0){
        throw "Hex number is not divisible by 8.  Length is: $($Str.Length)"
    }

    $UInt32Arr = @()

    for($i = 0; $i -lt $Str.Length; $i += 8){
        [string]$temp = "0x"

        for($j = 0; $j -lt 8; $j++){
            $temp += $Str[$i+$j]
        }

        $Uint32Arr += $temp
    }

    return $Uint32Arr
}

Function Convert-CharToASCII{
    Param(
        [char]$char = 'x'
    )

    return [byte][char]$char
}
