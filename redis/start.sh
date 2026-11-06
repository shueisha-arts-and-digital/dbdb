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
exitIfRunningPort $optPort

# start
$dir/basedir/src/redis-server \
 $dir/datadir/$optName/redis.conf \
 --port $optPort \
 --dir $dir/datadir/$optName \
 --pidfile $dir/datadir/$optName/redis.pid \
 --daemonize yes
echo $optPort > $dir/datadir/$optName/redis.port

normalOutputs=""
normalOutputs="${normalOutputs}Redis Successfully started. $optName $optVersion $optPort\n"
normalOutputs="${normalOutputs}Your config file is located $dir/datadir/$optName/redis.conf"

jsonOutputs=""
jsonOutputs="$jsonOutputs{
  \"message\": \"Redis Successfully started.\",
  \"name\": \"$optName\",
  \"type\": \"redis\",
  \"version\": \"$optVersion\",
  \"port\": \"$optPort\",
  \"dataDir\": \"$dir/datadir/$optName\",
  \"confPath\": \"$dir/datadir/$optName/redis.conf\"
}"

# Output
if [ "$format" = "json" ]; then
  echo -e "${jsonOutputs}"
else
  echo -e "${normalOutputs}"
fi
