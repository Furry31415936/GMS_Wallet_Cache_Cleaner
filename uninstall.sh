#!/system/bin/sh
# GMS Wallet Cache Cleaner - 卸载脚本
# 模块卸载时自动清理外部备份目录

# 删除所有备份数据
rm -rf /data/adb/gms_backup

echo "GMS Wallet Cache Cleaner 已卸载"
echo "备份目录已清理: /data/adb/gms_backup"
