<#
  This is a comment block.  You can guess how it starts and ends.
  
  When doing data comparisons, you will notice with PowerShell the symbols
   < > = or even >= <= == are not what you are looking for, unlike most
   modern languages.

  Instead we use -gt, -lt, -eq, -ne, etc.  You can find more on a quick 
    good search.  If you have used bash or assembly programming, you 
    are probably familiar with this type of notation.

  -gt greather than
  -lt less than
  -eq equal to
  -ne not equal to
  -ge greather than or equal to
  -le less than or equal to

#>

#get message from user
$message = Read-Host

#Check if the message is $null. Note that these are not case-sensitive
if($message -eq "Help")
{
  Write-Output "You asked for help"
}
elseif($message -eq "Love")
{
  Write-Output "I love you"
}
else
{
  Write-Output "You typed: $message"
}
