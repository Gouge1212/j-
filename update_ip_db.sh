#!/bin/bash

# ================= 配置区域 =================
# 你的 IP2Location 下载 Token
TOKEN="你的_DOWNLOAD_TOKEN"
# 数据库代码 (DB11 LITE BIN 包含 IPv4+IPv6)
CODE="DB11LITEBINIPV6"
# 文件保存目录 (确保 Java 程序有权访问)
# Docker TK：可复制到 ${TK_DATA}/backend-data/uploadPath/ip2location/ 后 POST ip-reload
# 或 application.yml 设置 security.ip2location.path=file:/app/data/uploadPath/ip2location/IP2LOCATION-LITE-DB11.IPV6.BIN
TARGET_DIR="/data/ip2location"
# Java 应用的重载接口地址
RELOAD_URL="http://localhost:8080/api/admin/security/ip-reload"
# ===========================================

TEMP_ZIP="$TARGET_DIR/ip_new.zip"
BIN_NAME="IP2LOCATION-LITE-DB11.IPV6.BIN"

echo "[$(date)] 开始更新 IP 离线库..."

# 1. 创建目录（如果不存在）
mkdir -p $TARGET_DIR

# 2. 下载最新的 ZIP 包
# 使用 -O 指定输出文件名
echo "正在下载最新数据库..."
wget -O $TEMP_ZIP "https://www.ip2location.com/download/?token=$TOKEN&file=$CODE"

if [ $? -ne 0 ]; then
    echo "错误：下载失败，请检查网络或 Token。"
    exit 1
fi

# 3. 解压文件
# -o 表示覆盖现有文件，-j 表示不创建压缩包内的文件夹层级，直接解压到当前目录
echo "正在解压..."
unzip -o -j $TEMP_ZIP "$BIN_NAME" -d $TARGET_DIR

if [ $? -ne 0 ]; then
    echo "错误：解压失败，请检查是否安装了 unzip。"
    exit 1
fi

# 4. 删除临时 ZIP 包
rm -f $TEMP_ZIP

# 5. 通知 Java 应用进行热重载
echo "通知 Java 应用重载数据..."
RESPONSE=$(curl -s -X POST $RELOAD_URL)

echo "应用响应: $RESPONSE"
echo "[$(date)] 更新流程结束。"