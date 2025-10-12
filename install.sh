rm -f /usr/bin/main /usr/bin/proxy
curl -s -L -o /usr/bin/main https://github.com/slecth/proxy/raw/refs/heads/main/main.sh
curl -s -L -o /usr/bin/proxy https://github.com/slecth/proxy/raw/refs/heads/main/$(uname -m)/proxy
chmod +x /usr/bin/main /usr/bin/proxy
clear && echo -e "\033[1;31mExecute: \033[1;32mmain\033[0m"