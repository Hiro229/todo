ファイル名を todo_app_requirements_v2.1.md に変更しました。# TODOアプリ要件定義書 v2.2

## 1. プロジェクト概要

### 1.1 プロジェクト名
Simple TODO Application

### 1.2 目的
日常のタスク管理を効率化するためのシンプルなTODOアプリケーションを開発する

### 1.3 対象ユーザー
- 個人でタスク管理を行いたいユーザー
- シンプルなタスク管理ツールを求めるユーザー

### 1.4 対象プラットフォーム
- iOS（iPhone/iPad）
- Android（スマートフォン/タブレット）

### 1.5 更新内容（v2.2）
- API Key認証を廃止し、JWT認証に変更
- セキュリティ要件を大幅に強化
- ユーザー識別なしでの認証システム実装
- 将来的なユーザー管理機能への拡張性を確保
- **段階的デプロイ戦略の追加**：開発→検証→本番環境への切り替え機能
- **Render利用による初期デプロイ**：小規模段階でのコスト効率化
- **機密情報管理の詳細化**：Render環境での安全な認証情報管理方法を明確化
- **JWT認証システム実装完了**：Phase 3の完了を反映

## 2. システム構成

### 2.1 技術スタック
- **フロントエンド**: Flutter（iOS/Android対応）
- **バックエンド**: Python（FastAPI推奨）
- **データベース**: PostgreSQL 15+
- **コンテナ化**: Docker & Docker Compose（開発環境）
- **API通信**: REST API（JSON形式）
- **認証**: JWT（JSON Web Token）
- **セキュリティ**: HTTPS必須、CORS設定、レート制限

### 2.2 デプロイ環境戦略
- **開発環境**: Docker Compose（ローカル開発）
- **検証環境**: Render（コスト効率重視の初期段階）
- **本番環境**: AWS または Render（スケールに応じて選択）
- **環境切り替え**: 設定ファイルベースの簡単な切り替え機能

### 2.3 アーキテクチャ
```
[Flutter App (iOS/Android)] ←→ [FastAPI Server + JWT Auth] ←→ [PostgreSQL]
                                           ↓
                               [環境別デプロイ基盤]
                                           ↓
                    [Docker Compose / Render / AWS ECS]
                                           ↓
                               [HTTPS + Security Headers]
```

## 3. 機能要件

### 3.1 基本機能
1. **認証機能**
   - アプリ起動時の自動JWT認証
   - セッション管理（ユーザー識別なし）
   - トークン自動更新機能

2. **タスク作成**
   - タスクのタイトル入力
   - タスクの説明入力（オプション）
   - 作成日時の自動記録

3. **タスク表示**
   - 全タスクの一覧表示
   - 完了/未完了ステータスの表示
   - 作成日時順での表示

4. **タスク編集**
   - タスクタイトルの編集
   - タスク説明の編集
   - 完了ステータスの変更

5. **タスク削除**
   - 個別タスクの削除
   - 削除前の確認ダイアログ

### 3.2 追加機能（Phase 2での実装検討）
- **ユーザー管理機能**
  - ユーザー登録/ログイン
  - プロフィール管理
  - マルチユーザー対応
- **機能拡張**
  - タスクの優先度設定
  - 期限設定
  - カテゴリ分類
  - 検索機能
  - フィルタリング機能

## 4. 認証・セキュリティ要件

### 4.1 JWT認証仕様
- **認証方式**: シンプルJWT認証（ユーザー識別なし）
- **トークン有効期限**: 12時間
- **自動更新**: アプリ起動時にトークン状態確認・更新
- **アルゴリズム**: HS256
- **ペイロード**: セッションID、認証タイプ、発行/有効期限情報

### 4.2 セキュリティ対策

#### 4.2.1 通信セキュリティ
- **HTTPS必須**: 全ての通信をTLS 1.2以上で暗号化
- **証明書ピニング**: 本番環境でのMITM攻撃対策
- **HSTS**: HTTP Strict Transport Security有効化

