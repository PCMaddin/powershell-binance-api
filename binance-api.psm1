class Binance {
 [String] $usedapiserver
 [String] $ApiSecret
 [String] $ApiKey
 [long] $timediff

 Binance([String]$newApiKey,[String]$newApiSecret){
  $this.Set_ApiCredentials($newApiKey,$newApiSecret)
  $this.choose_ApiServer() 
 [long]$servertime=$this.Get_Time()
[long]$mytime=((New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds)
 [int]$this.timediff =$mytime - $servertime
  }
 Binance(){
 $this.choose_ApiServer()
 [long]$servertime=$this.Get_Time()
[long]$mytime=((New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds)
 [int]$this.timediff =$mytime - $servertime
 }

 [int]update_timediff(){
 [long]$servertime=$this.Get_Time()
[long]$mytime=((New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds)
 [int]$this.timediff =$mytime - $servertime
 return $this.timediff
 }
 
 $binanceapiserver=("api.binance.com",
"api1.binance.com",
"api2.binance.com",
"api3.binance.com")
$websocketserver="wss://stream.binance.com:9443"
[PSCustomObject]action([String] $function, [String] $data,[bool] $sendapikey, [bool] $signquery,[String] $Method){ 
if($null -eq $data){ $result=Invoke-Webrequest  "https://$($this.usedapiserver)/api/v3/$($function)";}
else{
if($signquery){
$signature=$this.Sign($data)
$result= (Invoke-Webrequest  -Method $Method -Headers @{'X-MBX-APIKEY' = $($this.ApiKey)} "https://$($this.usedapiserver)/api/v3/$($function)?$data&signature=$signature")}
else { if($sendapikey){$result= (Invoke-Webrequest -Headers @{'X-MBX-APIKEY' = $($this.ApiKey)} "https://$($this.usedapiserver)/api/v3/$($function)?$data")}else{$result= (Invoke-Webrequest  "https://$($this.usedapiserver)/api/v3/$($function)?$data") }}
}
Write-Host "Used 1m weight:$(($result.rawcontent -split "`n" -match "x-mbx-used-weight-1m" -split ":").item(1).trim())"
return $result
}
[PSCustomObject]get([String] $function, [String] $data,[bool] $sendapikey, [bool] $signquery){ 
 return ($this.action($function,$data,$sendapikey,$signquery,"GET"))
}
[PSCustomObject]get([String] $function, [String] $data,[bool] $sendapikey){ return ($this.get($function,$data,$true,$false))}
[PSCustomObject]get([String] $function, [String] $data){ return ($this.get($function,$data,$false,$false))}
[PSCustomObject]get([String] $function){ return ($this.get($function,"",$false,$false))}
[PSCustomObject]post([String] $function, [String] $data,[bool] $sendapikey, [bool] $signquery){ 
 return ($this.action($function,$data,$sendapikey,$signquery,"POST"))
}
[PSCustomObject]delete([String] $function, [String] $data,[bool] $sendapikey, [bool] $signquery){ 
 return ($this.action($function,$data,$sendapikey,$signquery,"DELETE"))
}


[String]sign([String] $message){$hmacsha = New-Object System.Security.Cryptography.HMACSHA256
$hmacsha.key = [Text.Encoding]::ASCII.GetBytes($this.ApiSecret)
$signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes("$message"))
return $signature = [System.BitConverter]::ToString($signature) -replace '-', ''
}
[long]Get_Time(){ return ($this.get("time")|ConvertFrom-Json).ServerTime}
[String]Choose_ApiServer(){
$resultlist =@()
foreach($apiserver in $this.binanceapiserver)
{
$StartTime = $(get-date)
$ProgressPreference="SilentlyContinue"
 Invoke-Webrequest  "https://$apiserver/api/v3/ping" -Method Get | Out-Null
 $milliseconds=($(New-TimeSpan -Start $StartTime -End $(get-date))).Milliseconds
 $serverresult= New-Object -TypeName "PSCustomObject"
 $serverresult| Add-Member -type NoteProperty -Name "APIServer" -value $apiserver
 $serverresult| Add-Member -type NoteProperty -Name "ResponseTime" -value $milliseconds
 $resultlist+=$serverresult
 }
 $this.usedapiserver=($resultlist| Sort-Object ResponseTime |Select-Object APIServer -First 1).APIServer
 return "API Server is set to: $($this.usedapiserver)"
 }
[void]Set_ApiServer([String]$newApiServer){ $this.usedapiserver=$newApiServer}
[void]Set_ApiCredentials([String]$newApiKey,[String]$newApiSecret){ $this.ApiKey=$newApiKey;$this.ApiSecret=$newApiSecret}
[PSCustomObject]Exchange_Info() { return ($this.get("exchangeInfo") | ConvertFrom-Json) }
[PSCustomObject]price_ticker(){ return ($this.get("ticker/price") | ConvertFrom-Json) }
[PSCustomObject]price_ticker([String] $symbol){ return ($this.get("ticker/price","symbol=$Symbol") | ConvertFrom-Json) }
[double]get_currency_balance([String] $symbol){
[long]$timestamp=(New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds - $this.timediff 

return (($this.get("account","timestamp=$timestamp",$true,$true) | ConvertFrom-Json).balances | Where-Object { $_.asset -eq $symbol}).free
}
[PSCustomObject]get_balance(){
[long]$timestamp=(New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds - $this.timediff 

return (($this.get("account","timestamp=$timestamp",$true,$true) | ConvertFrom-Json).balances)
}
[PSCustomObject]depth([String] $symbol, [int] $limit){ return ($this.get("depth","symbol=$Symbol&limit=$limit") | ConvertFrom-Json) }
[PSCustomObject]depth([String] $symbol){ return ($this.get("depth","symbol=$Symbol") | ConvertFrom-Json) }
[PSCustomObject]trades([String] $symbol,[int] $limit){ return ($this.get("trades","symbol=$Symbol&limit=$limit") | ConvertFrom-Json) }
[PSCustomObject]trades([String] $symbol){ return ($this.get("trades","symbol=$Symbol") | ConvertFrom-Json) }
[PSCustomObject]historicalTrades([String] $symbol,[int] $limit, [int]$fromID){ return ($this.get("historicalTrades","symbol=$Symbol&limit=$limit&fromID=$fromID",$true) | ConvertFrom-Json) }
[PSCustomObject]historicalTrades([String] $symbol,[int] $limit){ return ($this.get("historicalTrades","symbol=$Symbol&limit=$limit",$true) | ConvertFrom-Json) }
[PSCustomObject]historicalTrades([String] $symbol){ return ($this.get("historicalTrades","symbol=$Symbol",$true) | ConvertFrom-Json) }
[PSCustomObject]avg_price([String] $symbol){ return ($this.get("avgPrice","symbol=$Symbol") | ConvertFrom-Json) }
[PSCustomObject]ticker24hr(){ return ($this.get("ticker/24hr") | ConvertFrom-Json) }
[PSCustomObject]ticker24hr([String] $symbol){ return ($this.get("ticker/24hr","symbol=$Symbol") | ConvertFrom-Json) }
[PSCustomObject]bookticker(){ return ($this.get("ticker/bookTicker") | ConvertFrom-Json) }
[PSCustomObject]bookticker([String] $symbol){ return ($this.get("ticker/bookTicker","symbol=$Symbol") | ConvertFrom-Json) }
[PSCustomObject]aggTrades([String] $symbol,[int] $limit, [int]$fromID,[long] $starttime, [long] $endtime){ return ($this.get("aggTrades","symbol=$Symbol&limit=$limit&fromID=$fromID&StartTime=$starttime&endtime=$endtime",$true) | ConvertFrom-Json) }
[PSCustomObject]aggTrades([String] $symbol,[int] $limit, [int]$fromID){ return ($this.get("aggTrades","symbol=$Symbol&limit=$limit&fromID=$fromID",$true) | ConvertFrom-Json) }
[PSCustomObject]aggTrades([String] $symbol,[int] $limit){ return ($this.get("aggTrades","symbol=$Symbol&limit=$limit",$true) | ConvertFrom-Json) }
[PSCustomObject]klines([String] $symbol,[string] $interval, [int]$limit,[long] $starttime, [long] $endtime ){ return ($this.get("klines","symbol=$Symbol&limit=$limit&interval=$interval&StartTime=$starttime&endtime=$endtime",$true) | ConvertFrom-Json) }
[PSCustomObject]klines([String] $symbol,[string] $interval, [int]$limit){ return ($this.get("klines","symbol=$Symbol&limit=$limit&interval=$interval",$true) | ConvertFrom-Json) }
[PSCustomObject]klines([String] $symbol,[string] $interval){ return ($this.get("klines","symbol=$Symbol&interval=$interval",$true) | ConvertFrom-Json) }
[PSCustomObject]myTrades([String] $symbol,[long] $recvWindow, [int]$limit,[long] $starttime, [long] $endtime ){[long]$timestamp=(New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds - $this.timediff; return ($this.get("myTrades","symbol=$Symbol&limit=$limit&timestamp=$timestamp&StartTime=$starttime&endtime=$endtime&recvWindow=$recvWindow",$true,$true) | ConvertFrom-Json) }
[PSCustomObject]myTrades([String] $symbol,[long] $recvWindow, [int]$limit){[long]$timestamp=(New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds - $this.timediff; return ($this.get("myTrades","symbol=$Symbol&limit=$limit&timestamp=$timestamp&recvWindow=$recvWindow",$true,$true) | ConvertFrom-Json) }
[PSCustomObject]myTrades([String] $symbol){[long]$timestamp=(New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds - $this.timediff; return ($this.get("myTrades","symbol=$Symbol&timestamp=$timestamp",$true,$true) | ConvertFrom-Json) }
[PSCustomObject]newLimitOrder([String] $symbol,[double] $quantity, [String] $ordertype, [String] $side, [double] $price, [string] $timeInForce ){[long]$timestamp=(New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds - $this.timediff; return ($this.post("order","symbol=$Symbol&type=$ordertype&side=$side&price=$($price -replace ",",".")&quantity=$($quantity -replace ",",".")&timeInForce=$timeInForce&timestamp=$timestamp",$true,$true) | ConvertFrom-Json) }
#[PSCustomObject]newLimitOrder([String] $symbol,[double] $quantity, [String] $ordertype, [String] $side, [double] $price, [string] $timeInForce ){[long]$timestamp=(New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds - $this.timediff; return ($this.post("order","symbol=$Symbol&type=$ordertype&side=$side&price=$price&quantity=$quantity&timeInForce=$timeInForce&timestamp=$timestamp",$true,$true) | ConvertFrom-Json) }
#[PSCustomObject]newMarketOrder([String] $symbol,[double] $quantity, [String] $ordertype, [String] $side, [double] $price, [string] $timeInForce ){[long]$timestamp=(New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds - $this.timediff; return ($this.post("order","symbol=$Symbol&type=$ordertype&side=$side&price=$price&quantity=$quantity&timeInForce=$timeInForce&timestamp=$timestamp",$true,$true) | ConvertFrom-Json) }
#[PSCustomObject]newMarketOrder([String] $symbol,[double] $quantity, [String] $ordertype, [String] $side, [double] $price, [string] $timeInForce ){[long]$timestamp=(New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds - $this.timediff; return ($this.post("order","symbol=$Symbol&type=$ordertype&side=$side&price=$price&quantity=$quantity&timeInForce=$timeInForce&timestamp=$timestamp",$true,$true) | ConvertFrom-Json) }
[PSCustomObject]cancelOrder([String] $symbol,[long] $orderId){[long]$timestamp=(New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds - $this.timediff; return ($this.delete("order","symbol=$Symbol&timestamp=$timestamp&orderId=$orderId",$true,$true) | ConvertFrom-Json) }
[PSCustomObject]queryOrder([String] $symbol,[string] $orderId){[long]$timestamp=(New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds - $this.timediff; return ($this.get("order","symbol=$Symbol&orderId=$orderId&timestamp=$timestamp",$true,$true) | ConvertFrom-Json) }
[PSCustomObject]cancelOpenOrders([String] $symbol){[long]$timestamp=(New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds - $this.timediff; return ($this.delete("openOrders","symbol=$Symbol&timestamp=$timestamp",$true,$true) | ConvertFrom-Json) }
[PSCustomObject]queryOpenOrders([String] $symbol){[long]$timestamp=(New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds - $this.timediff; return ($this.get("openOrders","symbol=$Symbol&timestamp=$timestamp",$true,$true) | ConvertFrom-Json) }
[PSCustomObject]queryOpenOrders(){[long]$timestamp=(New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds - $this.timediff; return ($this.get("openOrders","timestamp=$timestamp",$true,$true) | ConvertFrom-Json) }
[PSCustomObject]allOrders([String] $symbol){[long]$timestamp=(New-TimeSpan -Start "01.01.1970" -End $(Get-Date)).TotalMilliSeconds - $this.timediff; return ($this.get("allOrders","symbol=$Symbol&timestamp=$timestamp",$true,$true) | ConvertFrom-Json) }

}
