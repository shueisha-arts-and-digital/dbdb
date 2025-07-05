#!/usr/bin/env bash
set -eu

. ../lib/functions.sh

type=mongodb
version=4.4.10

cd ../$type/..

date=$(date +%Y%m%d%H%M%S)
md5="md5"
[ "$(getOS)" = "linux" ] && md5="md5sum"
hash=$(echo "dbdb-$date" | $md5 | cut -d ' ' -f 1)

echo "# Test create"
./$type/create.sh dbdb-test-$hash $version random
echo "# Test port"
./$type/port.sh dbdb-test-$hash
echo "# Test start"
./$type/start.sh dbdb-test-$hash
echo "# Test status"
./$type/status.sh dbdb-test-$hash
echo "# Test restart"
./$type/restart.sh dbdb-test-$hash
echo "# Test stop"
./$type/stop.sh dbdb-test-$hash
echo "# Test delete"
./$type/delete.sh dbdb-test-$hash

echo "# Test create"
./$type/create.sh -f json dbdb-test-$hash $version random | jq
echo "# Test port"
./$type/port.sh -f json dbdb-test-$hash | jq
echo "# Test start"
./$type/start.sh -f json dbdb-test-$hash | jq
echo "# Test status"
./$type/status.sh -f json dbdb-test-$hash | jq
echo "# Test restart"
./$type/restart.sh -f json dbdb-test-$hash | jq
echo "# Test stop"
./$type/stop.sh -f json dbdb-test-$hash | jq
echo "# Test delete"
./$type/delete.sh -f json dbdb-test-$hash | jq

./dbdb.sh
./$type/create-start.sh -f json dbdb-test-$hash $version random | jq
./dbdb.sh -f json | jq
./$type/delete.sh dbdb-test-$hash
./dbdb.sh
