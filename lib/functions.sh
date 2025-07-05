#!/bin/bash

confirm() {
  read -r -p "${1:-Are you sure? [y/N]} " response
  case "$response" in
  [yY][eE][sS] | [yY])
    true
    ;;
  *)
    false
    ;;
  esac
}

getOS() {
  case "$(uname -s)" in
  Linux*) os=linux ;;
  Darwin*) os=macos ;;
  *)
    echo "It supports Linux and MacOS." 1>&2
    exit 1
    ;;
  esac
  echo $os
}

getCurrentDir() {
  echo "$(
    cd "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
  )"
}

exitIfExistDir() {
  if [ -d $1 ]; then
    echo "The dir '$1' is exist." 1>&2
    exit 1
  fi
}

exitIfNotExistDir() {
  if [ ! -d $1 ]; then
    echo "The dir '$1' is NOT exist." 1>&2
    exit 1
  fi
}

exitIfRunningPort() {
  if nc -z 127.0.0.1 $1 >/dev/null 2>&1; then
    echo "The port '$1' is already in use." 1>&2
    exit 1
  fi
}

exitIfNotRunningPort() {
  if nc -z 127.0.0.1 $1 >/dev/null 2>&1; then
    :
  else
    echo "The port '$1' is NOT in use." 1>&2
    exit 1
  fi
}

getUrlFileAs() {
  if [ ! -e "$2" ]; then
    echo "Downloading... $1" 1>&2
    local temp_file="$2.tmp.$$"
    if wget --server-response "$1" -O "$temp_file" 2>/dev/null || curl --fail --silent "$1" -o "$temp_file"; then
      mv "$temp_file" "$2"
      return 0
    else
      rm -f "$temp_file"
      echo "Download failed or HTTP error for $1" 1>&2
      return 1
    fi
  fi
  return 0
}

extractFile() {
  if [ ! -d "$1/basedir" ]; then
    echo "Extracting..." 1>&2
    mkdir -p "$1/basedir"
    cd "$1/basedir"

    if [ -f "$1/$2.tar.gz" ]; then
      cp "$1/$2.tar.gz" .
      tar -xf "$2.tar.gz" --strip-components 1
      rm -f "$2.tar.gz"
    elif [ -f "$1/$2.tar.xz" ]; then
      cp "$1/$2.tar.xz" .
      tar -xf "$2.tar.xz" --strip-components 1
      rm -f "$2.tar.xz"
    fi
  fi
}

getCommands() {
  type=$(getType)

  format="${4:-}"
  if [ "$format" = "json" ]; then
    jsonOutputs="{
      \"start\":   \"./$type/start.sh $1\",
      \"stop\":    \"./$type/stop.sh $1\",
      \"restart\": \"./$type/restart.sh $1\",
      \"port\":    \"./$type/port.sh $1\",
      \"status\":  \"./$type/status.sh $1\",
      \"connect\": \"./$type/connect.sh $1\",
      \"delete\":  \"./$type/delete.sh $1\"
      }"
    echo -e $jsonOutputs
  else
    echo ""
    echo "# Start"
    echo "./$type/start.sh $1"
    echo ""
    echo "# Stop"
    echo "./$type/stop.sh $1"
    echo ""
    echo "# Restart"
    echo "./$type/restart.sh $1"
    echo ""
    echo "# Port"
    echo "./$type/port.sh $1"
    echo ""
    echo "# Status"
    echo "./$type/status.sh $1"
    echo ""
    echo "# Connect"
    echo "./$type/connect.sh $1"
    echo ""
    echo "# Delete"
    echo "./$type/delete.sh $1"
    echo ""
  fi

}

getRandomPort() {
  while true; do
    randomPort=$(shuf -i "49152-65535" -n 1 2>/dev/null || jot -r 1 49152 65535)
    netstat -a -n | grep ".$randomPort" | grep "LISTEN" 1>/dev/null 2>&1 || break
  done
  echo $randomPort
}

# if $1 name is duplicated in this datastore, exit(1)
exitIfDuplicatedName() {
  name=$1
  installDir=$(getInstallDir $(getType))
  found=$(find "$installDir" -type d -name "$name" | wc -l | tr -d '[:space:]')
  if [ "$found" = "0" ]; then
    :
  else
    echo "The name '$name' is already in use." 1>&2
    #find "$installDir" -type d -name "$name" | grep -E "datadir/$name$" 1>&2
    exit 1
  fi
}

exitIfNotExistVersion() {
  name=$1
  installDir=$(getInstallDir $(getType))
  version=$(find "$installDir" -type d -name "$name" | grep -E "datadir/$name$" | awk -F "/datadir/" '{print $1}' | awk -F "/versions/" '{print $2}')
  if [ "$version" = "" ]; then
    echo "There is no version for the given '$name'." 1>&2
    exit 1
  fi
}

getVersionByName() {
  name=$1
  installDir=$(getInstallDir $(getType))
  version=$(find "$installDir" -type d -name "$name" | grep -E "datadir/$name$" | awk -F "/datadir/" '{print $1}' | awk -F "/versions/" '{print $2}')
  echo "$version"
}

exitIfNotExistPortFile() {
  name=$1
  version=$2
  installDir=$(getInstallDir $(getType))
  portFiles=$(find "$installDir/versions/$version" -type f -name "*.port*" | grep -E "/datadir/$name/" || true)
  if [ "$portFiles" = "" ]; then
    echo "There are no port files for the given '$name'." 1>&2
    exit 1
  fi
}

getType() {
  if [[ "$(getCurrentDir)" == *"/dbdb/mongodb"* ]]; then
    echo "mongodb"
  elif [[ "$(getCurrentDir)" == *"/dbdb/mysql"* ]]; then
    echo "mysql"
  elif [[ "$(getCurrentDir)" == *"/dbdb/postgresql"* ]]; then
    echo "postgresql"
  elif [[ "$(getCurrentDir)" == *"/dbdb/redis"* ]]; then
    echo "redis"
  elif [[ "$(getCurrentDir)" == *"/dbdb/memcached"* ]]; then
    echo "memcached"
  else
    echo "unknown database type" 1>&2
    exit 1
  fi
}

getPortByName() {
  type=$(getType)
  name=$1
  version=$2
  installDir=$(getInstallDir $(getType))

  runningPort=$(cat "$installDir/versions/$version/datadir/$name/$type.port" 2>/dev/null || true)
  lastPort=$(cat "$installDir/versions/$version/datadir/$name/$type.port.last" 2>/dev/null || true)
  initPort=$(cat "$installDir/versions/$version/datadir/$name/$type.port.init" 2>/dev/null || true)

  if [ "$runningPort" ]; then
    echo $runningPort
  elif [ "$lastPort" ]; then
    echo $lastPort
  elif [ "$initPort" ]; then
    echo $initPort
  fi
}

getOptPort() {
  optPort=$1
  if [ "$optPort" = "random" ]; then
    getRandomPort
  else
    echo "$optPort"
  fi
}

getInstallDir() {
  suffix=dbdb/$1
  if [ -z "${XDG_DATA_HOME+x}" ]; then
    echo "$HOME/.local/share/$suffix"
  else
    echo "$XDG_DATA_HOME/$suffix"
  fi
}

# https://github.com/pj8/dbdb/issues/62
redisPatch() {
  if [[ $1 =~ ^6\.[0-9]+\.[0-9]+$ ]] && [ "$(getOS)" = "macos" ]; then
    sed -i '' '/#ifdef __APPLE__/a\
#define _DARWIN_C_SOURCE
' $2
  fi
}
