# Source for the jars in this kit

All of it is in https://github.com/ak4229330245-sudo/zeronyth under `besu-912701/` (upstream Hyperledger Besu 26.9.0 + ZERONYTH patches; build with JDK 25 and the Gradle wrapper, `./gradlew installDist -Pversion=26.11-develop-c9aa666`).

- `patches/0001`–`0007` (this folder): the Falcon-1024 QBFT consensus patch set on upstream Besu `ee9c64c` (26.9.0). Consensus and key-file classes in this kit are byte-identical to the v0.1.x build of these patches.
- Native PQ transactions (`0x7E` Falcon-1024, `0x7F` ML-DSA-65, `pqTxActivationBlock`): `besu-912701/` — see `besu-912701/ZERONYTH-SOURCE.md` and `docs/BINARY-PROVENANCE.md`.
- Native ZK-STARK transactions (`0x7D`), the STARKVERIFY precompile (`0x7d1`) and the `zk*` genesis options: `besu-912701/`, reconstructed from the production `besu-zk` bytecode on 2026-11-10 (commit 0030ebd "ZERONYTH zk-STARK: native ZK tx type 0x7D …"). A clean build of that tree matches these jars class-for-class (0 differing classes) and a full sync with it reproduces the production stateRoots — see `docs/ZK-SOURCE-RECONSTRUCTION.md`.
