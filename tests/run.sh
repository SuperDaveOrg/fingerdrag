#!/usr/bin/env bash
# Run the end-to-end test in clean containers.
# Usage: tests/run.sh [image ...]
set -euo pipefail
cd "$(dirname "$0")/.."
images=("$@")
[[ ${#images[@]} -gt 0 ]] ||
	images=(debian:trixie ubuntu:26.04 ubuntu:24.04 debian:bookworm linuxmintd/mint22-amd64)
for image in "${images[@]}"; do
	echo "=================== $image"
	extra=()
	# The Mint build image identifies itself as Ubuntu; give it the
	# os-release of a real Mint 22 install.
	if [[ $image == linuxmintd/mint22-* ]]; then
		extra=(-v "$PWD/tests/fixtures/mint22-os-release:/usr/lib/os-release:ro")
	fi
	docker run --rm -v "$PWD:/src:ro" "${extra[@]}" "$image" bash /src/tests/in-container.sh
done
