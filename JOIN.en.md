# Join the ZERONYTH Falcon test net (chain 912701) as a full node

> **Test net only.** ZNYT on chain 912701 has no monetary value. No airdrop or mainnet is promised.
>
> **Cryptography notice.** Block seals on 912701 use **Falcon-1024 from BouncyCastle 1.84, which implements the NIST round-3 Falcon submission**. That is an **experimental** implementation. It is **NOT the final FIPS 206 (FN-DSA) standard** and is not FIPS-validated. Keys and signatures may be incompatible with the final FN-DSA.

Your node joins as a **non-validator full node**. It syncs and verifies every Falcon-sealed block, but it does not propose or vote. Adding a validator needs a vote by the existing validators, and the operator approves each addition (see step 6).

## Requirements
- Linux x86_64 or arm64 (Ubuntu 22.04 / 24.04 tested) or WSL2 Ubuntu on Windows 10/11 (see "WSL2 notes"), 2+ CPU cores, 4 GB+ RAM, 20 GB+ SSD.
- **Java 25 runtime.** The build targets Java 25; Java 21 and older will not start it (tested with Temurin 25).
- Outbound TCP/UDP 30303. Inbound 30303 is optional; you only need it if you want other peers to connect to you.

## 1. Install Java 25 and download the release
```bash
sudo apt update && sudo apt install -y curl python3
mkdir -p ~/zeronyth-java && curl -fL "https://api.adoptium.net/v3/binary/latest/25/ga/linux/$(uname -m | sed 's/x86_64/x64/;s/arm64/aarch64/')/jre/hotspot/normal/eclipse" | tar xz -C ~/zeronyth-java --strip-components=1
export JAVA_HOME=~/zeronyth-java PATH=~/zeronyth-java/bin:$PATH && java -version

REL=https://github.com/ak4229330245-sudo/zeronyth-falcon-node/releases/download/falcon-912701-v0.2.0
curl -fLO $REL/zeronyth-falcon-node-912701-v0.2.0.tar.gz -fLO $REL/SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing      # must print: OK
tar xzf zeronyth-falcon-node-912701-v0.2.0.tar.gz && cd zeronyth-falcon-node-912701-v0.2.0
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
- if the genesis is not the production one (sha256 `9772dce0…ef3d`) or `besu/lib` does not match `besu-lib.sha256`
- with Java older than 25
- (WSL2) if the data directory is on a Windows drive under `/mnt`

## 4. Check sync
```bash
curl -s -X POST -H 'content-type: application/json' --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' http://127.0.0.1:8545
curl -s -X POST -H 'content-type: application/json' --data '{"jsonrpc":"2.0","id":1,"method":"net_peerCount","params":[]}' http://127.0.0.1:8545
```
Sync is done when the block number matches the latest block on https://zeronyth.dpdns.org/validator-apply.html. Blocks are produced every 1 s. In our test, a fresh node with one peer caught up about 10,500 blocks in under a minute.

If the log keeps showing either of these, you are on an old kit; upgrade to v0.2.0 as below:
- `Unsupported transaction type` with `Unable to retrieve blocks for block numbers: 165314 to 165318` (v0.1.1 and older cannot read the ML-DSA-65 transaction, type `0x7F`, in block 165,318)
- `Unable to retrieve blocks` at a low block (v0.1.0)

## Upgrading from v0.1.x (block DB and Falcon key are kept)
```bash
# 1. stop the old node (Ctrl-C)
# 2. download and extract v0.2.0 (step 1), then in its folder:
bin/upgrade-from-v0.1.x.sh            # add your node directory if it is not ~/zeronyth-912701
bin/start-fullnode.sh                 # resumes from the block where it stopped
```
- `~/zeronyth-912701/data` (block DB and `falcon1024.key`) and `secrets/falcon.pass` are neither deleted nor rewritten; your Falcon address stays the same.
- As a precaution the key and password (not the DB) are copied to `~/zeronyth-912701/backup-pre-v0.2.0-<time>/`.
- You can delete the old v0.1.x folder afterwards.

## 5. Your enode (public)
```bash
curl -s -X POST -H 'content-type: application/json' --data '{"jsonrpc":"2.0","id":1,"method":"admin_nodeInfo","params":[]}' http://127.0.0.1:8545 | grep -o 'enode://[^"]*'
```

## 6. Applying to become a validator (optional)
Use the form on https://zeronyth.dpdns.org/validator-apply.html. Paste your **enode** and your **Falcon address** (from `bin/zeronyth-falcon-key address`). The operator checks that your node is synced and reachable. A validator is only added after the operator approves it and the existing validators vote. Until then, your node stays a full node.

## Verify what you run
- `SHA256SUMS` covers the release tarball. `besu/lib` holds the exact jars running on the ZERONYTH VPS nodes (build `26.11-develop-c9aa666`).
- `besu-lib.sha256` lists the sha256 of every jar (checked automatically on each start).
- Source: see `source/SOURCE.md` (consensus: `source/patches/`; PQ transactions: `besu-912701/` in the public zeronyth repo).
- Genesis sha256: `9772dce0ddee9684839afd6c33e7b6c0bf0052eb23705b83cd451adc1a91ef3d` (v0.1.x genesis `ca050694…` plus the PQ/ZK activation blocks; the genesis block hash is unchanged)
- Supported transactions: standard 0x00–0x04, Falcon-1024 `0x7E` and ML-DSA-65 `0x7F` (from 157,773), ZK-STARK `0x7D` (from 242,414); STARKVERIFY precompile `0x7d1` (from 241,814).

## WSL2 (Windows) notes
- **Keep the node directory inside WSL (ext4), e.g. `~/zeronyth-912701`.** Under `/mnt/c/...` it is very slow and the DB is fragile (the start script refuses `/mnt`).
- Memory: put `[wsl2]` and `memory=6GB` (4 GB or more) in `C:\Users\<you>\.wslconfig`, then run `wsl --shutdown`.
- **Clock sync**: after Windows sleeps, the WSL clock can drift and the node stalls near the head. Fix it with `sudo hwclock -s` or `sudo timedatectl set-ntp true` (with systemd). `date` should be within a second of real time.
- Inbound connections do not reach WSL2 behind NAT; syncing works fine with outbound connections only.
- While Windows sleeps the node stops; when restarted it resumes where it left off.

## Stop / uninstall
Press Ctrl-C (graceful). To remove the node, delete `~/zeronyth-912701` and the release directory. Back up the key first if you want to keep your address.