#### 4.2.2 API セキュリティ
- **CORS設定**: 許可されたドメインからのアクセスのみ許可
- **レート制限**: 
  - 認証エンドポイント: 10回/分
  - その他API: 100回/分
- **リクエストサイズ制限**: 1MB以下
- **SQL インジェクション対策**: パラメータ化クエリ使用
- **XSS対策**: 入力値検証・エスケープ処理

#### 4.2.3 JWT セキュリティ
- **秘密鍵管理**: 環境変数での管理、256bit以上のランダムキー
- **トークン検証**: 署名・有効期限・発行者・対象者の検証
- **ペイロード最小化**: 必要最小限の情報のみ含有
- **セキュアストレージ**: Flutter Secure Storageでトークン保存

#### 4.2.5 Render環境での機密情報管理
- **環境変数管理**: Renderダッシュボードの Environment Variables セクション
- **データベース認証情報**: Render PostgreSQL接続情報の自動管理
- **JWT秘密鍵**: Renderの環境変数として安全に保存
- **API キー・トークン**: サードパーティサービス連携時の認証情報管理
- **ローカル開発との分離**: .env.example テンプレートのみリポジトリに含める
- **機密情報の version control 除外**: .gitignore による実際の設定ファイル除外

#### 4.2.4 アプリケーションセキュリティ
- **入力検証**: 全ての入力データの検証・サニタイズ
- **エラーハンドリング**: 内部情報を漏洩しないエラーメッセージ
- **ログ管理**: セキュリティイベントのログ記録
- **依存関係管理**: 定期的な脆弱性スキャン

## 5. 非機能要件

### 5.1 性能要件
- **API応答時間**: 500ms以内
- **同時接続数**: 50ユーザー以下
- **データ保存の即座反映**
- **JWT処理時間**: 50ms以内

### 5.2 可用性要件
- **稼働率**: 99.5%以上
- **データの永続化保証**
- **障害復旧時間**: 1時間以内

### 5.3 拡張性要件
- **水平スケーリング対応**: JWTステートレス認証による
- **マイクロサービス対応**: API設計での将来対応
- **データベース分散**: 将来的なシャーディング対応
- **環境間移行対応**: Docker/Render/AWS間での容易な切り替え

### 5.4 運用要件
- **多環境対応**: Docker/Render/AWS での統一運用
- **ログ出力機能**: 構造化ログ（JSON形式）
- **モニタリング**: ヘルスチェックエンドポイント
- **設定管理**: 環境変数での設定分離・環境別設定ファイル

## 6. データ設計

### 6.1 タスクテーブル（tasks）
| カラム名 | データ型 | 制約 | 説明 |
|---------|---------|-----|-----|
| id | INTEGER | PRIMARY KEY, AUTO_INCREMENT | タスクID |
| title | VARCHAR(255) | NOT NULL | タスクタイトル |
| description | TEXT | NULL | タスク説明 |
| is_completed | BOOLEAN | DEFAULT FALSE | 完了フラグ |
| session_id | VARCHAR(255) | NULL | セッションID（JWT由来） |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 更新日時 |

### 6.2 セッションテーブル（sessions）- Phase 2で追加予定
| カラム名 | データ型 | 制約 | 説明 |
|---------|---------|-----|-----|
| id | INTEGER | PRIMARY KEY, AUTO_INCREMENT | セッションID |
| session_uuid | UUID | UNIQUE, NOT NULL | セッション識別子 |
| device_info | JSONB | NULL | デバイス情報 |
| last_access | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 最終アクセス日時 |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 作成日時 |

## 7. API設計

### 7.1 認証エンドポイント
| メソッド | エンドポイント | 説明 | レート制限 |
|---------|---------------|-----|-----------|
| POST | /auth/simple | シンプル認証（自動） | 10回/分 |
| GET | /auth/verify | 認証状態確認 | 20回/分 |

