
#Prompt the user for an input
Write-Output "Input a value: "

#here we are reading the input from the console, and putting that value
# value into $response
$response = Read-Host

#Notice we $response is within the quotations.  You can call a variable
# mid string, and it will auto resolve its value based on that variable
Write-Output "Your value is: $response"