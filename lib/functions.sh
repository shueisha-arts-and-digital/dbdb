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

getTypeLabel() {
  case "$1" in
  mysql) echo "MySQL" ;;
  postgresql) echo "PostgreSQL" ;;
  mongodb) echo "MongoDB" ;;
  redis) echo "Redis" ;;
  memcached) echo "Memcached" ;;
  esac
}

getExampleVersion() {
  case "$1" in
  mysql) echo "8.0.41" ;;
  postgresql) echo "13.2" ;;
  mongodb) echo "7.0.21" ;;
  redis) echo "7.2.5" ;;
  memcached) echo "1.6.31" ;;
  esac
}

getConnectionInfo() {
  case "$1" in
  mysql) echo "host 127.0.0.1, port <port>, user root, no password" ;;
  postgresql) echo "host 127.0.0.1, port <port>, user postgres, no password, database postgres" ;;
  mongodb) echo "mongodb://127.0.0.1:<port>, no authentication" ;;
  redis) echo "redis://127.0.0.1:<port>, no password" ;;
  memcached) echo "127.0.0.1:<port>, no authentication (listens on all interfaces)" ;;
  esac
}

getConnectClient() {
  case "$1" in
  mysql) echo "mysql" ;;
  postgresql) echo "psql" ;;
  mongodb) echo "mongosh (or mongo for old versions)" ;;
  redis) echo "redis-cli" ;;
  memcached) echo "" ;;
  esac
}

getHelpArgs() {
  local type=$1
  local command=$2
  case "$command" in
  create | create-start) echo "<name> <version> <port|random>" ;;
  connect) [ -n "$(getConnectClient "$type")" ] && echo "<name> [client args...]" || echo "<name>" ;;
  *) echo "<name>" ;;
  esac
}

printHelpDescription() {
  local type=$1
  local command=$2
  local label
  label=$(getTypeLabel "$type")
  case "$command" in
  create)
    echo "Create a $label instance. It is not started; run start.sh next."
    echo "The first create of a version downloads its binaries (some are built from source),"
    echo "which can take several minutes."
    ;;
  create-start) echo "Create the $label instance if it does not exist, then start it." ;;
  start) echo "Start the $label instance. Fails if its port is already in use." ;;
  stop) echo "Stop the $label instance. Fails if it is not running." ;;
  restart) echo "Stop the $label instance if it is running, then start it." ;;
  port) echo "Print the port of the $label instance." ;;
  status) echo "Print the server status of the running $label instance." ;;
  connect) printConnectHelp "$type" ;;
  delete)
    echo "Stop the $label instance and delete its data directory."
    echo "It does NOT ask for confirmation and cannot be undone."
    ;;
  esac
}

printConnectHelp() {
  local type=$1
  local client
  client=$(getConnectClient "$type")
  if [ -z "$client" ]; then
    echo "Print how to connect to the running $(getTypeLabel "$type") instance (there is no bundled client)."
  else
    echo "Open $client for the running $(getTypeLabel "$type") instance."
    echo "Arguments after <name> are passed to $client, which lets you run it non-interactively."
  fi
  echo "Connection: $(getConnectionInfo "$type")"
}

printHelpArguments() {
  local type=$1
  local command=$2
  echo "Arguments:"
  case "$command" in
  create | create-start)
    echo "  name         New instance name, unique within $type"
    echo "  version      $(getTypeLabel "$type") version. Supported versions per OS/CPU: see README.md"
    echo "  port         Port number, or \"random\" for a free port in 49152-65535"
    ;;
  *)
    echo "  name         Instance name. List instances with dbdb.sh"
    ;;
  esac
  if [ "$command" = "connect" ] && [ -n "$(getConnectClient "$type")" ]; then
    echo "  client args  Passed to $(getConnectClient "$type") as is"
  fi
  return 0
}

printHelpExample() {
  local type=$1
  local command=$2
  echo "Example:"
  case "$command" in
  create | create-start) echo "  $0 ${type}1 $(getExampleVersion "$type") random" ;;
  connect) printConnectExample "$type" ;;
  *) echo "  $0 ${type}1" ;;
  esac
}

printConnectExample() {
  case "$1" in
  mysql) echo "  $0 mysql1 -e 'SELECT VERSION()'" ;;
  postgresql) echo "  $0 postgresql1 -c 'SELECT version()'" ;;
  mongodb) echo "  $0 mongodb1 --quiet --eval 'db.version()'" ;;
  redis) echo "  $0 redis1 PING" ;;
  memcached) echo "  $0 memcached1" ;;
  esac
}

printHelp() {
  local type command
  type=$(getType)
  command=$(basename "$0" .sh)
  local formatOption="[-f json] "
  [ "$command" = "connect" ] && formatOption=""
  echo "Usage: $0 ${formatOption}$(getHelpArgs "$type" "$command")"
  echo ""
  printHelpDescription "$type" "$command"
  echo ""
  printHelpArguments "$type" "$command"
  echo ""
  echo "Options:"
  [ "$command" != "connect" ] && echo "  -f json     Print the result as JSON"
  echo "  -h, --help  Show this help"
  echo ""
  printHelpExample "$type" "$command"
}

# Show the help with -h/--help (exit 0) or when no arguments are given (exit 1).
handleHelp() {
  case "${1:-}" in
  -h | --help)
    printHelp
    exit 0
    ;;
  "")
    printHelp 1>&2
    exit 1
    ;;
  esac
}

# https://github.com/shueisha-arts-and-digital/dbdb/issues/62
redisPatch() {
  if [[ $1 =~ ^6\.[0-9]+\.[0-9]+$ ]] && [ "$(getOS)" = "macos" ]; then
    sed -i '' '/#ifdef __APPLE__/a\
#define _DARWIN_C_SOURCE
' $2
  fi
}