### 7.2 タスク管理エンドポイント
| メソッド | エンドポイント | 説明 | 認証 |
|---------|---------------|-----|------|
| GET | /api/tasks | 全タスク取得 | JWT必須 |
| POST | /api/tasks | 新規タスク作成 | JWT必須 |
| GET | /api/tasks/{id} | 特定タスク取得 | JWT必須 |
| PUT | /api/tasks/{id} | タスク更新 | JWT必須 |
| DELETE | /api/tasks/{id} | タスク削除 | JWT必須 |

### 7.3 システムエンドポイント
| メソッド | エンドポイント | 説明 | 認証 |
|---------|---------------|-----|------|
| GET | /health | ヘルスチェック | 不要 |

### 7.4 リクエスト/レスポンス例

#### 認証リクエスト
```json
// POST /auth/simple (自動実行)
// Request Body: なし

// Response
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 43200
}
```

#### タスク作成
```json
// POST /api/tasks
// Headers: Authorization: Bearer {token}
{
  "title": "買い物に行く",
  "description": "牛乳とパンを買う"
}

// Response
{
  "task": {
    "id": 1,
    "title": "買い物に行く",
    "description": "牛乳とパンを買う",
    "is_completed": false,
    "session_id": "550e8400-e29b-41d4-a716-446655440000",
    "created_at": "2025-07-06T10:00:00Z",
    "updated_at": "2025-07-06T10:00:00Z"
  },
  "message": "Task created successfully"
}
```

## 8. UI/UX要件

### 8.1 画面構成
1. **スプラッシュ画面**
   - アプリ初期化
   - JWT認証処理
   - ローディング表示

2. **メイン画面**
   - タスク一覧表示
   - 新規作成ボタン
   - タスクの完了チェックボックス
   - プルツーリフレッシュ

3. **タスク作成/編集画面**
   - タイトル入力フィールド
   - 説明入力フィールド
   - 保存/キャンセルボタン

### 8.2 デザイン要件
- **マテリアルデザインの採用**
- **レスポンシブデザイン**
- **直感的な操作性**
- **ダークモード対応**（オプション）

### 8.3 エラーハンドリング
- **ネットワークエラー表示**
- **認証エラー時の自動再試行**
- **オフライン状態の表示**
- **ユーザーフレンドリーなエラーメッセージ**

## 9. 開発環境・デプロイ構成

### 9.1 必要なツール
- **Flutter SDK**: 3.10+
- **Dart**: 3.0+
- **Python**: 3.9+
- **PostgreSQL**: 15+
- **Docker & Docker Compose**
- **IDE**: VS Code推奨
- **セキュリティツール**: 
  - OWASP ZAP（脆弱性スキャン）
  - jwt.io（JWTデバッグ）

### 9.2 環境別構成

#### 9.2.1 開発環境（ローカル）
- **インフラ**: Docker Compose
- **データベース**: PostgreSQL（Dockerコンテナ）
- **API**: FastAPI開発サーバー
- **設定**: `.env.local`
- **機密情報管理**: ローカル .env ファイル（.gitignore対象）

#### 9.2.2 検証環境（Render）
- **インフラ**: Render Web Service + Render PostgreSQL
- **デプロイ**: GitHubアクション自動デプロイ
- **設定**: 環境変数（Renderダッシュボード）
- **SSL**: 自動生成（Renderプロビジョン）
- **機密情報管理**: 
  - Renderダッシュボード > Service Settings > Environment Variables
  - データベース接続情報は自動生成・管理
  - JWT秘密鍵等はRender環境変数として安全に保存

#### 9.2.3 本番環境（AWS/Render）
- **初期**: Render（小規模・コスト効率）
- **スケール時**: AWS ECS + RDS
- **設定**: Parameter Store / 環境変数
- **SSL**: ACM / Let's Encrypt
- **機密情報管理**:
  - **Render**: 環境変数による暗号化保存
  - **AWS**: Parameter Store（SecureString）/ Secrets Manager

### 9.3 環境切り替え機能

#### 9.3.1 設定管理
```python
# config/settings.py
from pydantic import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    environment: str = "development"
    database_url: str
    jwt_secret_key: str
    cors_origins: list = ["http://localhost:3000"]
    
    class Config:
        env_file = f".env.{os.getenv('ENVIRONMENT', 'development')}"

@lru_cache()
def get_settings():
    return Settings()
```

