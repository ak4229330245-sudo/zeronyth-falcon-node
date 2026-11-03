# Join the ZERONYTH Falcon test net (chain 912701) as a full node

> **Test net only.** ZNYT on chain 912701 has no monetary value. No airdrop or mainnet is promised.
>
> **Cryptography notice.** Block seals on 912701 use **Falcon-1024 from BouncyCastle 1.84, which implements the NIST round-3 Falcon submission**. That is an **experimental** implementation. It is **NOT the final FIPS 206 (FN-DSA) standard** and is not FIPS-validated. Keys and signatures may be incompatible with the final FN-DSA.

Your node joins as a **non-validator full node**. It syncs and verifies every Falcon-sealed block, but it does not propose or vote. Adding a validator needs a vote by the existing validators, and the operator approves each addition (see step 6).

## Requirements
- Linux x86_64 or arm64 (Ubuntu 22.04 / 24.04 tested), 2+ CPU cores, 4 GB+ RAM, 20 GB+ SSD.
- **Java 25 runtime.** The build targets Java 25; older Java versions will not start it.
- Outbound TCP/UDP 30303. Inbound 30303 is optional; you only need it if you want other peers to connect to you.

## 1. Install Java 25 and download the release
```bash
sudo apt update && sudo apt install -y curl python3
mkdir -p ~/zeronyth-java && curl -fL "https://api.adoptium.net/v3/binary/latest/25/ga/linux/$(uname -m | sed 's/x86_64/x64/;s/arm64/aarch64/')/jre/hotspot/normal/eclipse" | tar xz -C ~/zeronyth-java --strip-components=1
export JAVA_HOME=~/zeronyth-java PATH=~/zeronyth-java/bin:$PATH && java -version

REL=https://github.com/ak4229330245-sudo/zeronyth-falcon-node/releases/download/falcon-912701-v0.1.0
curl -fLO $REL/zeronyth-falcon-node-912701-v0.1.0.tar.gz -fLO $REL/SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing      # must print: OK
tar xzf zeronyth-falcon-node-912701-v0.1.0.tar.gz && cd zeronyth-falcon-node-912701-v0.1.0
```

## 2. Create your Falcon key (encrypted)
Every node on 912701 needs its own Falcon-1024 key, including full nodes.
```bash
bin/zeronyth-falcon-key init          # creates ~/zeronyth-912701/data/falcon1024.key + ~/zeronyth-912701/secrets/falcon.pass
bin/zeronyth-falcon-key address       # shows format, address and the full public key (public info)
```
- The key is encrypted with AES-256-GCM. The encryption key is derived with scrypt from a random password. Both files are created with mode 0600.
- **Back up `falcon1024.key` and `falcon.pass` offline. Never send either file to anyone.** ZERONYTH will never ask for them.
- Never run the same key on two machines at once.

## 3. Start the node
```bash
bin/start-fullnode.sh                 # data in ~/zeronyth-912701, P2P 30303, RPC 127.0.0.1:8545
# inbound peers (optional): P2P_HOST=<your public IP> bin/start-fullnode.sh
```
The node connects to the public bootnode `58.191.52.149:30303` (it is listed in `config/static-nodes.json` and `config/bootnodes.txt`) and starts syncing straight away. The script refuses to start:
- with a key that is not encrypted
- with a genesis that is not chain 912701
- with a genesis validator key

## 4. Check sync
```bash
curl -s -X POST -H 'content-type: application/json' --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' http://127.0.0.1:8545
curl -s -X POST -H 'content-type: application/json' --data '{"jsonrpc":"2.0","id":1,"method":"net_peerCount","params":[]}' http://127.0.0.1:8545
```
Sync is done when the block number matches the latest block on https://zeronyth.dpdns.org/validator-apply.html. Blocks are produced every 1 s.

## 5. Your enode (public)
```bash
curl -s -X POST -H 'content-type: application/json' --data '{"jsonrpc":"2.0","id":1,"method":"admin_nodeInfo","params":[]}' http://127.0.0.1:8545 | grep -o 'enode://[^"]*'
```

## 6. Applying to become a validator (optional)
Use the form on https://zeronyth.dpdns.org/validator-apply.html. Paste your **enode** and your **Falcon address** (from `bin/zeronyth-falcon-key address`). The operator checks that your node is synced and reachable. A validator is only added after the operator approves it and the existing validators vote. Until then, your node stays a full node.

## Verify what you run
- `SHA256SUMS` covers the release tarball. `besu/lib` holds the exact jars running on the ZERONYTH VPS nodes (build `26.11-develop-c9aa666`).
- Source: Hyperledger Besu `ee9c64c` (26.9.0 changelog rotation) plus the ZERONYTH patches in `source/patches/` (`git am`).
- Genesis sha256: `ca05069449b2baa429c95cb993d1d4af143fe22ecaec51b6a6ae5953a4f85390`

## Stop / uninstall
Press Ctrl-C (graceful). To remove the node, delete `~/zeronyth-912701` and the release directory. Back up the key first if you want to keep your address.
