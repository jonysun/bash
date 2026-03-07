#!/bin/bash

# 定义颜色
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
BOLD="\033[1m"
RESET="\033[0m"

echo
echo -e "${BOLD}${BLUE}🌐 请选择要运行的网络延迟测试脚本：${RESET}"
echo
echo -e "${YELLOW}1)${RESET} ${GREEN}Cd1s 的版本${RESET}"
echo -e "${YELLOW}2)${RESET} ${GREEN}danger-dream 的版本${RESET}"
echo
read -p "$(echo -e "${BOLD}📥 请输入选项 (1 或 2): ${RESET}")" choice

case "$choice" in
  1)
    echo -e "${BLUE}🚀 正在运行 Cd1s 的版本...${RESET}"
    bash <(wget -qO- https://raw.githubusercontent.com/Cd1s/network-latency-tester/main/latency.sh)
    ;;
  2)
    echo -e "${BLUE}🚀 正在运行 danger-dream 的版本...${RESET}"
    bash <(wget -qO- https://raw.githubusercontent.com/danger-dream/network-latency-tester/main/latency.sh)
    ;;
  *)
    echo -e "${RED}❌ 无效选项，脚本终止。${RESET}"
    exit 1
    ;;
esac

