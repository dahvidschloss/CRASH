<# 
ADversary Builder


Description: 
This script creates random vulnerabilites for users within your AD env and adds them to a vulnerable_users.csv file
that can be used on the workstations set up for your Range or CTF. 

Author: Dahvid Schloss
Email: dahvid.schloss@echeloncyber.com
Date: 2023-28-03

Don't be stupid and run this in a live envionrment, seems like common sense, but like....have you met some people's children.  
#>



# Import the Active Directory module
Import-Module ActiveDirectory
$rootDomain = $env:USERDNSDOMAIN.split('.')[1]
$subDomain = $env:USERDNSDOMAIN.split('.')[0]





function Get-RandomLine {
    #function for iterating through a world list that is line deliminated 
    param (
        $Path
    )

    $lineCount = 0
    # Did you know that Get-Content is so trash and inefficent if you try to load rockyou.txt and only have 1-2GB of ram you could bluescreen
    # So instead we use .Net's suprior StreamReader to read it. This is my life now. I read MS documentaiton... who reads comments anyways
    $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $Path

    #get the amount of lines...seems ineffecient and it is but it doesn't crash.
    while ($reader.ReadLine() -ne $null) {
        $lineCount++
    }

    $reader.Close()

    # Pick a number between 1 and what ever is max and don't tell me.
    $randomLineNumber = Get-Random -Minimum 1 -Maximum $lineCount

    # now lets go get a random word
    $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $Path
    $currentLine = 1
    $randomLine = $null

    while (($line = $reader.ReadLine()) -ne $null) {
        if ($currentLine -eq $randomLineNumber) {
            $randomLine = $line
            break
        }
        $currentLine++
    }

    $reader.Close()

    return $randomLine
}

function Disable-ADPasswordComplexity {
    # Get the default domain password policy
    $defaultDomainPasswordPolicy = Get-ADDefaultDomainPasswordPolicy
    
    # Disable password complexity requirements
    Set-ADDefaultDomainPasswordPolicy -Identity $defaultDomainPasswordPolicy -ComplexityEnabled $false

    #Hardest function ever.
    Write-Host "[+] Password complexity requirements have been disabled."
}

function Enable-ADPasswordComplexity {
    # Get the default domain password policy
    $defaultDomainPasswordPolicy = Get-ADDefaultDomainPasswordPolicy
    
    # Enable password complexity requirements
    Set-ADDefaultDomainPasswordPolicy -Identity $defaultDomainPasswordPolicy -ComplexityEnabled $true

    Write-Host "[+] Password complexity requirements have been enabled."
}

function Set-RandomWeakPasswordsForUsers {
    #Take 10 random users and set their passwords to something easy to crack from a wordlist
    param (
        $WordlistPath = (Join-Path -Path (Get-Location).Path -ChildPath "rockyou.txt"),
        $NumberOfUsers = 10
    )

    # Disable the AD Password complexity so we don't have issues
    Disable-ADPasswordComplexity

    # Retrieve all AD users
    $AllUsers = Get-ADUser -Filter * -Properties Enabled | Where-Object { $_.Enabled -eq $true }

    # Randomly select 10 users
    $RandomUsers = $AllUsers | Get-Random -Count $NumberOfUsers

    # Prepare the usersWithWeakPasswords array
    $usersWithWeakPasswords = @()

    # Set weak passwords from the RockYou wordlist for the selected users
    foreach ($user in $RandomUsers) {
        #So even when you disable the AD password complexity rules it will still tell you F no snake on certain passwords so we check to see if the password was
        #properly applied and if it wasn't we go back through the loop
        $success = $false
        while (-not $success) {
            try {
                $weakPassword = Get-RandomLine -Path $WordlistPath
                $securePassword = ConvertTo-SecureString -String $weakPassword -AsPlainText -Force
                Set-ADAccountPassword -Identity $user -Reset -NewPassword $securePassword
                Write-Host "[+] Assigned weak password ($weakPassword) from wordlist to user: $($user.SamAccountName)"
                $success = $true
                
                # Create a custom object with user's username and weak password
                $userInfo = [PSCustomObject]@{
                    Username      = $user.SamAccountName
                    WeakPassword  = $weakPassword
                }

                # Add the custom object to the usersWithWeakPasswords array
                $usersWithWeakPasswords += $userInfo
            }
            catch [Microsoft.ActiveDirectory.Management.ADPasswordComplexityException] {
                Write-Host "[!] Failed to assign password ($weakPassword) to user: $($user.SamAccountName). Retrying..." -ForegroundColor Red
            }
        }
    }

    # Write those users to the CSV file. We will use this later in a script to be run on a workstation host
    $csvOutputPath = (Join-Path -Path (Get-Location).Path -ChildPath "vulnerable_users.csv")
    $usersWithWeakPasswords | Export-Csv -Path $csvOutputPath -NoTypeInformation

    Write-Host "[+] User information has been saved to: $csvOutputPath"
}


