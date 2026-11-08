#!/bin/bash
set -eu
. "$(dirname "$0")/functions.sh"
handleHelp "$@"

optName=$1

exitIfNotExistVersion "$optName"
optVersion=$(getVersionByName "$optName")

exitIfNotExistPortFile "$optName" "$optVersion"
optPort=$(getPortByName "$optName" "$optVersion")

installDir=$(getInstallDir $(getType))
dir=$installDir/versions/$optVersion

exitIfNotExistDir $dir/datadir/$optName
exitIfNotRunningPort $optPort

echo "You can connect to the server by executing the following command."
echo "curl http://127.0.0.1:$optPort/health"
