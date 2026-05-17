/**
 * GMS Wallet Cache Cleaner v1.2 - WebUI 交互脚本
 * 分层清理系统：safe | refresh | experimental
 */

const MODULE_PATH = '/data/adb/modules/gms_wallet_cache_cleaner';
const SCRIPT_PATH = MODULE_PATH + '/clear.sh';

let currentLang = 'zh';
let logCount = 0;
let operationInProgress = false;

// ========== DOM 引用（延迟获取） ==========
function getLogEl() { return document.getElementById('log'); }
function getLogCountEl() { return document.getElementById('logCount'); }

// ========== 日志系统 ==========
function appendLog(text, type) {
    const logEl = getLogEl();
    if (!logEl) return;
    
    const timestamp = new Date().toLocaleTimeString('zh-CN', { hour12: false });
    const typeClass = type || '';
    const line = `[${timestamp}] <span class="${typeClass}">${escapeHtml(text)}</span>\n`;
    
    logEl.innerHTML += line;
    logEl.scrollTop = logEl.scrollHeight;
    
    logCount++;
    const countEl = getLogCountEl();
    if (countEl) countEl.textContent = logCount + ' 条';
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function setButtonsEnabled(enabled) {
    const buttons = document.querySelectorAll('.btn');
    buttons.forEach(btn => btn.disabled = !enabled);
    operationInProgress = !enabled;
}

function clearLog() {
    const logEl = getLogEl();
    if (logEl) {
        logEl.innerHTML = '';
        logCount = 0;
        const countEl = getLogCountEl();
        if (countEl) countEl.textContent = '0 条';
        appendLog('日志已清除', 'info');
    }
}

// ========== 命令执行 ==========
async function exec(cmd) {
    appendLog('执行: ' + cmd, 'info');
    
    try {
        const response = await fetch('/exec', {
            method: 'POST',
            headers: { 'Content-Type': 'text/plain' },
            body: cmd
        });
        
        if (!response.ok) {
            throw new Error('HTTP ' + response.status + ': ' + response.statusText);
        }
        
        const output = await response.text();
        const lines = output.trim().split('\n');
        lines.forEach(line => {
            const trimmed = line.trim();
            if (!trimmed) return;
            
            if (trimmed.startsWith('✓') || trimmed.startsWith('✅')) {
                appendLog(trimmed, 'success');
            } else if (trimmed.startsWith('✗')) {
                appendLog(trimmed, 'error');
            } else if (trimmed.startsWith('⚠️') || trimmed.startsWith('🔴') || trimmed.startsWith('警告')) {
                appendLog(trimmed, 'warn');
            } else if (trimmed.startsWith('ℹ️')) {
                appendLog(trimmed, 'info');
            } else {
                appendLog(trimmed, '');
            }
        });
        return output;
    } catch (error) {
        appendLog('执行失败: ' + error.message, 'error');
        throw error;
    }
}

// ========== 操作函数 ==========
function execCmd(cmd) {
    if (operationInProgress) {
        appendLog('当前有操作正在进行，请等待完成', 'warn');
        return;
    }
    
    let confirmMsg = '';
    let cmdToExec = 'sh ' + SCRIPT_PATH + ' ' + cmd;
    
    switch (cmd) {
        case 'safe':
            confirmMsg = '🟢 安全模式: 仅清除 cache 和 code_cache\n不影响账号和手表配对。\n\n确定继续吗？';
            break;
        case 'refresh':
            confirmMsg = '🟡 刷新模式: 清缓存 + 杀掉 unstable 进程\n这是推荐的日常清理方式。\n\n确定继续吗？';
            break;
        case 'experimental':
            confirmMsg = '🔴 探索模式: 清理 files/ 和 no_backup/ 中的非保护文件\n\n' +
                        '⚠️ 警告:\n' +
                        '• 此操作有一定风险\n' +
                        '• 但不会丢失账号和手表配对\n' +
                        '• 建议先执行 snapshot\n\n' +
                        '确定要继续吗？';
            break;
        case 'backup':
            confirmMsg = '📦 全量备份当前GMS数据\n这将创建一个完整的备份。\n\n确定继续吗？';
            break;
        case 'snapshot':
            confirmMsg = '📸 创建GMS文件状态快照\n记录当前所有文件的修改时间和大小。\n\n确定继续吗？';
            break;
        case 'diff':
            confirmMsg = '📊 对比最新的两次快照\n发现哪些文件发生了变化。\n\n确定继续吗？';
            break;
        case 'list':
            confirmMsg = ''; // 无需确认
            break;
        case 'reboot':
            confirmMsg = '🔁 确定要重启设备吗？';
            break;
        default:
            appendLog('未知命令: ' + cmd, 'error');
            return;
    }
    
    if (confirmMsg && !confirm(confirmMsg)) return;
    
    setButtonsEnabled(false);
    
    if (cmd === 'reboot') {
        appendLog('设备将在3秒后重启...', 'warn');
        setTimeout(() => {
            exec('reboot')
                .then(() => appendLog('重启命令已发送', 'info'))
                .catch(() => {
                    appendLog('重启失败，请手动重启', 'error');
                    setButtonsEnabled(true);
                });
        }, 3000);
    } else {
        exec(cmdToExec)
            .finally(() => setButtonsEnabled(true));
    }
}

// ========== 双语切换 ==========
function setLang(lang) {
    currentLang = lang;
    
    // Switch buttons
    document.getElementById('langZh').classList.toggle('active', lang === 'zh');
    document.getElementById('langEn').classList.toggle('active', lang === 'en');
    
    // Toggle all zh/en elements
    document.querySelectorAll('.lang-zh').forEach(el => {
        el.style.display = lang === 'zh' ? '' : 'none';
    });
    document.querySelectorAll('.lang-en').forEach(el => {
        el.style.display = lang === 'en' ? '' : 'none';
    });
    
    // Update time format
    updateClock();
    
    // Save preference
    try { localStorage.setItem('gms_cleaner_lang', lang); } catch(e) {}
}

function updateClock() {
    const timeEl = document.getElementById('time');
    if (!timeEl) return;
    const locale = currentLang === 'zh' ? 'zh-CN' : 'en-US';
    timeEl.textContent = new Date().toLocaleString(locale, { hour12: false });
}

// ========== 页面初始化 ==========
function init() {
    const timeEl = document.getElementById('time');
    if (timeEl) {
        updateClock();
        setInterval(updateClock, 1000);
    }
    
    // Restore language preference
    try {
        const saved = localStorage.getItem('gms_cleaner_lang');
        if (saved === 'en') setLang('en');
    } catch(e) {}
    
    const readyMsg = currentLang === 'zh' 
        ? 'GMS缓存清理器 v1.2 已就绪' 
        : 'GMS Cache Cleaner v1.2 ready';
    const tip1 = currentLang === 'zh'
        ? '推荐使用 🟡 Refresh 模式'
        : 'Recommended: 🟡 Refresh mode';
    const tip2 = currentLang === 'zh'
        ? '先用 snapshot 记录状态，操作后再 diff 对比'
        : 'Use snapshot first, then diff to find changes';
    
    appendLog(readyMsg, 'success');
    appendLog(tip1, 'info');
    appendLog(tip2, 'info');
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}
