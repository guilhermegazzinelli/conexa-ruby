#!/usr/bin/env bash
# Run the spec suite (and optionally RuboCop) against every supported Ruby.
#
# The gem declares >= 3.1 and CI covers 3.1-3.4; this reproduces that matrix
# locally before pushing, which is cheaper than finding out from CI.
#
# Usage:
#   claude_scripts/multi_ruby_specs/run.sh            # specs on every version
#   claude_scripts/multi_ruby_specs/run.sh --lint     # also run rubocop on the first
#   RUBIES="3.1.7 3.4.7" claude_scripts/multi_ruby_specs/run.sh
set -uo pipefail

cd "$(dirname "$0")/../.." || exit 1

RUBIES=${RUBIES:-"3.1.7 3.2.9 3.3.10 3.4.7"}
LINT=0
[[ ${1:-} == "--lint" ]] && LINT=1

command -v mise >/dev/null || { echo "mise not found — install it or set RUBIES to versions on PATH"; exit 1; }

# One bundle path per version: native extensions are not portable across them,
# and sharing vendor/bundle makes each run clobber the last.
export BUNDLE_WITHOUT=development

results=()
status=0

for version in $RUBIES; do
  echo
  echo "=============================================================="
  echo " ruby $version"
  echo "=============================================================="

  if ! mise ls ruby 2>/dev/null | grep -q "$version"; then
    echo "  SKIP — not installed (mise install ruby@$version)"
    results+=("$version SKIP")
    continue
  fi

  export BUNDLE_PATH="vendor/bundle-$version"

  if ! mise x "ruby@$version" -- bundle install --quiet; then
    echo "  FAIL — bundle install"
    results+=("$version FAIL(install)")
    status=1
    continue
  fi

  if mise x "ruby@$version" -- bundle exec rspec --format progress; then
    results+=("$version PASS")
  else
    results+=("$version FAIL(specs)")
    status=1
  fi
done

if [[ $LINT -eq 1 ]]; then
  first=$(echo "$RUBIES" | awk '{print $1}')
  echo
  echo "=============================================================="
  echo " rubocop (ruby $first)"
  echo "=============================================================="
  export BUNDLE_PATH="vendor/bundle-$first"
  if mise x "ruby@$first" -- bundle exec rubocop --parallel; then
    results+=("rubocop PASS")
  else
    results+=("rubocop FAIL")
    status=1
  fi
fi

echo
echo "=============================================================="
echo " summary"
echo "=============================================================="
printf '  %s\n' "${results[@]}"
exit $status
