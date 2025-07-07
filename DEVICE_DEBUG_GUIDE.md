# 実機デバッグガイド

このガイドでは、実機でTODOアプリをデバッグする方法を説明します。

## 問題の概要

実機でアプリを実行すると、以下のエラーが発生する場合があります：
```
Failed to authenticate. Please check your connection and try again.
```

これは、実機から開発用バックエンドサーバーへの接続ができないことが原因です。

## 解決方法

### 1. 開発用PCのIPアドレスを確認

開発用PCの実際のIPアドレスを確認します：

**macOS/Linux:**
```bash
ifconfig | grep inet
```

**Windows:**
```bash
ipconfig
```

例：`192.168.1.100` が開発用PCのIPアドレスの場合

### 2. バックエンドサーバーを起動

```bash
cd backend
docker-compose up -d
```

### 3. 実機でのデバッグ実行

#### 方法1: スクリプトを使用（推奨）

```bash
# 実機でアプリを実行
./frontend/scripts/build_dev_device.sh 192.168.1.100

# iOS用にビルド
./frontend/scripts/build_dev_device.sh 192.168.1.100 ios

# Android用にビルド
./frontend/scripts/build_dev_device.sh 192.168.1.100 android
```

#### 方法2: 手動でIPアドレスを指定

```bash
cd frontend
flutter run --dart-define=DEV_SERVER_HOST=192.168.1.100
```

#### 方法3: 設定ファイルを直接編集

`frontend/lib/config/app_config.dart` の以下の部分を編集：

```dart
return 'http://192.168.1.100:8000';  // 実際のIPアドレスに置き換え
```

### 4. ネットワーク設定確認

- 実機と開発用PCが同じWiFiネットワークに接続されていることを確認
- ファイアウォールが8000番ポートをブロックしていないことを確認

## トラブルシューティング

### エラーメッセージに応じた対処

1. **「Failed to authenticate」**: 
   - バックエンドサーバーが起動していることを確認
   - IPアドレスが正しく設定されていることを確認

2. **「Network error」**:
   - WiFi接続を確認
   - 開発用PCのファイアウォール設定を確認
   - 同じネットワークに接続されていることを確認

3. **「Connection refused」**:
   - バックエンドサーバーが8000番ポートで動作していることを確認
   - `curl http://YOUR_IP:8000/health` でサーバーにアクセス可能か確認

### バックエンドサーバーの状態確認

```bash
# サーバーの動作確認
curl http://YOUR_IP:8000/health

# 認証エンドポイントの確認
curl -X POST http://YOUR_IP:8000/auth/simple
```

### ログの確認

アプリで詳細なエラーログを確認：
```bash
flutter logs
```

## 注意事項

- 実機デバッグ時は、実際のIPアドレスを使用する必要があります
- エミュレータでは `localhost` や `10.0.2.2` を使用できますが、実機では使用できません
- 開発用PCのIPアドレスが変わった場合は、設定を更新する必要があります

## 環境別設定

### 開発環境
- Android エミュレータ: `http://10.0.2.2:8000`
- iOS シミュレータ: `http://localhost:8000`
- 実機: `http://YOUR_PC_IP:8000`

### ステージング環境
- 全プラットフォーム: `https://todo-app-api-staging.onrender.com`

### 本番環境
- 全プラットフォーム: `https://api.todo-app.example.com` 