function New-KerberoastableUsers {
    # Everyone's favorite AD abuse is back baby! Now you get to do it for real
    param(
        $OU = "OU=IT,DC=$subDomain,DC=$rootDomain",
        $WordListPath = (Join-Path -Path (Get-Location).Path -ChildPath "rockyou.txt"),
        $NumberOfAccounts = 2
    )
    $kerberoastableUsersWithWeakPasswords = @()

    # Disable the AD Password complexity so we don't have issues
    Disable-ADPasswordComplexity

    # Create kerberoastable users
    $services = @("SQL", "FileShare", "Backup", "Printer", "Web", "Mail")
    
    for ($i = 1; $i -le $NumberOfAccounts; $i++) {
        # Generate a service account username
        $userExists = $true
        while ($userExists) {
            # Generate a service account username
            $serviceName = (Get-Random -InputObject $services)
            $username = "svc_$($serviceName)_$i"
            # I was getting annoyed from testing where it would generate the same name and then get stuck in a loop so this checks to see if the user exists first
            # If it does generate a new user
            $userExists = Get-ADUser -Filter "samAccountName -eq '$username'" -ErrorAction SilentlyContinue
        }
        # So even when you disable the AD password complexity rules it will still tell you F no snake on certain passwords so we check to see if the password was
        # properly applied and if it wasn't we go back through the loop
        $success = $false
        while (-not $success) {
            $weakPassword = Get-RandomLine -Path $WordListPath
            $securePassword = ConvertTo-SecureString -String $weakPassword -AsPlainText -Force
            try {
                $user = New-ADUser -Name $username -SamAccountName $username -UserPrincipalName "$username@$rootDomain.$subDomain" -AccountPassword $securePassword -Path $OU -Enabled $true -PasswordNeverExpires $true -PassThru
                Write-Host "[+] Assigned weak password ($weakPassword) from wordlist to user: $($user.SamAccountName)"
                $success = $true
            }
            catch [Microsoft.ActiveDirectory.Management.ADPasswordComplexityException] {
                Write-Host "[!] Failed to assign password ($weakPassword) to user: $($user.SamAccountName). Retrying..." -ForegroundColor Red
            }
        }
        # Set SPN to make the user Kerberoastable
        Set-ADUser -Identity $user -ServicePrincipalNames @{Add="$username/$username.$rootDomain.$subDomain"}

        # Output the created user and their password
       $userInfo = [PSCustomObject]@{
            Username      = $user.samAccountName
            WeakPassword  = $weakPassword
        }
        # Add the user information to the kerberoastableUsersWithWeakPasswords array
        $kerberoastableUsersWithWeakPasswords += $userInfo
    }
    # Append the Kerberoastable users and passwords to the existing vulnerable_users.csv file
    $csvOutputPath = (Join-Path -Path (Get-Location).Path -ChildPath "vulnerable_users.csv")
    $kerberoastableUsersWithWeakPasswords | Export-Csv -Path $csvOutputPath -NoTypeInformation -Append
    Write-Host "[+] User information has been saved to: $csvOutputPath"
}

