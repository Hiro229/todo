# マルチステージビルド: ビルドステージ
FROM python:3.11-slim as builder

WORKDIR /app

# システムの依存関係をインストール（ビルド用）
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 仮想環境を作成
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Python依存関係をインストール
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# プロダクションステージ
FROM python:3.11-slim as production

# 非rootユーザーの作成
RUN groupadd --gid 1000 appuser && \
    useradd --uid 1000 --gid appuser --shell /bin/bash --create-home appuser

WORKDIR /app

# 必要なランタイム依存関係のみをインストール
RUN apt-get update && apt-get install -y \
    libpq5 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# ビルドステージから仮想環境をコピー
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# アプリケーションコードをコピー
COPY --chown=appuser:appuser . .

# セキュリティ: 非rootユーザーに切り替え
USER appuser

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')" || exit 1

# 環境変数のデフォルト値
ENV ENVIRONMENT=production
ENV HOST=0.0.0.0
ENV PORT=8000

# アプリケーションを起動
CMD ["sh", "-c", "uvicorn main:app --host $HOST --port $PORT"]