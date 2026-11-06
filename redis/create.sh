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

os=$(getOS)
optName=$1
optVersion=$2
optPort=$(getOptPort $3)
optFileName=redis-${optVersion}-${os}
installDir=$(getInstallDir $(getType))
dir=$installDir/versions/$optVersion

mkdir -p "$dir"
cd $dir

exitIfDuplicatedName $optName
exitIfExistDir $dir/datadir/$optName
exitIfRunningPort $optPort

getUrlFileAs https://dbdb.shueisha-artsdigital.co.jp/redis/$optFileName.tar.gz $optFileName.tar.gz
mkdir -p $dir/datadir/$optName
extractFile $dir $optFileName

if [ ! -e $dir/basedir/src/redis-server ]; then
  cd $dir/basedir
  echo "Installing..." 1>&2
  redisPatch $optVersion $dir/basedir/src/config.h
  make > /dev/null 2>&1
fi

# create redis.conf
if [ ! -f $dir/datadir/$optName/redis.conf ]; then
  cd $dir/datadir/$optName
  cp $dir/basedir/redis.conf .
fi

echo $optPort > $dir/datadir/$optName/redis.port.init

commands=$(getCommands $optName $optVersion $optPort $format)

normalOutputs=""
normalOutputs="${normalOutputs}redis.conf is here. $dir/datadir/$optName/redis.conf\n"
normalOutputs="${normalOutputs}Redis Successfully created. $optName $optVersion $optPort\n"
normalOutputs="${normalOutputs}$commands\n"

jsonOutputs=""
jsonOutputs="$jsonOutputs{
  \"message\": \"Redis Successfully created.\",
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
