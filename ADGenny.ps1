# Author: Dahvid Schloss
# Email: dahvid.schloss@echeloncyber.com
# Date: 2023-21-11
# Description: This script creates 100  random  users, creates OUs, and coorelating groups. 
Import-Module ActiveDirectory

# Set Variables
$path = "https://www.fakenamegenerator.com/gen-random-us-us.php"
$global:UserArray = @{}
$rootDomain = $env:USERDNSDOMAIN.split('.')[1]
$subDomain = $env:USERDNSDOMAIN.split('.')[0]
$OUs = "HR", "Finance", "Marketing", "IT", "Executives", "Programmers"
$Groups = "HR", "Finance", "Marketing", "IT", "Executives", "Programmers"
$global:IT = @()
$global:HR = @()
$global:Marketing = @()
$global:Executives = @()
$global:Finance = @()
$global:Programmers = @()
$global:AssignedExecTitles = @()

#Titles to be assigned 
$HRRoles = @("HR Specialist", "Recruiter", "HR Coordinator", "HR Manager", "Payroll Specialist")
$FinanceRoles = @("Accountant", "Financial Analyst", "Controller", "Finance Manager", "Bookkeeper")
$ITRoles = @("IT Support", "IT Analyst", "Network Administrator", "IT Manager", "Systems Administrator")
$MarketingRoles = @("Marketing Specialist", "Marketing Coordinator", "Marketing Manager", "Social Media Specialist", "Content Creator")
$ProgrammersRoles = @("Software Developer", "Web Developer", "QA Analyst", "Programmer Analyst", "Software Architect")

#Clean up some of the strings
Function Clean-String ($inputString) {
    return ($inputString -replace '[^a-zA-Z]', '').Trim()
}

#Does what it says it does
Function Create-OUs {
    Foreach ($o in $OUs) {
        New-ADOrganizationalUnit -Name $o -ProtectedFromAccidentalDeletion $False -Verbose
    }
}

#Time to get banned from Fake Name Generator by calling it 100 times in 5 seconds or less.
function Generate-Users {
    $Interations = 0

    While ($Iterations -ne 100) {
        $request = Invoke-WebRequest -UseBasicParsing -Uri $path

        # Get the Unparsed Name
        $unparsedname = $request.content.split("`r`n") | Select-String -Pattern "<h3>"
        # now parse the name
        $FullName = $unparsedname -replace ".*<h3>" -replace "</h3>.*"
        # Split the full name into multiple variables for easy ingestion into the array
        $FirstName, $MiddleIn, $LastName = $FullName.split(" ")
        # Grab the Password
        $RawPassword = ($request.content.split("`r`n") | Select-String -Pattern "<dd>")[10]
        # Parse the Password
        $UserPassword = $RawPassword -replace ".*<dd>" -replace "</dd>.*"

        $ADusername = $FirstName.Substring(0, 1) + $LastName
        while ($UserArray.ContainsKey($ADusername)) {
            $ADusername = $ADusername + (Get-Random -Minimum 1 -Maximum 3)
        }

        $global:UserArray[$ADusername] = @{
            FirstName    = $FirstName
            MiddleInitial = $MiddleIn
            LastName     = $LastName
            Password     = $UserPassword
        }

        $FullName
        $Iterations++
    }
}

