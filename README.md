# ZERONYTH Falcon node — chain 912701 (test net) — v0.2.0

This package runs a non-validator full node on the ZERONYTH Falcon test net (chain ID 912701, QBFT, 1-second blocks, Falcon-1024 block seals).

**v0.2.0 is required to sync past block 165,318.** v0.1.x stops there with `Unsupported transaction type` / `Unable to retrieve blocks for block numbers: 165314 to 165318`, because block 165,318 carries the first native ML-DSA-65 transaction (type `0x7F`). Upgrade an existing v0.1.x node in place with `bin/upgrade-from-v0.1.x.sh` — the block database and the Falcon key are kept.

- Guides: [JOIN.ja.md](JOIN.ja.md) (日本語) / [JOIN.en.md](JOIN.en.md) (English)
- `besu/`: the exact jars that run the ZERONYTH 912701 validators since 2026-11-06 (version string `26.11-develop-c9aa666`, Java 25). Includes native post-quantum transactions Falcon-1024 `0x7E` and ML-DSA-65 `0x7F` (active from block 157,773), native ZK-STARK transactions `0x7D` (from 242,414) and the STARKVERIFY precompile `0x7d1` (from 241,814). Falcon-1024 QBFT consensus and the key file format are unchanged from v0.1.x.
- `besu-lib.sha256`: SHA-256 of every jar in `besu/lib`; checked by `start-fullnode.sh` on every start.
- `bin/zeronyth-falcon-key`: generates an encrypted Falcon-1024 key and shows its public key and address. It never prints secrets.
- `bin/start-fullnode.sh`: starts a non-validator full node. Refuses: a genesis other than the production one (sha256 pinned), jars that do not match `besu-lib.sha256`, Java < 25, unencrypted keys, genesis validator keys, and (on WSL2) a data directory under `/mnt`.
- `bin/upgrade-from-v0.1.x.sh`: in-place upgrade from v0.1.0/v0.1.1 keeping `data/` (DB + `falcon1024.key`) and `secrets/`.
- `config/`: the production 912701 genesis (sha256 `9772dce0ddee9684839afd6c33e7b6c0bf0052eb23705b83cd451adc1a91ef3d`; adds `pqTxActivationBlock`, `zkPrecompileActivationBlock`, `zkTxActivationBlock`, `zkPoolAddress` — the genesis block hash is unchanged) and the public bootnode `enode://c949e893…de45541@58.191.52.149:30303`.
- `source/`: see `source/SOURCE.md`.

**EXPERIMENTAL / NOT FIPS 206.** Falcon here is BouncyCastle 1.84's implementation of NIST round-3 Falcon. It is not the final FIPS 206 FN-DSA standard and is not FIPS-validated. This is a test net: tokens have no monetary value, and no airdrop or mainnet is implied. The software is provided as-is.

License: Apache-2.0 (Hyperledger Besu and the ZERONYTH patches, see `besu/LICENSE`). Bundled third-party jars keep their own licenses. This includes BouncyCastle, which is under an MIT-style license.
