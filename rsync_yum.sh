#!/usr/bin/env bash

# Author: liuchao <liuchao07a@163.com> 

if [ -f /var/log/yum_server.pid ];then
    rm -rf /var/log/yum_server.pid
else
    echo "Ok. Continue rsync yum server."
fi

# 指定yum同步的公网地址
YUM_SIZE="rsync://mirrors.tuna.tsinghua.edu.cn/centos/"

# 指定存放的路径，路径为Apache默认主页目录
LOCAL_PATH="/var/www/html/centos/"

# 指定同步目录，需要哪个同步哪个
LOCAL_VER='6* 7*'

# 带宽的限制
BW_LIMIT=2048

# 指定yum进程文件路径
LOCK_FILE='/var/log/yum_server.pid'

# 指定rsync命令的执行路径，若没有源码编译安装则为空
RSYNC_PATH=''

# 获取yum_server的进程文件，检测是否能够同步，若被占用则无法同步
MY_PID=$$
if [ -f $LOCK_FILE ]; then
    get_pid=`/bin/cat $LOCK_FILE`
    get_system_pid=`/bin/ps -ef|grep -v grep|grep $get_pid|wc -l`
    if [ $get_system_pid -eq 0 ] ; then
        echo $MY_PID>$LOCK_FILE
    else
        echo "Have update yum server now!"
        exit 1
    fi
else
    echo $MY_PID>$LOCK_FILE
fi

# 检测rsync程序及命令是否存在，若不存在则安装
if [ -z $RSYNC_PATH ]; then
    RSYNC_PATH=`/usr/bin/whereis rsync|awk ' ' '{print $2}'`
    if [ -z $RSYNC_PATH ]; then
        echo 'Not find rsync tool.'
        echo 'use comm: yum install -y rsync'
    fi
fi

# 同步及基本检查
for VER in $LOCAL_VER;
do
# 检查指定同步到本地的目录是否存在，若不存在创建（增加程序的健壮性）
    if [ ! -d "$LOCAL_PATH$VER" ] ; then
        echo "Create dir $LOCAL_PATH$VER"
        `/bin/mkdir -p $LOCAL_PATH$VER`
    fi
# 开始同步yum源，但舍弃掉镜像目录
    echo "Start sync $LOCAL_PATH$VER"
    $RSYNC_PATH -avrtH --delete --bwlimit=$BW_limit --exclude "isos" $YUM_SITE$VER $LOCAL_PATH
done

# 清理yum的pid文件
`/bin/rm -f $LOCK_FILE`

# 书写同步日志，方便以后维护及查阅工作是否正常
echo "rsync end $(date +%Y-%m-%d_%k:%M:%S)" >> /var/www/html/centos/centos_rsync_is_end.txt
exit 1