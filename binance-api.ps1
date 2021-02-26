## THESE ARE USING EXAMPLES -> Important file binance-api.psm1
Using module .\binance-api.psm1 #Mandatory! change in containing directory before you run your skript <---- NEEEED
$starttime=Get-date #for measure runtime
$global:progressPreference = 'silentlyContinue' #Better performance and looks better <---- BETTER IF

$key="YOUR_API_KEY"   #<---- NEEEED
$secret="YOUR_API_SECRET"    #<---- NEEEED

$bt= [Binance]::new($key,$secret) #Mandatory! Create a New Binance Connection Object <---- NEEEED
$balance = $bt.get_currency_balance("BTC")
$depth = $bt.depth("ETHBTC")
$trades =$bt.trades("ETHBTC")
$exchangeinfo =$bt.Exchange_Info()
$ratelimits=$exchangeinfo.rateLimits
$allticker=$bt.ticker24hr()
Write-Output (new-timespan -Start $starttime -End $(Get-Date)) #for measure runtime

Pause(30)


##EXAMPLE FOR MARKET CAP FILTER IN BOTS : copy to new script and uncomment

#Using module .\binance-api.psm1
#$global:progressPreference = 'silentlyContinue' #Better performance and looks better 
#$key="YOUR_API_KEY"   #<---- NEEEED
#$secret="YOUR_API_SECRET"    #<---- NEEEED
#$bt= [Binance]::new($key,$secret)
#$allticker=$bt.ticker24hr()
#$bridge="BUSD"
#($allticker| Where{ $_.symbol -like "*$bridge"  }| Where { $( [double]$_.quoteVolume) -gt 5000000}).symbol.replace("$bridge","") | Out-File supported_coinlist.txt