#### 9.3.2 デプロイ構成ファイル
```yaml
# render.yaml（検証・本番環境）
services:
  - type: web
    name: todo-app-api
    env: python
    buildCommand: pip install -r requirements.txt
    startCommand: uvicorn app.main:app --host 0.0.0.0 --port $PORT
    envVars:
      - key: ENVIRONMENT
        value: production
      - key: DATABASE_URL
        fromDatabase:
          name: todo-app-db
          property: connectionString

# docker-compose.yml（開発環境）
version: '3.8'
services:
  api:
    build: ./backend
    environment:
      - ENVIRONMENT=development
      - DATABASE_URL=postgresql://postgres:password@db:5432/todo_db
  db:
    image: postgres:15
```

### 9.4 Flutter 依存関係
```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
  http: ^1.1.0
  jwt_decoder: ^2.0.1
  device_info_plus: ^9.1.0

dev_dependencies:
  flutter_test: ^1.0.0
  integration_test: ^1.0.0
```

### 9.5 Python 依存関係
```txt
fastapi==0.104.1
uvicorn==0.24.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
slowapi==0.1.9
psycopg2-binary==2.9.7
pydantic-settings==2.1.0
```

### 9.6 ディレクトリ構成
```
todo-app/
├── frontend/                # Flutter app
│   ├── lib/
│   │   ├── config/         # 環境別API設定
│   │   ├── services/       # 認証・API サービス
│   │   ├── models/         # データモデル
│   │   ├── screens/        # 画面
│   │   └── widgets/        # 共通ウィジェット
├── backend/                # FastAPI application
│   ├── app/
│   │   ├── config/         # 環境別設定
│   │   ├── auth/          # JWT認証関連
│   │   ├── api/           # APIエンドポイント
│   │   ├── models/        # データベースモデル
│   │   ├── security/      # セキュリティ機能
│   │   └── utils/         # ユーティリティ
├── database/               # PostgreSQL init scripts
├── deploy/                 # デプロイ関連
│   ├── docker-compose.yml # 開発環境
│   ├── render.yaml        # Render設定
│   └── aws/               # AWS CloudFormation/CDK
├── config/                 # 環境別設定ファイル
│   ├── .env.development
│   ├── .env.staging
│   └── .env.production
├── README.md
└── docs/                  # API・セキュリティドキュメント
```

## 10. 開発フェーズ

### Phase 1: 基本機能実装（完了済み）
- **データベース設計** ✅
- **API実装** ✅
- **Flutter基本UI実装** ✅
- **Docker環境構築** ✅

### Phase 2: 機能拡張（完了済み）
- ~~**API key認証機能**~~ ❌ **対象外**（JWT認証に変更のため）
- **追加機能の実装**（優先度、期限設定等） ✅
- **UI/UX改善** ✅
- **パフォーマンス最適化** ✅

### Phase 3: JWT認証システム実装（完了済み）
- **JWT認証システム設計・実装** ✅
- **シンプル認証エンドポイント実装** ✅
- **Flutter側認証サービス実装** ✅
- **セキュアストレージ対応** ✅
- **トークン自動更新機能** ✅
- **セキュリティ基盤構築** ✅

### Phase 4: 環境切り替えシステム実装（新規）
- **環境別設定管理システム構築**
  - 開発/検証環境の設定分離（Docker/Render）
  - 環境変数による動的設定切り替え
  - データベース接続先の環境別管理
- **Renderデプロイ基盤構築**
  - render.yaml設定ファイル作成
  - GitHubアクション自動デプロイ設定
  - 環境変数管理システム構築
  - Render PostgreSQL + Web Service連携
- **Docker最適化**
  - マルチステージビルド実装
  - 開発用Dockerイメージ最適化
  - セキュリティスキャン自動化
- **Flutter環境別設定**
  - API エンドポイント環境別管理（開発/Render）
  - ビルド構成の環境別分離
  - 開発/検証証明書管理

