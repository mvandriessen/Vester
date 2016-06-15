#requires -Modules VMware.VimAutomation.Core
#requires -Version 1 -Modules Pester

Invoke-Expression -Command (Get-Item -Path 'Config.ps1')
[string]$drsmode = $global:config.cluster.drsmode
[int]$drslevel = $global:config.cluster.drslevel


Describe -Name 'Cluster Configuration: DRS Settings' -Fixture {
    foreach ($cluster in (Get-Cluster)) 
    {
        It -name "$($cluster.name) Cluster DRS Mode" -test {
            $value = (Get-Cluster $cluster).DrsAutomationLevel
            try 
            {
                $value | Should Be $drsmode
            }
            catch 
            {
                Write-Warning -Message "Fixing $cluster - $_"
                Set-Cluster -Cluster $cluster -DrsAutomationLevel:$drsmode -Confirm:$false
            }
        }
        It -name "$($cluster.name) Cluster DRS Automation Level" -test {
            $value = (Get-Cluster $cluster | Get-View).Configuration.DrsConfig.VmotionRate
            try 
            {
                $value | Should Be $drslevel
            }
            catch 
            {
                Write-Warning -Message "Fixing $cluster - $_"
                $clusterview = Get-Cluster -Name $cluster | Get-View
                $clusterspec = New-Object -TypeName VMware.Vim.ClusterConfigSpecEx
                $clusterspec.drsConfig = New-Object -TypeName VMware.Vim.ClusterDrsConfigInfo
                $clusterspec.drsConfig.vmotionRate = $drslevel
                $clusterview.ReconfigureComputeResource_Task($clusterspec, $true)
            }
        }
    }
}