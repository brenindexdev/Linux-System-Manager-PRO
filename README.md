# Linux System Manager PRO
> **Projeto Final - SI103 | Automação de Tarefas em Ambiente Linux e Controle de Versões**

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Linux](https://img.shields.io/badge/OS-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Version](https://img.shields.io/badge/Version-1.0.0-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Conclu%C3%ADdo-success?style=for-the-badge)

Uma robusta Interface de Usuário Baseada em Texto (TUI) construída inteiramente em Shell Script (Bash). O sistema atua como um painel centralizado para administração, monitoramento, limpeza, segurança e análise de redes em sistemas operacionais Linux, eliminando a necessidade de interfaces gráficas pesadas ou execução manual de comandos complexos.


---


# Índice
1. [Descrição e Objetivo do Projeto](#descricao)
2. [Apresentação em Vídeo](#video)
3. [Manual de uso](#manual)
4. [Pré-requisitos e Dependências](#pre-requisitos)
5. [Exemplos de execução](#exemplos)
6. [Uso de IA no Projeto](#ia)
7. [Integrantes do Projeto](#integrantes)


---


<a id=”descricao”><a>
# 📝 Descrição e Objetivo do Projeto

O Linux System Manager PRO é uma interface de terminal (TUI - Text-based User Interface) desenvolvida inteiramente em Shell Script (Bash). O objetivo da ferramenta é centralizar, automatizar e facilitar a administração de sistemas Linux. Sem a necessidade de instalar bibliotecas gráficas pesadas, o sistema oferece monitoramento em tempo real, manipulação avançada de arquivos, auditoria de segurança e uma robusta engine de downloads e redes.


---


<a id=”video”><a>
# 🎥 Apresentação em Vídeo

[![Assista ao vídeo de apresentação](https://img.youtube.com/vi/COLOQUE_SEU_LINK_AQUI/0.jpg)](https://www.youtube.com/watch?v=COLOQUE_SEU_LINK_AQUI)
*(Clique na imagem acima para assistir ao vídeo demonstrando o funcionamento do sistema e o processo de automação).*


---


<a id="manual"></a>
# ⚙️ Manual de uso

***MENU INTERATIVO***
- Setas (↑ / ↓): Movem o cursor pelos menus.
- ENTER: Confirma a opção selecionada.
- ESC: Volta para a tela/menu anterior.
- Duplo ESC: Durante qualquer digitação, aperta-se ESC duas vezes para cancelar a operação.
- TAB: Autocompleta nomes de arquivos ou diretórios durante a digitação.
<br>

**1. MONITORAMENTO EM TEMPO REAL** <br>
Este é um dashboard em tempo real. Não é necessário atualizar a página, os dados mudam sozinhos a cada segundo.

- _Visão Geral:_ Exibe o Kernel do Linux e o Uptime (tempo ligado).
  
- _Memória RAM:_ Mostra o consumo exato da RAM do computador, atualizando dinamicamente através do comando free.
  
- _Top 10 Processos:_ Uma lista filtrada (usando ps aux e sort) que mostra os programas que mais estão "sugando" processador no momento.
  
- _Armazenamento:_ Lê as partições de disco e mostra o espaço livre e ocupado.
  
- _Serviços Falhos:_ Verifica se algum módulo vital do systemd quebrou ou falhou ao iniciar.
<br>

**2. ARQUIVOS E LIMPEZA** <br>
Um canivete suíço para gerenciar a máquina sem precisar decorar comandos longos.

- _Criar/Editar:_ Permite criar diretórios e arquivos de texto. O sistema tenta usar o vim; se não encontrar, tenta abrir o nano.
 
- _Limpeza de Temporários:_ Esvazia com segurança a pasta /tmp e a Lixeira do usuário.
 
- _Busca de Gigantes:_ Ao fornecer uma pasta raiz, ele usa o comando du combinado com sort para listar os 10 arquivos ou pastas mais pesados, ajudando a encontrar o que está lotando o HD.
<br>

**3. SEGURANÇA E BACKUP** <br>

- _Dashboard de Logins:_ No topo da tela, sempre visível, mostra os últimos acessos à máquina.
  
- _Procurar Falhas de Permissão:_ Usa o comando find para varrer diretórios inteiros atrás de arquivos com permissão 777 (leitura, escrita e execução para qualquer pessoa do mundo), que são falhas críticas de segurança.
  
- _Criador de Backups:_ Você digita o nome de uma pasta, e o programa cria automaticamente um arquivo .tar.gz compactado com a data e hora no nome, guardando-o de forma organizada dentro do diretório do System Manager.
<br>

**4. INTERNET E REDES** <br>
O módulo mais avançado do sistema, projetado para ser resiliente contra falhas de internet.
Monitor de Rede: Um painel em tempo real que exibe os IPs da máquina, testa conexões de saída e varre serviços que estão com "portas abertas" usando o ss ou netstat.

- _Ping Customizado:_ Testa se sites ou servidores específicos estão no ar.
  
- _Teste de Velocidade:_ Roda o speedtest-cli e aplica filtros de texto avançados (grep e awk) para entregar latência, download e upload limpos na tela.
  
-  _Motor de Download Avançado (Wget & yt-dlp):_
      
     - **Para Arquivos:** Usa o wget disfarçado de Google Chrome (alterando o User-Agent) para furar bloqueios de firewalls. É imune a travamentos por IPv6 inativo e desiste automaticamente após tentar reconectar em servidores mortos.
      
    -  **Para Vídeos (YouTube):** Possui um Instalador Automático. Ao detectar um link do YouTube, ele avisa se as bibliotecas yt-dlp e ffmpeg faltam e as instala para você. O motor foi calibrado para forçar a formatação em .MP4, baixando vídeo em alta qualidade, juntando com o áudio separadamente e entregando um arquivo pronto para reprodução.
<br>

**5. RELATÓRIOS**

- Todas as ações do usuário (acessos, criações, deleções, downloads) são registradas silenciosamente com data e hora.

- A opção 5 do menu lê o arquivo manager_relatorio.log e exibe as últimas 50 ações executadas, permitindo rastrear quem fez o quê no sistema.


---


<a id="pre-requisitos"></a>
# Pré-requisitos

O núcleo do script roda em Bash puro, mas para habilitar 100% das ferramentas do menu de **Redes**, garanta que seu sistema possua os seguintes pacotes:

## Atualize a lista de pacotes
sudo apt update

## Instale as dependências fundamentais
sudo apt install wget 

```bash
# Instale as dependências fundamentais
sudo apt install wget bc speedtest-cli ffmpeg
```


---


<a id="exemplos"></a>
## Exemplos de execução

- Em uma empresa onde os computadores utilizam predominantemente o sistema operacional Linux, muitos funcionários podem não possuir conhecimento técnico suficiente para realizar operações básicas do sistema. Nesse contexto, um programa com interface simples pode automatizar tarefas e facilitar o uso do computador, permitindo que os usuários executem atividades essenciais com segurança, rapidez e menor risco de erros.
  
- Em um laboratório de informática de uma universidade, diversos computadores executam Linux e necessitam de manutenção frequente. Com o Linux System Manager PRO, o técnico responsável consegue monitorar o consumo de CPU, memória e armazenamento, gerenciar permissões de arquivos, realizar diagnósticos da rede e efetuar downloads de atualizações diretamente pela interface TUI, agilizando a administração dos computadores sem depender de ambientes gráficos.


---


<a id="ia"></a>
## 🤖 Uso de GenAI

O desenvolvimento deste projeto contou com o apoio de ferramentas de IA Generativa da seguinte forma:

- Documentação: Foi utilizada IA para a implementação de ícones e estruturação semântica da documentação deste README.md.

- Sintaxe do Código: Utilizada para organizar e refatorar a sintaxe que estava confusa, melhorando a compreensão e visualização do código-fonte, além de auxiliar na adição de comentários para sinalizar a localização de cada menu e submenu.


---


<a id="integrantes"></a>
## 👥 Integrantes

- Breno Silveira Domingues (312320)
- Manuela Castro de Souza (312385)
- Maria Laura Cantareli de Aguiar (312387)
- Murylo Henrique Cardoso da Silva (31299)


---


_O código-fonte deste projeto foi inicialmente desenvolvido, testado e finalizado localmente de forma colaborativa fora do repositório Git. Para cumprir com os requisitos de avaliação da disciplina quanto ao uso prático do Git/GitHub e demonstração do fluxo de trabalho, o histórico de commits foi refeito de forma retroativa, reconstruindo a linha do tempo e a divisão lógica do desenvolvimento modular do sistema._