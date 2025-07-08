# TODOアプリ - Render本番環境デプロイ手順書

## 概要
このドキュメントは、TODOアプリをRender.comにデプロイするための詳細な手順を説明します。

## 前提条件
- GitHubアカウントとリポジトリ
- Render.comアカウント
- データベースが既に設定済み

## 重要な注意事項
- **Python版**: このアプリケーションは**Python 3.12**で動作するように設定されています
- **依存関係**: `requirements.txt`はRender環境での安定性を考慮して最適化されています
- **`.python-version`**ファイルでPython 3.12を明示的に指定しています
- **pydantic-coreエラー対策**: Python 3.13でのビルドエラーを回避するため、pydantic 2.4.0を使用

## データベース情報
既に設定済みのPostgreSQLデータベース:
- **ホスト名**: `dpg-d1ks3615pdvs73b82g7g-a`
- **ポート**: `5432`
- **データベース名**: `todo_db_22qu`
- **ユーザー名**: `todo_user`
- **パスワード**: [Renderダッシュボードで確認]

## デプロイ手順

### ステップ1: 設定ファイルの準備

1. **本番環境設定のコピー**
   ```bash
   cp render.production.yaml render.yaml
   ```

2. **データベースパスワードの更新**
   - Renderダッシュボードにアクセス
   - データベースサービスの詳細でパスワードを確認
   - `render.yaml`の`DATABASE_URL`を更新:
   ```yaml
   - key: DATABASE_URL
     value: postgresql://todo_user:[実際のパスワード]@dpg-d1ks3615pdvs73b82g7g-a:5432/todo_db_22qu
   ```

3. **CORS設定の更新**
   - フロントエンドのドメインが決まっている場合は更新:
   ```yaml
   - key: CORS_ORIGINS
     value: '["https://your-frontend-domain.onrender.com"]'
   ```

### ステップ2: GitHubリポジトリの更新

1. **変更をコミット**
   ```bash
   git add .
   git commit -m "本番環境用設定を追加"
   git push origin main
   ```

### ステップ3: Renderでのサービス作成

1. **Render.comにログイン**
   - https://render.com にアクセス
   - GitHubアカウントでログイン

2. **新しいWebサービスの作成**
   - ダッシュボードで「New +」をクリック
   - 「Web Service」を選択
   - GitHubリポジトリを選択

3. **基本設定**
   - **Name**: `todo-app-api-production`
   - **Region**: `Oregon (US West)`
   - **Branch**: `main`
   - **Root Directory**: （空のまま）

4. **ビルド設定**
   - **Build Command**:
     ```bash
     cd backend && pip install --upgrade pip && pip install -r requirements.txt
     ```
   - **Start Command**:
     ```bash
     cd backend && ./start.sh
     ```

### ステップ4: 環境変数の設定

Renderダッシュボードで以下の環境変数を設定:

| 変数名 | 値 | 説明 |
|--------|-----|------|
| `ENVIRONMENT` | `production` | 本番環境フラグ |
| `DATABASE_URL` | `postgresql://todo_user:[パスワード]@dpg-d1ks3615pdvs73b82g7g-a:5432/todo_db_22qu` | データベース接続URL |
| `JWT_SECRET_KEY` | （自動生成） | JWT暗号化キー |
| `DEBUG` | `false` | デバッグモード無効 |
| `APP_NAME` | `TODO App API` | アプリケーション名 |
| `APP_VERSION` | `4.0.0` | バージョン |
| `CORS_ORIGINS` | `["https://your-frontend-domain.onrender.com"]` | 許可するオリジン |
| `MAX_REQUEST_SIZE` | `1048576` | 最大リクエストサイズ |
| `RATE_LIMIT_AUTH` | `5/minute` | 認証エンドポイントの制限 |
| `RATE_LIMIT_API` | `50/minute` | APIエンドポイントの制限 |
| `JWT_ALGORITHM` | `HS256` | JWTアルゴリズム |
| `ACCESS_TOKEN_EXPIRE_HOURS` | `12` | トークン有効期限 |
| `HOST` | `0.0.0.0` | ホスト設定 |

### ステップ5: ヘルスチェックの設定

- **Health Check Path**: `/health`
- Renderが自動的にこのエンドポイントを監視します

### ステップ6: デプロイの実行

1. **設定を保存**
   - 「Create Web Service」をクリック

2. **デプロイの監視**
   - ビルドログを確認
   - エラーがないか確認

3. **デプロイ完了の確認**
   - サービスURLにアクセス
   - `/health`エンドポイントで正常性確認

## デプロイ後の確認事項

### 1. APIエンドポイントの確認
```bash
# ヘルスチェック
curl https://your-service-name.onrender.com/health

# ルートエンドポイント
curl https://your-service-name.onrender.com/
```

### 2. データベース接続の確認
- ログでデータベースマイグレーションが成功しているか確認
- `/api/tasks`エンドポイントでデータ取得を確認

### 3. 認証機能の確認
- `/auth/register`と`/auth/login`エンドポイントが動作するか確認

## トラブルシューティング

### よくある問題と解決方法

1. **データベース接続エラー**
   - パスワードが正しいか確認
   - データベースサービスが稼働しているか確認
   - 環境変数`DATABASE_URL`を再確認

2. **ビルドエラー**
   - `requirements.txt`のパッケージが正しいか確認
   - Python版数の互換性確認
   - **Python 3.13エラー**: `.python-version`ファイルで3.12を指定済みです
   - **pydantic-coreエラー**: requirements.txtは既にRender環境で動作するように最適化されています

3. **起動エラー**
   - `start.sh`が実行可能権限を持っているか確認
   - 環境変数`ENVIRONMENT`が正しく設定されているか確認

4. **CORS エラー**
   - `CORS_ORIGINS`設定を確認
   - フロントエンドドメインが正しく設定されているか確認

## 本番環境の特徴

### パフォーマンス
- **Gunicorn**: 2ワーカーで高性能処理
- **レート制限**: API乱用防止
- **リクエスト制限**: 1MB制限でセキュリティ向上

### セキュリティ
- JWT認証による全エンドポイント保護
- セキュリティヘッダー自動付与
- CORS制限による不正アクセス防止

### 監視
- ヘルスチェックエンドポイント
- Renderダッシュボードでのログ監視
- 自動再起動機能

## 次のステップ

1. **フロントエンドの設定**
   - FlutterアプリでAPIのベースURLを本番環境に変更

2. **独自ドメインの設定**（オプション）
   - Renderで独自ドメインを設定
   - CORS設定の更新

3. **監視とアラート**
   - アプリケーションの監視設定
   - エラーアラートの設定

4. **バックアップ戦略**
   - データベースの定期バックアップ設定

## サポート

デプロイで問題が発生した場合:
1. Renderダッシュボードのログを確認
2. 環境変数の設定を再確認
3. データベース接続設定を確認
4. 必要に応じて再デプロイを実行