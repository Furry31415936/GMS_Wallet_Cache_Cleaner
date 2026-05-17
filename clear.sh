#!/system/bin/sh
# GMS Wallet Cache Cleaner - 核心脚本
# 支持: backup | cache | data | restore

MODDIR=${0%/*}
BACKUP_DIR="/data/adb/gms_backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$BACKUP_DIR/operation_log.txt"

# 目标包名: Google Play服务 / Google钱包 / Play商店
GMS_PKGS="com.google.android.gms com.google.android.apps.walletnfcrel com.android.vending"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE" 2>/dev/null
}

ensure_backup_dir() {
    mkdir -p "$BACKUP_DIR" 2>/dev/null
    chmod 755 "$BACKUP_DIR" 2>/dev/null
}

force_stop_pkg() {
    am force-stop $1 2>/dev/null
    sleep 1
}

case "$1" in
    backup)
        ensure_backup_dir
        log "开始备份GMS数据..."
        mkdir -p "$BACKUP_DIR/$TIMESTAMP"
        
        for pkg in $GMS_PKGS; do
            if [ -d "/data/data/$pkg" ]; then
                # 先停止进程
                force_stop_pkg $pkg
                # 备份整个应用数据目录
                cp -a "/data/data/$pkg" "$BACKUP_DIR/$TIMESTAMP/" 2>/dev/null
                if [ $? -eq 0 ]; then
                    log "✓ 已备份: $pkg"
                else
                    log "✗ 备份失败: $pkg"
                fi
            else
                log "- 跳过(不存在): $pkg"
            fi
        done
        
        log "备份完成 → $BACKUP_DIR/$TIMESTAMP"
        log "备份大小: $(du -sh "$BACKUP_DIR/$TIMESTAMP" 2>/dev/null | cut -f1)"
        ;;

    cache)
        log "开始清除GMS缓存..."
        
        for pkg in $GMS_PKGS; do
            if [ -d "/data/data/$pkg" ]; then
                force_stop_pkg $pkg
                
                # 清除缓存目录
                rm -rf /data/data/$pkg/cache/* 2>/dev/null
                rm -rf /data/data/$pkg/code_cache/* 2>/dev/null
                
                log "✓ 缓存已清除: $pkg"
            else
                log "- 跳过(不存在): $pkg"
            fi
        done
        
        log "缓存清除完成！请重启设备使更改生效"
        ;;

    data)
        log "⚠️ 开始选择性清除数据..."
        
        for pkg in $GMS_PKGS; do
            if [ -d "/data/data/$pkg" ]; then
                force_stop_pkg $pkg
                
                # 清除缓存目录（不清除databases和shared_prefs以保持登录状态）
                rm -rf /data/data/$pkg/cache/* 2>/dev/null
                rm -rf /data/data/$pkg/code_cache/* 2>/dev/null
                rm -rf /data/data/$pkg/files/* 2>/dev/null
                rm -rf /data/data/$pkg/no_backup/* 2>/dev/null
                
                log "✓ 数据已处理: $pkg"
            else
                log "- 跳过(不存在): $pkg"
            fi
        done
        
        log "选择性数据处理完成！请重启设备"
        log "注意: 部分服务可能需要重新登录"
        ;;

    restore)
        log "开始搜索备份..."
        
        # 列出所有备份目录并按时间排序
        LATEST=$(ls -dt "$BACKUP_DIR"/*/ 2>/dev/null | head -n1)
        
        if [ -z "$LATEST" ]; then
            log "✗ 未找到任何备份文件！请先执行备份操作。"
            exit 1
        fi
        
        log "找到最新备份: $LATEST"
        
        for pkg in $GMS_PKGS; do
            if [ -d "$LATEST$pkg" ]; then
                force_stop_pkg $pkg
                # 恢复备份数据
                cp -a "$LATEST$pkg/"* "/data/data/$pkg/" 2>/dev/null
                if [ $? -eq 0 ]; then
                    log "✓ 已恢复: $pkg"
                else
                    log "✗ 恢复失败: $pkg"
                fi
            else
                log "- 备份中不存在: $pkg (跳过)"
            fi
        done
        
        log "恢复完成！请重启设备使更改生效"
        ;;

    list)
        echo "=== GMS备份列表 ==="
        ls -dt "$BACKUP_DIR"/*/ 2>/dev/null | while read dir; do
            dirname=$(basename "$dir")
            size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            echo "  $dirname  ($size)"
        done
        if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR"/ 2>/dev/null)" ]; then
            echo "  (暂无备份)"
        fi
        ;;

    *)
        echo "GMS Wallet Cache Cleaner - 用法"
        echo "================================"
        echo "  $0 backup      备份当前GMS数据"
        echo "  $0 cache       清除缓存（推荐，不丢登录）"
        echo "  $0 data        选择性清除数据（谨慎）"
        echo "  $0 restore     恢复最新备份"
        echo "  $0 list        查看备份列表"
        echo ""
        echo "示例: $0 cache"
        ;;
esac
