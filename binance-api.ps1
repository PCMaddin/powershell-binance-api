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

 $binanceapiserver=("api.binance.com",
"api1.binance.com",
"api2.binance.com",
"api3.binance.com")

[PSCustomObject]get([String] $function, [String] $data,[bool] $sendapikey, [bool] $signquery){ 
if($data -eq $null){ $result=Invoke-Webrequest  "https://$($this.usedapiserver)/api/v3/$($function)";}
else{
if($signquery){
$signature=$this.Sign($data)
$result= (Invoke-Webrequest  -Method GET -Headers @{'X-MBX-APIKEY' = $($this.ApiKey)} "https://$($this.usedapiserver)/api/v3/$($function)?$data&signature=$signature")}
else { if($sendapikey){$result= (Invoke-Webrequest -Headers @{'X-MBX-APIKEY' = $($this.ApiKey)} "https://$($this.usedapiserver)/api/v3/$($function)?$data")}else{$result= (Invoke-Webrequest  "https://$($this.usedapiserver)/api/v3/$($function)?$data") }}
}
Write-Host "Used 1m weight:$(($result.rawcontent -split "`n" -match "x-mbx-used-weight-1m" -split ":").item(1).trim())"
return $result
}
[PSCustomObject]get([String] $function, [String] $data,[bool] $sendapikey){ return ($this.get($function,$data,$true,$false))}
[PSCustomObject]get([String] $function, [String] $data){ return ($this.get($function,$data,$false,$false))}
[PSCustomObject]get([String] $function){ return ($this.get($function,"",$false,$false))}
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

return (($this.get("account","timestamp=$timestamp",$true,$true) | ConvertFrom-Json).balances | Where { $_.asset -eq $symbol}).free
}
[PSCustomObject]depth([String] $symbol, [int] $limit){ return ($this.get("depth","symbol=$Symbol&limit=$limit") | ConvertFrom-Json) }
[PSCustomObject]depth([String] $symbol){ return ($this.get("depth","symbol=$Symbol") | ConvertFrom-Json) }
[PSCustomObject]trades([String] $symbol,[int] $limit){ return ($this.get("trades","symbol=$Symbol&limit=$limit") | ConvertFrom-Json) }
[PSCustomObject]trades([String] $symbol){ return ($this.get("trades","symbol=$Symbol") | ConvertFrom-Json) }

}

$key="YOURKEY"
$secret=YOURSECRET"

$bt= [Binance]::new()
$bt.Set_ApiCredentials($key,$secret)
$balance = $bt.get_currency_balance("BTC")
$depth = $bt.depth("ETHBTC")
$trades =$bt.trades("ETHBTC")
$exchangeinfo =$bt.Exchange_Info()
$ratelimits=$exchangeinfo.rateLimits