function Test-LAPSConfiguration {
    # Check if LAPS module is installed
    $lapsModule = Get-Module -ListAvailable -Name AdmPwd.PS
    if (-not $lapsModule) {
        Write-Host "[!] LAPS module not found. LAPS is not installed or not properly configured." -ForegroundColor Red
        return
    }

    # Import LAPS module
    Import-Module AdmPwd.PS

    # Check if LAPS schema extension is present
    try {
        Get-ADObject -Filter "lDAPDisplayName -eq 'ms-Mcs-AdmPwd'" -SearchBase (Get-ADRootDSE).SchemaNamingContext -ErrorAction Stop
    }
    catch {
        Write-Host "[!] LAPS schema extension not found. LAPS is not properly configured." -ForegroundColor Red
        return
    }

    # Check for LAPS Group Policy settings
    $lapsGpoFound = $false
    $gpos = Get-GPO -All
    foreach ($gpo in $gpos) {
        $lapsSettings = Get-GPRegistryValue -Name $gpo.DisplayName -Key "HKLM\SOFTWARE\Policies\Microsoft Services\AdmPwd" -ValueName "PasswordAgeDays" -ErrorAction SilentlyContinue
        if ($lapsSettings) {
            $lapsGpoFound = $true
            Write-Host "[+] LAPS Group Policy found: $($gpo.DisplayName)" -ForegroundColor Green
        }
    }

    if (-not $lapsGpoFound) {
        Write-Host "[!] LAPS Group Policy not found. LAPS may not be properly configured." -ForegroundColor Red
    }

    # Check for LAPS permissions on computer objects
    $computerOUs = Get-ADOrganizationalUnit -Filter *
    $lapsPermissionFound = $false
    foreach ($ou in $computerOUs) {
        $lapsPermissions = Find-AdmPwdExtendedRights -Identity $ou -ErrorAction SilentlyContinue
        if ($lapsPermissions) {
            $lapsPermissionFound = $true
            Write-Host "[+] LAPS permissions found for OU: $($ou.Name)" -ForegroundColor Green
        }
    }

    if (-not $lapsPermissionFound) {
        Write-Host "[!] LAPS permissions not found on any OU. LAPS may not be properly configured." -ForegroundColor Red
    }
}

function Grant-LAPSAccess {
    # take 2 users from the programmers OU and make it so they have the ability to read laps, because this is something i've actually seen on a red team and had to go...why?
    # Doesn't work if you don't have LAPS already configured. 
    param(
        $OU = "OU=Programmers,DC=$subDomain,DC=$rootDomain",
        $LAPSGroup = "LAPS Admins",
        $WordlistPath = (Join-Path -Path (Get-Location).Path -ChildPath "rockyou.txt")
    )

   # Call the Test-LAPSConfiguration function to check if LAPS is installed and configured
   $lapsConfigured = Test-LAPSConfiguration

   if (-not $lapsConfigured) {
       return
   }

    # Get users from the Programmers OU
    $users = Get-ADUser -Filter * -SearchBase $OU

    # Select 2 random users
    $RandomUsers = $users | Get-Random -Count 2

    # Prepare the usersWithWeakPasswords array
    $usersWithWeakPasswords = @()

    foreach ($user in $RandomUsers) {
        #So even when you disable the AD password complexity rules it will still tell you F no snake on certain passwords so we check to see if the password was
        #properly applied and if it wasn't we go back through the loop
        $success = $false
        while (-not $success) {
            try {
                $weakPassword = Get-RandomLine -Path $WordListPath
                $securePassword = ConvertTo-SecureString -String $weakPassword -AsPlainText -Force
                
                Set-ADAccountPassword -Identity $user -Reset -NewPassword $securePassword
                
                Write-Host "[+] Assigned weak password ($weakPassword) from wordlist to user: $($user.SamAccountName)"
                $success = $true

                # create an object with user/pass
                $userInfo = [PSCustomObject]@{
                    Username      = $user.samAccountName
                    WeakPassword  = $weakPassword
            }

                # Add the custom object to the usersWithWeakPasswords array
                $usersWithWeakPasswords += $userInfo
            }
            catch [Microsoft.ActiveDirectory.Management.ADPasswordComplexityException] {
                Write-Host "[!] Failed to assign password ($weakPassword) to user: $($user.SamAccountName). Retrying..." -ForegroundColor Red
            }
        # Add user to the LAPSGroup
        Add-ADGroupMember -Identity $LAPSGroup -Members $user

        # Create a custom object with user's username and weak password
  
        }
    }
    # Append the users with weak passwords to the existing vulnerable_users.csv file
    $csvOutputPath = (Join-Path -Path (Get-Location).Path -ChildPath "vulnerable_users.csv")
    $usersWithWeakPasswords | Export-Csv -Path $csvOutputPath -NoTypeInformation -Append
    Write-Host "[+] User information has been saved to: $csvOutputPath"
}

