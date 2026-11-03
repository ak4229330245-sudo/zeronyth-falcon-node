#!/usr/bin/env bash
# Start a NON-VALIDATOR full node for the ZERONYTH Falcon test net (chain 912701).
# Usage: bin/start-fullnode.sh [DIR]   (DIR defaults to ~/zeronyth-912701; run bin/zeronyth-falcon-key init first)
# Env: P2P_PORT (30303), RPC_PORT (8545), P2P_HOST (your public IP if you accept inbound peers), XMX (1g), EXTRA_BESU_ARGS
# Sync tuning: Falcon-1024 seals make each header ~10 KB, so header requests are kept small and few;
# with Besu defaults a node with a single peer stalls ("Unable to retrieve blocks").
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; D="${1:-$HOME/zeronyth-912701}"
G="$HERE/config/genesis-falcon-912701.json"
python3 - "$G" <<'PY' 2>/dev/null || grep -q '"chainId" *: *912701' "$G" || { echo "genesis is not chain 912701 - refusing"; exit 1; }
import json,sys; c=json.load(open(sys.argv[1]))['config']; sys.exit(0 if c['chainId']==912701 and c['qbft'].get('falcon1024') else 1)
PY
[ -f "$D/data/falcon1024.key" ] || { echo "no Falcon key: run  $HERE/bin/zeronyth-falcon-key init $D  first"; exit 1; }
grep -q '^format=falcon1024-enc-v1' "$D/data/falcon1024.key" || { echo "Falcon key is not encrypted - refusing"; exit 1; }
ADDR=$(grep '^address=' "$D/data/falcon1024.key" | cut -d= -f2)
if python3 -c "import json,sys;g=json.load(open('$G'));sys.exit(0 if '${ADDR#0x}'.lower() in g['extraData'].lower() else 1)" 2>/dev/null; then
  echo "this Falcon key is a GENESIS VALIDATOR key - refusing (never run a validator key twice)"; exit 1; fi
cp -n "$HERE/config/static-nodes.json" "$D/static-nodes.json" 2>/dev/null || true
export BESU_FALCON1024_KEY_FILE="$D/data/falcon1024.key" BESU_FALCON1024_KEY_PASSWORD_FILE="$D/secrets/falcon.pass" BESU_FALCON1024_REQUIRE_ENCRYPTED=true
export BESU_OPTS="${BESU_OPTS:--Xmx${XMX:-1g}}"
NAT=(--nat-method=NONE); [ -n "${P2P_HOST:-}" ] && NAT+=(--p2p-host="$P2P_HOST")
exec "$HERE/besu/bin/besu" --genesis-file="$G" --network-id=912701 \
  --data-path="$D/data" --sync-mode=FULL \
  --bootnodes="$(cat "$HERE/config/bootnodes.txt")" --static-nodes-file="$D/static-nodes.json" \
  --p2p-port="${P2P_PORT:-30303}" "${NAT[@]}" \
  --rpc-http-enabled --rpc-http-host=127.0.0.1 --rpc-http-port="${RPC_PORT:-8545}" \
  --rpc-http-api=ETH,NET,WEB3,QBFT,ADMIN --host-allowlist=localhost,127.0.0.1 --min-gas-price=0 \
  --Xsynchronizer-header-download-parallelism-factor=1 --Xsynchronizer-downloader-parallelism=2 \
  --Xsynchronizer-downloader-header-request-size=64 ${EXTRA_BESU_ARGS:-}
