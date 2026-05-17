#!/system/bin/sh
# GMS Wallet Cache Cleaner v1.2 - 核心脚本
# 分层清理系统：safe | refresh | experimental
# 支持: backup | snapshot | diff | list

MODDIR=${0%/*}
BACKUP_DIR="/data/adb/gms_backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$BACKUP_DIR/operation_log.txt"
SNAPSHOT_DIR="$BACKUP_DIR/snapshots"

# ============================================================
# 目标包名
# ============================================================
GMS_PKGS="com.google.android.gms com.google.android.apps.walletnfcrel com.android.vending"

# ============================================================
# 🛡️ 保护目录白名单（绝不触碰）
# 删除以下目录会导致：账号退出 / 手表断连 / 推送失效
# ============================================================
PROTECTED_DIRS="
databases
shared_prefs
app_AccountData
app_SSO_authorization
app_wearable
app_nearby
app_fcm
app_Chromium_Linker
app_WebView
"

# ============================================================
# 工具函数
# ============================================================

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE" 2>/dev/null
}

ensure_dir() {
    mkdir -p "$1" 2>/dev/null
    chmod 755 "$1" 2>/dev/null
}

force_stop_pkg() {
    am force-stop "$1" 2>/dev/null
    sleep 1
}

# 安全删除：跳过保护目录
safe_rm() {
    local base_dir="$1"
    local target="$2"
    
    # 检查是否在保护名单中
    for protected in $PROTECTED_DIRS; do
        case "$target" in
            *"$protected"*)
                log "- 跳过(保护目录): $target"
                return 1
                ;;
        esac
    done
    
    rm -rf "$target" 2>/dev/null
    return 0
}

# 递归安全删除目录内容（跳过保护目录）
safe_rm_dir_contents() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        return
    fi
    
    for item in "$dir"/*; do
        [ -e "$item" ] || continue
        local basename_item=$(basename "$item")
        
        # 检查是否在保护名单中
        local skip=0
        for protected in $PROTECTED_DIRS; do
            if [ "$basename_item" = "$protected" ] || echo "$basename_item" | grep -q "$protected"; then
                skip=1
                break
            fi
        done
        
        if [ "$skip" = 1 ]; then
            log "- 跳过(保护): $item"
        else
            rm -rf "$item" 2>/dev/null
        fi
    done
}

# ============================================================
# 核心功能
# ============================================================

# --- 备份 ---
do_backup() {
    ensure_dir "$BACKUP_DIR/$TIMESTAMP"
    log "📦 开始备份GMS数据..."
    
    for pkg in $GMS_PKGS; do
        if [ -d "/data/data/$pkg" ]; then
            force_stop_pkg "$pkg"
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
    
    log "✅ 备份完成 → $BACKUP_DIR/$TIMESTAMP"
    log "   大小: $(du -sh "$BACKUP_DIR/$TIMESTAMP" 2>/dev/null | cut -f1)"
}

# --- Safe Level: 仅清普通缓存 ---
do_safe() {
    log "🔵 [Safe Mode] 开始清除缓存..."
    log "   仅清理 cache/ 和 code_cache/，不影响账号和手表"
    
    for pkg in $GMS_PKGS; do
        if [ -d "/data/data/$pkg" ]; then
            force_stop_pkg "$pkg"
            
            # 只清普通缓存
            rm -rf "/data/data/$pkg/cache/"* 2>/dev/null
            rm -rf "/data/data/$pkg/code_cache/"* 2>/dev/null
            
            log "✓ 缓存已清除: $pkg"
        else
            log "- 跳过(不存在): $pkg"
        fi
    done
    
    log "✅ Safe 模式执行完成！请重启设备"
}

# --- Refresh Level: 安全清理 + 刷新进程 ---
do_refresh() {
    log "🟡 [Refresh Mode] 开始刷新GMS状态..."
    log "   清理缓存 + 重启unstable进程 + 刷新内存态verdict"
    
    # 1. 先做Safe清理
    for pkg in $GMS_PKGS; do
        if [ -d "/data/data/$pkg" ]; then
            force_stop_pkg "$pkg"
            rm -rf "/data/data/$pkg/cache/"* 2>/dev/null
            rm -rf "/data/data/$pkg/code_cache/"* 2>/dev/null
            log "✓ 缓存已清除: $pkg"
        fi
    done
    
    # 2. 关键：杀掉 gms.unstable 进程（DroidGuard/Integrity运行在此）
    #   优先级：先 SIGTERM(kill) 尝试优雅退出 → 2秒后未退出再 SIGKILL(kill -9)
    #   这样可以避免强制杀进程导致的 sqlite 写损坏
    log "- 正在处理 com.google.android.gms.unstable..."
    local unstable_pids=$(pidof com.google.android.gms.unstable 2>/dev/null)
    if [ -n "$unstable_pids" ]; then
        # 先尝试 SIGTERM（优雅停止）
        kill $unstable_pids 2>/dev/null
        log "✓ 已发送 SIGTERM → unstable (PID: $unstable_pids)"
        sleep 2
        
        # 检查是否仍在运行，如果是则强杀
        local still_running=$(pidof com.google.android.gms.unstable 2>/dev/null)
        if [ -n "$still_running" ]; then
            kill -9 $still_running 2>/dev/null
            log "  ⚠️ SIGTERM 超时，回退 SIGKILL (PID: $still_running)"
        else
            log "  ✓ 已优雅退出"
        fi
        sleep 1
    else
        log "- unstable 进程未运行"
    fi
    
    # 3. 杀掉 Wallet 进程（同样先 SIGTERM）
    local wallet_pids=$(pidof com.google.android.apps.walletnfcrel 2>/dev/null)
    if [ -n "$wallet_pids" ]; then
        kill $wallet_pids 2>/dev/null
        sleep 2
        local wallet_still=$(pidof com.google.android.apps.walletnfcrel 2>/dev/null)
        if [ -n "$wallet_still" ]; then
            kill -9 $wallet_still 2>/dev/null
            log "✓ 已终止 Wallet 进程 (SIGKILL fallback)"
        else
            log "✓ 已终止 Wallet 进程 (SIGTERM)"
        fi
        sleep 1
    fi
    
    log "✅ Refresh 模式执行完成！"
    log "   提示: 打开Wallet前建议先重启设备，或等待2-3分钟让GMS重连"
}

# --- Experimental Level: 探索性清理 ---
do_experimental() {
    log "🔴 [Experimental Mode] 开始探索性清理..."
    log "   警告: 此模式会清理 files/ 和 no_backup/ 中的非保护文件"
    log "   可能影响部分非核心功能，但不会丢失账号和手表配对"
    
    # 1. 先执行Refresh
    do_refresh
    
    # 2. 清理 files/ 中的非保护文件
    for pkg in $GMS_PKGS; do
        if [ -d "/data/data/$pkg" ]; then
            force_stop_pkg "$pkg"
            
            # 安全清理 files/
            if [ -d "/data/data/$pkg/files" ]; then
                log "- 清理 files/ 目录 (跳过保护文件)..."
                safe_rm_dir_contents "/data/data/$pkg/files"
            fi
            
            # 安全清理 no_backup/
            if [ -d "/data/data/$pkg/no_backup" ]; then
                log "- 清理 no_backup/ 目录 (跳过保护文件)..."
                safe_rm_dir_contents "/data/data/$pkg/no_backup"
            fi
            
            log "✓ 探索性清理完成: $pkg"
        fi
    done
    
    log "✅ Experimental 模式执行完成！"
    log "   强烈建议重启设备"
}

# --- 文件快照（用于研究哪些文件变化） ---
# 记录：size + mtime + md5 校验和
# md5sum 能发现"内容变了但大小没变"的情况（如 protobuf/xml 原地修改）
do_snapshot() {
    ensure_dir "$SNAPSHOT_DIR"
    local snapshot_file="$SNAPSHOT_DIR/snapshot_$TIMESTAMP.txt"
    
    log "📸 正在创建GMS文件状态快照（含md5校验和）..."
    log "   保存到: $snapshot_file"
    log "   提示: 如果 diff 发现文件大小未变但内容已变，说明是原地修改"
    
    {
        echo "============================================"
        echo "GMS File Snapshot (with md5 checksums)"
        echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Format: size | mtime | md5 | path"
        echo "============================================"
        echo ""
        
        for pkg in $GMS_PKGS; do
            if [ -d "/data/data/$pkg" ]; then
                echo "--- $pkg ---"
                find "/data/data/$pkg" -type f \
                    -not -path "*/cache/*" \
                    -not -path "*/code_cache/*" \
                    2>/dev/null | while read -r f; do
                    if [ -f "$f" ]; then
                        local size=$(stat -c%s "$f" 2>/dev/null)
                        local mtime=$(stat -c%y "$f" 2>/dev/null | cut -d. -f1)
                        local md5=$(md5sum "$f" 2>/dev/null | cut -d' ' -f1)
                        [ -z "$md5" ] && md5="NO_CHECKSUM"
                        echo "$size | $mtime | $md5 | $f"
                    fi
                done | sort -t'|' -k4
                echo ""
            fi
        done
    } > "$snapshot_file"
    
    log "✅ 快照已创建: $(wc -l < "$snapshot_file") 行"
    log "   你可以在不同状态下多次 snapshot 后用 diff 对比"
    log "   关注：大小不变但md5变化的文件 → 很可能是状态文件"
}

# --- 快照对比（纯POSIX sh，不依赖bash数组） ---
do_diff() {
    # 用while read + 临时文件列表替代数组
    local snapshot_list="/tmp/gms_snapshot_list.$$"
    ls -t "$SNAPSHOT_DIR"/snapshot_*.txt 2>/dev/null > "$snapshot_list"
    
    local count=0
    while IFS= read -r line; do
        count=$((count + 1))
    done < "$snapshot_list"
    
    if [ "$count" -lt 2 ]; then
        log "✗ 需要至少2个快照才能对比 (当前: $count)"
        log "   请先在不同状态下(如Wallet FAIL/PASS)执行snapshot"
        rm -f "$snapshot_list"
        return
    fi
    
    # 取最新的两个（第1行和第2行）
    local latest=""
    local prev=""
    local line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if [ "$line_num" -eq 1 ]; then
            latest="$line"
        elif [ "$line_num" -eq 2 ]; then
            prev="$line"
        fi
    done < "$snapshot_list"
    
    rm -f "$snapshot_list"
    
    if [ -z "$latest" ] || [ -z "$prev" ]; then
        log "✗ 无法获取快照文件"
        return
    fi
    
    log "📊 对比快照:"
    log "   之后: $(basename "$latest")"
    log "   之前: $(basename "$prev")"
    
    local diff_output=$(diff "$prev" "$latest" 2>/dev/null)
    if [ -z "$diff_output" ]; then
        log "   没有变化"
    else
        log "   变化内容如下:"
        echo "$diff_output" | while IFS= read -r line; do
            log "   $line"
        done
    fi
}

# --- 查看备份/快照列表 ---
do_list() {
    echo ""
    echo "📂 GMS备份列表"
    echo "================"
    if [ -d "$BACKUP_DIR" ]; then
        ls -dt "$BACKUP_DIR"/*/ 2>/dev/null | while read -r dir; do
            [ -z "$dir" ] && continue
            local dirname=$(basename "$dir")
            local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            echo "  📦 $dirname  ($size)"
        done
    fi
    
    echo ""
    echo "📸 快照列表"
    echo "================"
    if [ -d "$SNAPSHOT_DIR" ]; then
        ls -t "$SNAPSHOT_DIR"/snapshot_*.txt 2>/dev/null | while read -r f; do
            [ -z "$f" ] && continue
            local fname=$(basename "$f")
            local lines=$(wc -l < "$f")
            echo "  📄 $fname  ($lines 行)"
        done
    fi
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR"/ 2>/dev/null)" ]; then
        echo "  (暂无备份)"
    fi
}

