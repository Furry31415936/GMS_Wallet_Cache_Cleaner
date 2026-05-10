let logElement = document.getElementById('log');

function log(msg) {
    const timestamp = new Date().toLocaleTimeString();
    logElement.innerHTML += `[${timestamp}] ${msg}\n`;
    // 自动滚动到底部
    logElement.scrollTop = logElement.scrollHeight;
}

function exec(cmd, successMsg, errorMsg) {
    log(`执行命令: ${cmd}`);
    
    // 模拟执行（实际部署时会被替换为真实的执行接口）
    fetch('/exec', { 
        method: 'POST', 
        headers: {
            'Content-Type': 'text/plain',
        },
        body: cmd 
    })
    .then(response => {
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.text();
    })
    .then(text => {
        log(successMsg || '命令执行成功');
        log(`输出: ${text}`);
    })
    .catch(error => {
        log(errorMsg || `命令执行失败: ${error.message}`);
        console.error('执行错误:', error);
    });
}

function backup() {
    if(confirm('确定要备份当前GMS数据吗？这将创建一个带有时间戳的备份。')) {
        // 在实际环境中，这将调用真实的后端接口
        log('开始备份GMS数据...');
        exec(
            'sh /data/adb/modules/gms_wallet_cache_cleaner/clear.sh backup',
            'GMS数据备份完成',
            'GMS数据备份失败'
        );
    }
}

function clearCache() {
    if(confirm('确定要清除GMS和Wallet的缓存吗？这不会清除登录数据。')) {
        log('开始清除缓存...');
        exec(
            'sh /data/adb/modules/gms_wallet_cache_cleaner/clear.sh cache',
            '缓存清除完成，请重启设备使更改生效',
            '缓存清除失败'
        );
    }
}

function clearDataSelective() {
    if(confirm('⚠️ 警告：这将清除部分数据，可能会导致需要重新登录部分服务！确定继续吗？')) {
        log('开始选择性清除数据...');
        exec(
            'sh /data/adb/modules/gms_wallet_cache_cleaner/clear.sh data',
            '选择性数据清除完成，请重启设备使更改生效',
            '选择性数据清除失败'
        );
    }
}

function restore() {
    if(confirm('确定要从最新的备份恢复数据吗？这将覆盖当前的所有GMS数据。')) {
        log('开始从备份恢复...');
        exec(
            'sh /data/adb/modules/gms_wallet_cache_cleaner/clear.sh restore',
            '数据恢复完成，请重启设备使更改生效',
            '数据恢复失败'
        );
    }
}

function reboot() {
    if(confirm('确定要重启设备吗？请确保已保存所有工作。')) {
        log('设备将在3秒后重启...');
        setTimeout(() => {
            exec(
                'reboot',
                '设备正在重启...',
                '重启命令发送失败'
            );
        }, 3000);
    }
}

// 更新时间显示
setInterval(() => {
    document.getElementById('time').innerText = new Date().toLocaleString();
}, 1000);

// 页面加载完成后显示欢迎信息
window.onload = function() {
    log('GMS缓存清理器已就绪');
    log('请选择要执行的操作');
};