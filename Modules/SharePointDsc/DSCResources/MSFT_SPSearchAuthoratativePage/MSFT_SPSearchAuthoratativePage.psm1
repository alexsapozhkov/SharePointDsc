function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$SeviceAppName,

		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

		[System.Single]
		$Level,

		[ValidateSet("Authoratative","Demoted")]
		[System.String]
		$Action,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[System.Management.Automation.PSCredential]
		$InstallAccount
	)

	 Write-Verbose -Message "Getting Content Source Setting for '$Name'"

     $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
		$params = $args[0]

		$nullReturn = @{
            ServiceAppName = $params.SeviceAppName
            Path = ""
			Level = $params.Level
			Action = $params.Action
			Ensure = "Absent"
            InstallAccount = $params.InstallAccount
        }  

  		$serviceApp = Get-SPEnterpriseSearchServiceApplication -Identity $params.ServiceAppName
		if($null -eq $serviceApp)
		{
			return $nullReturn
		}

		$searchObjectLevel = [Microsoft.Office.Server.Search.Administration.SearchObjectLevel]::Ssa
		$searchOwner = New-Object Microsoft.Office.Server.Search.Administration.SearchObjectOwner($searchObjectLevel)

		if($params.Action -eq "Authoratative")
		{
			
			$queryAuthority = Get-SPEnterpriseSearchQueryAuthority -Identity $params.Path `
																   -Owner $searchOwner `
																   -SearchApplication $serviceApp `
																   -ErrorAction SilentlyContinue
			if($null -eq $queryAuthority)
			{
				return $nullReturn
			}
			else 
			{
				
				return @{
					ServiceAppName = $params.ServiceAppName
					Path = $params.Path
					Level = $queryAuthority.Level
					Action = $params.Action
					Ensure = "Present"
					InstallAccount = $params.InstallAccount
				}
			}
		}
		else 
		{
			$queryDemoted = $serviceApp | Get-SPEnterpriseSearchQueryDemoted -Identity $params.Path
			if($null -eq $queryDemoted)
			{
				return $nullReturn
			}
			else 
			{
				return @{
					ServiceAppName = $params.ServiceAppName
					Path = $params.Path
					Action = $params.Action
					Ensure = "Present"
					InstallAccount = $params.InstallAccount
				}
			}
		}

	 }
	return $result
	<#
	$returnValue = @{
		SeviceAppName = [System.String]
		Path = [System.String]
		Level = [System.Single]
		Action = [System.String]
		Ensure = [System.String]
		InstallAccount = [System.Management.Automation.PSCredential]
	}

	$returnValue
	#>
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$SeviceAppName,

		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

		[System.Single]
		$Level,

		[ValidateSet("Authoratative","Demoted")]
		[System.String]
		$Action,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[System.Management.Automation.PSCredential]
		$InstallAccount
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

	#Include this line if the resource requires a system reboot.
	#$global:DSCMachineStatus = 1


}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$SeviceAppName,

		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

		[System.Single]
		$Level,

		[ValidateSet("Authoratative","Demoted")]
		[System.String]
		$Action,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[System.Management.Automation.PSCredential]
		$InstallAccount
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."


	<#
	$result = [System.Boolean]
	
	$result
	#>
}


Export-ModuleMember -Function *-TargetResource

