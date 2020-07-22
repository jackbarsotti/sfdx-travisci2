#! /bin/bash
# Provide basic information about the current build type
echo "Travis event type: $TRAVIS_EVENT_TYPE"
echo "Current branch: $TRAVIS_BRANCH"

# Install sfdx plugins and configure build with sfdx settings
export SFDX_AUTOUPDATE_DISABLE=false
export SFDX_USE_GENERIC_UNIX_KEYCHAIN=true
export SFDX_DOMAIN_RETRY=300
export SFDX_DISABLE_APP_HUB=true
export SFDX_LOG_LEVEL=DEBUG
mkdir sfdx
wget -qO- $URL | tar xJ -C sfdx --strip-components 1
"./sfdx/install"
export PATH=./sfdx/$(pwd):$PATH
sfdx --version
sfdx plugins --core

# Authenticate against correct org
if [ "$TRAVIS_BRANCH" == "uat" ]; then
  echo $SFDXAUTHURLUAT>authtravisci.txt;
elif [ "$TRAVIS_BRANCH" == "master" ]; then
  echo $SFDXAUTHURL>authtravisci.txt;
fi;

# Set the target environment for force:source:retrieve command
sfdx force:auth:sfdxurl:store -f authtravisci.txt -a targetEnvironment

# Create variables for frequently-referenced file paths and branches
export classPath=force-app/main/default/classes
export triggerPath=force-app/main/default/triggers
sudo mkdir -p /Users/jackbarsotti/sfdx-travisci2/$classPath
sudo mkdir -p /Users/jackbarsotti/sfdx-travisci2/$triggerPath

# Delete the contents of force-app folder before we paste source:retrieve contents into it
echo
#echo $(rm -rfv force-app/main/default/*)
echo
echo 'The contents of the force-app directory have been deleted.'
echo "Ready to retrieve org files to your "$TRAVIS_BRANCH" branch."
echo

# Run a source:retrieve to rebuild the contents of the force-app folder (branch specific)
export RETRIEVED_FILES=$(sfdx force:source:retrieve -u targetEnvironment -p force-app/main/default)
sfdx force:source:retrieve -u targetEnvironment -p force-app/main/default

# Recreate "classes" and "triggers" folders and move retrieved files into them
#check syntax here and make sure it isn't superfluous for a shell script
for FILE in $RETRIEVED_FILES; do
    if [[ $FILE == *.cls ]] || [[ $FILE == *.cls-meta.xml ]]; then
        
        echo "Moved $FILE file to $classPath directory."
    elif [[ $FILE == *.trigger ]] || [[ $FILE == *.trigger-meta.xml ]]; then
        
        echo "Moved $FILE file to $triggerPath directory."
    fi;
done;
echo
echo 'All retrieved files have been moved to their original folders for this branch.'
echo

# Git add . changes
#git add .
echo 'git add . '

# Git commit -m "auto-build" changes
#fix syntax
#git commit -m "auto-build"
echo 'git commit -m "auto-build"'
