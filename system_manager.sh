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
# SUBMENU 3: SEGURANÇA E BACKUP
# ==============================================================================
menu_seguranca() {
    local opcoes=(
        "Procurar Falhas de Permissão (777)"
        "Gerar Backup Compactado Organizado"
        "Voltar"
    )
    
    while true; do
        logins_recentes=$(last -a | head -n 5)
        titulo_seg="   SEGURANÇA E BACKUP\n\n${AMARELO}[ HISTÓRICO DE LOGINS RECENTES ]${NC}\n${logins_recentes}\n"
        
        menu_interativo "$titulo_seg" "${opcoes[@]}"
        escolha=$?
        [[ $escolha -eq 255 || $escolha -eq 2 ]] && break

        clear
        case $escolha in
            0)
                echo -e "${AMARELO}--- ARQUIVOS COM PERMISSÃO 777 (RISCO) ---${NC}"
                ler_input_com_esc "Diretório para buscar: " dir_busca
                if [[ "$dir_busca" == "__CANCELADO__" ]]; then echo -e "${VERMELHO}Operação cancelada.${NC}"; sleep 1; continue; fi

                if [[ -d "$dir_busca" ]]; then
                    processando "Buscando vulnerabilidades..."
                    resultado=$(find "$dir_busca" -type f -perm 0777 2>/dev/null)
                    
                    if [[ -z "$resultado" ]]; then
                        sucesso "Excelente! Nenhuma vulnerabilidade (777) encontrada em: $dir_busca"
                    else
                        echo -e "${VERMELHO}Vulnerabilidades Encontradas:${NC}"
                        echo "$resultado"
                    fi
                    registrar_log "Buscou permissões 777 em $dir_busca"
                else
                    erro "Diretório não encontrado!"
                fi
                echo -e "\n${MAGENTA}Pressione ENTER para voltar.${NC}"; read
                ;;
            1)
                echo -e "${AMARELO}--- CRIADOR DE BACKUPS ORGANIZADOS ---${NC}"
                ler_input_com_esc "Diretório que deseja fazer o backup: " origem
                if [[ "$origem" == "__CANCELADO__" ]]; then echo -e "${VERMELHO}Operação cancelada.${NC}"; sleep 1; continue; fi

                if [[ -d "$origem" ]]; then
                    nome_dir=$(basename "$origem")
                    pasta_destino="$BASE_DIR/$nome_dir"
                    
                    mkdir -p "$pasta_destino"
                    processando "Compactando os dados..."
                    
                    nome_backup="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
                    tar -czf "$pasta_destino/$nome_backup" "$origem" 2>/dev/null
                    
                    sucesso "Backup salvo em: $pasta_destino/$nome_backup"
                    registrar_log "Backup criado para $origem"
                else
                    erro "A origem informada não é um diretório válido."
                fi
                ;;
        esac
    done
}

