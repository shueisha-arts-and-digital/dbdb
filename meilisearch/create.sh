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
installDir=$(getInstallDir $(getType))
dir=$installDir/versions/$optVersion

# Official Community Edition (MIT) binaries on GitHub Releases. Apple Silicon only on macOS, like the other types.
assetName=meilisearch-linux-amd64
[ "$os" = "macos" ] && assetName=meilisearch-macos-apple-silicon

mkdir -p "$dir"
cd $dir

exitIfDuplicatedName $optName
exitIfExistDir $dir/datadir/$optName
exitIfRunningPort $optPort

mkdir -p $dir/basedir
getUrlFileAs https://github.com/meilisearch/meilisearch/releases/download/v$optVersion/$assetName $dir/basedir/meilisearch
chmod +x $dir/basedir/meilisearch

mkdir -p $dir/datadir/$optName
echo "# https://www.meilisearch.com/docs/resources/self_hosting/configuration/reference" > $dir/datadir/$optName/config.toml
echo $optPort > $dir/datadir/$optName/meilisearch.port.init

commands=$(getCommands $optName $optVersion $optPort $format)

normalOutputs=""
normalOutputs="${normalOutputs}config.toml is here. $dir/datadir/$optName/config.toml\n"
normalOutputs="${normalOutputs}Meilisearch Successfully created. $optName $optVersion $optPort\n"
normalOutputs="${normalOutputs}$commands\n"

jsonOutputs=""
jsonOutputs="$jsonOutputs{
  \"message\": \"Meilisearch Successfully created.\",
  \"name\": \"$optName\",
  \"type\": \"meilisearch\",
  \"version\": \"$optVersion\",
  \"port\": \"$optPort\",
  \"dataDir\": \"$dir/datadir/$optName\",
  \"confPath\": \"$dir/datadir/$optName/config.toml\"
}"

# Output
if [ "$format" = "json" ]; then
  echo -e "${jsonOutputs}"
else
  echo -e "${normalOutputs}"
fi
