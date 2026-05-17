/**
 * GMS Wallet Cache Cleaner - WebUI 交互脚本
 * 兼容 Magisk WebUI 和 KernelSU WebUI 的 /exec 接口
 */

// 模块根路径（KSU和Magisk的访问路径一致）
const MODULE_PATH = '/data/adb/modules/gms_wallet_cache_cleaner';
const SCRIPT_PATH = MODULE_PATH + '/clear.sh';
const BACKUP_DIR = '/data/adb/gms_backup';

let logCount = 0;

function getLogEl() {
    return document.getElementById('log');
}

function updateLogCount() {
    const el = document.getElementById('logCount');
    if (el) el.textContent = logCount + ' 条';
}

function appendLog(text, type) {
    const logEl = getLogEl();
    if (!logEl) return;
    
    const timestamp = new Date().toLocaleTimeString('zh-CN', { hour12: false });
    const typeClass = type || '';
    const line = `[${timestamp}] <span class="${typeClass}">${escapeHtml(text)}</span>\n`;
    
    logEl.innerHTML += line;
    logEl.scrollTop = logEl.scrollHeight;
    
    logCount++;
    updateLogCount();
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function setButtonsEnabled(enabled) {
    const buttons = document.querySelectorAll('.btn');
    buttons.forEach(btn => btn.disabled = !enabled);
}

function clearLog() {
    const logEl = getLogEl();
    if (logEl) {
        logEl.innerHTML = '';
        logCount = 0;
        updateLogCount();
        appendLog('日志已清除', 'info');
    }
}

/**
 * 通过 KSU/Magisk WebUI 执行命令
 */
function exec(cmd) {
    appendLog('执行: ' + cmd, 'info');
    
    return fetch('/exec', {
        method: 'POST',
        headers: { 'Content-Type': 'text/plain' },
        body: cmd
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('HTTP ' + response.status + ': ' + response.statusText);
        }
        return response.text();
    })
    .then(output => {
        // 解析并显示输出
        const lines = output.trim().split('\n');
        lines.forEach(line => {
            const trimmed = line.trim();
            if (!trimmed) return;
            
            if (trimmed.startsWith('✓')) {
                appendLog(trimmed, 'success');
            } else if (trimmed.startsWith('✗')) {
                appendLog(trimmed, 'error');
            } else if (trimmed.startsWith('⚠️') || trimmed.startsWith('注意')) {
                appendLog(trimmed, 'warn');
            } else {
                appendLog(trimmed, '');
            }
        });
        return output;
    })
    .catch(error => {
        appendLog('执行失败: ' + error.message, 'error');
        throw error;
    });
}

// ========== 操作函数 ==========

function backup() {
    if (!confirm('⚠️ 确定要备份当前GMS数据吗？\n\n这将创建一个带时间戳的完整备份。')) return;
    
    setButtonsEnabled(false);
    appendLog('开始备份GMS数据...', 'info');
    
    exec('sh ' + SCRIPT_PATH + ' backup')
        .finally(() => setButtonsEnabled(true));
}

function clearCache() {
    if (!confirm('🗑️ 确定要清除GMS和Wallet的缓存吗？\n\n这不会清除登录数据，是最安全的操作。')) return;
    
    setButtonsEnabled(false);
    appendLog('开始清除缓存...', 'info');
    
    exec('sh ' + SCRIPT_PATH + ' cache')
        .finally(() => setButtonsEnabled(true));
}

function clearData() {
    if (!confirm('⚠️ 警告：这将清除部分数据！\n\n可能会导致需要重新登录部分Google服务。\n确定继续吗？')) return;
    
    if (!confirm('⚠️ 二次确认：\n\n请确保已先执行"备份"操作！\n确定要继续吗？')) return;
    
    setButtonsEnabled(false);
    appendLog('开始选择性清除数据...', 'warn');
    
    exec('sh ' + SCRIPT_PATH + ' data')
        .finally(() => setButtonsEnabled(true));
}

function restore() {
    if (!confirm('🔄 确定要从最新的备份恢复数据吗？\n\n这将覆盖当前的所有GMS数据。')) return;
    
    setButtonsEnabled(false);
    appendLog('开始从备份恢复...', 'info');
    
    exec('sh ' + SCRIPT_PATH + ' restore')
        .finally(() => setButtonsEnabled(true));
}

function listBackups() {
    setButtonsEnabled(false);
    appendLog('正在查询备份列表...', 'info');
    
    exec('sh ' + SCRIPT_PATH + ' list')
        .finally(() => setButtonsEnabled(true));
}

function reboot() {
    if (!confirm('🔁 确定要重启设备吗？\n\n请确保已保存所有工作。')) return;
    
    appendLog('设备将在3秒后重启...', 'warn');
    setButtonsEnabled(false);
    
    setTimeout(() => {
        exec('reboot')
            .then(() => appendLog('重启命令已发送', 'info'))
            .catch(() => {
                appendLog('重启失败，请手动重启设备', 'error');
                setButtonsEnabled(true);
            });
    }, 3000);
}

// ========== 页面初始化 ==========

function init() {
    // 更新时间显示
    const timeEl = document.getElementById('time');
    if (timeEl) {
        function updateTime() {
            timeEl.textContent = new Date().toLocaleString('zh-CN', { hour12: false });
        }
        updateTime();
        setInterval(updateTime, 1000);
    }
    
    appendLog('GMS缓存清理器已就绪', 'success');
    appendLog('请先备份，再执行清除操作', 'info');
}

// 等待DOM加载完成后初始化
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}
