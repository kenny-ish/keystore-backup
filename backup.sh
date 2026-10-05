#!/usr/bin/env bash
# Encrypted, rotated backups of a directory.
set -euo pipefail
umask 077

usage() {
  echo "usage: $0 -s SOURCE_DIR -d DEST_DIR [-k KEEP] [-p PASSPHRASE_FILE] [-V]" >&2
  exit 2
}

src="" dest="" keep=7 pass_file="" verify=0
while getopts "s:d:k:p:Vh" opt; do
  case "$opt" in
    s) src=$OPTARG ;;
    d) dest=$OPTARG ;;
    k) keep=$OPTARG ;;
    p) pass_file=$OPTARG ;;
    V) verify=1 ;;
    *) usage ;;
  esac
done
[[ -n $src && -n $dest ]] || usage
[[ -d $src ]] || { echo "source $src is not a directory" >&2; exit 1; }
[[ -z $pass_file || -r $pass_file ]] || { echo "cannot read $pass_file" >&2; exit 1; }
mkdir -p "$dest"

gpg_opts=(--batch --yes)
if [[ -n $pass_file ]]; then
  gpg_opts+=(--pinentry-mode loopback --passphrase-file "$pass_file")
else
  gpg_opts=(--yes)
fi

out="$dest/backup-$(date +%Y%m%d-%H%M%S).tar.gz.gpg"
tar -C "$(dirname "$src")" -czf - "$(basename "$src")" |
  gpg "${gpg_opts[@]}" --symmetric --cipher-algo AES256 -o "$out"
(cd "$dest" && sha256sum "$(basename "$out")" >"$(basename "$out").sha256")
echo "wrote $out ($(du -h "$out" | cut -f1))"

if ((verify)); then
  count=$(gpg "${gpg_opts[@]}" --quiet -d "$out" | tar -tzf - | wc -l)
  echo "verified: archive decrypts and lists $count entries"
fi

shopt -s nullglob
backups=("$dest"/backup-*.tar.gz.gpg) # names sort chronologically
excess=$((${#backups[@]} - keep))
for ((i = 0; i < excess; i++)); do
  rm -f -- "${backups[$i]}" "${backups[$i]}.sha256"
  echo "removed old ${backups[$i]}"
done
