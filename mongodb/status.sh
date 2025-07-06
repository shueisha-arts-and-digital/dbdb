#!/bin/bash
set -eu

# Get format option
format=""
while getopts ":f:" opt; do
  case ${opt} in
  f)
    format="$OPTARG"
    ;;
  \?)
    echo "Invalid option: -$OPTARG" 1>&2
    exit 1
    ;;
  :)
    echo "Option -$OPTARG requires an argument." 1>&2
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

currentDir="$(
  cd "$(dirname "$0")" >/dev/null 2>&1
  pwd -P
)"
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

# Try mongosh first, then mongo, then fallback to port check
if [ -f "$dir/basedir/bin/mongosh" ]; then
  status=$($dir/basedir/bin/mongosh --port $optPort --quiet --eval "db.serverStatus().ok" 2>/dev/null)
elif [ -f "$dir/basedir/bin/mongo" ]; then
  status=$($dir/basedir/bin/mongo --port $optPort --quiet --eval "db.serverStatus().ok" 2>/dev/null)
else
  # Fallback: check if port is in use (1=running, 0=not running)
  if nc -z 127.0.0.1 $optPort >/dev/null 2>&1; then
    status="1"
  else
    status="0"
  fi
fi

normalOutputs=""
normalOutputs="${normalOutputs}$status"

jsonOutputs=""
jsonOutputs="$jsonOutputs{
  \"status\": \"$status\"
}"

# Output
if [ "$format" = "json" ]; then
  echo -e "${jsonOutputs}"
else
  echo -e "${normalOutputs}"
fi
