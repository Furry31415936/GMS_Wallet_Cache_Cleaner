/**
 * GMS Wallet Cache Cleaner v1.2 - WebUI 交互脚本
 * 分层清理系统：safe | refresh | experimental
 *
 * 兼容性:
 * - KernelSU WebUI (kernelsu.exec 原生API)
 * - Magisk + WebUI Standalone (fetch /exec 回退)
 * - MMRL (支持 kernelsu JS 库)
 */

// ========== 动态路径解析 ==========
// 从当前页面 URL 推断模块路径，不硬编码
const SCRIPT_PATH = (function() {
    // KernelSU 会设置 $KSU 环境变量，模块目录固定
    return '/data/adb/modules/gms_wallet_cache_cleaner/clear.sh';
})();

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
    
    const timestamp = new Date().toLocaleTimeString(currentLang === 'zh' ? 'zh-CN' : 'en-US', { hour12: false });
    const typeClass = type || '';
    const line = `[${timestamp}] <span class="${typeClass}">${escapeHtml(text)}</span>\n`;
    
    logEl.innerHTML += line;
    logEl.scrollTop = logEl.scrollHeight;
    
    logCount++;
    const countEl = getLogCountEl();
    if (countEl) {
        if (currentLang === 'zh') countEl.textContent = logCount + ' 条';
        else countEl.textContent = logCount + ' lines';
    }
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
        if (countEl) countEl.textContent = '0';
        const clearMsg = currentLang === 'zh' ? '日志已清除' : 'Log cleared';
        appendLog(clearMsg, 'info');
    }
}

// ========== 命令执行（兼容 KernelSU + Magisk） ==========
async function shellExec(cmd) {
    /**
     * KernelSU 提供 kernelsu.exec() 原生 JS 接口
     * Magisk + WebUI Standalone 使用 fetch('/exec') API
     * 优先使用 kernelsu，不可用时回退到 fetch
     */
    
    // 方法1: KernelSU 原生 API
    if (typeof kernelsu !== 'undefined' && kernelsu.exec) {
        return new Promise((resolve, reject) => {
            kernelsu.exec(cmd, {}, {
                onStdout: (text) => { resolve(text); },
                onStderr: (text) => { resolve(text); },
                onError: (err) => { reject(new Error(err)); }
            });
        });
    }
    
    // 方法2: 通用 fetch API
    try {
        const response = await fetch('/exec', {
            method: 'POST',
            body: cmd
        });
        if (!response.ok) {
            throw new Error('HTTP ' + response.status);
        }
        return await response.text();
    } catch (error) {
        throw new Error('Shell exec failed: ' + error.message);
    }
}

// ========== 命令执行与日志输出 ==========
async function exec(cmd) {
    const execMsg = currentLang === 'zh' ? '执行: ' : 'Exec: ';
    appendLog(execMsg + cmd, 'info');
    
    try {
        const output = await shellExec(cmd);
        const lines = output.trim().split('\n');
        lines.forEach(line => {
            const trimmed = line.trim();
            if (!trimmed) return;
            
            if (trimmed.startsWith('✓') || trimmed.startsWith('✅')) {
                appendLog(trimmed, 'success');
            } else if (trimmed.startsWith('✗')) {
                appendLog(trimmed, 'error');
            } else if (trimmed.startsWith('⚠️') || trimmed.startsWith('🔴') || trimmed.startsWith('警告') || trimmed.startsWith('Warning')) {
                appendLog(trimmed, 'warn');
            } else if (trimmed.startsWith('ℹ️') || trimmed.startsWith('🟡') || trimmed.startsWith('🟢') || trimmed.startsWith('🔵')) {
                appendLog(trimmed, 'info');
            } else {
                appendLog(trimmed, '');
            }
        });
        return output;
    } catch (error) {
        const failMsg = currentLang === 'zh' ? '执行失败: ' : 'Failed: ';
        appendLog(failMsg + error.message, 'error');
        throw error;
    }
}

