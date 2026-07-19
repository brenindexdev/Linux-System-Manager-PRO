#!/usr/bin/env bash
# ==============================================================================
# PROJETO FINAL - SI103
# TEMA: Linux System Manager PRO
# ==============================================================================

# --- CORES E FORMATACÃO ---
VERMELHO='\033[0;31m'
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
CIANO='\033[0;36m'
MAGENTA='\033[0;35m'
NEGRITO='\033[1m'
NC='\033[0m'

BASE_DIR="$HOME/System Manager"
LOG_DIR="$BASE_DIR/Relatórios"
ARQUIVO_LOG="$LOG_DIR/manager_relatorio.log"

if [[ -e "$BASE_DIR" && ! -d "$BASE_DIR" ]]; then
    echo -e "${VERMELHO}Erro crítico: Existe um arquivo chamado '$BASE_DIR' que impede a criação da pasta principal.${NC}"
    exit 1
fi
mkdir -p "$LOG_DIR"

registrar_log() {
    local acao="$1"
    local data_hora=$(date "+%d/%m/%Y %H:%M:%S")
    echo "[$data_hora] - $acao" >> "$ARQUIVO_LOG"
}

sucesso() { echo -e "${VERDE}[✓] $1${NC}"; sleep 1.5; }
erro() { echo -e "${VERMELHO}[✗] $1${NC}"; sleep 2.5; }
processando() { echo -e "${AMARELO}[...] $1${NC}"; sleep 1; }

