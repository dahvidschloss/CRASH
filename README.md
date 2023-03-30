#The Unintentional IT Administrator(v1.0) (aka ADGenny)
##Author: Dahvid Schloss
##phone number: (281) 330-8004

##This PowerShell script generates a set of random users and populates them into Active Directory. It creates Organizational Units (OUs) and corresponding groups based on predefined department names, then assigns users to these groups. Users are given randomly generated names, passwords, and titles specific to their department.
Features

  -  Generates 100 random users with unique names and passwords
  -  Creates OUs and corresponding groups for departments such as HR, Finance, Marketing, IT, Executives, and Programmers
  -  Assigns users to respective groups and gives them titles specific to their department
  -  Assigns a unique "Director" title to a random user in each department
  -  Creates the users in Active Directory and adds them to their respective groups

##Usage

   - Install the Active Directory module for PowerShell if you haven't already
   - Run the script in a PowerShell environment with Domain Admin privileges (just do ./adgenny.ps1)
   - Watch the script generate and populate random users in your Active Directory

Version

Current version: 1.0
Planned Improvements

   - Add more departments and roles to better mimic real-world organizations
   - Implement user-friendly customization of departments, roles, and user counts through either arguments or a config file
   - Generate user email addresses (would be cool if we could fake Exchange entirely but who's got time for that"
   - Optimize the script to minimize web requests to the Fake Name Generator API (when using more than 100 calls)
   - Add error handling for cases where the Fake Name Generator API is not accessible or rate-limited (or error handling in general, but like if it works it works)
   - Improve the script's performance by optimizing loops and string manipulation (you got a slow computer then this bad boy goes mad slow)

Please feel free to contribute to this project by submitting pull requests or opening issues for any bugs or feature requests.
