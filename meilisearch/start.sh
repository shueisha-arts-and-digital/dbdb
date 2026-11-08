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
dataDir=$dir/datadir/$optName

exitIfNotExistDir $dataDir
exitIfRunningPort $optPort

# start
# Meilisearch has no daemon mode, so run it in the background and record its pid.
# It reads ./config.toml and writes dumps/ and snapshots/ relative to the working directory.
cd $dataDir
nohup $dir/basedir/meilisearch \
  --http-addr 127.0.0.1:$optPort \
  --db-path $dataDir/data.ms \
  --no-analytics \
  </dev/null >meilisearch.log 2>&1 &
pid=$!
echo $pid > meilisearch.pid

# wait until it listens
for i in $(seq 30); do
  nc -z 127.0.0.1 $optPort >/dev/null 2>&1 && break
  if ! kill -0 $pid 2>/dev/null || [ "$i" = 30 ]; then
    echo "Meilisearch failed to start. See $dataDir/meilisearch.log" 1>&2
    tail -n 20 meilisearch.log 1>&2
    kill $pid 2>/dev/null || true
    rm -f meilisearch.pid
    exit 1
  fi
  sleep 1
done
echo $optPort > meilisearch.port

normalOutputs=""
normalOutputs="${normalOutputs}Meilisearch Successfully started. $optName $optVersion $optPort\n"
normalOutputs="${normalOutputs}Your config file is located $dataDir/config.toml"

jsonOutputs=""
jsonOutputs="$jsonOutputs{
  \"message\": \"Meilisearch Successfully started.\",
  \"name\": \"$optName\",
  \"type\": \"meilisearch\",
  \"version\": \"$optVersion\",
  \"port\": \"$optPort\",
  \"dataDir\": \"$dataDir\",
  \"confPath\": \"$dataDir/config.toml\"
}"

# Output
if [ "$format" = "json" ]; then
  echo -e "${jsonOutputs}"
else
  echo -e "${normalOutputs}"
fi