# ==============================================================================
# SUBMENU 4: INTERNET E REDES
# ==============================================================================
menu_redes() {
    local opcoes=(
        "Monitor de Rede (IPs, Portas e Conexão em Tempo Real)"
        "Verificar Conexão Personalizada (Ping)"
        "Teste de Velocidade (Speedtest)"
        "Download de Arquivos (Wget / yt-dlp)"
        "Voltar"
    )

    while true; do
        menu_interativo "   INTERNET E REDES" "${opcoes[@]}"
        escolha=$?
        [[ $escolha -eq 255 || $escolha -eq 4 ]] && break

        clear
        case $escolha in
            0)
                registrar_log "Acessou Dashboard de Redes"
                while true; do
                    clear
                    echo -e "${CIANO}${NEGRITO}=== MONITOR DE REDE (Atualizando a cada 1s) ===${NC}"
                    echo -e "${MAGENTA}Pressione [ESC] para voltar ao menu anterior.${NC}\n"

                    echo -e "${VERDE}${NEGRITO}[1] ENDEREÇOS IP E CONEXÕES ATIVAS${NC}"
                    ip -br a 2>/dev/null || ifconfig 2>/dev/null
                    
                    echo -e "\n${VERDE}${NEGRITO}[2] PORTAS ABERTAS E SERVIÇOS OUVINDO${NC}"
                    saida_ss=$(ss -tulpn 2>/dev/null | grep LISTEN)
                    if [[ -n "$saida_ss" ]]; then
                        echo "$saida_ss" | head -n 10
                    else
                        saida_netstat=$(netstat -tulpn 2>/dev/null | grep LISTEN)
                        if [[ -n "$saida_netstat" ]]; then
                            echo "$saida_netstat" | head -n 10
                        else
                            echo "Nenhuma porta detectada ou ferramentas incompatíveis."
                        fi
                    fi

                    echo -e "\n${VERDE}${NEGRITO}[3] STATUS DE CONECTIVIDADE (Ping 8.8.8.8)${NC}"
                    ping -c 1 -W 1 8.8.8.8 &>/dev/null && echo "Conectado à Internet (OK)" || echo "Sem conexão com a Internet (ERRO)"

                    read -t 1 -rsn1 key
                    [[ "$key" == $'\e' ]] && break
                done
                ;;
            1)
                echo -e "${AMARELO}--- VERIFICAR CONEXÃO (PING) ---${NC}"
                echo -e "${CIANO}================= MANUAL DO PING =================${NC}"
                echo -e "  O Ping testa se um site ou IP está online."
                echo -e "  ${NEGRITO}O que digitar:${NC} Domínios ou IPs puros."
                echo -e "  ${VERDE}Certo:${NC} google.com, 8.8.8.8, unicamp.br"
                echo -e "  ${VERMELHO}Errado:${NC} https://google.com, www.site.com/pasta"
                echo -e "${CIANO}==================================================${NC}\n"
                
                ler_input_com_esc "Informe o servidor a ser testado: " server
                if [[ "$server" == "__CANCELADO__" ]]; then echo -e "${VERMELHO}Operação cancelada.${NC}"; sleep 1; continue; fi
                
                processando "Aguarde, enviando pacotes para $server..."
                if ping -c 2 -w 2 "$server" > /dev/null 2>&1; then
                    sucesso "A internet está funcionando e $server está acessível!"
                else
                    erro "Não está funcionando ou servidor indisponível."
                fi
                registrar_log "Testou ping personalizado para $server"
                echo -e "\n${MAGENTA}Pressione ENTER para voltar.${NC}"; read
                ;;
            2)
                echo -e "${AMARELO}--- TESTE DE VELOCIDADE (SPEEDTEST) ---${NC}"
                if command -v speedtest &> /dev/null || command -v speedtest-cli &> /dev/null; then
                    echo -e "${VERDE}Iniciando teste de conexão (Acompanhe em tempo real abaixo):${NC}\n"
                    if command -v speedtest-cli &> /dev/null; then
                        speedtest-cli --simple
                    else
                        speedtest --accept-license --accept-gdpr
                    fi
                else
                    erro "O pacote 'speedtest' (ou speedtest-cli) não está instalado."
                    echo -e "\n${AMARELO}Dica para instalar no Ubuntu/Debian:${NC}"
                    echo -e "Abra um terminal normal e digite: ${VERDE}sudo apt install speedtest-cli${NC}"
                fi
                registrar_log "Executou Speedtest"
                echo -e "\n${MAGENTA}Pressione ENTER para voltar.${NC}"; read
                ;;
            3)
                echo -e "${AMARELO}--- DOWNLOAD DE ARQUIVOS E VÍDEOS ---${NC}"
                echo -e "${CIANO}================= MANUAL DE DOWNLOAD =================${NC}"
                echo -e "  Baixe qualquer arquivo ou vídeo da internet."
                echo -e "  - Arquivos normais (.pdf, .zip, etc) usam ${VERDE}wget${NC}."
                echo -e "  - Vídeos do YouTube usam ${VERDE}yt-dlp${NC} (com auto-instalador)."
                echo -e "${CIANO}======================================================${NC}\n"

                if ! command -v wget &> /dev/null; then
                    erro "A ferramenta 'wget' não está instalada no seu sistema."
                    echo -e "${AMARELO}Ela é obrigatória para fazer downloads ou instalar módulos.${NC}"
                    echo -e "Abra um terminal e digite: ${VERDE}sudo apt install wget${NC}"
                    echo -e "\n${MAGENTA}Pressione ENTER para voltar.${NC}"; read
                    continue
                fi
                
                ler_input_com_esc "Link do arquivo/vídeo: " link
                if [[ "$link" == "__CANCELADO__" ]]; then echo -e "${VERMELHO}Operação cancelada.${NC}"; sleep 1; continue; fi
                
                # --- AUTO-INSTALADOR DE YOUTUBE (yt-dlp) ---
                if [[ "$link" == *"youtube.com"* || "$link" == *"youtu.be"* ]]; then
                    echo -e "\n${AMARELO}Detectado link do YouTube!${NC}"
                    YTDLP_CMD="yt-dlp"
                    
                    if ! command -v yt-dlp &> /dev/null && [ ! -f "$HOME/.local/bin/yt-dlp" ]; then
                        echo -e "${VERMELHO}A ferramenta de vídeos 'yt-dlp' não está instalada.${NC}"
                        ler_input_com_esc "Deseja instalar o yt-dlp na sua pasta de usuário agora? (S/N): " resp_inst
                        
                        if [[ "${resp_inst,,}" == "s" ]]; then
                            processando "Baixando o yt-dlp oficial do GitHub..."
                            mkdir -p "$HOME/.local/bin"
                            
                            if wget -q --show-progress -O "$HOME/.local/bin/yt-dlp" "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp"; then
                                chmod a+rx "$HOME/.local/bin/yt-dlp"
                                export PATH="$HOME/.local/bin:$PATH"
                                sucesso "Instalado com sucesso!"
                                YTDLP_CMD="$HOME/.local/bin/yt-dlp"
                            else
                                erro "Falha ao baixar o instalador do yt-dlp. Verifique sua conexão."
                                sleep 2; continue
                            fi
                        else
                            echo -e "${VERMELHO}Instalação cancelada. Abortando download.${NC}"
                            sleep 2; continue
                        fi
                    else
                        [[ -f "$HOME/.local/bin/yt-dlp" ]] && YTDLP_CMD="$HOME/.local/bin/yt-dlp"
                    fi

                    if ! command -v ffmpeg &> /dev/null; then
                        echo -e "\n${VERMELHO}[ ATENÇÃO ] - FFmpeg não encontrado!${NC}"
                        echo -e "O YouTube separa os arquivos de áudio e vídeo de alta qualidade."
                        echo -e "Para juntá-los perfeitamente, o yt-dlp precisa do ${NEGRITO}ffmpeg${NC} instalado."
                        echo -e "${AMARELO}Para instalar, abra outro terminal e rode: sudo apt install ffmpeg${NC}\n"
                        sleep 4
                    fi

                    ler_input_com_esc "Caminho de destino (ex: $HOME/Vídeos): " caminho
                    [[ "$caminho" == "__CANCELADO__" ]] && continue
                    mkdir -p "$caminho"

                    processando "Baixando o vídeo... (Aguarde)"
                    
                    # FLAG --recode-video mp4 ADICIONADA: Força o FFmpeg a recodificar o vídeo para tocar em qualquer player!
                    if $YTDLP_CMD -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --merge-output-format mp4 --recode-video mp4 -P "$caminho" "$link"; then
                        sucesso "Vídeo baixado e convertido (MP4 Universal) em $caminho!"
                    else
                        erro "Falha ao baixar o vídeo."
                    fi
                    registrar_log "Baixou vídeo do YouTube em $caminho"
                    echo -e "\n${MAGENTA}Pressione ENTER para voltar.${NC}"; read
                    continue
                fi

                # --- WGET PADRÃO PARA ARQUIVOS ---
                ler_input_com_esc "Caminho de destino (ex: $HOME/Downloads): " caminho
                if [[ "$caminho" == "__CANCELADO__" ]]; then echo -e "${VERMELHO}Operação cancelada.${NC}"; sleep 1; continue; fi
                
                ler_input_com_esc "Nome final do arquivo (Deixe em branco p/ usar original): " nome_custom
                if [[ "$nome_custom" == "__CANCELADO__" ]]; then echo -e "${VERMELHO}Operação cancelada.${NC}"; sleep 1; continue; fi

                processando "Iniciando download... (Isso evitará travamentos na tela)"
                mkdir -p "$caminho"
                USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/114.0.0.0 Safari/537.36"
                
                if [[ -z "$nome_custom" ]]; then
                    if wget -c -4 --tries=3 --timeout=10 --no-check-certificate --user-agent="$USER_AGENT" -P "$caminho" "$link"; then
                        sucesso "Download concluído!"
                    else
                        erro "Falha no download. O servidor recusou (Anti-Bot) ou link inválido."
                    fi
                else
                    if wget -c -4 --tries=3 --timeout=10 --no-check-certificate --user-agent="$USER_AGENT" -O "${caminho}/${nome_custom}" "$link"; then
                        sucesso "Download salvo como '${nome_custom}'!"
                    else
                        erro "Falha no download. O servidor recusou (Anti-Bot) ou link inválido."
                    fi
                fi
                registrar_log "Fez download com wget para $caminho"
                echo -e "\n${MAGENTA}Pressione ENTER para voltar.${NC}"; read
                ;;
        esac
    done
}

# ==============================================================================
# SUBMENU 5: RELATÓRIOS
# ==============================================================================
exibir_relatorios() {
    clear
    echo -e "${CIANO}${NEGRITO}=== RELATÓRIOS DE AUDITORIA ===${NC}\n"
    
    echo -e "${AMARELO}Diretório de Armazenamento:${NC} $LOG_DIR"
    total=$(wc -l < "$ARQUIVO_LOG" 2>/dev/null || echo 0)
    echo -e "${AMARELO}Total de Ações Registradas:${NC} $total\n"

    echo -e "${VERDE}ÚLTIMAS 50 AÇÕES:${NC}"
    echo "--------------------------------------------------------"
    if [[ -f "$ARQUIVO_LOG" ]]; then
        tail -n 50 "$ARQUIVO_LOG"
    else
        echo "Nenhum log registrado até o momento."
    fi
    echo "--------------------------------------------------------"
    
    registrar_log "Visualizou o relatório de auditoria"
    echo -e "\n${MAGENTA}Pressione ENTER para voltar ao Menu Principal.${NC}"; read
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