# CRASH - Completely Risky Active-Directory Simulation Hub
Author: Dahvid Schloss

Phone number: (281) 330-8004 (call it I dare you)




## The Unintentional IT Administrator(v1.1) (aka ADGenny)
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
  1.0
  - what can I say its 1.0
  1.1
  - Made UserArray a global varriable

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

### Requirements

To make this work you need a wordlist, Suggest importing Rockyou.txt from your Kali Linux instance to the local CRASH folder. I can't figure out how to import files larger than 100mb and Rockyou is 110mb.

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

## Fake File Share(v1.0)(FFS.ps1)
### This PowerShell script creates a simulated corporate file share environment with randomly generated documents.Fake File Share is designed to create a realistic-looking file structure with various documents in an Active Directory (AD) environment. It uses OpenAI to generate document content and names, creating an authentic experience for training or testing purposes.

   - Creates .docx,.csv, and .txt files
   - Can use GPT3-5-Turbo or GPT-4

### Requirments
  - This script requires MS Office be installed on the host that is running FakeFileShare.
  - Also don't run in admin mode, no idea why but it told me to F off when I was testing

### Usage

- Import the file to the instance
  `. .\FFS.ps1`
- Run the script
  `Generate-FakeFileShare -APIKey 'SK-\<API KEY\>' `

- Other options include
   - "-RootPath" = This will allow you change the path where the folders will be created. Default is "C:\CorporateFileShare"
   - "-Model" = This will allow you to chose between GPT3-5 and GPT4
   - "-MaxTokens" = This will allow you to change the size of the return. Max is set to 4000 (this is the deafult too) due to call request limits
   - "-Verbose" = If you really want to see all those reponses and stuff
   - "-Debug" = if you are running into weird issues this should allow you to see if the documents are opening and saving
- If you want to add more departments edit line 167 


### Version

Current version: 1.0

##### Patch Notes: 
  - Inital Commit


### Planned Improvements
   - Add more error checks
   - Add ability to create PowerPoint documents
   - Add the ability to create PDF docuuments
   - Add the ability to pull from AD to grab random users in departments and dynamically create a few files for them too. 

## Please feel free to contribute to this project by submitting pull requests or opening issues for any bugs or feature requests.
