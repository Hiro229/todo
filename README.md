# TODO App

シンプルなTODOアプリケーション - Flutter（フロントエンド）+ FastAPI（バックエンド）+ PostgreSQL

## 機能

- ✅ タスクの作成・編集・削除
- ✅ タスクの完了状態管理
- ✅ タスク一覧表示（作成日時順）
- ✅ レスポンシブデザイン
- ✅ エラーハンドリング

## 技術スタック

- **フロントエンド**: Flutter 3.7+
- **バックエンド**: Python FastAPI
- **データベース**: PostgreSQL 15
- **デプロイ**: Docker & Docker Compose

## セットアップ

### 前提条件

- Docker & Docker Compose
- Flutter SDK 3.7+
- Dart 3.0+

## 環境設定

このプロジェクトは**開発環境**と**本番環境**をサポートしています。

### 開発環境 (Development)

**特徴:**
- ローカルのDockerでバックエンドとデータベースを実行
- デバッグログが有効
- ホットリロード対応

**バックエンドの起動:**
```bash
# Docker Composeでバックエンドとデータベースを起動
docker-compose -f docker-compose.dev.yml up -d

# APIが正常に動作することを確認
curl http://localhost:8000/
```

**フロントエンドの起動:**
```bash
# frontend ディレクトリに移動
cd frontend

# 依存関係をインストール
flutter pub get

# 開発環境でアプリを実行
flutter run --dart-define=FLUTTER_ENV=development
```

### 本番環境 (Production)

**特徴:**
- RenderのサーバーAPI (`https://todo-2ui9.onrender.com`) に接続
- 本番用の最適化された設定
- エラーレポート機能有効

**フロントエンドの起動:**
```bash
# frontend ディレクトリに移動
cd frontend

# 依存関係をインストール
flutter pub get

# 本番環境でアプリを実行
flutter run --dart-define=FLUTTER_ENV=production
```

**本番用ビルド:**
```bash
# Android本番用ビルド
flutter build apk --dart-define=FLUTTER_ENV=production

# iOS本番用ビルド
flutter build ios --dart-define=FLUTTER_ENV=production
```

## 開発コマンド

### バックエンド

#### 開発環境
```bash
# バックエンドのみ起動（開発環境）
cd backend
pip install -r requirements.txt
ENVIRONMENT=development uvicorn main:app --reload

# Docker コンテナの状態確認
docker-compose -f docker-compose.dev.yml ps

# ログの確認
docker-compose -f docker-compose.dev.yml logs backend
```

#### 本番環境
```bash
# バックエンドの本番環境起動
cd backend
ENVIRONMENT=production uvicorn main:app --host 0.0.0.0 --port 8000
```

### フロントエンド

#### 開発環境
```bash
cd frontend

# 依存関係のインストール
flutter pub get

# 開発環境でアプリの実行
flutter run --dart-define=FLUTTER_ENV=development

# 特定のデバイスで実行（開発環境）
flutter run --dart-define=FLUTTER_ENV=development -d chrome      # Webブラウザ
flutter run --dart-define=FLUTTER_ENV=development -d android     # Android
flutter run --dart-define=FLUTTER_ENV=development -d ios         # iOS
```

#### 本番環境
```bash
cd frontend

# 本番環境でアプリの実行
flutter run --dart-define=FLUTTER_ENV=production

# 本番環境用ビルド
flutter build apk --dart-define=FLUTTER_ENV=production          # Android
flutter build ios --dart-define=FLUTTER_ENV=production          # iOS
```

#### 共通コマンド
```bash
cd frontend

# コードの解析
flutter analyze

# テストの実行
flutter test

# ビルドファイルのクリーンアップ
flutter clean
```

### IDE設定（Cursor / VS Code）

#### デバッグ実行設定

CursorやVS Codeで環境変数を含めてデバッグ実行するには、以下の設定が`.vscode/launch.json`に含まれています：

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "frontend (development)",
      "cwd": "frontend",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=FLUTTER_ENV=development"
      ]
    },
    {
      "name": "frontend (production)",
      "cwd": "frontend",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=FLUTTER_ENV=production"
      ]
    }
  ]
}
```

#### 使用方法

1. **Run and Debug**パネルを開く（Ctrl+Shift+D / Cmd+Shift+D）
2. 上部のドロップダウンから実行したい環境を選択：
   - **frontend (development)** - 開発環境
   - **frontend (production)** - 本番環境
3. 再生ボタンをクリックするか、F5キーを押して実行

これにより、選択した環境設定でFlutterアプリが起動されます。

## API エンドポイント

| メソッド | エンドポイント | 説明 |
|---------|---------------|-----|
| GET | `/api/tasks` | 全タスク取得 |
| POST | `/api/tasks` | 新規タスク作成 |
| GET | `/api/tasks/{id}` | 特定タスク取得 |
| PUT | `/api/tasks/{id}` | タスク更新 |
| DELETE | `/api/tasks/{id}` | タスク削除 |

### API リクエスト例

#### 開発環境
```bash
# 全タスク取得（開発環境）
curl -X GET http://localhost:8000/api/tasks

# タスク作成（開発環境）
curl -X POST http://localhost:8000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "買い物", "description": "牛乳とパンを買う"}'

