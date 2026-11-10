# ZERONYTH Falcon テストネット（チェーン 912701）にフルノードで参加する

> **テストネット専用です。** チェーン 912701 の ZNYT にお金としての価値はありません。エアドロップやメインネットを約束するものではありません。
>
> **暗号についての注意。** 912701 のブロック署名には **BouncyCastle 1.84 の Falcon-1024（NIST 第3ラウンド提出版の実装）** を使っています。これは**実験的な実装**で、**最終規格の FIPS 206（FN-DSA）ではありません**。FIPS 認証も受けていません。正式な FN-DSA とは鍵・署名の互換性がない可能性があります。

参加するノードは **バリデーターではないフルノード** です。Falcon 署名付きの全ブロックを同期して検証しますが、ブロックの提案や投票はしません。バリデーターの追加には既存バリデーターの投票が必要で、運営が1件ずつ承認します（手順6）。

## 必要なもの
- Linux x86_64 / arm64（Ubuntu 22.04 / 24.04 で確認）、または Windows 10/11 の WSL2 Ubuntu（下の「WSL2 の注意」を参照）
- CPU 2コア以上、メモリ 4 GB以上、SSD 20 GB以上
- **Java 25**（このビルドは Java 25 向けです。Java 21 以下では起動しません。Temurin 25 で確認済み）
- 外向きの TCP/UDP 30303。内向きの 30303 は任意です（他のノードから接続を受けたい場合だけ必要）。

## 1. Java 25 の導入とリリースのダウンロード
```bash
sudo apt update && sudo apt install -y curl python3
mkdir -p ~/zeronyth-java && curl -fL "https://api.adoptium.net/v3/binary/latest/25/ga/linux/$(uname -m | sed 's/x86_64/x64/;s/arm64/aarch64/')/jre/hotspot/normal/eclipse" | tar xz -C ~/zeronyth-java --strip-components=1
export JAVA_HOME=~/zeronyth-java PATH=~/zeronyth-java/bin:$PATH && java -version

REL=https://github.com/ak4229330245-sudo/zeronyth-falcon-node/releases/download/falcon-912701-v0.2.0
curl -fLO $REL/zeronyth-falcon-node-912701-v0.2.0.tar.gz -fLO $REL/SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing      # 「OK」と出ること
tar xzf zeronyth-falcon-node-912701-v0.2.0.tar.gz && cd zeronyth-falcon-node-912701-v0.2.0
```

## 2. Falcon 鍵を作る（暗号化）
912701 では、フルノードも含めて全ノードに自分専用の Falcon-1024 鍵が必要です。
```bash
bin/zeronyth-falcon-key init          # ~/zeronyth-912701/data/falcon1024.key と ~/zeronyth-912701/secrets/falcon.pass を作成
bin/zeronyth-falcon-key address       # 形式・アドレス・公開鍵（すべて公開情報）を表示
```
- 鍵は AES-256-GCM で暗号化されます。暗号化の鍵は、ランダムなパスワードから scrypt で作ります。2つのファイルはどちらも権限 0600 で作成されます。
- **`falcon1024.key` と `falcon.pass` はオフラインにバックアップし、誰にも送らないでください。** 運営が聞くこともありません。
- 同じ鍵を2台で同時に動かさないでください。

## 3. ノードを起動
```bash
bin/start-fullnode.sh                 # データは ~/zeronyth-912701、P2P 30303、RPC は 127.0.0.1:8545 のみ
# 外部からの接続も受ける場合（任意）: P2P_HOST=<あなたのグローバルIP> bin/start-fullnode.sh
```
公開ブートノード `58.191.52.149:30303` に自動で接続し、すぐに同期を始めます（`config/static-nodes.json` と `config/bootnodes.txt` に記載済み）。次の場合、スクリプトは起動を拒否します。
- 鍵が暗号化されていない
- genesis がチェーン 912701 のものではない
- genesis のバリデーター鍵を使おうとしている
- genesis が本番のもの（sha256 `9772dce0…ef3d`）と違う、または `besu/lib` の jar が `besu-lib.sha256` と合わない
- Java が 25 より古い
- （WSL2）データの場所が `/mnt/c` などの Windows ドライブ上にある

