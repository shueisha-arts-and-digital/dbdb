#!/bin/bash
set -eu
. "$(dirname "$0")/functions.sh"
handleHelp "$@"

optName=$1

exitIfNotExistVersion "$optName"
optVersion=$(getVersionByName "$optName")

exitIfNotExistPortFile "$optName" "$optVersion"
optPort=$(getPortByName "$optName" "$optVersion")

optSocket=/tmp/dbdb_mysql_$optPort.sock
installDir=$(getInstallDir $(getType))
dir=$installDir/versions/$optVersion

exitIfNotExistDir $dir/datadir/$optName
exitIfNotRunningPort $optPort
$dir/basedir/bin/mysql --user=root --host=localhost --port=$optPort --socket=$optSocket "${@:2}"
