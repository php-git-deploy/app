# PHP Git Deploy releases

Signed release artifacts for [PHP Git Deploy](https://www.php-git-deploy.com),
automated Git deployments for shared hosting, packaged as a single PHAR.

> [!NOTE]
> PHP Git Deploy is pre-1.0 and under active development. Releases may contain
> breaking changes, and the signing and self-update mechanism is still being
> proven out. Review the release notes before updating, and keep the previous
> `app.<build>.phar` on disk so you can roll back.

**This repository holds no source code** — just this README, `verify.sh`,
`public-key.pem`, `LICENSE`, and `THIRD_PARTY_NOTICES.md`. Every release is a
[GitHub Release](https://github.com/php-git-deploy/app/releases); the PHAR, the
entry point, and the signed checksums live there as assets.

## Install

From the [latest release](https://github.com/php-git-deploy/app/releases/latest):

| Asset               | What it is                                           |
| ------------------- | ---------------------------------------------------- |
| `app.<build>.phar`  | the application                                      |
| `index.php`         | entry point; loads the newest `app.*.phar` beside it |
| `checksums.txt`     | SHA-256 of every asset above                         |
| `checksums.txt.sig` | OpenSSL signature over `checksums.txt`               |

```sh
base="https://github.com/php-git-deploy/app/releases/latest/download"
curl -fLO "$base/app.<build>.phar"
curl -fLO "$base/index.php"
curl -fLO "$base/checksums.txt"
curl -fLO "$base/checksums.txt.sig"
```

Verify (below), then upload `app.<build>.phar` and `index.php` to your host's web
directory. The first request creates `.htaccess`, `storage/`, and a one-time
setup URL.

To update later, drop the newer `app.<build>.phar` next to the old one. `index.php`
picks the newest by filename, and the app can do this itself (self-update).

## Verify

```sh
curl -fLO https://raw.githubusercontent.com/php-git-deploy/app/main/public-key.pem

# 1. the signature vouches for checksums.txt
openssl dgst -sha256 -verify public-key.pem \
  -signature checksums.txt.sig checksums.txt          # Verified OK

# 2. checksums.txt vouches for every file it lists
#    (Linux: sha256sum -c checksums.txt)
shasum -a 256 -c checksums.txt                        # app.<build>.phar: OK
                                                      # index.php: OK
```

Or run [`verify.sh`](verify.sh) against a directory holding the downloaded assets.

One signature over the checksum list covers every file in the release, and the
signing private key stays offline on the maintainer's machine.

**What this protects.** Once an install is running, self-updates are verified
against the `public-key.pem` that was compiled into its PHAR at build time and is
never re-fetched. A compromised repository or a swapped release asset cannot push
an update to an existing install — that would need the offline private key.

**What it does not yet protect.** A _first_ manual install trusts this repository
on first use: `public-key.pem` and the artifacts come from the same place, so
whoever can write here could serve a matching key and signature. An independent
key fingerprint for cross-checking will be published at
`https://www.php-git-deploy.com/` before 1.0. Until then a first install is only
as trustworthy as this repository and GitHub's transport.

## Releases

Cut from the private source repo with `scripts/release.sh`: build from a clean
checkout, sign `checksums.txt` with the offline key using `openssl`, then publish
with `gh release create`. Signing never runs in CI. Each release's notes record
the `build` id and the source commit.

## License

PHP Git Deploy is proprietary software, © 2025–2026 Jakub Pelák — see
[`LICENSE`](LICENSE). End-user rights are governed by the EULA at
<https://www.php-git-deploy.com/terms> (forthcoming). Bundled third-party
components keep their own licenses — see
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
