#!/usr/bin/env bash
# PR checks for digitaljunk-tools. Usage: scripts/check.sh <base-sha> [infra]
set -uo pipefail
BASE="${1:-origin/main}"; INFRA="${2:-}"
fail=0; err(){ echo "::error::$*"; fail=1; }
RESERVED='^(\.github|scripts|edf-redirect|ci)$'

python3 -c 'import json,sys
d=json.load(open("tools.json")); assert isinstance(d,list)
for t in d:
  for k in ("slug","name","oneliner","date"): assert k in t, f"{t} missing {k}"' || err "tools.json is invalid"

changed=$(git diff --name-only "$BASE"...HEAD) || { echo "::error::git diff failed"; exit 1; }
echo "Changed files:"; echo "$changed"
slugs=$(echo "$changed" | grep / | cut -d/ -f1 | sort -u | grep -Ev "$RESERVED" || true)

# scope: only own slug + tools.json + index.html unless infra
if [ "$INFRA" != "infra" ]; then
  n=$(echo "$slugs" | grep -c . || true)
  [ "$n" -gt 1 ] && err "PR touches multiple slug folders: $(echo $slugs). Label 'infra' if intended."
  bad=$(echo "$changed" | grep -Ev '^(tools\.json|index\.html)$' | grep -Ev "^[^/]+/" || true)
  infra_files=$(echo "$changed" | grep -E '^(\.github|ci|scripts|edf-redirect)/|^\.htaccess$|^README\.md$' || true)
  [ -n "$bad$infra_files" ] && err "PR touches non-tool files without 'infra' label: $bad $infra_files"
fi

for s in $slugs; do
  [ -d "$s" ] || continue   # deleted folder
  [[ "$s" =~ ^[a-z0-9][a-z0-9-]*$ ]] || err "slug '$s' must be lowercase a-z0-9-"
  [ -f "$s/index.html" ] || err "$s/index.html missing"
  python3 -c "import json,sys; sys.exit(0 if any(t['slug']=='$s' for t in json.load(open('tools.json'))) else 1)" || err "$s has no entry in tools.json"
  # absolute refs must stay inside /<slug>/
  hits=$(grep -rnoE "(src|href|action)=[\"']/[^\"']*" --include='*.html' "$s" | grep -vE "=[\"']/($s/|/)" || true)
  jshits=$(grep -rnoE "[\"'\`]/assets/[^\"'\`]*" --include='*.js' --include='*.mjs' --include='*.css' "$s" || true)
  [ -n "$hits$jshits" ] && err "$s has absolute paths outside /$s/ (build with base '/$s/'):
$hits
$jshits"
  # secrets heuristics
  grep -rlE '(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{30,}|gho_[A-Za-z0-9]{30,}|sk-[A-Za-z0-9]{32,}|-----BEGIN [A-Z ]*PRIVATE KEY)' "$s" && err "$s looks like it contains a secret"
  ls "$s"/.env* >/dev/null 2>&1 && err "$s contains .env files"
  # static only
  find "$s" -type f \( -name '*.php' -o -name '*.py' -o -name '*.cgi' -o -name '*.sh' -o -name 'package.json' \) | grep . && err "$s must be static built files only"
done

big=$(find . -path ./.git -prune -o -type f -size +20M -print)
[ -n "$big" ] && err "Files over 20 MB: $big"

exit $fail