# ==============================================================================
# MOTOR DE LEITURA COM CANCELAMENTO E AUTOCOMPLETE (TAB)
# ==============================================================================
ler_input_com_esc() {
    local prompt="$1"
    local var_name="$2"
    local input=""
    local esc_count=0

    echo -ne "$prompt"
    
    while IFS= read -rsn1 char; do
        if [[ "$char" == $'\e' ]]; then
            read -rsn2 -t 0.05 seq 
            if [[ -z "$seq" ]]; then
                ((esc_count++))
                if [[ $esc_count -eq 1 ]]; then
                    echo -ne "\033[s\n\033[K${AMARELO}Pressione [ESC] novamente para cancelar.${NC}\033[u"
                elif [[ $esc_count -eq 2 ]]; then
                    echo -ne "\033[s\n\033[K\033[u\n"
                    eval "$var_name='__CANCELADO__'"
                    return 1
                fi
                continue
            else
                continue 
            fi
        fi

        if [[ $esc_count -ge 1 ]]; then
            esc_count=0
            echo -ne "\033[s\n\033[K\033[u"
        fi

        if [[ "$char" == $'\t' ]]; then
            if [[ -n "$input" ]]; then
                matches=($(compgen -f -- "$input"))
                if [[ ${#matches[@]} -eq 1 ]]; then
                    restante="${matches[0]#$input}"
                    if [[ -d "${matches[0]}" ]]; then restante+="/"; fi
                    input+="$restante"
                    echo -ne "$restante"
                elif [[ ${#matches[@]} -gt 1 ]]; then
                    echo -e "\n${CIANO}Possibilidades: ${matches[*]}${NC}"
                    echo -ne "$prompt$input"
                fi
            fi
            continue
        fi

        if [[ "$char" == $'\x7f' || "$char" == $'\b' ]]; then
            if [[ ${#input} -gt 0 ]]; then
                input="${input%?}"
                echo -ne "\b \b" 
            fi
            continue
        fi

        if [[ -z "$char" ]]; then
            echo ""
            eval "$var_name=\"\$input\""
            return 0
        fi

        input+="$char"
        echo -ne "$char"
    done
}

# ==============================================================================
# MOTOR DO MENU INTERATIVO (SETAS DO TECLADO)
# ==============================================================================
menu_interativo() {
    local titulo="$1"
    shift
    local opcoes=("$@")
    local selecionado=0

    while true; do
        clear
        echo -e "${CIANO}${NEGRITO}==============================================================${NC}"
        echo -e "${NEGRITO}${titulo}${NC}"
        echo -e "${CIANO}${NEGRITO}==============================================================${NC}"
        echo -e "${MAGENTA}Navegue com ↑/↓ | ENTER para selecionar | ESC para voltar${NC}\n"

        for i in "${!opcoes[@]}"; do
            if [[ $i -eq $selecionado ]]; then
                echo -e "${VERDE}${NEGRITO}  ► ${opcoes[$i]}${NC}"
            else
                echo -e "    ${opcoes[$i]}"
            fi
        done

        read -rsn1 key
        case "$key" in
            $'\e')
                read -rsn2 -t 0.1 seq
                if [[ -z "$seq" ]]; then return 255;
                elif [[ "$seq" == "[A" ]]; then
                    ((selecionado--))
                    [[ $selecionado -lt 0 ]] && selecionado=$((${#opcoes[@]} - 1))
                elif [[ "$seq" == "[B" ]]; then
                    ((selecionado++))
                    [[ $selecionado -ge ${#opcoes[@]} ]] && selecionado=0
                fi
                ;;
            "") return $selecionado ;;
        esac
    done
}

# ==============================================================================
# DASHBOARD 1: MONITORAMENTO (TEMPO REAL)
# ==============================================================================
dashboard_monitoramento() {
    registrar_log "Acessou Dashboard de Monitoramento"
    while true; do
        clear
        echo -e "${CIANO}${NEGRITO}=== DASHBOARD DE PERFORMANCE (Atualizando a cada 1s) ===${NC}"
        echo -e "${MAGENTA}Pressione [ESC] para voltar ao menu anterior.${NC}\n"

        echo -e "${VERDE}${NEGRITO}[1] VISÃO GERAL DO HARDWARE/SISTEMA${NC}"
        echo -e "Sistema/Kernel : $(uname -snrvm)"
        echo -e "Uptime/Carga   : $(uptime)"
        
        echo -e "\n${VERDE}${NEGRITO}[2] USO DE MEMÓRIA RAM (Detalhado)${NC}"
        free -h
        
        echo -e "\n${VERDE}${NEGRITO}[3] TOP 10 PROCESSOS MAIS PESADOS (CPU/RAM)${NC}"
        ps aux --sort=-%cpu | head -n 11 | cut -c 1-100
        
        echo -e "\n${VERDE}${NEGRITO}[4] ESTADO DOS DISCOS E PARTIÇÕES${NC}"
        df -h -T --exclude-type=tmpfs --exclude-type=devtmpfs | head -n 5

        echo -e "\n${VERDE}${NEGRITO}[5] SAÚDE DO SISTEMA (Serviços Falhos)${NC}"
        if pidof systemd >/dev/null || [[ -d /run/systemd/system ]]; then
            falhas=$(systemctl --failed --no-legend | wc -l)
            [[ $falhas -eq 0 ]] && echo "Nenhum serviço em falha." || systemctl --failed --no-pager | head -n 3
        else
            echo "Ambiente WSL/Container detectado. (Systemd inativo)."
        fi

        read -t 1 -rsn1 key
        [[ "$key" == $'\e' ]] && break
    done
}

# ==============================================================================
# SUBMENU 2: ARQUIVOS E LIMPEZA
# ==============================================================================
menu_limpeza() {
    local opcoes=(
        "Criar Diretórios"
        "Criar/Editar Arquivos (Vim/Nano)"
        "Deletar Arquivo ou Diretório"
        "Limpar Arquivos Temporários e Lixeira"
        "Buscar os 10 Maiores Arquivos/Diretórios"
        "Voltar"
    )
    while true; do
        menu_interativo "   ARQUIVOS E LIMPEZA DO SISTEMA" "${opcoes[@]}"
        escolha=$?
        [[ $escolha -eq 255 || $escolha -eq 5 ]] && break

        clear
        case $escolha in
            0)
                echo -e "${AMARELO}--- CRIAR DIRETÓRIOS ---${NC}"
                ler_input_com_esc "Nome do diretório: " nome_dir
                if [[ "$nome_dir" == "__CANCELADO__" ]]; then echo -e "${VERMELHO}Operação cancelada.${NC}"; sleep 1; continue; fi
                
                if [[ ! -e "$nome_dir" ]]; then
                    mkdir -p "$nome_dir"
                    sucesso "Diretório '$nome_dir' criado!"
                    registrar_log "Criou diretório: $nome_dir"
                else
                    erro "Já existe um arquivo/pasta com esse nome!"
                fi
                ;;
            1)
                echo -e "${AMARELO}--- CRIAR/EDITAR ARQUIVOS ---${NC}"
                ler_input_com_esc "Nome do arquivo: " nome_arq
                if [[ "$nome_arq" == "__CANCELADO__" ]]; then echo -e "${VERMELHO}Operação cancelada.${NC}"; sleep 1; continue; fi
                
                if command -v vim >/dev/null 2>&1; then
                    vim "$nome_arq"
                    sucesso "Edição de '$nome_arq' concluída!"
                elif command -v nano >/dev/null 2>&1; then
                    echo -e "${VERMELHO}Vim não encontrado! Abrindo com Nano...${NC}"
                    sleep 1.5
                    nano "$nome_arq"
                    sucesso "Edição de '$nome_arq' concluída!"
                else
                    erro "Nenhum editor de texto está instalado."
                fi
                registrar_log "Abriu/Criou arquivo: $nome_arq"
                ;;
            2)
                echo -e "${AMARELO}--- DELETAR ARQUIVO/DIRETÓRIO ---${NC}"
                ler_input_com_esc "Caminho do alvo: " alvo
                if [[ "$alvo" == "__CANCELADO__" ]]; then echo -e "${VERMELHO}Operação cancelada.${NC}"; sleep 1; continue; fi
                
                if [[ -e "$alvo" ]]; then
                    processando "Deletando '$alvo'..."
                    rm -rf "$alvo"
                    sucesso "Excluído permanentemente!"
                    registrar_log "Deletou permanentemente: $alvo"
                else
                    erro "Arquivo ou diretório não encontrado!"
                fi
                ;;
            3)
                echo -e "${AMARELO}--- LIMPANDO TEMPORÁRIOS ---${NC}"
                processando "Esvaziando /tmp e Lixeira do Usuário..."
                rm -rf /tmp/*$USER* 2>/dev/null
                rm -rf ~/.local/share/Trash/files/* 2>/dev/null
                sucesso "Sistema limpo com sucesso!"
                registrar_log "Executou limpeza profunda"
                ;;
            4)
                echo -e "${AMARELO}--- MAIORES ARQUIVOS/DIRETÓRIOS ---${NC}"
                ler_input_com_esc "Digite o diretório alvo (Ex: / para raiz, . para atual): " dir_alvo
                if [[ "$dir_alvo" == "__CANCELADO__" ]]; then echo -e "${VERMELHO}Operação cancelada.${NC}"; sleep 1; continue; fi

                if [[ -d "$dir_alvo" ]]; then
                    processando "Analisando..."
                    echo -e "\n${VERDE}OS 10 MAIORES ITENS EM: $dir_alvo${NC}"
                    du -ah "$dir_alvo" 2>/dev/null | sort -rh | head -n 11
                    registrar_log "Buscou arquivos gigantes em $dir_alvo"
                else
                    erro "Diretório inválido!"
                fi
                echo -e "\n${MAGENTA}Pressione ENTER para voltar.${NC}"; read
                ;;
        esac
    done
}

# ==============================================================================
# MENU PRINCIPAL (LOOP CENTRAL)
# ==============================================================================
opcoes_principais=(
    "Monitoramento e Saúde (Dashboards em Tempo Real)"
    "Arquivos, Limpeza e Controle de Espaço"
    "Segurança e Gerenciamento de Backups"
    "Internet, Testes de Conexão e Redes"
    "Auditoria e Leitura de Relatórios"
    "Sair do PC Manager"
)

registrar_log "--- INICIOU SESSÃO ---"

while true; do
    menu_interativo "   LINUX SYSTEM MANAGER PRO" "${opcoes_principais[@]}"
    escolha_principal=$?
    
    case $escolha_principal in
        0) dashboard_monitoramento ;;
        1) menu_limpeza ;;
        2) menu_seguranca ;;
        3) menu_redes ;;
        4) exibir_relatorios ;;
        5|255)
            clear
            echo -e "${VERDE}Encerrando o Linux System Manager Pro. Até logo, $USER!${NC}\n"
            registrar_log "--- ENCERROU SESSÃO ---"
            exit 0
            ;;
    esac
done