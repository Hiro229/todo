#!/bin/bash

# 実機デバッグ用ビルドスクリプト
# 使用方法: ./scripts/build_dev_device.sh 192.168.1.100

if [ $# -eq 0 ]; then
    echo "使用方法: ./scripts/build_dev_device.sh <開発用PCのIPアドレス>"
    echo "例: ./scripts/build_dev_device.sh 192.168.1.100"
    exit 1
fi

DEV_SERVER_HOST=$1

echo "開発用サーバーIPを設定: $DEV_SERVER_HOST"

# iOSの場合
if [ "$2" == "ios" ]; then
    echo "iOSデバイス用にビルドします..."
    flutter build ios --debug --dart-define=DEV_SERVER_HOST=$DEV_SERVER_HOST
    echo "iOSビルド完了"
# Androidの場合
elif [ "$2" == "android" ]; then
    echo "Androidデバイス用にビルドします..."
    flutter build apk --debug --dart-define=DEV_SERVER_HOST=$DEV_SERVER_HOST
    echo "Androidビルド完了"
else
    echo "実機デバッグ用に実行します..."
    flutter run --dart-define=DEV_SERVER_HOST=$DEV_SERVER_HOST
fi 