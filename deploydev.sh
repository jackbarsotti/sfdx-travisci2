- echo openssl version
- sfdx force:org:display -u DEV
- sfdx force:source:deploy --wait 10 --sourcepath $DEPLOYDIR --testlevel $TESTLEVEL -u DEV
- sfdx force:apex:test:run -u DEV --wait 10