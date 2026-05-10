#!/system/bin/sh
# 模块服务脚本 - 在模块安装后执行初始化任务

# 创建备份目录
mkdir -p /data/adb/gms_backup

# 设置适当的权限
chmod 755 /data/adb/gms_backup

# 记录模块激活
echo "$(date): GMS Wallet Cache Cleaner module activated" >> /data/adb/gms_backup/module_log.txt