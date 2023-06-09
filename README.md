# CRASH - Completely Risky Active-Directory Simulation Hub
Author: Dahvid Schloss

Phone number: (281) 330-8004 (call it I dare you)




## The Unintentional IT Administrator(v1.0) (aka ADGenny)
### This PowerShell script generates a set of random users and populates them into Active Directory. It creates Organizational Units (OUs) and corresponding groups based on predefined department names, then assigns users to these groups. Users are given randomly generated names, passwords, and titles specific to their department.
Features

  -  Generates 100 random users with unique names and passwords
  -  Creates OUs and corresponding groups for departments such as HR, Finance, Marketing, IT, Executives, and Programmers
  -  Assigns users to respective groups and gives them titles specific to their department
  -  Assigns a unique "Director" title to a random user in each department
  -  Creates the users in Active Directory and adds them to their respective groups

### Usage

   - Install the Active Directory module for PowerShell if you haven't already
   - Run the script in a PowerShell environment with Domain Admin privileges (just do ./adgenny.ps1)
   - Watch the script generate and populate random users in your Active Directory

### Version

Current version: 1.0

##### Patch Notes: 
  - what can I say its 1.0

### Planned Improvements

   - Add more departments and roles to better mimic real-world organizations
   - Implement user-friendly customization of departments, roles, and user counts through either arguments or a config file
   - Generate user email addresses (would be cool if we could fake Exchange entirely but who's got time for that"
   - Optimize the script to minimize web requests to the Fake Name Generator API (when using more than 100 calls)
   - Add error handling for cases where the Fake Name Generator API is not accessible or rate-limited (or error handling in general, but like if it works it works)
   - Improve the script's performance by optimizing loops and string manipulation (you got a slow computer then this bad boy goes mad slow)


## ADversary Builder(v1.0)
### This PowerShell script designed to create random vulnerabilities for users within an Active Directory (AD) environment. The script generates a vulnerable_users.csv file, which can be used on workstations set up for your Range or Capture the Flag (CTF) exercises. It is intended to help security professionals assess and improve their organization's security posture.

   - Sets weak passwords for randomly selected users from a wordlist
   - Creates Kerberoastable users with weak passwords
   - Grants LAPS access to users in a specified Organizational Unit (OU) and assigns them weak passwords

### !!NOTE!! To make this work you need a wordlist, Suggest importing Rockyou.txt from your Kali Linux instance to the local CRASH folder. I can't figure out how to import files larger than 100mb and Rockyou is 110mb.

### Usage

   - Install the Active Directory module for PowerShell if you haven't already
   - Import the script into the current PowerShell Instance
   - Run Set-RandomWeakPasswordsForUsers first
   - Follow up with  New-KerberoastableUsers and/or  Grant-LAPSAccess (if LAPS is configured)

### Version

Current version: 1.0

##### Patch Notes: 
  - Inital Commit

### Planned Improvements

   - Add more user vulnerabilites
   - Implement user-friendly wrapper function to run functions at random
   - Implement fucntions to create Workstaion Vulnerabilites within AD
   - Implement functions to create LSASS entries into workstaitons from the vulnerable users csv


## Please feel free to contribute to this project by submitting pull requests or opening issues for any bugs or feature requests.
