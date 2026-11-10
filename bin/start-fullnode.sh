#!/usr/bin/env bash
# Start a NON-VALIDATOR full node for the ZERONYTH Falcon test net (chain 912701).  Kit v0.2.0
# Usage: bin/start-fullnode.sh [DIR]   (DIR defaults to ~/zeronyth-912701; run bin/zeronyth-falcon-key init first)
# Env: P2P_PORT (30303), RPC_PORT (8545), P2P_HOST (your public IP if you accept inbound peers), XMX (1g),
#      EXTRA_BESU_ARGS, SKIP_JAR_CHECK=1 (skip the besu/lib sha256 check), ALLOW_MNT=1 (allow DIR under /mnt on WSL2)
# v0.2.0: same Besu jars as the production 912701 validators since 2026-11-06 (native PQ tx 0x7E/0x7F, ZK tx 0x7D,
#         STARKVERIFY precompile) and the production genesis with its activation blocks. v0.1.x stops at block 165318.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; D="${1:-$HOME/zeronyth-912701}"
G="$HERE/config/genesis-falcon-912701.json"
GENESIS_SHA256=9772dce0ddee9684839afd6c33e7b6c0bf0052eb23705b83cd451adc1a91ef3d
JAVA="${JAVA_HOME:+$JAVA_HOME/bin/}java"
command -v "$JAVA" >/dev/null || { echo "java not found: install Java 25 (see JOIN guide)"; exit 1; }
JV=$("$JAVA" -XshowSettings:properties -version 2>&1 | awk -F'= ' '/java.specification.version/{print $2}')
[ "${JV%%.*}" -ge 25 ] 2>/dev/null || { echo "Java 25 or newer is required (found: ${JV:-unknown})"; exit 1; }
# 1) genesis must be exactly the production 912701 genesis (activation blocks included)
got=$(sha256sum "$G" | cut -d' ' -f1)
[ "$got" = "$GENESIS_SHA256" ] || { echo "genesis sha256 mismatch ($got) - expected the production 912701 genesis $GENESIS_SHA256 - refusing"; exit 1; }
python3 - "$G" <<'PY' || { echo "genesis is missing chain 912701 / falcon1024 / PQ+ZK activation fields - refusing"; exit 1; }
import json,sys; c=json.load(open(sys.argv[1]))['config']
need=('pqTxActivationBlock','zkPrecompileActivationBlock','zkTxActivationBlock','zkPoolAddress')
sys.exit(0 if c['chainId']==912701 and c['qbft'].get('falcon1024') and all(k in c for k in need) else 1)
PY
# 2) jars must be the published production set
if [ "${SKIP_JAR_CHECK:-0}" != 1 ]; then
  ( cd "$HERE/besu/lib" && sha256sum -c --quiet ../../besu-lib.sha256 ) || { echo "besu/lib does not match besu-lib.sha256 - refusing (re-extract the release)"; exit 1; }
fi
# 3) WSL2: keep the database on the Linux (ext4) filesystem, not on /mnt/c
case "$(readlink -f "$D" 2>/dev/null || echo "$D")" in
  /mnt/*) if [ "${ALLOW_MNT:-0}" != 1 ]; then echo "DIR is under /mnt (Windows drive). Put the node on the WSL ext4 filesystem (e.g. ~/zeronyth-912701). Set ALLOW_MNT=1 to override."; exit 1; fi;;
esac
[ -f "$D/data/falcon1024.key" ] || { echo "no Falcon key: run  $HERE/bin/zeronyth-falcon-key init $D  first"; exit 1; }
grep -q '^format=falcon1024-enc-v1' "$D/data/falcon1024.key" || { echo "Falcon key is not encrypted - refusing"; exit 1; }
ADDR=$(grep '^address=' "$D/data/falcon1024.key" | cut -d= -f2)
if python3 -c "import json,sys;g=json.load(open('$G'));sys.exit(0 if '${ADDR#0x}'.lower() in g['extraData'].lower() else 1)" 2>/dev/null; then
  echo "this Falcon key is a GENESIS VALIDATOR key - refusing (never run a validator key twice)"; exit 1; fi
cp -n "$HERE/config/static-nodes.json" "$D/static-nodes.json" 2>/dev/null || true
echo "v0.2.0" > "$D/.zeronyth-kit-version" 2>/dev/null || true
export BESU_FALCON1024_KEY_FILE="$D/data/falcon1024.key" BESU_FALCON1024_KEY_PASSWORD_FILE="$D/secrets/falcon.pass" BESU_FALCON1024_REQUIRE_ENCRYPTED=true
export BESU_OPTS="${BESU_OPTS:--Xmx${XMX:-1g}}"
NAT=(--nat-method=NONE); [ -n "${P2P_HOST:-}" ] && NAT+=(--p2p-host="$P2P_HOST")
exec "$HERE/besu/bin/besu" --genesis-file="$G" --network-id=912701 \
  --data-path="$D/data" --sync-mode=FULL \
  --bootnodes="$(cat "$HERE/config/bootnodes.txt")" --static-nodes-file="$D/static-nodes.json" \
  --p2p-port="${P2P_PORT:-30303}" "${NAT[@]}" \
  --rpc-http-enabled --rpc-http-host=127.0.0.1 --rpc-http-port="${RPC_PORT:-8545}" \
  --rpc-http-api=ETH,NET,WEB3,QBFT,ADMIN --host-allowlist=localhost,127.0.0.1 --min-gas-price=0 \
  --tx-pool-max-tx-bytes=1048576 \
  --Xsynchronizer-header-download-parallelism-factor=1 --Xsynchronizer-downloader-parallelism=2 \
  --Xsynchronizer-downloader-header-request-size=64 ${EXTRA_BESU_ARGS:-}
