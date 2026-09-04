#!/usr/bin/env bash
#
# Verify a downloaded PHP Git Deploy release.
#
#   ./verify.sh [dir]
#
# <dir> (default: current directory) must contain the release assets:
#   app.<build>.phar, index.php, checksums.txt, checksums.txt.sig
# and public-key.pem — either in <dir>, or next to this script (this repo's copy).
#
# Steps: (1) verify the OpenSSL signature over checksums.txt with the public key,
# then (2) check every file listed in checksums.txt against its recorded SHA-256.
# The signature vouches for the manifest; the manifest vouches for the files.

set -euo pipefail

fail() { echo "error: $*" >&2; exit 1; }

dir="${1:-.}"
script_dir="$(cd "$(dirname "$0")" && pwd)"

[[ -d "$dir" ]] || fail "$dir is not a directory"
cd "$dir"

key="public-key.pem"
[[ -f "$key" ]] || key="$script_dir/public-key.pem"
[[ -f "$key" ]] || fail "public-key.pem not found in $dir or beside verify.sh"

[[ -f "checksums.txt" ]]     || fail "checksums.txt missing"
[[ -f "checksums.txt.sig" ]] || fail "checksums.txt.sig missing"

# sha256sum on Linux, shasum on macOS (and anywhere Perl is installed).
if command -v sha256sum >/dev/null 2>&1; then
  sha=(sha256sum)
elif command -v shasum >/dev/null 2>&1; then
  sha=(shasum -a 256)
else
  fail "neither sha256sum nor shasum found"
fi

echo "1. signature over checksums.txt:"
openssl dgst -sha256 -verify "$key" -signature checksums.txt.sig checksums.txt \
  || fail "signature does not match checksums.txt — do not use this release"

echo
echo "2. file hashes:"
"${sha[@]}" -c checksums.txt \
  || fail "one or more files do not match checksums.txt — do not use this release"

# A file that checksums.txt does not mention was never signed. Point it out.
for f in app.*.phar index.php; do
  [[ -f "$f" ]] || continue
  grep -Fq -- " $f" checksums.txt \
    || echo "warning: $f is not listed in checksums.txt and was not verified" >&2
done

echo
echo "OK — release in $PWD is authentic."
