# Script to add users to Active Directory from eportal
#
# Adds users in the form firstname.surname.00@domain.com
#
# BrianHenryIE@gmail.com

# Your ePortal/Facility server
$server = "MIS"

# The database name, default is CMIS_ADMIN
$database = "CMIS_ADMIN"

# Students' base OU (without the domain)
$studentsOU = 'ou=Students,ou=Users,ou=PrimaryOU'

# Default password. They'll be forced to change it at first logon
# It must meet the password complexity requirements for AD
$defaultPassword = "Password1"

#######
# Script begins
#######

# Get the year this school year started
$year = get-date –format yyyy
if((get-date -Format mm) -lt 08){
	$year = $year -1
}

# Get the AD domain name
$domain = "$env:USERDNSDOMAIN".ToLower()
$dc = 'dc='+$domain.Replace(".", ",dc=")

# Ensure the OU is present
$splitOU = $studentsOU.Split(',')
$addOU = $dc
for($i=$splitOU.Length-1; $i -ge 0; $i--){
	$nextOU = $splitOU[$i]
	$addOU = "$nextOU`,$addOU"
	#Write-Host "dsadd ou `"$addOU`""
	Invoke-Expression "dsadd ou `"$addOU`""
}

# From StackOverflow
function sql([string]$sqlText, [string]$database, [string]$server)
{
    $connection = new-object System.Data.SqlClient.SQLConnection("Data Source=$server;Integrated Security=SSPI;Initial Catalog=$database");
    $cmd = new-object System.Data.SqlClient.SqlCommand($sqlText, $connection);

    $connection.Open();
    $reader = $cmd.ExecuteReader()

    $results = @()
    while ($reader.Read())
    {
        $row = @{}
        for ($i = 0; $i -lt $reader.FieldCount; $i++)
        {
            $row[$reader.GetName($i)] = $reader.GetValue($i)
        }
        $results += new-object psobject -property $row            
    }
    $connection.Close();

    $results
}



# Get each year's students and add each to AD
for($currentYear=[int]$year; $currentYear -gt [int]$year-6; $currentYear--){
 
 	$createOU = "dsadd ou `"ou=$currentYear,$studentsOU,$dc`""
	
	Invoke-Expression $createOU
 
 	$shortYear = $currentYear-2000
	
	$sqlQuery = "SELECT [Name], [ClassGroupId] FROM [$database].[STUD_ADMIN].[STUDENTS] WHERE [RuleSetId] LIKE '$currentYear%';"

	$results = sql $sqlQuery $database $server

	foreach ($student in $results){
	
		$fName = $student.Name.Split("{,}")[1].Trim()
		$fNameLower = $fName.ToLower()
		
		$sName = $student.Name.Split("{,}")[0].Trim()
		$sNameLower = $sName.ToLower()
		
		$username = "$fNameLower.$sNameLower.$shortYear"
		# Remove apostrophes
		$username = $username.Replace("``","")
		$username = $username.Replace("'","")
		
		# Hyphenate double barreled names
		$username = $username.Replace(" ","-")
		
		# AD needs a username of max length 20 for backwards compatability
		$samid = $username
		if ($samid.length -gt 20) {
			$samid = $samid.subString(0, 20)
		}
		
		$addUserCmd = "dsadd.exe user `"CN=$username,ou=$currentYear,$studentsOU,$dc`" -fn `"$fName`" -ln `"$sName`" -display `"$fName $sName`" -upn `"$username@$domain`" -reversiblepwd yes -mustchpwd yes -pwd `"$defaultPassword`" -samid `"$samid`""

		# Debug output!
		#Write-Host " "
		#Write-Host $username
		#Write-Host $addUserCmd

		Invoke-Expression $addUserCmd
	}
	
}



