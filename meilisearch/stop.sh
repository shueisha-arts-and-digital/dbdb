#!/bin/bash
set -eu
. "$(dirname "$0")/functions.sh"
handleHelp "$@"

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

optName=$1

exitIfNotExistVersion "$optName"
optVersion=$(getVersionByName "$optName")

exitIfNotExistPortFile "$optName" "$optVersion"
optPort=$(getPortByName "$optName" "$optVersion")

installDir=$(getInstallDir $(getType))
dir=$installDir/versions/$optVersion
dataDir=$dir/datadir/$optName

exitIfNotExistDir $dataDir
exitIfNotRunningPort $optPort

if [ -f "$dataDir/meilisearch.pid" ]; then
  pid=$(cat $dataDir/meilisearch.pid)
  kill $pid
  # wait for the process to exit so that the database lock is released
  while kill -0 $pid 2>/dev/null; do
    sleep 1
  done
  rm -f $dataDir/meilisearch.pid
fi
[ -f "$dataDir/meilisearch.port" ] && cp $dataDir/meilisearch.port $dataDir/meilisearch.port.last
[ -f "$dataDir/meilisearch.port" ] && rm -f $dataDir/meilisearch.port

normalOutputs=""
normalOutputs="${normalOutputs}Meilisearch Successfully stopped. $optName $optVersion $optPort"

jsonOutputs=""
jsonOutputs="$jsonOutputs{
  \"message\": \"Meilisearch Successfully stopped.\",
  \"name\": \"$optName\",
  \"type\": \"meilisearch\",
  \"version\": \"$optVersion\",
  \"port\": \"$optPort\",
  \"dataDir\": \"$dataDir\",
  \"confPath\": \"$dataDir/config.toml\"
}"

# Output
if [ "$format" = "json" ]; then
  echo -e "${jsonOutputs}"
else
  echo -e "${normalOutputs}"
fi