### Phase 5: セキュリティ強化
- **HTTPS通信の強制**
- **レート制限実装**
- **CORS設定**
- **入力値検証強化**
- **セキュリティテスト実施**
- **脆弱性対策実装**

### Phase 6: ユーザー管理機能追加（将来実装）
- **ユーザー登録・ログイン機能**
- **プロフィール管理**
- **マルチユーザー対応**
- **JWT ペイロードにユーザー情報追加**
- **ユーザー固有データ管理**

### Phase 7: 高度なセキュリティ・運用機能
- **OAuth 2.0対応**（Google/Apple Sign-in）
- **セキュリティ監査・改善**
- **ログ管理・監視強化**
- **パフォーマンス最適化**
- **Render環境での高度な運用最適化**

### Phase 8: AWS移行・エンタープライズ対応（将来実装）
- **AWS移行準備**
  - CloudFormation/CDKテンプレート作成
  - ECS + RDS構成設計
  - Render→AWS移行手順書作成
- **エンタープライズインフラ構築**
  - 高可用性・災害復旧対応
  - マルチリージョン展開
  - 本番監視・ログ分析基盤
- **本番運用最適化**
  - Auto Scaling設定
  - コスト最適化
  - セキュリティ強化（WAF、GuardDuty等）
- **Flutter本番配布最適化**
  - アプリストア配布自動化
  - 本番証明書管理
  - エンタープライズデバイス管理対応

## 11. セキュリティテスト計画

### 11.1 テスト項目
1. **認証テスト**
   - JWT署名検証
   - トークン有効期限テスト
   - 不正トークンでのアクセステスト

2. **API セキュリティテスト**
   - SQLインジェクション テスト
   - XSS 攻撃テスト
   - CSRF 攻撃テスト
   - レート制限テスト

3. **通信セキュリティテスト**
   - HTTPS 強制テスト
   - 証明書検証テスト
   - MITM 攻撃対策テスト

### 11.2 セキュリティチェックリスト
- [ ] JWT秘密鍵が環境変数で管理されている
- [ ] HTTPS通信が強制されている
- [ ] CORS設定が適切に行われている
- [ ] レート制限が実装されている
- [ ] 入力値検証が全エンドポイントで実装されている
- [ ] エラーメッセージが内部情報を漏洩していない
- [ ] ログに機密情報が記録されていない
- [ ] 依存関係に既知の脆弱性がない
- [ ] **Render環境変数に機密情報が適切に保存されている**
- [ ] **データベース接続情報がソースコードにハードコードされていない**
- [ ] **実際の .env ファイルが .gitignore に含まれている**
- [ ] **.env.example のみがリポジトリに含まれている**

## 12. 制約事項・前提条件

### 12.1 Phase 1 制約事項
- **単一セッション利用**（ユーザー識別なし）
- **ユーザー管理機能なし**（Phase 2で追加予定）
- **オフライン機能は含まない**
- **プッシュ通知は含まない**

### 12.2 セキュリティ前提条件
- **HTTPS環境での運用必須**
- **適切な秘密鍵管理**
- **定期的なセキュリティアップデート**
- **セキュリティ監視体制**

### 12.3 環境切り替え前提条件
- **設定ファイル分離**による環境管理
- **自動デプロイパイプライン**の構築
- **環境間でのデータ移行手順**の整備

## 13. デプロイ環境・セキュリティ

### 13.1 段階的デプロイ戦略

#### 13.1.1 初期段階（小規模・コスト重視）
- **プラットフォーム**: Render
- **理由**: 
  - 無料プランでの初期検証が可能
  - GitHubからの自動デプロイ
  - PostgreSQL + Web Service の統合管理
  - 最低月額$13でのスモールスタート
- **構成**: Render Web Service + Render PostgreSQL
- **適用期間**: MVP〜初期ユーザー獲得段階

#### 13.1.2 成長段階（スケール・機能重視）
- **プラットフォーム**: AWS
- **移行タイミング**: 
  - 月間アクティブユーザー1,000人超
  - データ量10GB超
  - より高度なセキュリティ要件が必要
