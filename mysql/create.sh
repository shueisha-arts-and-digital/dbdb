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

if [ $# -eq 0 ]; then
  cat <<_EOT_ >&2
usage : $currentDir/create.sh {Name} {MysqlVersion} {Port}
e.g.  : $currentDir/create.sh mysql5-foo 5.7.31 13306
e.g.  : $currentDir/create.sh mysql8-bar 8.0.30 23306
e.g.  : $currentDir/create.sh mysql8-baz 8.0.30 random
_EOT_
  exit 1
fi

. functions.sh

os=$(getOS)
optName=$1
optVersion=$2
optPort=$(getOptPort $3)
optFileName=mysql-${optVersion}-${os}
optUser=_dbdb_mysql
optSocket=/tmp/dbdb_mysql_$optPort.sock
installDir=$(getInstallDir $(getType))
dir=$installDir/versions/$optVersion

mkdir -p "$dir"
cd $dir

exitIfDuplicatedName $optName
exitIfExistDir $dir/datadir/$optName
exitIfRunningPort $optPort

getUrlFileAs https://dbdb.shueisha-artsdigital.co.jp/mysql/$optFileName.tar.gz $optFileName.tar.gz || getUrlFileAs https://dbdb.shueisha-artsdigital.co.jp/mysql/$optFileName.tar.xz $optFileName.tar.xz
mkdir -p $dir/datadir/$optName
extractFile $dir $optFileName

$dir/basedir/bin/mysqld \
  --no-defaults \
  --initialize-insecure \
  --user=$optUser \
  --port=$optPort \
  --socket=$optSocket \
  --basedir=$dir/basedir \
  --plugin-dir=$dir/basedir/lib/plugin \
  --datadir=$dir/datadir/$optName \
  --log-error=$dir/datadir/$optName/mysqld.err \
  --pid-file=$dir/datadir/$optName/mysql.pid

echo $optPort >$dir/datadir/$optName/mysql.port.init

echo "#my.cnf" > $dir/datadir/$optName/my.cnf
echo "[mysqld]" >> $dir/datadir/$optName/my.cnf
echo "bind-address = 127.0.0.1" >> $dir/datadir/$optName/my.cnf

commands=$(getCommands $optName $optVersion $optPort $format)

normalOutputs=""
normalOutputs="${normalOutputs}my.cnf is here. $dir/datadir/$optName/my.cnf\n"
normalOutputs="${normalOutputs}MySQL Successfully created. $optName $optVersion $optPort\n"
normalOutputs="${normalOutputs}$commands\n"

jsonOutputs=""
jsonOutputs="$jsonOutputs{
  \"message\": \"MySQL Successfully created.\",
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
