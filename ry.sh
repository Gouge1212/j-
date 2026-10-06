#!/bin/sh
# ./ry.sh start 启动 stop 停止 restart 重启 status 状态
AppName=ruoyi-admin.jar

# 按本机内存自动计算 JVM 堆（可用 JVM_XMX_MB / JVM_XMS_MB 覆盖）
detect_mem_mb() {
    if [ -n "${HOST_TOTAL_MEM_MB:-}" ] && [ "${HOST_TOTAL_MEM_MB}" -gt 0 ] 2>/dev/null; then
        echo "$HOST_TOTAL_MEM_MB"
        return
    fi
    if [ -r /proc/meminfo ]; then
        awk '/MemTotal:/ {printf "%d", $2/1024}' /proc/meminfo
        return
    fi
    if command -v sysctl >/dev/null 2>&1; then
        bytes=$(sysctl -n hw.memsize 2>/dev/null)
        if [ -n "$bytes" ]; then
            echo $((bytes / 1024 / 1024))
            return
        fi
    fi
    echo 2048
}

calc_jvm_heap() {
    total_mb=$1
    if [ "$total_mb" -le 1536 ]; then
        echo "256 512"
    elif [ "$total_mb" -le 2048 ]; then
        echo "384 640"
    elif [ "$total_mb" -le 4096 ]; then
        echo "512 1024"
    elif [ "$total_mb" -le 8192 ]; then
        echo "768 1536"
    else
        echo "1024 2048"
    fi
}

TOTAL_MB=$(detect_mem_mb)
set -- $(calc_jvm_heap "$TOTAL_MB")
JVM_XMS_MB="${JVM_XMS_MB:-$1}"
JVM_XMX_MB="${JVM_XMX_MB:-$2}"

JVM_OPTS="-Dname=$AppName -Duser.timezone=Asia/Shanghai -Xms${JVM_XMS_MB}m -Xmx${JVM_XMX_MB}m -XX:+UseG1GC -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=${JVM_METASPACE_MB:-256}m -XX:+HeapDumpOnOutOfMemoryError"
APP_HOME=`pwd`
LOG_PATH=$APP_HOME/logs/$AppName.log

if [ "$1" = "" ];
then
    echo -e "\033[0;31m 未输入操作名 \033[0m  \033[0;34m {start|stop|restart|status} \033[0m"
    exit 1
fi

if [ "$AppName" = "" ];
then
    echo -e "\033[0;31m 未输入应用名 \033[0m"
    exit 1
fi

function start()
{
    PID=`ps -ef |grep java|grep $AppName|grep -v grep|awk '{print $2}'`

	if [ x"$PID" != x"" ]; then
	    echo "$AppName is running..."
	else
		nohup java $JVM_OPTS -jar $AppName > /dev/null 2>&1 &
		echo "Start $AppName success..."
	fi
}

function stop()
{
    echo "Stop $AppName"

	PID=""
	query(){
		PID=`ps -ef |grep java|grep $AppName|grep -v grep|awk '{print $2}'`
	}

	query
	if [ x"$PID" != x"" ]; then
		kill -TERM $PID
		echo "$AppName (pid:$PID) exiting..."
		while [ x"$PID" != x"" ]
		do
			sleep 1
			query
		done
		echo "$AppName exited."
	else
		echo "$AppName already stopped."
	fi
}

function restart()
{
    stop
    sleep 2
    start
}

function status()
{
    PID=`ps -ef |grep java|grep $AppName|grep -v grep|wc -l`
    if [ $PID != 0 ];then
        echo "$AppName is running..."
    else
        echo "$AppName is not running..."
    fi
}

case $1 in
    start)
    start;;
    stop)
    stop;;
    restart)
    restart;;
    status)
    status;;
    *)

esac
