#!/system/bin/sh

MODDIR=${0%/*}
BACKUP_DIR="/data/adb/gms_backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

GMS_PKGS="com.google.android.gms com.google.android.apps.walletnfcrel com.android.vending"

case "$1" in
    backup)
        mkdir -p "$BACKUP_DIR/$TIMESTAMP"
        for pkg in $GMS_PKGS; do
            if [ -d "/data/data/$pkg" ]; then
                cp -a "/data/data/$pkg" "$BACKUP_DIR/$TIMESTAMP/" 2>/dev/null
                echo "已备份 $pkg"
            fi
        done
        echo "备份完成: $BACKUP_DIR/$TIMESTAMP"
        ;;
    
    cache)
        for pkg in $GMS_PKGS; do
            am force-stop $pkg 2>/dev/null
            rm -rf /data/data/$pkg/cache/* 2>/dev/null
            rm -rf /data/data/$pkg/code_cache/* 2>/dev/null
            echo "已清除 $pkg Cache"
        done
        echo "Cache清除完成"
        ;;
    
    data)
        # 选择性，只清部分临时文件
        for pkg in $GMS_PKGS; do
            am force-stop $pkg 2>/dev/null
            rm -rf /data/data/$pkg/cache/* /data/data/$pkg/code_cache/* 2>/dev/null
            echo "已处理 $pkg"
        done
        echo "选择性Data处理完成"
        ;;
    
    restore)
        LATEST=$(ls -d "$BACKUP_DIR"/*/ 2>/dev/null | sort | tail -n1)
        if [ -n "$LATEST" ]; then
            for pkg in $GMS_PKGS; do
                if [ -d "$LATEST$pkg" ]; then
                    cp -a "$LATEST$pkg/"* "/data/data/$pkg/" 2>/dev/null
                    echo "已恢复 $pkg"
                fi
            done
            echo "恢复完成"
        else
            echo "未找到备份"
        fi
        ;;
    
    *)
        echo "用法: $0 [backup|cache|data|restore]"
        ;;
esac