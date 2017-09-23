. .\hPi.ps1
. .\Convert-StringToUInt32Arr.ps1

class Test{

    Test($hPi){
        $this.Init($hPi)
    }
    
    <#############################################
        Initilizes S and P box values using
        hexidecimal Pi values
    
    
    ###############################################>
    [void]init($hPi){
       $this.P = New-Object uint32[] $this.Plength
       $this.S = New-Object uint32[][] $this.SlengthW,$this.SlengthH

       $hPi = Convert-StringToUInt32Arr -Str $hPi

       for([uint32]$i = 0; $i -lt $this.Plength; $i++){
            $this.P[$i] = $($hPi[$i])
       }

       [uint32]$i = $this.Plength
       for([uint32]$w = 0; $w -lt $this.SlengthW; $w++){
            for([uint32]$h = 0; $h -lt $this.SlengthH; $h++){
                $this.S[$w][$h] = $hPi[$i++]
            }
       }
    }

    <#############################################
        Creates new P box values using key
    
    
    ###############################################>
    [void]generateSubKeys($key){
        if($key.Length -lt 4){
            throw "Key is less than 32bits"
        }

        $keyLength = [math]::Ceiling($key.Length / 4)
        $arrOf32bitStrs = New-Object uint32[] $keyLength

        #Create 32bit elements for array out of the str.  For example "xyzuv" will be broken into {xyzu},{v000}
        for([uint16]$i = 0; $i -lt $key.Length; $i += 4){

            [uint32]$tempBlock = 0

            $tempBlock = ($tempBlock -bor [uint32](Convert-CharToUnicode -char $key[0]) -shl 24)
            if(($i+1) -lt $key.Length) { $tempBlock = ($tempBlock -bor [uint32](Convert-CharToUnicode -char $key[1]) -shl 16) }
            if(($i+2) -lt $key.Length) { $tempBlock = ($tempBlock -bor [uint32](Convert-CharToUnicode -char $key[2]) -shl 8) }
            if(($i+3) -lt $key.Length) { $tempBlock = ($tempBlock -bor [uint32](Convert-CharToUnicode -char $key[3])) }

            $arrOf32bitStrs[$i / 4] = $tempBlock

        }

        for([uint16]$i = 0; $i -lt $this.P.Length; $i++){
            $this.P[$i] = $this.P[$i] -bxor $arrOf32bitStrs[$i%4]
        }

        [uint32]$R = 0
        [uint32]$L = 0
        for([uint16]$i = 0; $i -lt $this.Plength; $i += 2){
            $this._encrypt([ref]$L, [ref]$R)
            $this.P[$i] = $L
            $this.P[$i+1] = $R
        }

        for([uint16]$i = 0; $i -lt $this.SlengthW; $i++){
            for([uint16]$j = 0; $j -lt $this.SlengthH; $j += 2){
                $this._encrypt([ref]$L, [ref]$R)
                $this.S[$i][$j] = $L
                $this.S[$i][$j+1] = $R
            }
        }
    }

    <#############################################
       Encrypt the message and convert it to Base64
       This also splits the message into 64bit chunks
       and splits it into 32bit halves
    
    
    ###############################################>
    [string]encrypt([string]$msg){
    
        [string]$cryptedData = ""
 
        for([uint16]$i = 0; $i -lt $msg.Length; $i+=8){

            [uint32] $L = $this.get32Batch($msg, $i)
            [uint32] $R = $this.get32Batch($msg, $i+4)


            $this._encrypt([ref]$L, [ref]$R)
            $cryptedData += $this.ConvertToString($L,$R)
        }
 

        $Bytes = [System.Text.Encoding]::Unicode.GetBytes($cryptedData)

        return [Convert]::ToBase64String($Bytes)
    }

    <#############################################
       Decrypts the message after first decoding base64
       This also splits the message into 64bit chunks
       and splits it into 32bit halves        
    
    
    ###############################################>
    [string]decrypt([string]$cryptedMsg){

        $cryptedMsg = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($cryptedMsg))

        [string]$msg = ""