// ========== 操作函数 ==========
function execCmd(cmd) {
    if (operationInProgress) {
        const busyMsg = currentLang === 'zh' ? '当前有操作正在进行，请等待完成' : 'Operation in progress, please wait';
        appendLog(busyMsg, 'warn');
        return;
    }
    
    let confirmMsg = '';
    let cmdToExec = 'sh ' + SCRIPT_PATH + ' ' + cmd;
    
    if (currentLang === 'zh') {
        switch (cmd) {
            case 'safe':
                confirmMsg = '🟢 安全模式: 仅清除 cache 和 code_cache\n不影响账号和手表配对。\n\n确定继续吗？';
                break;
            case 'refresh':
                confirmMsg = '🟡 刷新模式: 清缓存 + 杀掉 unstable 进程\n这是推荐的日常清理方式。\n\n确定继续吗？';
                break;
            case 'experimental':
                confirmMsg = '🔴 探索模式: 清理 files/ 和 no_backup/ 中的非保护文件\n\n⚠️ 此操作有一定风险\n但不会丢失账号和手表配对\n\n确定要继续吗？';
                break;
            case 'backup':
                confirmMsg = '📦 全量备份当前GMS数据\n\n确定继续吗？';
                break;
            case 'snapshot':
                confirmMsg = '📸 创建GMS文件状态快照\n记录当前所有文件的修改时间和大小。\n\n确定继续吗？';
                break;
            case 'diff':
                confirmMsg = '📊 对比最新的两次快照\n发现哪些文件发生了变化。\n\n确定继续吗？';
                break;
            case 'reboot':
                confirmMsg = '🔁 确定要重启设备吗？';
                break;
        }
    } else {
        switch (cmd) {
            case 'safe':
                confirmMsg = '🟢 Safe Mode: Clear cache and code_cache only\nSafe for account and watch pairing.\n\nContinue?';
                break;
            case 'refresh':
                confirmMsg = '🟡 Refresh Mode: Clear cache + kill unstable process\nRecommended daily operation.\n\nContinue?';
                break;
            case 'experimental':
                confirmMsg = '🔴 Experimental: Clean files/ and no_backup/ (filtered)\n⚠️ Higher risk, but won\'t break account or watch.\n\nContinue?';
                break;
            case 'backup':
                confirmMsg = '📦 Full backup of GMS data\n\nContinue?';
                break;
            case 'snapshot':
                confirmMsg = '📸 Create GMS file snapshot\nRecords file modification times and sizes.\n\nContinue?';
                break;
            case 'diff':
                confirmMsg = '📊 Diff the latest two snapshots\nFind which files changed.\n\nContinue?';
                break;
            case 'reboot':
                confirmMsg = '🔁 Reboot device now?';
                break;
        }
    }
    
    if (cmd !== 'list' && confirmMsg && !confirm(confirmMsg)) return;
    
    setButtonsEnabled(false);
    
    if (cmd === 'reboot') {
        const rebootMsg = currentLang === 'zh' ? '设备将在3秒后重启...' : 'Rebooting in 3 seconds...';
        const rebootSent = currentLang === 'zh' ? '重启命令已发送' : 'Reboot command sent';
        const rebootFail = currentLang === 'zh' ? '重启失败，请手动重启' : 'Reboot failed, please restart manually';
        
        appendLog(rebootMsg, 'warn');
        setTimeout(() => {
            exec('reboot')
                .then(() => appendLog(rebootSent, 'info'))
                .catch(() => {
                    appendLog(rebootFail, 'error');
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
    
    document.getElementById('langZh').classList.toggle('active', lang === 'zh');
    document.getElementById('langEn').classList.toggle('active', lang === 'en');
    
    document.querySelectorAll('.lang-zh').forEach(el => {
        el.style.display = lang === 'zh' ? '' : 'none';
    });
    document.querySelectorAll('.lang-en').forEach(el => {
        el.style.display = lang === 'en' ? '' : 'none';
    });
    
    updateClock();
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
    updateClock();
    setInterval(updateClock, 1000);
    
    // Restore language
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
        : 'Use snapshot first, then diff for comparison';
    const kernel = typeof kernelsu !== 'undefined' ? 'KernelSU' : 'WebUI';
    const tip3 = 'API: ' + kernel;
    
    appendLog(readyMsg, 'success');
    appendLog(tip3, 'info');
    appendLog(tip1, 'info');
    appendLog(tip2, 'info');
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}
