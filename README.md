# ZERONYTH Falcon node — chain 912701 (test net) — v0.1.1

This package runs a non-validator full node on the ZERONYTH Falcon test net (chain ID 912701, QBFT, 1-second blocks, Falcon-1024 block seals).

- Guides: [JOIN.ja.md](JOIN.ja.md) (日本語) / [JOIN.en.md](JOIN.en.md) (English)
- `besu/`: Hyperledger Besu with the ZERONYTH Falcon-1024 QBFT patches. Build `26.11-develop-c9aa666`, Java 25. These are the same jars that run the ZERONYTH VPS nodes.
- `bin/zeronyth-falcon-key`: generates an encrypted Falcon-1024 key and shows its public key and address. It never prints secrets.
- `bin/start-fullnode.sh`: starts a non-validator full node. It refuses unencrypted keys, genesis validator keys, and any genesis that is not chain 912701.
- `config/`: the 912701 genesis (sha256 `ca050694…f85390`) and the public bootnode `enode://c949e893…de45541@58.191.52.149:30303`.
- `source/patches/`: the ZERONYTH changes on top of upstream Besu `ee9c64c`, applied with `git am`.

**EXPERIMENTAL / NOT FIPS 206.** Falcon here is BouncyCastle 1.84's implementation of NIST round-3 Falcon. It is not the final FIPS 206 FN-DSA standard and is not FIPS-validated. This is a test net: tokens have no monetary value, and no airdrop or mainnet is implied. The software is provided as-is.

License: Apache-2.0 (Hyperledger Besu and the ZERONYTH patches, see `besu/LICENSE`). Bundled third-party jars keep their own licenses. This includes BouncyCastle, which is under an MIT-style license.