# タスク完了状態の更新（開発環境）
curl -X PUT http://localhost:8000/api/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{"is_completed": true}'
```

#### 本番環境
```bash
# 全タスク取得（本番環境）
curl -X GET https://todo-2ui9.onrender.com/api/tasks

# タスク作成（本番環境）
curl -X POST https://todo-2ui9.onrender.com/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "買い物", "description": "牛乳とパンを買う"}'

# タスク完了状態の更新（本番環境）
curl -X PUT https://todo-2ui9.onrender.com/api/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{"is_completed": true}'
```

## プロジェクト構成

```
todo/
├── backend/                 # FastAPI バックエンド
│   ├── main.py             # メインアプリケーション
│   ├── models.py           # データベースモデル
│   ├── schemas.py          # Pydantic スキーマ
│   ├── crud.py             # データベース操作
│   ├── database.py         # データベース設定
│   ├── requirements.txt    # Python依存関係
│   └── Dockerfile          # Docker設定
├── frontend/               # Flutter フロントエンド
│   ├── lib/
│   │   ├── main.dart       # メインアプリ
│   │   ├── models/         # データモデル
│   │   ├── services/       # API サービス
│   │   └── screens/        # UI画面
│   ├── pubspec.yaml        # Flutter依存関係
│   └── test/               # テストファイル
├── docker-compose.yml      # Docker Compose設定
├── .env                    # 環境変数
└── README.md              # このファイル
```

## トラブルシューティング

### バックエンドのエラー

- **データベース接続エラー**: PostgreSQLコンテナが起動していることを確認
- **ポートエラー**: 8000番ポートが使用中でないことを確認

### フロントエンドのエラー

- **API接続エラー**: 
  - Android エミュレータの場合: `10.0.2.2:8000`
  - iOS シミュレータの場合: `localhost:8000`
  - 実機の場合: PC のローカルIPアドレス

### Docker関連

```bash
# コンテナの再起動
docker-compose down
docker-compose up -d

# データベースのリセット
docker-compose down -v
docker-compose up -d
```

## 開発者向け情報

### データベーススキーマ

```sql
CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### 環境変数

#### Flutter環境変数
- `FLUTTER_ENV`: 環境設定 (`development` | `production`)
- `DEV_SERVER_HOST`: 開発用サーバーのカスタムIP（オプション）

#### Backend環境変数
- `ENVIRONMENT`: 環境設定 (`development` | `production`)
- `DATABASE_URL`: PostgreSQL接続URL
- `JWT_SECRET_KEY`: JWT認証用シークレットキー
- `POSTGRES_DB`: データベース名
- `POSTGRES_USER`: データベースユーザー名
- `POSTGRES_PASSWORD`: データベースパスワード

## タスク登録の流れ

### 1. フロントエンド（Flutter）でのタスク作成

1. **UI操作**: ユーザーがタスク作成画面でタイトルと説明を入力
2. **バリデーション**: 入力データの検証（必須項目チェック等）
3. **API呼び出し**: HTTP POSTリクエストを`/api/tasks`エンドポイントに送信

```dart
// Flutter側のAPIサービス呼び出し例
Future<Task> createTask(String title, String description) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/tasks'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'title': title,
      'description': description,
    }),
  );
  
  if (response.statusCode == 201) {
    return Task.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('タスクの作成に失敗しました');
  }
}
```

### 2. バックエンド（FastAPI）でのタスク処理

1. **リクエスト受信**: POST `/api/tasks`でリクエストを受信
2. **データ検証**: Pydanticスキーマによる入力データの検証
3. **データベース操作**: PostgreSQLにタスクデータを保存
4. **レスポンス**: 作成されたタスクデータをJSON形式で返却

```python
# FastAPI側のタスク作成エンドポイント例
@app.post("/api/tasks/", response_model=TaskResponse)
async def create_task(task: TaskCreate, db: Session = Depends(get_db)):
    # データベースにタスクを保存
    db_task = crud.create_task(db=db, task=task)
    return db_task
```

### 3. データベース（PostgreSQL）での保存

1. **SQL実行**: INSERTクエリによりtasksテーブルにデータを挿入
2. **自動設定**: 
   - `id`: 自動採番（SERIAL PRIMARY KEY）
   - `created_at`: 現在のタイムスタンプを自動設定
   - `updated_at`: 現在のタイムスタンプを自動設定
   - `is_completed`: デフォルト値FALSE

```sql
-- 実際に実行されるSQL例
INSERT INTO tasks (title, description, is_completed, created_at, updated_at)
VALUES ('買い物', '牛乳とパンを買う', FALSE, NOW(), NOW())
RETURNING *;
```

### 4. フロントエンドでの表示更新

1. **APIレスポンス受信**: 作成されたタスクデータを受信
2. **状態管理**: アプリの状態（State）を更新
3. **UI更新**: タスク一覧画面に新しいタスクを表示

### エラーハンドリング

各段階でエラーが発生した場合の処理：

- **バリデーションエラー**: 入力フォームにエラーメッセージを表示
- **ネットワークエラー**: 接続エラーの通知を表示
- **サーバーエラー**: 500エラー等のサーバー側エラーを適切に処理
- **データベースエラー**: 制約違反等のデータベースエラーを処理

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。