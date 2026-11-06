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
$dir/basedir/bin/mongod \
 --config $dir/datadir/$optName/mongod.conf \
 --dbpath $dir/datadir/$optName \
 --logpath $dir/datadir/$optName/mongodb.log \
 --pidfilepath $dir/datadir/$optName/mongodb.pid \
 --port $optPort \
 --fork 1>&2
echo $optPort > $dir/datadir/$optName/mongodb.port

sleep 1

normalOutputs=""
normalOutputs="${normalOutputs}MongoDB Successfully started. $optName $optVersion $optPort\n"
normalOutputs="${normalOutputs}Your config file is located $dir/datadir/$optName/mongodb.conf"

jsonOutputs=""
jsonOutputs="$jsonOutputs{
  \"message\": \"MongoDB Successfully started.\",
  \"name\": \"$optName\",
  \"type\": \"mongodb\",
  \"version\": \"$optVersion\",
  \"port\": \"$optPort\",
  \"dataDir\": \"$dir/datadir/$optName\",
  \"confPath\": \"$dir/datadir/$optName/mongod.conf\"
}"

# Output
if [ "$format" = "json" ]; then
  echo -e "${jsonOutputs}"
else
  echo -e "${normalOutputs}"
fi
