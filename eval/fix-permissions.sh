#!/bin/bash
# Label Studio 權限修復腳本

echo "修復 Label Studio 目錄權限..."

# 創建必要目錄
mkdir -p mydata/media
mkdir -p mydata/uploads
mkdir -p mydata/static

# 設置正確的權限
chmod -R 777 mydata

echo "目錄結構已創建，權限已設置"
echo ""
echo "現在可以運行："
echo "docker run -it -p 8080:8080 -v \$(pwd)/mydata:/label-studio/data heartexlabs/label-studio:latest"

