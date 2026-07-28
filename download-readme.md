```bash
# MySQL

# - macOS ARM
#   - https://dev.mysql.com/downloads/mysql/
#   - Select `macOS`
#   - Select `macOS 15 (ARM, 64-bit)`
#   - Select `Compressed TAR Archive`
#   - e.g.

## 8.0.28
major=8
minor=0
patch=28
osVer=macos11
version=$major.$minor.$patch
url=https://dev.mysql.com/get/Downloads/MySQL-$major.$minor/mysql-$version-$osVer-arm64.tar.gz
wget -O mysql-$version-macos.tar.gz "$url"

## 8.0.42
major=8
minor=0
patch=42
osVer=macos15
version=$major.$minor.$patch
url=https://dev.mysql.com/get/Downloads/MySQL-$major.$minor/mysql-$version-$osVer-arm64.tar.gz
wget -O mysql-$version-macos.tar.gz "$url"

## 8.4.4
major=8
minor=4
patch=4
osVer=macos15
version=$major.$minor.$patch
url=https://dev.mysql.com/get/Downloads/MySQL-$major.$minor/mysql-$version-$osVer-arm64.tar.gz
wget -O mysql-$version-macos.tar.gz "$url"
## 9.2.0
major=9
minor=2
patch=0
osVer=macos15
version=$major.$minor.$patch
url=https://dev.mysql.com/get/Downloads/MySQL-$major.$minor/mysql-$version-$osVer-arm64.tar.gz
wget -O mysql-$version-macos.tar.gz "$url"
```
