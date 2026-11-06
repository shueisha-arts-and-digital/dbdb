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

optSocket=/tmp/dbdb_mysql_$optPort.sock
installDir=$(getInstallDir $(getType))
dir=$installDir/versions/$optVersion

exitIfNotExistDir $dir/datadir/$optName
exitIfNotRunningPort $optPort
$dir/basedir/bin/mysqladmin --user=root --host=localhost --port=$optPort --socket=$optSocket shutdown
[ -f "$dir/datadir/$optName/mysql.port" ] && cp $dir/datadir/$optName/mysql.port $dir/datadir/$optName/mysql.port.last
[ -f "$dir/datadir/$optName/mysql.port" ] && rm -f $dir/datadir/$optName/mysql.port

normalOutputs=""
normalOutputs="${normalOutputs}MySQL Successfully stopped. $optName $optVersion $optPort"

jsonOutputs=""
jsonOutputs="$jsonOutputs{
  \"message\": \"MySQL Successfully stopped.\",
  \"name\": \"$optName\",
  \"type\": \"mysql\",
  \"version\": \"$optVersion\",
  \"port\": \"$optPort\",
  \"dataDir\": \"$dir/datadir/$optName\",
  \"confPath\": \"$dir/datadir/$optName/my.cnf\"
}"

# Output
if [ "$format" = "json" ]; then
  echo -e "${jsonOutputs}"
else
  echo -e "${normalOutputs}"
fi
