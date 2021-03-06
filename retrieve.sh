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
# rm -rfv will display the output of rm
rm -rfv force-app/main/default/*
echo
echo 'The contents of the force-app directory have been removed.'
echo "Ready to retrieve org metadata to your $TRAVIS_BRANCH branch."
echo

# Create variables for frequently-referenced file paths
# Recreate "classes" and "triggers" folders for retrieved metadata files
export classPath=force-app/main/default/classes
export triggerPath=force-app/main/default/triggers
sudo mkdir -p /Users/jackbarsotti/sfdx-travisci2/$classPath
sudo mkdir -p /Users/jackbarsotti/sfdx-travisci2/$triggerPath

# Run a source:retrieve to rebuild the contents of the force-app folder (branch specific)

# do i really need this: export RETRIEVED_FILES=$(sfdx force:source:retrieve -u targetEnvironment -m ApexClass)
sfdx force:source:retrieve -u targetEnvironment -m ApexClass,ApexTrigger
echo
echo "All retrieved metadata files have been added to the force-app directory on your $TRAVIS_BRANCH branch."
echo
echo "Now adding and committing these changes to your $TRAVIS_BRANCH branch..."

# Prepare to run a git commit and git push
git config --global user.email "travis@travis-ci.org"
git config --global user.name "Travis CI"
git add force-app/.
git checkout master

# Git commit -m "auto-build" changes
echo
echo 'Running: git commit -m "auto-build"'
git commit -q -m "auto-build"
echo "New commit made: $(git log -1 --oneline)"
echo
echo "All metadata files have been retrieved, and the changes have been commited to your $TRAVIS_BRANCH branch."
echo 'Run "git pull" on your local machine to update your local branch with the new changes.'
echo
echo "Build complete!"
echo

# Add the remote origin a push changes to rebuild master branch
git remote add origin-master https://${GH_TOKEN}@github.com/jackbarsotti/sfdx-travisci2.git > /dev/null 2>&1
git push --quiet --set-upstream origin-master master
