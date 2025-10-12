#!/bin/bash

PROXY_BIN="/usr/bin/proxy"
SERVICE_DIR="/etc/systemd/system"
KEY_FILE="$HOME/.proxy_key"

prompt() {
    echo -e "\033[1;33m$1\033[0m"
}

load_key_from_file() {
    if [ -f "$KEY_FILE" ]; then
        cat "$KEY_FILE"
    fi
}

save_key_to_file() {
    local key="$1"
    echo "$key" > "$KEY_FILE"
}

check_key() {
    if [ ! -f "$KEY_FILE" ]; then
        echo -e "\033[1;33mChave não encontrada\033[0m"
        read -rp "$(prompt 'Por favor, insira sua chave: ')" key
        save_key_to_file "$key"
        echo -e "\n\033[1;32mChave salva em $KEY_FILE\033[0m"
    fi
}

is_port_in_use() {
    local port=$1
    nc -z localhost "$port"
}

show_ports_in_use() {
    local ports_in_use=$(systemctl list-units --all --plain --no-legend | grep -oE 'proxy-[0-9]+' | cut -d'-' -f2)
    if [ -n "$ports_in_use" ]; then
        ports_in_use=$(echo "$ports_in_use" | tr '\n' ' ')
        echo -e "\033[1;34m║\033[1;32mEm uso:\033[1;33m $(printf '%-21s' "$ports_in_use")\033[1;34m║\033[0m"
        echo -e "\033[1;34m║═════════════════════════════║\033[0m"
    fi
}

pause_prompt() {
    read -rp "$(prompt 'Enter para continuar...')" voidResponse
}

get_valid_port() {
    while true; do
        read -rp "$(prompt 'Porta: ')" port
        if ! [[ "$port" =~ ^[0-9]+$ ]]; then
            echo -e "\033[1;31mPorta inválida.\033[0m"
        elif [ "$port" -le 0 ] || [ "$port" -gt 65535 ]; then
            echo -e "\033[1;31mPorta fora do intervalo permitido.\033[0m"
        elif is_port_in_use "$port"; then
            echo -e "\033[1;31mPorta em uso.\033[0m"
        else
            break
        fi
    done
    echo "$port"
}

start_proxy() {
    local port=$(get_valid_port)
    local status_value service_name service_file
    local key=$(load_key_from_file)

    read -rp "$(prompt 'Status (--status): ')" status_value

    service_name="proxy-$port"
    service_file="$SERVICE_DIR/$service_name.service"
    cat > "$service_file" <<EOF
[Unit]
Description=DTunnel Proxy Server on port $port

[Service]
ExecStart=$PROXY_BIN --key=$key --port=$port --status=$status_value
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl start "$service_name"
    systemctl enable "$service_name"

    echo -e "\033[1;32mProxy iniciado na porta $port.\033[0m"
    pause_prompt
}

restart_proxy() {
    local port
    read -rp "$(prompt 'Porta: ')" port

    local service_name="proxy-$port"
    if ! systemctl is-active "$service_name" >/dev/null; then
        echo -e "\033[1;31mProxy na porta $port não está ativo.\033[0m"
        pause_prompt
        return
    fi

    systemctl restart "$service_name"

    echo -e "\033[1;32mProxy na porta $port reiniciado.\033[0m"
    pause_prompt
}

stop_proxy() {
    show_ports_in_use

    local port
    read -rp "$(prompt 'Porta: ')" port
    local service_name="proxy-$port"

    systemctl stop "$service_name"
    systemctl disable "$service_name"
    systemctl daemon-reload
    rm "$SERVICE_DIR/$service_name.service"

    echo -e "\033[1;32mProxy na porta $port foi fechado.\033[0m"
    pause_prompt
}

exit_proxy_menu() {
    echo -e "\033[1;31mSaindo...\033[0m"
    exit 0
}

main() {
    clear
    check_key

    echo -e "\033[1;34m╔═════════════════════════════╗\033[0m"
    echo -e "\033[1;34m║\033[1;41m\033[1;32m      DTunnel Proxy Menu     \033[0m\033[1;34m║"
    echo -e "\033[1;34m║═════════════════════════════║\033[0m"

    show_ports_in_use

    local option
    echo -e "\033[1;34m║\033[1;36m[\033[1;32m01\033[1;36m] \033[1;32m• \033[1;31mABRIR PORTA           \033[1;34m║"
    echo -e "\033[1;34m║\033[1;36m[\033[1;32m02\033[1;36m] \033[1;32m• \033[1;31mFECHAR PORTA          \033[1;34m║"
    echo -e "\033[1;34m║\033[1;36m[\033[1;32m03\033[1;36m] \033[1;32m• \033[1;31mREINICIAR PORTA       \033[1;34m║"
    echo -e "\033[1;34m║\033[1;36m[\033[1;32m00\033[1;36m] \033[1;32m• \033[1;31mSAIR                  \033[1;34m║"
    echo -e "\033[1;34m╚═════════════════════════════╝\033[0m"
    read -rp "$(prompt 'Escolha uma opção: ')" option

    case "$option" in
        1) start_proxy ;;
        2) stop_proxy ;;
        3) restart_proxy ;;
        0) exit_proxy_menu ;;
        *) echo -e "\033[1;31mOpção inválida. Tente novamente.\033[0m" ; pause_prompt ;;
    esac

    main
}

main