# ============================================================
# 主入口
# ============================================================

case "$1" in
    backup)
        do_backup
        ;;
    
    safe)
        do_safe
        ;;
    
    refresh)
        do_refresh
        ;;
    
    experimental)
        do_experimental
        ;;
    
    snapshot)
        do_snapshot
        ;;
    
    diff)
        do_diff
        ;;
    
    list)
        do_list
        ;;
    
    # 兼容旧版命令
    cache)
        log "ℹ️ 'cache' 已重命名为 'safe'，使用更安全的清理策略"
        do_safe
        ;;
    
    data)
        log "ℹ️ 'data' 已拆分为 'refresh' 和 'experimental'"
        log "   推荐使用: $0 refresh"
        log "   如需更深入: $0 experimental"
        ;;
    
    restore)
        log "⚠️ 全量恢复功能已移除（风险过高）"
        log "   建议改用 snapshot 功能记录文件状态"
        log "   如确实需要恢复，请手动操作:"
        log "   Latest backup: $(ls -dt "$BACKUP_DIR"/*/ 2>/dev/null | head -n1)"
        ;;
    
    *)
        echo ""
        echo "╔════════════════════════════════════════════════════╗"
        echo "║        GMS Wallet Cache Cleaner v1.2              ║"
        echo "║        分层清理系统 | Layered Cleaning System     ║"
        echo "╚════════════════════════════════════════════════════╝"
        echo ""
        echo "┌─ Cleaning / 清理操作 ─────────────────────────────┐"
        echo "│  $0 safe           🟢 Safe / 安全模式              │"
        echo "│  CN: 仅清 cache/code_cache                        │"
        echo "│  EN: Cache only, safest                           │"
        echo "│                                                    │"
        echo "│  $0 refresh        🟡 Refresh / 刷新模式 ⭐        │"
        echo "│  CN: 清缓存 + 杀unstable，推荐                    │"
        echo "│  EN: Cache + kill unstable, recommended           │"
        echo "│                                                    │"
        echo "│  $0 experimental 🔴 Experimental / 探索模式      │"
        echo "│  CN: 额外清理 files/ 和 no_backup/                │"
        echo "│  EN: Also cleans files/ and no_backup/            │"
        echo "└────────────────────────────────────────────────────┘"
        echo ""
        echo "┌─ Tools / 辅助功能 ─────────────────────────────────┐"
        echo "│  $0 backup      📦 Backup / 全量备份               │"
        echo "│  $0 snapshot    📸 Snapshot / 文件快照             │"
        echo "│  $0 diff        📊 Diff snapshots / 对比快照       │"
        echo "│  $0 list        📋 List backups / 查看列表         │"
        echo "└────────────────────────────────────────────────────┘"
        echo ""
        echo "┌─ Examples / 使用示例 ─────────────────────────────┐"
        echo "│  $0 safe        Daily cleanup / 日常清理            │
        echo "│  $0 refresh     Refresh then reboot / 刷新后重启   │
        echo "│  $0 snapshot    Record current state / 记录状态    │"
        echo "└────────────────────────────────────────────────────┘"
        echo ""
        ;;
esac
