#!/usr/bin/env bash

CHANGED_FILES=`git diff --name-only master src/`

for CHANGED_FILE in $CHANGED_FILES; do
  echo ../$CHANGED_FILE
done
