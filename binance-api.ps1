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

##EXAMPLE FOR A ORDER TO BUY AT ACTUAL PRICE
$tradepair ="BTCUSDT"
$quantity = 0.001    #Number of Coins
$buyprice=[DOUBLE]($bt.price_ticker($tradepair).price)
$order=$bt.newLimitOrder($tradepair,$quantity,"LIMIT","BUY",$buyprice,"GTC")
WHILE(!($bt.queryOrder("$tradepair",($order.orderID)).status -eq "FILLED")){Start-Sleep 1}

##SAME JUST WITH USDT INSTEAD OF COIN
$tradepair ="BTCUSDT"
$balance=50
$buyprice=[DOUBLE]($bt.price_ticker($tradepair).price)
$quantity = $quantity=[Math]::Floor((($balance / $buyprice)*10000))/10000    #Number of Coins
$order=$bt.newLimitOrder($tradepair,$quantity,"LIMIT","BUY",$buyprice,"GTC")
WHILE(!($bt.queryOrder("$tradepair",($order.orderID)).status -eq "FILLED")){Start-Sleep 1}
