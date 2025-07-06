#!/bin/bash
set -eu

currentDir="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $currentDir
. functions.sh

optName=$1

exitIfNotExistVersion "$optName"
optVersion=$(getVersionByName "$optName")

exitIfNotExistPortFile "$optName" "$optVersion"
optPort=$(getPortByName "$optName" "$optVersion")

installDir=$(getInstallDir $(getType))
dir=$installDir/versions/$optVersion

exitIfNotExistDir $dir/datadir/$optName
exitIfNotRunningPort $optPort
# Try mongosh first, then mongo
if [ -f "$dir/basedir/bin/mongosh" ]; then
  $dir/basedir/bin/mongosh --port $optPort
elif [ -f "$dir/basedir/bin/mongo" ]; then
  $dir/basedir/bin/mongo --port $optPort
else
  echo "Neither mongosh nor mongo client found in $dir/basedir/bin/" 1>&2
  exit 1
fi
