#!/usr/bin/env sh
set -e
GRADLE_VERSION=8.9
BASE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DIST_ROOT="$BASE_DIR/.gradle-local"
GRADLE_HOME="$DIST_ROOT/gradle-$GRADLE_VERSION"
if [ ! -x "$GRADLE_HOME/bin/gradle" ]; then
  mkdir -p "$DIST_ROOT"
  ZIP="$DIST_ROOT/gradle-$GRADLE_VERSION-bin.zip"
  curl -L "https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip" -o "$ZIP"
  unzip -q -o "$ZIP" -d "$DIST_ROOT"
fi
exec "$GRADLE_HOME/bin/gradle" "$@"
