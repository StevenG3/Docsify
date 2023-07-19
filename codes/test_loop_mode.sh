#!/bin/bash

# 设置SoC/HOST参数
SOC_A_IP="soc_a_ip"
SOC_A_PW="soc_a_pw"
HOST_A_IP="host_a_ip"
HOST_A_PW="host_a_pw"

SOC_B_IP="soc_b_ip"
SOC_B_PW="soc_b_pw"
HOST_B_IP="host_b_ip"
HOST_B_PW="host_b_pw"

# 设置iperf参数
SERVER_IP="server_ip"
SERVER_PORT="server_port"
TEST_DURATION="iperf_time"

# 测试VF数
num=126

# 性能测试工具
RESULT="iperf"

# 远程执行命令函数
function remote_execute() {
	local host=$1
	local user=$2
	local password=$3
	local command=$4

	sshpass -p "$password" ssh -o StrictHostKeyChecking=no $user@$host "$command"
}

function start_iperf_servers() {
	for i in $(seq 2 $((num + 2))); do
		local command="iperf -sD >/dev/null"
		remote_execute "$HOST_A_IP" root "$HOST_A_PW" "$command"
	done
}

function run_iperf_client() {
	local vfid=$1
	local server=$2
	local command="ip netns exec ns${vfid} iperf -c $server -t $TEST_DURATION -i 2"
	local result=$(remote_execute "$HOST_A_IP" root "$HOST_A_PW" "$command")
	echo "$result" >> "${RESULT}_${vfid}.txt"
}

# 启动iperf服务器端
start_iperf_servers

# 等待服务端启动
sleep 10

# 运行iperf客户端
for ((vfid=2; vfid < num + 2; vfid+=2)); do
	server=$((vfid+1))
	run_iperf_client "$vfid" "$server" &
done

wait