#Now take all those users and throw them into either IT, Finance, HR, Execs, Marketing, or Programmings, because you know, no other section exists
function Populate-Groups {
    $randomOrder = $UserArray.Keys | Sort-Object {Get-Random}
    $randomOrder | Out-Null
    $total = $UserArray.Count
    $n = 0

#this equals 1 aka 100 so 10,20,10,10,20,30 if you change the numer in $iterations it will change how many each get, but you know the worlds your oyster. I feel like 100 is a good size
#user base for small CTFs or Ranges because hoenstly are you really going to configure a ton of miconfigurations for more than 15 people? 
$ITTotal = $total * .1
$FinanceTotal = $total * .2
$HRTotal = $total * .1
#keep the Execs at 10 or else not everony is going to have a title
$ExecutivesTotal = $total * .1
$MarketingTotal = $total * .2
$ProgrammersTotal = $total *.3

   
    write-host "IT"
    while ($n -ne $ITTotal) { 
        
        $user = $randomOrder[$n]
        $global:IT += $user
        Assign-RandomRole $user "IT"
        $n++
    }
    #DEBUGGING uncomment to DEBUG
    #$global:IT
    #write-host "ITTotal:$($ITTotal)  Count:$($global:IT.Count)"
    #Read-Host -Prompt "Press Enter to continue"

    write-host "Finance"
    while ($n -ne $ITTotal + $FinanceTotal) {
        $user = $randomOrder[$n]
        $global:Finance += $user
        Assign-RandomRole $user "Finance"
        $n++
    }
    #DEBUGGING uncomment to DEBUG
    #$global:Finance
    #write-host "FinanceTotal:$($FinanceTotal)  Count:$($global:Finance.Count)"
    #Read-Host -Prompt "Press Enter to continue"
    
    write-host "HR"
    while ($n -ne $ITTotal + $FinanceTotal + $HRTotal) { 
        $user = $randomOrder[$n]
        $global:HR += $user
        Assign-RandomRole $user "HR"
        $n++
    }
    #DEBUGGING uncomment to DEBUG
    #$global:HR
    #write-host "HRTotal:$($HRTotal)  Count:$($global:HR.Count)"
    #Read-Host -Prompt "Press Enter to continue"

    Write-Host "Executives"
    while ($n -ne $ITTotal + $FinanceTotal + $HRTotal + $ExecutivesTotal) {
        $user = $randomOrder[$n]
        $global:Executives += $user
        Assign-ExecutiveTitle $user
        $n++
    }
    #DEBUGGING uncomment to DEBUG
    #$global:Executives
    #write-host "ExecTotal:$($ExecutivesTotal)  Count:$($global:Executives.Count)"
    #Read-Host -Prompt "Press Enter to continue"

    Write-Host "Marketing"
    while ($n -ne $ITTotal + $FinanceTotal + $HRTotal + $ExecutivesTotal + $MarketingTotal) {
        $user = $randomOrder[$n]
        $global:Marketing += $user
        Assign-RandomRole $user "Marketing"
        $n++
    }
    #DEBUGGING uncomment to DEBUG
    #$global:Marketing
    #write-host "MarketingTotal:$($MarketingTotal)  Count:$($global:Marketing.Count)"
    #Read-Host -Prompt "Press Enter to continue"

    Write-Host "Programming"
    while ($n -ne $total) {
        $user = $randomOrder[$n]
        $global:Programmers += $user
        Assign-RandomRole $user "Programmers"
        $n++
    }
    #DEBUGGING uncomment to DEBUG
    #$global:Programmers
    #write-host "ProgrammersTotal:$($ProgrammersgTotal)  Count:$($global:Programmers.Count)"
    #Read-Host -Prompt "Press Enter to continue"
}


#Assign a role from one of the keys set from the roles above
function Assign-RandomRole($user, $OU) {
    if (!$user) { return }
    $roles = $null
    switch ($OU) {
        "IT" { $roles = $ITRoles }
        "HR" { $roles = $HRRoles }
        "Finance" { $roles = $FinanceRoles }
        "Marketing" { $roles = $MarketingRoles }
        "Programmers" { $roles = $ProgrammersRoles }
    }
    if ($roles -and $roles.Count -gt 0 -and $UserArray.ContainsKey($user)) {
        $randomRole = $roles | Get-Random
        $UserArray[$user].Role = $randomRole
    }
}

#Take a random user in each OU and make one a Director
function Assign-DirectorTitle($OU) {
    $usersInOU = $null
    switch ($OU) {
        "IT" { $usersInOU = $IT }
        "HR" { $usersInOU = $HR }
        "Finance" { $usersInOU = $Finance }
        "Marketing" { $usersInOU = $Marketing }
        "Programmers" { $usersInOU = $Programmers }
    }
    if ($usersInOU -and $usersInOU.Count -gt 0) {
        $directorUser = $usersInOU | Get-Random
        if (-not ($UserArray[$directorUser].Role -like "Director of*")) {
            $UserArray[$directorUser].Role = "Director of $OU"
        }
    }
}

