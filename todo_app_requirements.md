# TODOアプリ要件定義書

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

## 2. システム構成

### 2.1 技術スタック
- **フロントエンド**: Flutter（iOS/Android対応）
- **バックエンド**: Python（FastAPI推奨）
- **データベース**: PostgreSQL 15+
- **コンテナ化**: Docker & Docker Compose
- **API通信**: REST API（JSON形式）

### 2.2 アーキテクチャ
```
[Flutter App (iOS/Android)] ←→ [FastAPI Server] ←→ [PostgreSQL]
                                      ↓
                               [Docker Container]
```

## 3. 機能要件

### 3.1 基本機能
1. **タスク作成**
   - タスクのタイトル入力
   - タスクの説明入力（オプション）
   - 作成日時の自動記録

2. **タスク表示**
   - 全タスクの一覧表示
   - 完了/未完了ステータスの表示
   - 作成日時順での表示

3. **タスク編集**
   - タスクタイトルの編集
   - タスク説明の編集
   - 完了ステータスの変更

4. **タスク削除**
   - 個別タスクの削除
   - 削除前の確認ダイアログ

### 3.2 追加機能（Phase 2での実装検討）
- タスクの優先度設定
- 期限設定
- カテゴリ分類
- 検索機能
- フィルタリング機能

## 4. 非機能要件

### 4.1 性能要件
- API応答時間: 500ms以内
- 同時接続数: 10ユーザー以下（個人利用想定）
- データ保存の即座反映

### 4.2 可用性要件
- 稼働率: 99%以上（開発環境）
- データの永続化保証

### 4.3 セキュリティ要件
- 認証機能なし（Phase 2でAPI key認証追加予定）
- SQLインジェクション対策
- XSS対策
- CORS設定

### 4.4 運用要件
- Dockerコンテナでの簡単なデプロイ
- ログ出力機能
- 基本的なエラーハンドリング

## 5. データ設計

### 5.1 タスクテーブル（tasks）
| カラム名 | データ型 | 制約 | 説明 |
|---------|---------|-----|-----|
| id | INTEGER | PRIMARY KEY, AUTO_INCREMENT | タスクID |
| title | VARCHAR(255) | NOT NULL | タスクタイトル |
| description | TEXT | NULL | タスク説明 |
| is_completed | BOOLEAN | DEFAULT FALSE | 完了フラグ |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 更新日時 |

## 6. API設計

### 6.1 エンドポイント一覧
| メソッド | エンドポイント | 説明 |
|---------|---------------|-----|
| GET | /api/tasks | 全タスク取得 |
| POST | /api/tasks | 新規タスク作成 |
| GET | /api/tasks/{id} | 特定タスク取得 |
| PUT | /api/tasks/{id} | タスク更新 |
| DELETE | /api/tasks/{id} | タスク削除 |

### 6.2 リクエスト/レスポンス例
```json
// POST /api/tasks
{
  "title": "買い物に行く",
  "description": "牛乳とパンを買う"
}

// Response
{
  "id": 1,
  "title": "買い物に行く",
  "description": "牛乳とパンを買う",
  "is_completed": false,
  "created_at": "2025-07-04T10:00:00Z",
  "updated_at": "2025-07-04T10:00:00Z"
}
```

## 7. UI/UX要件

### 7.1 画面構成
1. **メイン画面**
   - タスク一覧表示
   - 新規作成ボタン
   - タスクの完了チェックボックス

2. **タスク作成/編集画面**
   - タイトル入力フィールド
   - 説明入力フィールド
   - 保存/キャンセルボタン

### 7.2 デザイン要件
- マテリアルデザインの採用
- レスポンシブデザイン
- 直感的な操作性

## 8. 開発環境

### 8.1 必要なツール
- Flutter SDK 3.10+
- Dart 3.0+
- Python 3.9+
- PostgreSQL 15+
- Docker & Docker Compose
- IDE（VS Code推奨）

### 8.2 ディレクトリ構成
```
todo-app/
├── frontend/          # Flutter app
├── backend/           # FastAPI application
├── database/          # PostgreSQL init scripts
├── docker-compose.yml
├── .env
├── README.md
└── docs/             # API documentation
```

## 9. 開発フェーズ

### Phase 1: 基本機能実装
- データベース設計
- API実装
- Flutter基本UI実装
- Docker環境構築

### Phase 2: 機能拡張（将来的な実装）
- API key認証機能
- 追加機能の実装（優先度、期限設定等）
- UI/UX改善
- パフォーマンス最適化

## 10. 制約事項

- 単一ユーザー利用想定
- 認証機能なし（Phase 2で追加予定）
- オフライン機能は含まない
- プッシュ通知は含まない
- 最小限の機能に限定

## 11. デプロイ環境候補

### 11.1 本番環境候補
- **クラウドプラットフォーム**
  - AWS (ECS + RDS)
  - Google Cloud Platform (Cloud Run + Cloud SQL)
  - Azure (Container Instances + Azure Database)
  - Railway
  - Render

- **VPS/専用サーバー**
  - DigitalOcean
  - Linode
  - Vultr

### 11.2 アプリストア配布
- Google Play Store (Android)
- Apple App Store (iOS)
- または両プラットフォーム対応のテスト配布

## 12. 成果物

1. Flutter モバイルアプリ
2. Python API サーバー
3. Docker構成ファイル
4. README（セットアップ手順）
5. 基本的なテストコード