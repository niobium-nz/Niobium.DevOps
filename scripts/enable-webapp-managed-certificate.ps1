$ErrorActionPreference = 'Stop'
Install-Module Az.Websites
New-AzWebAppCertificate -ResourceGroupName $env:ResourceGroupName -WebAppName $env:FunctionAppName -Name $env:FunctionAppName -HostName $env:CustomDomainName -AddBinding -SslState 'SniEnabled'