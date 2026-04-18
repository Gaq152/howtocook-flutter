# Android 签名密钥存放目录

本目录用于存放 release 签名的 keystore 文件。

**重要：keystore 文件（*.jks / *.keystore）与口令永不入库**，通过 `.gitignore` 规则隔离。仅本 README 作为目录占位会被提交。

## 首次生成 keystore（只做一次，永不替换）

```bash
cd android
keytool -genkey -v -keystore keystore/howtocook-release.jks \
  -keyalg RSA -keysize 2048 -validity 36500 \
  -alias howtocook \
  -dname "CN=anlife,OU=dev,O=howtocook,C=CN"
```

按提示设置 store password 和 key password（可以相同）。

## 本地开发使用

在 `android/` 下创建 `key.properties`（已 gitignore）：

```properties
storeFile=keystore/howtocook-release.jks
storePassword=你的store口令
keyAlias=howtocook
keyPassword=你的key口令
```

有了这两个文件后，`flutter build apk --release` 会自动用 release 签名。若缺失，会回退到 debug 签名（仅供本地调试）。

## CI 使用

keystore 以 base64 形式存入 GitHub Secrets，workflow 运行时解码恢复：

```bash
base64 -w 0 android/keystore/howtocook-release.jks
```

把输出粘进 `KEYSTORE_BASE64` secret，另加三个 secret：

- `KEYSTORE_PASSWORD`
- `KEY_ALIAS` = `howtocook`
- `KEY_PASSWORD`

## 重要风险

- **一旦丢失 keystore 或口令，任何新签名都无法与老版本匹配**，老用户只能卸载重装。请把 `.jks` 和口令**离线备份**到安全位置（1Password、加密 U 盘等）。
- 不要为了方便把 keystore 提交到仓库（即便是 private repo 也不建议）。
