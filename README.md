# keystore-backup

Backs up a directory of sensitive files (validator keystores, wallet keystores, node configs) as an
encrypted archive that can be copied anywhere.

```bash
./backup.sh -s ~/validator_keys -d /mnt/backup -k 14
./backup.sh -s ~/validator_keys -d /mnt/backup -p ~/.backup-pass -V   # unattended + verify
```

Steps:

1. `tar` is piped into `gpg --symmetric --cipher-algo AES256` and written directly to the
   destination. No unencrypted archive is written to disk.
2. A `.sha256` file is written next to each backup to detect corruption or tampering later.
3. With `-V`, the new backup is decrypted into a pipe and listed with `tar -t`, which shows that it
   can be restored.
4. Only the newest `-k` backups are kept (7 by default).

Without `-p`, gpg asks for the passphrase. With `-p FILE` the passphrase is read from that file.
Keep it at `chmod 600` and on a different disk than the backups.

## Restore

```bash
sha256sum -c backup-20260923-120000.tar.gz.gpg.sha256
gpg -d backup-20260923-120000.tar.gz.gpg | tar -xzf - -C /restore/here
```

Files are created with `umask 077`. Needs `bash`, `tar`, `gzip`, `gpg` and `sha256sum`.