#Make sure all 10 users get a unique Cheif Position because you can't have two CEOs
function Assign-ExecutiveTitle($user) {
    if (!$user) { return }
    if ($UserArray.ContainsKey($user)) {
        $execTitles = @("CEO", "CFO", "COO", "CTO", "CMO", "CHRO", "CSO", "CRO", "CIO", "CISO")
        $availableTitles = $execTitles | Where-Object { $AssignedExecTitles -notcontains $_ }
        
        if ($availableTitles.Count -gt 0) {
            $randomTitle = $availableTitles | Get-Random
            $UserArray[$user].Role = $randomTitle
            $global:AssignedExecTitles += $randomTitle
        } else {
            Write-Host "Error: All executive titles have been assigned."
        }
    }
}

Function Create-Groups {
    Foreach ($g in $Groups) {
        New-ADGroup -Name $g -GroupCategory Security -GroupScope Global -Verbose
    }
}

#This is the meat and potatoes of the script. We make all our users in AD here. 
Function Create-Users {
    foreach ($User in $UserArray.Keys) {
        $samAccountName = $User
        $givenName = Clean-String $UserArray[$User].FirstName
        $initials = Clean-String $UserArray[$User].MiddleInitial
        $sn = Clean-String $UserArray[$User].LastName
        $password = $UserArray[$User].Password
        $title = $UserArray[$User].Role

        $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
        
    $OUPath = ""
    if ($IT -contains $User) {
    $OUPath = "OU=IT,DC=$subDomain,DC=$rootDomain"
    } 
    elseif ($HR -contains $User) {
    $OUPath = "OU=HR,DC=$subDomain,DC=$rootDomain"
    } 
    elseif ($Marketing -contains $User) {
    $OUPath = "OU=Marketing,DC=$subDomain,DC=$rootDomain"
    } 
    elseif ($Executives -contains $User) {
    $OUPath = "OU=Executives,DC=$subDomain,DC=$rootDomain"
    } 
    elseif ($Finance -contains $User) {
    $OUPath = "OU=Finance,DC=$subDomain,DC=$rootDomain"
    } 
    elseif ($Programmers -contains $User) {
    $OUPath = "OU=Programmers,DC=$subDomain,DC=$rootDomain"}



        $newUser = @{
            SamAccountName = $samAccountName
            UserPrincipalName = "$samAccountName@$env:USERDNSDOMAIN"
            GivenName = $givenName
            Initials = $initials
            Surname = $sn
            Enabled = $true
            DisplayName = "$givenName $sn"
            Name = "$givenName $sn"
            Path = $OUPath
            AccountPassword = $securePassword
            ChangePasswordAtLogon = $false
            PasswordNeverExpires = $true
            Description = $title
        }
        
        #DEBUGGING uncomment to DEBUG 
        #Write-Host "User: $samAccountName | IT: $($IT -contains $User) | HR: $($HR -contains $User) | Marketing: $($Marketing -contains $User) | Executives: $($Executives -contains $User) | Finance: $($Finance -contains $User) | Programmers: $($Programmers -contains $User)"

        if (![string]::IsNullOrEmpty($OUPath)) {
            New-ADUser @newUser -Verbose
        } else {
            Write-Host "Error: Could not create user $samAccountName because OUPath is empty."
        }

        # Add user to their respective group
        if ($IT -contains $User) {
            Add-ADGroupMember -Identity "IT" -Members $samAccountName
        } elseif ($HR -contains $User) {
            Add-ADGroupMember -Identity "HR" -Members $samAccountName
        } elseif ($Finance -contains $User) {
            Add-ADGroupMember -Identity "Finance" -Members $samAccountName
        } elseif ($Marketing -contains $User) {
            Add-ADGroupMember -Identity "Marketing" -Members $samAccountName
        } elseif ($Executives -contains $User) {
            Add-ADGroupMember -Identity "Executives" -Members $samAccountName
        } elseif ($Programmers -contains $User) {
            Add-ADGroupMember -Identity "Programmers" -Members $samAccountName
        }
    }
}



# Create Organizational Units
Create-OUs

# Generate Users
Generate-Users

#Create Groups
Create-Groups

# Populate Groups
Populate-Groups

# Assign Directors
foreach ($ou in $OUs) {
    Assign-DirectorTitle $ou
}

# Create Users in Active Directory
Create-Users
