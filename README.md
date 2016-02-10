# ePortal to Active Directory student accounts

This is a PowerShell script for automatically populating Active Directory with users added to Facility ePortal.

It creates user accounts in the form ```firstname.lastname.2digitYear```, e.g. ``brian.henry.15``. Double-barreled names are hyphenated and apostrophes are removed, e.g. Brian Henry O'Farrell becomes ```brian.henry-ofarrell.15```.

Some settings need to be specified at the top of the script:

```
# Your ePortal/Facility server
$server = "MIS"
```
No need for FQDN here.

```
# The database name, default is CMIS_ADMIN
$database = "CMIS_ADMIN"
```
The Facility SQL database name. I can't imagine many cases where it's not the default.

```
# Students' base OU (without the domain)
$studentsOU = 'ou=Students,ou=Users,ou=PrimaryOU'
```
The OU in which each year's OU then student accounts will be created. The OU structure I've been using is:

![OU screenshot](https://github.com/BrianHenryIE/ePortal-to-AD/blob/master/ADUC-OUs.png)

```
# Default password. They'll be forced to change it at first logon
# It must meet the password complexity requirements for AD
$defaultPassword = "Password1"
```
It's currently set to store the passwords with reversible encryption.
## Scheduled task
I have this set to run as a scheculed task every Sunday. On one of your servers, navigate to Task Scheduler in Server Manager (or run ```Taskschd.msc```)), in Task Scheduler Library, click "Create Task", configure the name and Triggers as you wish. Add a new Action, "Start a Program"; under "Program/Script" enter ```powershell.exe```; and in "Add arguments" enter ```-ExecutionPolicy Bypass -file "path\to\script\eportal-to-ad-scheduled-task.ps1"```. Then under the General tab, use "Change User or Group" to select a user with enough privileges to access the database and manage Active Directory, select "Run whether the user is logged in or not" and select "Run with highest privleges".
##Status/Caveats
This appears to be working fine for me so I'm happy to share it. It really just tries to add every account each time it's run and if it fails on one because the account exists, it's no big deal. It does the same for creating the OUs. If students are removed from ePortal, their accounts are not removed from Active Directory, e.g. if a students name is misspelled and corrected. It checks back six years into ePortal.