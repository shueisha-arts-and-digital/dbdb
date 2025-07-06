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

status=$($dir/basedir/bin/mongo --port $optPort --quiet --eval "db.serverStatus().ok" 2>/dev/null || $dir/basedir/bin/mongosh --port $optPort --quiet --eval "db.serverStatus().ok")

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
