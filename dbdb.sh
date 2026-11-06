#!/bin/bash
set -eu

getInstallDir() {
  suffix=dbdb
  if [ -z "${XDG_DATA_HOME+x}" ]; then
    echo "$HOME/.local/share/$suffix"
  else
    echo "$XDG_DATA_HOME/$suffix"
  fi
}

printHelp() {
  local dir
  dir="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
  . "$dir/lib/functions.sh"
  cat <<_EOT_
DBDB - database version manager for MySQL, PostgreSQL, MongoDB, Redis and Memcached

Usage:
  $dir/dbdb.sh [-f json]
      List all instances with their type, version, port, status and data directory.
  $dir/<type>/<command>.sh [options] <name> [...]
      Manage one instance. Run any of them with --help for details.

Types:
  mysql postgresql mongodb redis memcached

Commands:
  create        <name> <version> <port|random>  Create an instance (not started)
  create-start  <name> <version> <port|random>  Create the instance if missing, then start it
  start | stop | restart | status | port  <name>
  connect       <name> [client args...]  Open the client; extra args run it non-interactively
  delete        <name>  Stop the instance and delete its data (no confirmation)

Options:
  -f json        Print the result as JSON (all commands except connect)
  -h, --help     Show this help
  -v, --version  Show the dbdb version (dbdb.sh only)

Supported versions:
  Differ by OS and CPU. See $dir/README.md

Connection (MySQL, PostgreSQL, MongoDB and Redis listen on localhost only):
_EOT_
  for type in mysql postgresql mongodb redis memcached; do
    printf "  %-11s %s\n" "$type" "$(getConnectionInfo "$type")"
  done
  cat <<_EOT_

Data directory:
  ${XDG_DATA_HOME:-$HOME/.local/share}/dbdb/<type>/versions/<version>/datadir/<name>
  Server logs (mysqld.err, postgres.log, mongodb.log) are written there.

Examples:
  $dir/mysql/create-start.sh mysql1 8.0.41 3306
  $dir/mysql/connect.sh mysql1 -e 'SHOW DATABASES'
  $dir/dbdb.sh -f json
_EOT_
}

case "${1:-}" in
-h | --help)
  printHelp
  exit 0
  ;;
-v | --version)
  cat "$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)/VERSION"
  exit 0
  ;;
esac

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

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

currentDir="$(
  cd "$(dirname "$0")" >/dev/null 2>&1
  pwd -P
)"
cd "$currentDir"
installDir=$(getInstallDir)

normalOutputs=""
jsonOutputs=""
dbTypes=(mongodb mysql postgresql redis memcached)
for dbType in "${dbTypes[@]}"; do
  for dbVersion in $(ls "$installDir/$dbType/versions" 2>/dev/null); do
    if [ -d "$installDir/$dbType/versions/$dbVersion" ]; then
      for dbServerName in $(ls "$installDir/$dbType/versions/$dbVersion/datadir" 2>/dev/null); do
        if [ -d "$installDir/$dbType/versions/$dbVersion/basedir" ]; then
          if [ -d "$installDir/$dbType/versions/$dbVersion/datadir/$dbServerName" ]; then
            # port
            dbPort="{port}"
            if [ -f "$installDir/$dbType/versions/$dbVersion/datadir/$dbServerName/$dbType.port" ]; then
              dbPort=$(cat "$installDir/$dbType/versions/$dbVersion/datadir/$dbServerName/$dbType.port")
            elif [ -f "$installDir/$dbType/versions/$dbVersion/datadir/$dbServerName/$dbType.port.last" ]; then
              dbPort=$(cat "$installDir/$dbType/versions/$dbVersion/datadir/$dbServerName/$dbType.port.last")
            elif [ -f "$installDir/$dbType/versions/$dbVersion/datadir/$dbServerName/$dbType.port.init" ]; then
              dbPort=$(cat "$installDir/$dbType/versions/$dbVersion/datadir/$dbServerName/$dbType.port.init")
            fi

            # pid
            pidFile="$installDir/$dbType/versions/$dbVersion/datadir/$dbServerName/$dbType.pid"

            # status
            if [ -f "$pidFile" ] && pgrep -F "$pidFile" >/dev/null; then
              status="running"
            else
              status="stopped"
            fi

            # change output color
            if [ "$status" = "running" ]; then
              normalOutputs="$normalOutputs ${GREEN}# $dbServerName (type:$dbType version:$dbVersion port:$dbPort) is ${status}.${NC}\n"
            else
              normalOutputs="$normalOutputs ${RED}# $dbServerName (type:$dbType version:$dbVersion port:$dbPort) is ${status}.${NC}\n"
            fi

            # normalOutputs
            normalOutputs="$normalOutputs $currentDir/$dbType/{start|stop|restart|port|status|connect|delete}.sh $dbServerName\n"
            normalOutputs="$normalOutputs $currentDir/$dbType/start.sh $dbServerName\n"
            normalOutputs="$normalOutputs $currentDir/$dbType/stop.sh  $dbServerName\n"
            normalOutputs="$normalOutputs \n"

            # confName
            if [ "$dbType" = "mongodb" ];then
              confName="$installDir/$dbType/versions/$dbVersion/datadir/$dbServerName/mongod.conf"
            elif [ "$dbType" = "mysql" ];then
              confName="$installDir/$dbType/versions/$dbVersion/datadir/$dbServerName/my.cnf"
            elif [ "$dbType" = "postgresql" ];then
              confName="$installDir/$dbType/versions/$dbVersion/datadir/$dbServerName/postgresql.conf"
            elif [ "$dbType" = "redis" ];then
              confName="$installDir/$dbType/versions/$dbVersion/datadir/$dbServerName/redis.conf"
            elif [ "$dbType" = "memcached" ];then
              confName=""
            fi

            # jsonOutputs
            availableCommands='["start.sh", "stop.sh", "restart.sh", "port.sh", "status.sh", "connect.sh", "delete.sh"]'
            jsonOutputs="$jsonOutputs{
              \"name\": \"$dbServerName\",
              \"type\": \"$dbType\",
              \"version\": \"$dbVersion\",
              \"port\": \"$dbPort\",
              \"status\": \"$status\",
              \"commandPath\": \"$currentDir/$dbType/\",
              \"availableCommands\": $availableCommands,
              \"dataDir\": \"$installDir/$dbType/versions/$dbVersion/datadir/$dbServerName\",
              \"confPath\": \"$confName\"
            },"
          fi
        fi
      done
    fi
  done
done

# Output
if [ "$format" = "json" ]; then
  echo -e "[${jsonOutputs%?}]"
else
  echo -e "${normalOutputs%?????}"
fi
