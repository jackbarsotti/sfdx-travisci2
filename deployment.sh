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

# Run a git diff for the incremental build depending on checked-out branch
  # Create tracking branches
  # Copy the git diff outputted files into the deploy directory
if [ "$BRANCH" == "dev" ]; then
  echo 'Your current branches: '
  echo
  for branch in $(git branch -r|grep -v HEAD); do
      echo $branch
      git checkout -qf ${branch#origin/}
  done;
  echo
  git checkout dev

  export CHANGED_FILES=$(git diff --name-only master force-app/)
  sudo cp --parents $(git diff --name-only master force-app/) $DEPLOYDIR;

  echo
  echo 'Your changed files: '
  echo
  for FILE in $CHANGED_FILES; do
    echo ../$FILE
  done;
  echo
fi;

if [ "$BRANCH" == "qa" ]; then
  echo 'Your current branches: '
  echo
  for branch in $(git branch -r|grep -v HEAD); do
      echo $branch
      git checkout -qf ${branch#origin/}
  done;
  echo
  git checkout qa

  export CHANGED_FILES=$(git diff --name-only dev force-app/)
  sudo cp --parents $(git diff --name-only dev force-app/) $DEPLOYDIR;

  echo
  echo 'Your changed files: '
  echo
  for FILE in $CHANGED_FILES; do
    echo ../$FILE
  done;
  echo
fi;

if [ "$BRANCH" == "uat" ]; then
  echo 'Your current branches: '
  echo
  for branch in $(git branch -r|grep -v HEAD); do
      echo $branch
      git checkout -qf ${branch#origin/}
  done;
  echo
  git checkout uat

  export CHANGED_FILES=$(git diff --name-only qa force-app/)
  sudo cp --parents $(git diff --name-only qa force-app/) $DEPLOYDIR;

  echo
  echo 'Your changed files: '
  echo
  for FILE in $CHANGED_FILES; do
    echo ../$FILE
  done;
  echo
fi;

if [ "$BRANCH" == "master" ]; then
  echo 'Your current branches: '
  echo
  for branch in $(git branch -r|grep -v HEAD); do
      echo $branch
      git checkout -qf ${branch#origin/}
  done;
  echo
  git checkout master

  export CHANGED_FILES=$(git diff --name-only dev force-app/)
  sudo cp --parents $(git diff --name-only dev force-app/) $DEPLOYDIR;

  echo
  echo 'Your changed files: '
  echo
  for FILE in $CHANGED_FILES; do
    echo ../$FILE
  done;
  echo
fi;

# List each changed file from the git diff command
  # For any changed class or trigger file, it's associated meta data file is copied to the deploy directory (and vice versa)
# NOTE: naming convention used for <className>Test.cls files: "Test"
for FILE in $CHANGED_FILES; do
  echo ' ';
  echo "Found changed file:`echo ' '$FILE`";
  if [[ $FILE == *Test.cls ]]; then
    sudo cp --parents "$(find $classPath -samefile "$FILE-meta.xml")"* $DEPLOYDIR;
    echo 'Copying class file to diff folder for deployment...';
    echo 'Class files that will be deployed:';
    ls $userPath$diffPath/classes;

  elif [[ $FILE == *Test.cls-meta.xml ]]; then
    export FILE2=${FILE%.cls-meta.xml};
    sudo cp --parents "$(find $classPath -samefile "$FILE2.cls")"* $DEPLOYDIR;
    echo 'Copying class meta file to diff folder for deployment...';
    echo 'Class files that will be deployed:';
    ls $userPath$diffPath/classes;

  elif [[ $FILE == *.cls ]]; then
    sudo cp --parents "$(find $classPath -samefile "$FILE-meta.xml")"* $DEPLOYDIR;
    echo 'Copying class file to diff folder for deployment...';
    echo 'Class files that will be deployed:';
    ls $userPath$diffPath/classes;

  elif [[ $FILE == *.cls-meta.xml ]]; then
    export FILE2=${FILE%.cls-meta.xml};
    sudo cp --parents "$(find $classPath -samefile "$FILE2.cls")"* $DEPLOYDIR;
    echo 'Copying class meta file to diff folder for deployment...';
    echo 'Class files that will be deployed:';
    ls $userPath$diffPath/classes;
   
  elif [[ $FILE == *.trigger ]]; then
    sudo cp --parents "$(find $triggerPath -samefile "$FILE-meta.xml")"* $DEPLOYDIR;
    echo 'Copying trigger file to diff folder for deployment...';
    echo 'Trigger files that will be deployed:';
    ls $userPath$diffPath/triggers;
      
  elif [[ $FILE == *.trigger-meta.xml ]]; then
    export FILE3=${FILE%.trigger-meta.xml};
    sudo cp --parents "$(find $triggerPath -samefile "$FILE3.trigger")"* $DEPLOYDIR;
    echo 'Copying trigger meta file to diff folder for deployment...';
    echo 'Trigger files that will be deployed:';
    ls $userPath$diffPath/triggers;
  fi;
done;

# Make temporary folder for our <className>Test.cls files that will be deployed
sudo mkdir -p /Users/jackbarsotti/sfdx-travisci2/force-app/main/default/unparsedTests
export unparsedTestsDir=/Users/jackbarsotti/sfdx-travisci2/force-app/main/default/unparsedTests
# Search the local "classes" folder for <className>Test.cls files
export classTests=$(find $classPath -name "*Test.cls")
# Parse the <className>Test.cls filenames to remove each file's path and ".cls" ending, result: <className>Test
export parsedList=''
for testfiles in $classTests; do
  sudo cp "$testfiles"* $unparsedTestsDir;
  export parsed=$(find $unparsedTestsDir -name "*Test.cls");
  export parsed=${parsed##*/};
  export parsed=${parsed%.cls*};
  export parsedList="${parsedList}${parsed},";
done;
# Output the string that will be called in the deploy command in script phase
echo "parsedList = ${parsedList}"

# Finally, go back to the HEAD from the before_script phase
git checkout $build_head

# Automatically authenticate against current branch's corresponding SalesForce org
# Create deployment variable for "sfdx:force:source:deploy RunSpecifiedTests -r <variable>" (see script phase below)
# Only validate, not deploy, when a pull request is being created
  # When a pull request is MERGED, deploy it

if [ "$BRANCH" == "dev" ]; then
  echo $SFDXAUTHURLDEV>authtravisci.txt;
  if [ "$TRAVIS_EVENT_TYPE" == "pull_request" ]; then
    export TESTLEVEL="RunSpecifiedTests -r $parsedList -c";
  else
    export TESTLEVEL="RunSpecifiedTests -r $parsedList";
  fi;
fi;

if [ "$BRANCH" == "qa" ]; then
  echo $SFDXAUTHURLQA>authtravisci.txt;
  if [ "$TRAVIS_EVENT_TYPE" == "pull_request" ]; then
    export TESTLEVEL="RunSpecifiedTests -r $parsedList -c";
  else
    export TESTLEVEL="RunSpecifiedTests -r $parsedList";
  fi;
fi;

if [ "$BRANCH" == "uat" ]; then
  echo $SFDXAUTHURLUAT>authtravisci.txt;
  if [ "$TRAVIS_EVENT_TYPE" == "pull_request" ]; then
    export TESTLEVEL="RunLocalTests -c";
  else
    export TESTLEVEL="RunLocalTests";
  fi;
fi;

if [ "$BRANCH" == "master" ]; then
  echo $SFDXAUTHURL>authtravisci.txt;
  if [ "$TRAVIS_EVENT_TYPE" == "pull_request" ]; then
    export TESTLEVEL="RunLocalTests -c";
  else
    export TESTLEVEL="RunLocalTests";
  fi;
fi;

sfdx force:auth:sfdxurl:store -f authtravisci.txt -a targetEnvironment

# Create error message to account for potential deployment failure
export deployErrorMsg='There was an issue deploying. Check ORG deployment status page for details'

# Run apex tests and deploy apex classes/triggers
sfdx force:org:display -u targetEnvironment
sfdx force:source:deploy -w 10 -p $DEPLOYDIR -l $TESTLEVEL -u targetEnvironment

# Failure message if deployment fails
if [ TRAVIS_TEST_RESULT != 0 ]; then
  echo $deployErrorMsg;
fi;