## 4. 同期の確認
```bash
curl -s -X POST -H 'content-type: application/json' --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' http://127.0.0.1:8545
curl -s -X POST -H 'content-type: application/json' --data '{"jsonrpc":"2.0","id":1,"method":"net_peerCount","params":[]}' http://127.0.0.1:8545
```
https://zeronyth.dpdns.org/validator-apply.html の「最新ブロック」と同じ数字になれば同期完了です。ブロックは1秒ごとに作られます。私たちのテストでは、ピア1つの新規ノードが約10,500ブロックに1分以内で追いつきました。

ログに次のどちらかが出続ける場合は古い版です。下の「v0.1.x からの更新」で v0.2.0 にしてください。
- `Unsupported transaction type` と `Unable to retrieve blocks for block numbers: 165314 to 165318`（v0.1.1 以前。ブロック 165,318 の ML-DSA-65 取引 `0x7F` を読めません）
- 低いブロックで `Unable to retrieve blocks` が続く（v0.1.0）

## v0.1.x からの更新（ブロックDBと Falcon 鍵はそのまま）
```bash
# 1. 古いノードを Ctrl-C で止める
# 2. v0.2.0 をダウンロードして展開（手順1）し、そのフォルダで:
bin/upgrade-from-v0.1.x.sh            # ~/zeronyth-912701 以外を使っていた場合はそのパスを付ける
bin/start-fullnode.sh                 # 止まったブロックの続きから同期します
```
- `~/zeronyth-912701/data`（ブロックDBと `falcon1024.key`）と `secrets/falcon.pass` は消しも書き換えもしません。Falcon アドレスも変わりません。
- 念のため、鍵とパスワードだけを `~/zeronyth-912701/backup-pre-v0.2.0-日時/` にコピーします（DBはコピーしません）。
- 古い v0.1.x のフォルダは、更新後に消してかまいません。

## 5. 自分の enode（公開情報）
```bash
curl -s -X POST -H 'content-type: application/json' --data '{"jsonrpc":"2.0","id":1,"method":"admin_nodeInfo","params":[]}' http://127.0.0.1:8545 | grep -o 'enode://[^"]*'
```

## 6. バリデーターへの申請（任意）
https://zeronyth.dpdns.org/validator-apply.html のフォームに、**enode** と **Falcon アドレス**（`bin/zeronyth-falcon-key address` で表示されるもの）を貼ってください。運営がノードの同期と接続を確認します。運営の承認と既存バリデーターの投票を経てから追加されます。それまではフルノードのままです。

## 中身の確認
- `SHA256SUMS` はリリースの tar.gz を対象にしています。`besu/lib` には、ZERONYTH の VPS ノードで実際に動いているものと同じ jar が入っています（ビルド `26.11-develop-c9aa666`）。
- ソース: `source/SOURCE.md` を見てください（合意部分は `source/patches/`、PQ取引は公開リポジトリ `zeronyth` の `besu-912701/`）。
- `besu-lib.sha256` に全 jar の sha256 があります（起動のたびに自動で確認します）。
- genesis の sha256: `9772dce0ddee9684839afd6c33e7b6c0bf0052eb23705b83cd451adc1a91ef3d`（v0.1.x の `ca050694…` に PQ/ZK の有効化ブロックを足したもの。genesis ブロックのハッシュは同じです）
- 対応している取引: 通常の 0x00〜0x04、Falcon-1024 `0x7E`・ML-DSA-65 `0x7F`（157,773 から）、ZK-STARK `0x7D`（242,414 から）。STARKVERIFY プリコンパイル `0x7d1`（241,814 から）。

## WSL2（Windows）の注意
- **ノードのフォルダは WSL の中（`~/zeronyth-912701` など ext4）に置いてください。** `/mnt/c/...` に置くと非常に遅く、DB が壊れやすくなります（スクリプトは `/mnt` を拒否します）。
- メモリ: `C:\Users\<名前>\.wslconfig` に `[wsl2]` と `memory=6GB`（4GB以上）を書き、`wsl --shutdown` で反映します。
- **時計合わせ**: スリープ復帰後に WSL の時計がずれると、最新ブロック付近で同期が止まります。`sudo hwclock -s` か `sudo timedatectl set-ntp true`（systemd 有効時）で合わせてください。`date` が実際の時刻と1秒以上ずれていないか確認できます。
- 外からの接続は WSL2 の NAT で届きません。同期は外向きの接続だけで問題なくできます。
- Windows のスリープ中はノードも止まります。起動し直すと続きから同期します。

## 停止・削除
Ctrl-C で安全に停止します。削除するときは `~/zeronyth-912701` とリリースのフォルダを消してください。同じアドレスを使い続けたい場合は、先に鍵をバックアップしてください。
