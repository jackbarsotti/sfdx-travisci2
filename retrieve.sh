#! /bin/bash
# Provide basic information about the current build type
echo
echo "Travis event type: $TRAVIS_EVENT_TYPE"
echo "Current branch: $TRAVIS_BRANCH"
echo

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

# Delete the contents of force-app folder before we paste source:retrieve contents into it
echo
echo $(rm -rfv force-app/main/default/*)
echo
echo 'The contents of the force-app directory have been removed.'
echo "Ready to retrieve org files to your $TRAVIS_BRANCH branch."
echo

# Create variables for frequently-referenced file paths and branches
export classPath=force-app/main/default/classes
export triggerPath=force-app/main/default/triggers
sudo mkdir -p /Users/jackbarsotti/sfdx-travisci2/$classPath
sudo mkdir -p /Users/jackbarsotti/sfdx-travisci2/$triggerPath

# Run a source:retrieve to rebuild the contents of the force-app folder (branch specific)
export RETRIEVED_FILES=$(sfdx force:source:retrieve -u targetEnvironment -p force-app/main/default)
sfdx force:source:retrieve -u targetEnvironment -p force-app/main/default

# Recreate "classes" and "triggers" folders and move retrieved files into them
#check syntax here and make sure it isn't superfluous for a shell script
for FILE in $RETRIEVED_FILES; do
    if [[ $FILE == *.cls ]] || [[ $FILE == *.cls-meta.xml ]]; then
        mv $FILE $classPath
    elif [[ $FILE == *.trigger ]] || [[ $FILE == *.trigger-meta.xml ]]; then
        mv $FILE $classPath
    fi;
done;
echo
echo "All retrieved class and/or trigger files have been added back to their original directories on your $TRAVIS_BRANCH branch."
echo
echo "Now adding and committing these changes to your $TRAVIS_BRANCH branch..."

# Git add . changes
git add .
echo 'Running: git add . '

# Git commit -m "auto-build" changes
#fix syntax
git commit -m "auto-build"
echo 'Running: git commit -m "auto-build"'
echo
echo "All org files have been retrieved, and the changes have been commited to your $TRAVIS_BRANCH branch."
echo "Build complete!"
echo