        for([uint32]$i=0; $i -lt $cryptedMsg.length; $i+=8){
            [uint32]$L = $this.get32Batch($cryptedMsg, $i);
            [uint32]$R = $this.get32Batch($cryptedMsg, $i+4);
 
            $this._decrypt([ref]$L, [ref]$R);
            $msg += $this.ConvertToString($L,$R)
        }
 
 
        return $msg
    }

    <#############################################
        The bowfish funciton.  Uses -band to 
        cut the overflow off
    
    
    ###############################################>
    hidden [uint32]f([uint32] $x){

        $h = ($this.S[0][$x -shr 24] + $this.S[1][$x -shr 16 -band 0xff])
        $h = $h -band 0xffffffff

        $h = $h -bxor $this.S[2][$x -shr 8 -band 0xff]
        $h = $h -band 0xfffffff

        $h = $h + $this.S[3][$x -band 0xff]
        $h = $h -band 0xfffffff 

        return $h
    }

    <#############################################
        hidden encrypt function that does the 
        actual blowfish algorithmic encryption
    
    
    ###############################################>
    hidden [void]_encrypt([ref]$L, [ref]$R){
        for([uint16]$i = 0; $i -lt ($this.Plength - 2); $i += 2){
            $L.Value = $L.Value -bxor $this.P[$i]
            $R.Value = $R.Value -bxor $this.f($L.Value)
            $R.Value = $R.Value -bxor $this.P[$i + 1]
            $L.Value = $L.Value -bxor $this.f($R.Value)
        }

        $L.Value = $L.Value -bxor $this.P[$this.Plength - 2]
        $R.Value = $R.Value -bxor $this.P[$this.Plength - 1]

        $temp = $L.Value
        $L.Value = $R.Value
        $R.Value = $temp
    }

    <#############################################
        hidden decrypt function that does the 
        actual blowfish algorithmic encryption        
    
    
    ###############################################>
    hidden [void]_decrypt([ref]$L, [ref]$R){

        for([uint16]$i = ($this.Plength - 2); $i -gt 0; $i -= 2){
            $L.Value = $L.Value -bxor $this.P[$i+1]
            $R.Value = $R.Value -bxor $this.f($L.Value)
            $R.Value = $R.Value -bxor $this.P[$i]
            $L.Value = $L.Value -bxor $this.f($R.Value)
        }

        $L.Value = $L.Value -bxor $this.P[1]
        $R.Value = $R.Value -bxor $this.P[0]

        $temp = $L.Value
        $L.Value = $R.Value
        $R.Value = $temp
    }

    <#############################################
        Takes data and creates a 32bit chunk
        based on the startVal specified
    
    
    ###############################################>
    hidden [uint32]get32Batch([string]$data, [uint32]$startVal){
        [uint32]$result = 0

        for($i=$startVal; $i -lt $startVal+4; $i++){
            $result = $result -shl 8
            if($i -lt $data.Length){
                $result = $result -bor ($data[$i] -band 0xff)
            }
        }

        return $result
    }

    <#############################################
        Converts $L and $R values to a string
    
    
    ###############################################>
    hidden [string]ConvertToString([uint32]$L,[uint32]$R){
        
        [string]$result = ""

        $result += [char]($L -shr 24 -band 0xFF)
        $result += [char]($L -shr 16 -band 0xFF)
        $result += [char]($L -shr 8 -band 0xFF)
        $result += [char]($L -band 0xFF)

        $result += [char]($R -shr 24 -band 0xFF)
        $result += [char]($R -shr 16 -band 0xFF)
        $result += [char]($R -shr 8 -band 0xFF)
        $result += [char]($R -band 0xFF)

        return $result
    }

    #Properties
    hidden [uint32]$Plength = 18
    hidden [uint32]$SlengthW = 4
    hidden [uint32]$SlengthH = 256

    hidden [uint32[]]$P
    hidden [uint32[][]]$S
}

$key = "randomkey1231"
$test = [Test]::new($hPi)
$test.generateSubKeys("$key")

$msg = "This message will be encrypted and decrypted"
$msgE = $test.encrypt($msg)
$msgD = $test.decrypt($msgE)

Write-Output "Key: $Key`n"
Write-Output "OriginalMsg:`n $msg"
Write-Output "***********************`n"
Write-Output "Encrypted Message:`n"
Write-Output $msgE
Write-Output "`n*********************"
Write-Output "Decrypted Message:`n"
Write-Output $msgD
