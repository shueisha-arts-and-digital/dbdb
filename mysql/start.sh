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

optUser=root
optSocket=/tmp/dbdb_mysql_$optPort.sock
installDir=$(getInstallDir $(getType))
dir=$installDir/versions/$optVersion

exitIfNotExistDir $dir/datadir/$optName
exitIfRunningPort $optPort

$dir/basedir/bin/mysqld \
  --defaults-file=$dir/datadir/$optName/my.cnf \
  --daemonize \
  --user=$optUser \
  --port=$optPort \
  --socket=$optSocket \
  --basedir=$dir/basedir \
  --plugin-dir=$dir/basedir/lib/plugin \
  --datadir=$dir/datadir/$optName \
  --log-error=$dir/datadir/$optName/mysqld.err \
  --pid-file=$dir/datadir/$optName/mysql.pid
echo $optPort > $dir/datadir/$optName/mysql.port

normalOutputs=""
normalOutputs="${normalOutputs}MySQL Successfully started. $optName $optVersion $optPort\n"
normalOutputs="${normalOutputs}Your config file is located $dir/datadir/$optName/my.cnf"

jsonOutputs=""
jsonOutputs="$jsonOutputs{
  \"message\": \"MySQL Successfully started.\",
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
