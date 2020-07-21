#! /bin/bash
# Provide basic information about the current build type
echo $TRAVIS_EVENT_TYPE
echo $TRAVIS_PULL_REQUEST
echo $TRAVIS_PULL_REQUEST_BRANCH

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

# Create temporary diff folder to paste files into later for incremental deployment
  # This is the deploy directory (see below in before_script)
sudo mkdir -p /Users/jackbarsotti/sfdx-travisci2/force-app/main/default/diff
# Pull our local branches so they exist locally
# We are on a detached head, so we keep track of where Travis puts us
export build_head=$(git rev-parse HEAD)
echo $build_head
# Overwrite remote.origin.fetch to fetch the remote branches (overrides Travis's --depth clone)
git config --replace-all remote.origin.fetch +refs/heads/*:refs/remotes/origin/*
git fetch
# Create variables for frequently-referenced file paths and branches
export BRANCH=$TRAVIS_BRANCH
export branch=$TRAVIS_BRANCH
echo $TRAVIS_BRANCH
export userPath=/Users/jackbarsotti/sfdx-travisci2/force-app/main/default
export diffPath=/diff/force-app/main/default
# For a full build, deploy directory should be "- export DEPLOYDIR=force-app/main/default":
export DEPLOYDIR=/Users/jackbarsotti/sfdx-travisci2/force-app/main/default/diff
export classPath=force-app/main/default/classes
export triggerPath=force-app/main/default/triggers


sfdx force:source:retrieve -u targetEnvironment -p force-app/main/default
