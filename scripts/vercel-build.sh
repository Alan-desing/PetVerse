#!/usr/bin/env bash
set -euo pipefail

FLUTTER_HOME="${HOME}/.cache/petverse-flutter"

if [ ! -x "${FLUTTER_HOME}/bin/flutter" ]; then
  echo "Descargando el SDK estable de Flutter..."
  release_json="$(curl --fail --silent --show-error --location \
    https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json)"
  archive="$(printf '%s' "$release_json" | node -e '
    let input = "";
    process.stdin.on("data", (chunk) => input += chunk);
    process.stdin.on("end", () => {
      const releases = JSON.parse(input);
      const stableHash = releases.current_release.stable;
      const stable = releases.releases.find((release) => release.hash === stableHash);
      if (!stable) process.exit(1);
      process.stdout.write(stable.archive);
    });
  ')"
  temp_archive="$(mktemp --suffix=.tar.xz)"
  curl --fail --silent --show-error --location \
    "https://storage.googleapis.com/flutter_infra_release/releases/${archive}" \
    --output "$temp_archive"
  mkdir -p "$FLUTTER_HOME"
  tar -xJf "$temp_archive" --strip-components=1 -C "$FLUTTER_HOME"
  rm -f "$temp_archive"
fi

export PATH="${FLUTTER_HOME}/bin:${PATH}"
flutter config --enable-web
flutter --version
flutter pub get
flutter build web --release --no-wasm-dry-run
