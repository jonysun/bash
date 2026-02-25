#!/bin/bash

echo "======================================"
echo " Qinglong 挖矿木马专项检测工具"
echo "======================================"
echo

FOUND=0

# -----------------------------
# 1️⃣ 检查 Qinglong 容器
# -----------------------------
echo "[1] 检查 Qinglong 容器..."

QL_CONTAINER=$(docker ps -a --format '{{.Names}}' | grep -i qinglong)

if [[ -z "$QL_CONTAINER" ]]; then
    echo "未发现 qinglong 容器"
else
    echo "发现容器: $QL_CONTAINER"

    echo "正在解析挂载路径..."
    MOUNTS=$(docker inspect "$QL_CONTAINER" 2>/dev/null | grep -A 5 '"Destination": "/ql/data"' | grep '"Source"' | awk -F '"' '{print $4}')

    if [[ -z "$MOUNTS" ]]; then
        echo "未找到 /ql/data 挂载路径，尝试查找常规挂载..."
        MOUNTS=$(docker inspect "$QL_CONTAINER" | grep '"Source"' | awk -F '"' '{print $4}')
    fi

    for DIR in $MOUNTS; do
        if [[ -d "$DIR/db" ]]; then
            TARGET="$DIR/db"
        else
            TARGET="$DIR"
        fi

        echo "扫描目录: $TARGET"
        RESULT=$(find "$TARGET" -type f -name ".fullgc" 2>/dev/null)

        if [[ -n "$RESULT" ]]; then
            echo "⚠ 发现可疑文件:"
            echo "$RESULT"
            FOUND=1
        else
            echo "未发现 .fullgc"
        fi
    done
fi

echo
# -----------------------------
# 2️⃣ 扫描常见高危路径
# -----------------------------
echo "[2] 扫描常见系统路径..."

COMMON_PATHS="/var /root /opt /ugreen"

for P in $COMMON_PATHS; do
    if [[ -d "$P" ]]; then
        echo "扫描 $P ..."
        RESULT=$(find "$P" -type f -name ".fullgc" 2>/dev/null)
        if [[ -n "$RESULT" ]]; then
            echo "⚠ 在 $P 发现可疑文件:"
            echo "$RESULT"
            FOUND=1
        else
            echo "未发现异常"
        fi
    fi
done

echo
# -----------------------------
# 3️⃣ 检查隐藏进程
# -----------------------------
echo "[3] 检查隐藏进程..."

PROC=$(ps aux | grep "\.fullgc" | grep -v grep)

if [[ -n "$PROC" ]]; then
    echo "⚠ 发现可疑进程:"
    echo "$PROC"
    FOUND=1
else
    echo "未发现 .fullgc 进程"
fi

echo
# -----------------------------
# 4️⃣ 检查高CPU异常进程
# -----------------------------
echo "[4] 检查高CPU占用进程..."

TOPPROC=$(ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6)

echo "$TOPPROC"

echo "$TOPPROC" | grep -q ".fullgc"
if [[ $? -eq 0 ]]; then
    FOUND=1
fi

echo
# -----------------------------
# 结果判断
# -----------------------------
if [[ $FOUND -eq 1 ]]; then
    echo "======================================"
    echo "⚠ 系统存在高风险迹象！建议立即排查"
    echo "======================================"
else
    echo "======================================"
    echo "✓ 未发现明显挖矿木马特征"
    echo "======================================"
fi