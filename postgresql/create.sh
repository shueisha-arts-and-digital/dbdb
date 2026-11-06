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
optFileName=postgresql-${optVersion}-${os}
installDir=$(getInstallDir $(getType))
dir=$installDir/versions/$optVersion

mkdir -p "$dir"
cd $dir

exitIfDuplicatedName $optName
exitIfExistDir $dir/datadir/$optName
exitIfRunningPort $optPort

getUrlFileAs https://dbdb.shueisha-artsdigital.co.jp/postgresql/$optFileName.tar.gz $optFileName.tar.gz
mkdir -p $dir/datadir/$optName
extractFile $dir $optFileName

# install for linux
if [ ! -d $dir/basedir/bin ]; then
  if [ $os = "linux" ]; then
    echo "Installing..." 1>&2
    cd $dir/basedir
    # PostgreSQL 16 より前は C23 でコンパイルできない。既定が C23 の gcc 15 以降でも通るよう、常に gnu11 を指定する（gnu17 と違い gcc 7 でも使える）
    # CFLAGS が未設定のときだけ -O2 を付ける（configure の既定と同じ）。利用者の CFLAGS は残す
    ./configure --prefix=$(pwd) CFLAGS="${CFLAGS--O2} -std=gnu11" > /dev/null 2>&1
    make > /dev/null 2>&1
    make install > /dev/null 2>&1
    rm -fr config contrib doc src
  fi
fi

# initdb
$dir/basedir/bin/initdb \
  --pgdata=$dir/datadir/$optName \
  --username=postgres \
  --encoding=UTF-8 \
  --locale=en_US.UTF-8 1>&2
echo $optPort > $dir/datadir/$optName/postgresql.port.init

commands=$(getCommands $optName $optVersion $optPort $format)

normalOutputs=""
normalOutputs="${normalOutputs}postgresql.conf is here. $dir/datadir/$optName/postgresql.conf\n"
normalOutputs="${normalOutputs}PostgreSQL Successfully created. $optName $optVersion $optPort\n"
normalOutputs="${normalOutputs}$commands\n"

jsonOutputs=""
jsonOutputs="$jsonOutputs{
  \"message\": \"PostgreSQL Successfully created.\",
  \"name\": \"$optName\",
  \"type\": \"postgresql\",
  \"version\": \"$optVersion\",
  \"port\": \"$optPort\",
  \"dataDir\": \"$dir/datadir/$optName\",
  \"confPath\": \"$dir/datadir/$optName/postgresql.conf\"
}"

# Output
if [ "$format" = "json" ]; then
  echo -e "${jsonOutputs}"
else
  echo -e "${normalOutputs}"
fi
