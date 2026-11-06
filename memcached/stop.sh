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

exitIfNotExistDir $dir/datadir/$optName
exitIfNotRunningPort $optPort
[ -f "$dir/datadir/$optName/memcached.pid" ] && kill $(cat $dir/datadir/$optName/memcached.pid) && rm -f $dir/datadir/$optName/memcached.pid
[ -f "$dir/datadir/$optName/memcached.port" ] && cp $dir/datadir/$optName/memcached.port $dir/datadir/$optName/memcached.port.last
[ -f "$dir/datadir/$optName/memcached.port" ] && rm -f $dir/datadir/$optName/memcached.port

sleep 1

normalOutputs=""
normalOutputs="${normalOutputs}Memcached Successfully stopped. $optName $optVersion $optPort"

jsonOutputs=""
jsonOutputs="$jsonOutputs{
  \"message\": \"Memcached Successfully stopped.\",
  \"name\": \"$optName\",
  \"type\": \"memcached\",
  \"version\": \"$optVersion\",
  \"port\": \"$optPort\",
  \"dataDir\": \"$dir/datadir/$optName\",
  \"confPath\": \"\"
}"

# Output
if [ "$format" = "json" ]; then
  echo -e "${jsonOutputs}"
else
  echo -e "${normalOutputs}"
fi
