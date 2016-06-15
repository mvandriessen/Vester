#requires -Modules VMware.VimAutomation.Core
#requires -Version 1 -Modules Pester

Invoke-Expression (Get-Item 'Config.ps1')
[array]$esxntp = $global:config.host.esxntp

Describe -Name 'Host Configuration: NTP Server(s)' -Fixture {
    foreach ($server in (Get-VMHost)) 
    {
        It -name "$($server.name) Host NTP settings" -test {
            $value = Get-VMHostNtpServer -VMHost $server
            try 
            {
                Compare-Object -ReferenceObject $esxntp -DifferenceObject $value | Should Be $null
            }
            catch 
            {
                Write-Warning "Fixing $server - $_"
                Get-VMHostNtpServer -VMHost $server | ForEach-Object -Process {
                    Remove-VMHostNtpServer -VMHost $server -NtpServer $_ -Confirm:$false
                }
                Add-VMHostNtpServer -VMHost $server -NtpServer $esxntp
                $ntpclient = Get-VMHostService -VMHost $server | Where-Object -FilterScript {
                    $_.Key -match 'ntpd'
                }
                $ntpclient | Set-VMHostService -Policy:On -Confirm:$false -ErrorAction:Stop
                $ntpclient | Restart-VMHostService -Confirm:$false -ErrorAction:Stop
            }
        }
    }
}