#!/usr/bin/env bash
# Lint the shell scripts with pinned shellcheck versions, so that a local run
# and CI always agree. The older release is the one Ubuntu 24.04 ships; it
# flags things the newer one lets through.
set -euo pipefail
cd "$(dirname "$0")/.."
for tag in v0.9.0 v0.11.0; do
	echo "shellcheck $tag"
	docker run --rm -v "$PWD:/mnt:ro" "koalaman/shellcheck:$tag" fingerdrag tests/*.sh
done
echo "lint clean"
