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