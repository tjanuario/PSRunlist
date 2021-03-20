# PSRunlist

 PSRunlist is a framework for running automation powershell scripts.  The strength of the system comes
 from it's ability to use dynamically determine attributes of the system at run-time based on the parameters
 that are passed in at the command-line.

Prerequisites:
1. Install the latest version of PowerShell (windows) or PowerShell Core (linux)
2. Install other Powershell libraries that will be needed (ex. AWSPowerShell.NetCore for AWS or Az for Azure) and configure them (This is outside of the context of this readme.  ... Read the docs.)

To Install PowerShell-RunbookCollection
1. Clone the Powershell-RunbookCollection repository which this readme is a part of
2. Open a powershell console
3. CD to the root of the repository and execute `./executeTests.ps1 -publish`

## How it works...
In its simplest form, the command-line looks like this:
```powershell
    New-Runlist -Names myRunbook | Invoke-Runlist
```
The New-Runlist commandlet is able to find all runbooks that are in the present working directory or any descendent directories.  It uses the
-Names parameter to determine which of those runbooks are being called explicitly and then loads those runbooks and any dependencies into the
return object which can then be passed to Invoke-Runlist or analyzed in order to ensure that the loaded properties are as expected.  Invoke-Runlist
executes the runbooks.

### Attributes  
There are three types of attributes:
parameters attributes - loaded based on the value of the New-Runlist parameter of the same name.  
runbook attributes - basic attribute definitions defined by the runbooks.  These are contained in an .\attributes folder and all files are loaded.  
additional config - attributes that are passed in at run-time in order to add or over-ride parameter or runbook attributes.  

### Parameters 
There are two fixed parameters of New-Runlist.  
- -Names : an array of strings that explicitly state which runbooks to execute  
- -AdditionalConfig : either the path to a json file or a json string that defines attributes  

There are also dynamic parameters, which are defined by the runbooks themselves.  They do not exist until the -Names parameter has been  
assigned a valid runbook name.  Once that happens, the runbook is immediately loaded, and the parameters defined in the runbook's initialization file (..\runbookDirectory\runbook.json)
 are loaded and any defined parameters are added.  

### Runbook Collection  
A runbook collection is defined as a directory with a file named runbook.json in it.  This file identifies the directory as a runbook and allows certain components  
of the runbook to be defined.  

The following example is complete and defines the 'runbook1' runbook collection.  A directory named runbook1 contains a file named runbook.json with the following  json content.  It 
defines a required parameter name -Environment that accepts the value 'development' or 'innovation, a dependency on a different runbook collection  (named runbook2), a derived runbook 
made up of two other runbooks, and an autorun runbook which will run every time this runbook is loaded.  

```json
{
    "parameters": [
        {
            "Name": "Environment",
            "Type": "string",
            "Mandatory": true,
            "ValidateSet": [
                "development",
                "innovation"
            ]
        }
    ],
    "dependencies": [
        "runbook2"
    ],
    "runbooks": {
        "default": [
            "runbook1::foo",
            "runbook1::bar"
        ]
    },
    "autorun": [
        "runbook1::autorun"
    ]
}
```

What this means is that if this runbook were called directly, it would have the following minimum command-line:
`New-Runlist -Names runbook1 -Environment development | Invoke-Runlist`

At run-time, it will load the runbook1 runbook, as well as the runbook 'runbook2' on which it is dependent.  This means that any attributes defined in 
runbook2 will be available to runbook1.  This would be important if runbook2 creates a resource that runbook1 depends on.  The attributes in runbook2 might
define the name of the resource it creates, and runbook1 will need to make a connection to that resource.  The attribute value in each resource can be controlled 
by the -Environment parameter in order to create sandboxing between the two environments (development and innovation).  This could be done,
for example by runbook2 defining the attribute 
```json
$attributes.runbook2.resourceName = "$(Environment)_runbook2Resource"
```
or more likely in the file ..\runbook2\attributes\anyNameWorks.json like:
```json
{
  "default_attributes" : {
    "runbook2": {
      "resourceName": "$(Environment)_runbook2Resource"
    }
}
```
Using the command-line above,
this would derive as "development_runbook2Resource" which runbook1 can access by asking for $attribute.runbook2.resourceName .

Runbooks are loaded and processed in order.  In our above example, we are calling a play in runbook1.  Without explicitly defining the runbook we will call by using the
 runbookCollection::runbook naming standard, the runbook defaults to runbookCollection::default.  The runbook1::default runbook in the above json is derived from two other runbooks, 
 runbook1::foo and runbook::bar.  Runbook1 has a dependency on runbook2, so runbook2 default_attributes are loaded before runbook1 default attributes.  When all runbook 
 default attributes have been loaded, the override attributes are then procesed in the same order which allows attributes to be overridden.  A runbook might define an 
 attribute that we want to be different for a specific environment.  Override attributes allow this to be done.  Parameter attributes are loaded first, followed by 
 additional config attributes, and finally runbookCollection attributes.

### Runbook  
A runbook can be described in two ways.  The primary method is by creating a file in the .\runbook directory.  A file named foo.ps1 in the runbook1\runbook directory is 
referenced as runbook1::foo and the file bar.ps1 in the same directory is referenced as runbook1::bar.

The second way a runbook can be described is in the runbook.json file as the default runbook is described in the above json.  The default runbook is comprised of the two runbooks 
mentioned in the previous paragraph.  By executing runbook1::default, both runbook1::foo and runbook1::bar will be executed.  This allows us to string several runbooks 
together as a single runbook for convenience.  The three following command-lines are functionally identical:
```
New-Runlist -Names runbook1::foo, runbook1::bar -Environment development | Invoke-Runlist
New-Runlist -Names runbook1::default -Environment development | Invoke-Runlist
New-Runlist -Names runbook1 -Environment development | Invoke-Runlist (when no play is appended to the runbook name, the play 'default' is implied)
```

`New-Runlist -Names runbook1::bar, runbook1::foo -Environment development | Invoke-Runlist` is not functionally identical to the three above command-lines because the order 
of execution has changed so that runbook1::bar (.\runbook1\plays\bar.ps1) is executed before runbook1::foo (.\runbook1\plays\foo.ps1).

The autorun section of runbook.json defines a runbook that will run every time the runbook is loaded.  This means even if the runbook is loaded as a dependency and not 
directly referenced in the -Names parameter.  These are rarely used.  An example of a good use of the autorun field is to call a runbook that logs the user into a service 
for a group of runbooks that work with the service.  

A parent runbookCollection (a runbook that contains subdirectories that contain runbookCollections) will be loaded when the child is loaded as if it were a dependency of the child.  This 
allows runbookCollections to be grouped, for example, around a common parameter or autorun runbook.  A parent runbookCollection can define a parameter and every child will inherit it, or the 
parent might have an autorun that will be executed every time a child runbookCollectoin is executed (or loaded).

### Analysis of a loaded runlist (new-runlist)
The contents of a loaded runlist can be analyzed by passing the object returned to other commandlets.  This is often done using the following commands:
```Powershell
$runlist = New-Runlist -Names myrunlist
$runlist | Format-Json
```
Or, if we want to specifically look at a part of the runbook, like the runbook.attributes collection:
```Powershell
$runlist = New-Runlist -Names myrunlist
$runlist.attributes | Format-Json
```
This last one can also be done more succintly as:
```Powershell
(New-Runlist -Names myrunlist).attributes | Format-Json
```