- **構成**: 
  - AWS (ECS + RDS + ALB + CloudFront)
  - Google Cloud Platform (Cloud Run + Cloud SQL + Load Balancer)
  - Azure (Container Instances + Azure Database + Application Gateway)

### 13.2 環境切り替え機能
- **設定ベース切り替え**: 環境変数/設定ファイルによる動的切り替え
- **データ移行**: PostgreSQLダンプ・リストアによる環境間移行
- **DNS切り替え**: ゼロダウンタイムでの環境切り替え
- **ロールバック**: 問題発生時の即座な切り戻し機能

### 13.3 セキュリティインフラ
- **WAF (Web Application Firewall)**: DDoS・不正アクセス対策
- **CDN**: SSL終端・キャッシュ・DDoS対策
- **ログ管理**: CloudWatch/Cloud Logging によるセキュリティログ監視
- **監視**: アラート機能による異常検知

### 13.4 アプリストア配布
- **Google Play Store** (Android): アプリ署名・セキュリティ審査
- **Apple App Store** (iOS): App Transport Security準拠

## 14. 成果物

### 14.1 開発成果物
1. **Flutter モバイルアプリ**（JWT認証対応）
2. **Python API サーバー**（セキュリティ強化）
3. **Docker構成ファイル**（セキュア設定）
4. **データベース設計書**
5. **API ドキュメント**（OpenAPI/Swagger）

### 14.2 セキュリティ成果物
1. **セキュリティ設計書**
2. **JWT実装ガイド**
3. **セキュリティテスト報告書**
4. **脆弱性対策一覧**
5. **運用セキュリティガイド**

### 14.3 運用成果物
1. **セットアップ手順書**
2. **セキュリティ運用手順書**
3. **環境切り替え手順書**
4. **トラブルシューティングガイド**
5. **基本的なテストコード**
6. **デプロイメントスクリプト**

### 14.4 デプロイ・インフラ成果物
1. **Docker Compose設定**（開発環境）
2. **Render設定ファイル**（render.yaml）
3. **AWS CloudFormation/CDK テンプレート**（本番環境）
4. **GitHubアクション設定**（CI/CD）
5. **環境別設定ファイル**
6. **データベース移行スクリプト**

### 14.5 セキュリティ・機密情報管理成果物
1. **機密情報管理ガイド**（Render環境変数設定手順）
2. **環境変数設定テンプレート**（.env.example）
3. **データベース接続設定ガイド**
4. **JWT秘密鍵生成・管理手順書**
5. **セキュリティ設定チェックリスト**
1. **Docker Compose設定**（開発環境）
2. **Render設定ファイル**（render.yaml）
3. **AWS CloudFormation/CDK テンプレート**（本番環境）
4. **GitHubアクション設定**（CI/CD）
5. **環境別設定ファイル**
6. **データベース移行スクリプト**

---

## 変更履歴

**v2.2 (2025-07-06)**
- Render環境での機密情報管理方法を詳細化
- JWT認証システム実装完了（Phase 3）をマーク
- セキュリティチェックリストにRender固有項目を追加
- 機密情報管理成果物を新規追加

**v2.1 (2025-07-06)**
- 段階的デプロイ戦略を追加（Render→AWS移行パス）
- 環境切り替えシステムの設計・実装フェーズを追加
- 開発・検証・本番環境での統一運用設計
- Phase 4として環境切り替えシステム実装フェーズを新設
- デプロイ環境・セキュリティ章にRender利用戦略を追加
- 多環境対応のディレクトリ構成・設定管理を強化

**v2.0 (2025-07-06)**
- API Key認証を廃止し、JWT認証に変更
- セキュリティ要件を大幅に強化
- ユーザー識別なしでの認証システム設計
- セキュリティテスト計画を追加
- デプロイ環境のセキュリティ要件を追加
- 開発フェーズを再編成（Phase 1-2完了済み、Phase 3以降で新機能実装）

**v1.0 (2025-07-04)**
- 初版作成