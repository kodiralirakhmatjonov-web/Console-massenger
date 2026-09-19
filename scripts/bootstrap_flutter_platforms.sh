#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK is required."
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cp -R lib "$TMP/lib"
cp pubspec.yaml "$TMP/pubspec.yaml"
cp analysis_options.yaml "$TMP/analysis_options.yaml"

flutter create \
  --project-name console_messenger \
  --org com.iumrah \
  --platforms ios,android,web \
  .

rm -rf lib
cp -R "$TMP/lib" lib
cp "$TMP/pubspec.yaml" pubspec.yaml
cp "$TMP/analysis_options.yaml" analysis_options.yaml

python3 <<'PY'
from pathlib import Path
import re

pbx = Path('ios/Runner.xcodeproj/project.pbxproj')
if pbx.exists():
    text = pbx.read_text(encoding='utf-8')
    text = re.sub(
        r'PRODUCT_BUNDLE_IDENTIFIER = [^;]+;',
        lambda m: 'PRODUCT_BUNDLE_IDENTIFIER = com.iumrah.beta.RunnerTests;'
        if 'RunnerTests' in m.group(0)
        else 'PRODUCT_BUNDLE_IDENTIFIER = com.iumrah.beta;',
        text,
    )
    pbx.write_text(text, encoding='utf-8')
PY

flutter pub get
flutter analyze

echo "Flutter platform scaffolding ready."
echo "iOS bundle target: com.iumrah.beta"
