#!/usr/bin/env bash
# Upgrade a node that was running kit v0.1.0 / v0.1.1 to this kit (v0.2.0), KEEPING its block database
# (DIR/data), its Falcon key (DIR/data/falcon1024.key) and its password (DIR/secrets/falcon.pass).
# Nothing in DIR is deleted or rewritten. The old kit folder is not touched (you can delete it afterwards).
# Usage: 1) stop the old node (Ctrl-C)  2) bin/upgrade-from-v0.1.x.sh [DIR]  3) bin/start-fullnode.sh [DIR]
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; D="${1:-$HOME/zeronyth-912701}"
[ -d "$D/data" ] || { echo "no node directory at $D (expected $D/data). Pass the directory you used with v0.1.x."; exit 1; }
[ -f "$D/data/falcon1024.key" ] || { echo "no Falcon key at $D/data/falcon1024.key - nothing to upgrade"; exit 1; }
[ -f "$D/secrets/falcon.pass" ] || echo "WARNING: $D/secrets/falcon.pass not found (start-fullnode.sh expects it there)"
if pgrep -f -- "--data-path=$D/data" >/dev/null 2>&1; then
  echo "a node is still running on $D/data - stop it first (Ctrl-C in its terminal), then run this again"; exit 1; fi
case "$(readlink -f "$D")" in /mnt/*) echo "NOTE: $D is on a Windows drive (/mnt). Move it into WSL (~/) before starting; see JOIN guide (WSL2).";; esac
echo "Falcon key (public info only):"; grep -E '^(format|address)=' "$D/data/falcon1024.key"
# small safety copy of the key + password only (the DB is not copied); 0700, inside DIR
B="$D/backup-pre-v0.2.0-$(date +%Y%m%d-%H%M%S)"; ( umask 077; mkdir -p "$B"; cp -p "$D/data/falcon1024.key" "$B/"; if [ -f "$D/secrets/falcon.pass" ]; then cp -p "$D/secrets/falcon.pass" "$B/"; fi )
echo "copied key + password to $B (keep it private; delete when no longer needed)"
# static-nodes: keep the user's entries, add the public bootnode if missing
python3 - "$D/static-nodes.json" "$HERE/config/static-nodes.json" <<'PY'
import json,sys,os
mine,ref=sys.argv[1],sys.argv[2]; r=json.load(open(ref))
m=json.load(open(mine)) if os.path.exists(mine) else []
for e in r:
  if e not in m: m.append(e)
json.dump(m,open(mine,'w'),indent=1); print("static-nodes.json:",len(m),"entries")
PY
if "$HERE/bin/zeronyth-falcon-key" address "$D/data/falcon1024.key" >/dev/null 2>&1; then echo "key file opens with this kit: OK"; else echo "WARNING: could not read the key with this kit (check Java 25)"; fi
echo "Done. Start with:  $HERE/bin/start-fullnode.sh $D"
echo "The node resumes from its last block; blocks from 165318 on (PQ/ZK transactions) now import."
