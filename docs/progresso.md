# Progresso da conclusao do projeto

Atualizado em 25/11/2026. Checkout observado main/fd9d217.

## Estado atual — revisão de 25/11/2026

As partes de preparação 2–8 e a reprodução 10 têm implementação/evidências
registradas na atualização de 24/11 abaixo. **Próximo passo: parte 9,
testes físicos na DE2-115.** Conferência do enunciado integral permanece
pendente. As seções de 23/11 são históricas e não descrevem o estado atual.

Nesta revisão: 16 suítes GHDL passaram (37 mensagens PASS); seis hashes
SOF conferidos; 106 pinos conferidos com a referência, sem divergências ou
duplicações. ModelSim/Quartus não foram reexecutados aqui; seus relatórios
recebidos foram inspecionados. Nenhum RTL ou imagem de programação mudou.

Roteiro de bancada ampliado para oito páginas em
`entrega/Roteiro de testes - DE2-115.pdf`, com fonte reproduzível em
`docs/tools/gerar_roteiro_pdf.py`. Pendências atuais:
[pendencias-e-dependencias.md](pendencias-e-dependencias.md).

## Atualização de 24/11/2026

Abrir `cpu_de2_115.qpf` no Quartus Prime Lite 20.1. A parte 6 tem QPF,
QSF com os 106 pinos das portas do top, 17 fontes RTL, MIF da demo e SDC.
O Timing Analyzer pré-Fitter
leu o SDC e reconheceu CLOCK_50 a 50 MHz. A referência de pinagem é o
QSF Terasic fornecido pelo grupo. Conferir revisão e jumpers na placa.

A habilitação explícita de leitura em `memory.vhd` corrigiu a inferência
da RAM. O Fitter confirmou 1024 × 16 bits em dois M9K, com clock único e
`cpu_test.mif` associado. A escrita bloqueia a leitura na mesma borda.
As 34 simulações ModelSim passaram após a correção.

### Parte 7 — interface integrada

O quarto cenário do top usa `tests/top_memory.mif`. Carrega 7FFF,
soma 1, observa o LED de overflow, grava 8000 e provoca falha em JMP 0400.
O teste interrompe leitura e escrita por reset, confere o conteúdo da RAM
após pausa e após escrita autorizada, alterna modo com botão mantido e
verifica dois passos próximos e a retomada após falha. Os 35 casos do
ModelSim passaram. Em cópia temporária, retirar a habilitação interna
de escrita da RAM fez o teste falhar ao reler o dado após a pausa.

### Parte 8 — compilação e timing

Na raiz do projeto, `quartus_sh --flow compile cpu_de2_115` concluiu com
0 erros e 30 avisos no Quartus Prime Lite 20.1.0 Build 711. O Fitter
usou 649 elementos lógicos, 285 registradores, 106 pinos e dois blocos
M9K com a imagem `cpu_test.mif`. Os relatórios ficam em `.build/quartus/`.

Para CLOCK_50 a 50 MHz, as menores folgas entre os três modelos foram
5,009 ns de setup, 0,181 ns de hold, 13,458 ns de recovery, 2,989 ns de
removal e 9,200 ns de largura de pulso. TNS zero em todas as verificações.
O Timing Analyzer confirmou cobertura completa para setup e hold com as
exceções de entradas assíncronas e indicadores previstas no SDC.

O aviso 15714 registra ausência de valores explícitos de corrente e slew
rate para as 83 saídas. O QSF de referência deixa esses parâmetros no
padrão. O aviso 169177 abrange requisitos elétricos de 23 entradas.
Conferir tensões dos bancos e jumpers na placa antes da programação.
O aviso 276027 da RAM refere-se à leitura simultânea à escrita, bloqueada
pelo RTL. O Fitter confirmou clock único.

Imagem desta execução: `.build/quartus/cpu_de2_115.sof`, 3.541.748 bytes.
SHA-256: `46c77bfdbbb0a70d96e11e610f876fd2c4139170d76ab65f4b0d5c05ad140f36`.
A parte 9 começa pela conferência física da DE2-115 e programação por JTAG.

### Parte 9 — lembrete para o laboratório

**Pendente. Executar quando a DE2-115 estiver disponível.** Registrar data,
revisão da placa, hash do SOF e fotos ou vídeo com os valores observados.

- [ ] Conferir dispositivo, tensões e jumpers dos bancos de I/O. Detectar
  o USB-Blaster em JTAG e carregar o SOF da demo pelo Quartus Programmer.
- [ ] Com SW0 em 0, aplicar KEY0. Conferir PC 0000. Cada pressão de KEY1
  deve avançar um ciclo da máquina de estados, inclusive quando mantida.
  Com SW3..1 em 000, após dois passos esperar PC 0001 e instrução 5203.
- [ ] Passar ao contínuo com SW0 em 1 e voltar ao manual. No laço final,
  selecionar RDM (SW3..1 = 100) e conferir 0003 em HEX3..0 e LEDR15..0.
  Selecionar IR (000) e conferir A009. Repetir após reset e reprogramação.
- [ ] Com imagens específicas, comparar aritmética, memória e desvios
  com os resultados de [programs.md](programs.md). Com o MIF de teste
  `tests/top_memory.mif`, observar LEDG5 durante a soma 7FFF + 1 em passo
  manual e LEDR17 após JMP 0400. Conferir parada até reset. Cada imagem
  requer um SOF com o MIF correspondente associado à RAM.

### Parte 10 — reprodução em pasta limpa

Em 24/11/2026, a cópia dos arquivos de trabalho, incluindo as fontes
ainda fora do Git, começou sem banco de compilação, biblioteca ModelSim
ou SOF anterior. As 35 simulações passaram e a compilação completa
terminou com 0 erros e 30 avisos. O resumo de timing coincide com o da
parte 8. O SOF desta compilação tem SHA-256
`f682fdbbc831bcb514359c74663dd3858091bb9b2104146b02ae57fb07f2827f`.
As duas compilações produziram hashes distintos para o SOF.

Na nova pasta, executar `quartus_sh --flow compile cpu_de2_115`.
Para repetir o ModelSim no Windows, definir MODELSIM_BIN com a pasta
dos executáveis e MODELSIM com o caminho absoluto de uma cópia gravável
do modelsim.ini da instalação. Na raiz do projeto em PowerShell:

```powershell
vsim -c -do 'if {[catch {source [file normalize tests/run_modelsim.do]} message]} {puts $message; quit -force -code 1}; quit -force -code 0'
```

Logs, relatórios, SOF e manifesto SHA-256 das entradas usadas estão em
`.build/parte10-cpu-repro-f2cedcfa-539b-4f52-a2ce-158af28da267/`.
Incluir os arquivos novos ao transportar o projeto para o laboratório.

## Histórico de 23/11


**Parte 1: levantamento realizado; requisitos completos ainda pendentes.**
**Parte 2: script preparado; falta executar no ModelSim do laboratorio.**
**Partes 3–5: implementadas e testadas no GHDL. Proxima: parte 6, projeto Quartus/pinos/SDC.**

Luccas confirmou que Quartus/ModelSim e a DE2-115 ficam em outro computador,
no laboratorio. Nao procurar/instalar novamente essas ferramentas neste
computador ao recuperar o contexto. Nao confundir versao do pacote oficial
com versao observada na instalacao do laboratorio.

| Parte | Entrega | Estado |
| --- | --- | --- |
| 1 | Requisitos, ferramentas e acesso a placa | Levantamento feito; enunciado integral e instalacao do laboratorio nao inspecionados |
| 2 | Regressao no ModelSim | Script preparado; execucao real pendente |
| 3 | Habilitacao global para pausa/passo | Implementada; 6 cenarios GHDL passaram; ModelSim pendente |
| 4 | Reset, sincronizadores, repique e controles | Implementada e testada no GHDL; placa pendente |
| 5 | Top DE2-115, LEDs e displays | Implementada; simulacao/sintese GHDL passaram; placa pendente |
| 6 | QPF/QSF/SDC, fontes, MIF e pinos | Nao iniciada |
| 7 | Testes da interface, pausa e passo | Cobertura parcial nas partes 3–5; bateria adicional pendente |
| 8 | Compilacao Quartus, RAM/MIF, recursos e timing | Pendente do projeto da placa e laboratorio |
| 9 | Programacao e testes fisicos | Pendente da placa/USB-Blaster |
| 10 | Reproducao final de compilacao e execucao | Pendente |

## Parte 1 — fatos confirmados

- Quartus Prime Lite 20.1 informado por Luccas.
- Referencia oficial: ModelSim-Intel FPGA/Starter Edition 2020.1, pacote
  20.1.0.711; versao instalada no laboratorio ainda nao observada.
- DE2-115/Cyclone IV E, alvo EP4CE115F29C7; componente de catalogo
  EP4CE115F29C7N. Unidade fisica ainda nao inspecionada.
- Nenhum quartus_sh, vcom, vsim ou jtagconfig encontrado no PATH ou busca
  limitada em home/opt/usr-local/mnt/media. lsusb nao mostrou USB-Blaster.
- PDF de pendencias e ISA local disponiveis; enunciado integral do professor
  nao encontrado. Conformidade final continua condicionada a ele.
- As 13 suites GHDL passaram novamente nesta rodada.

## Parte 2 — entrega e verificacao

`tests/run_modelsim.do` executa 34 simulacoes: 11 testbenches basicos/integrados,
quatro programas, oito cenarios de enderecamento, seis de pausa/passo, dois de controles e tres do top. Usa VHDL-2008, biblioteca
work isolada e MIF preparados no diretorio de execucao. Logs ficam em
`.build/modelsim-.../`, ignorado pelo Git.

Tres probes verificam o runner: finish normal deve retornar sucesso;
assertion intencional e timeout devem retornar erro. Cada teste tem limite
de 100 us. `summary.txt` so e criado quando todos passam. Falhas interrompem
a regressao e preservam os logs.

Verificado localmente:
- Preparacao executada em Tcl 8.6.16, sem ModelSim.
- Manifesto/MIF produzidos pelo Tcl: 23 simulacoes GHDL passaram.
- Ferramenta ausente causa erro, sem resumo falso de sucesso.
- Execucao preserva stderr e propaga codigo de saida diferente de zero.
- Revisao independente estatica sem problemas concretos apontados.

Tcl foi extraido em pasta temporaria, sem instalacao no sistema. Nao e uma
dependencia adicional para quem executa o script dentro do ModelSim.
**Pendentes:** vcom/vsim e probes reais, Windows, bibliotecas Intel e NativeLink.
Preparacao Tcl e simulacao GHDL nao comprovam execucao ModelSim.

## Rodar no laboratorio

Copiar o projeto inteiro, incluindo arquivos ainda nao commitados e os MIF.
Abrir uma sessao nova do ModelSim. No Transcript, ajustar o caminho e executar:

```tcl
do {C:/caminho/arquitetura-cpu/tests/run_modelsim.do}
```

Se os executaveis nao forem encontrados, informar a pasta que contem vlib,
vmap, vcom e vsim. Exemplo de caminho (ajustar conforme a instalacao):

```tcl
set env(MODELSIM_BIN) {C:/intelFPGA_lite/20.1/modelsim_ase/win32aloem}
do {C:/caminho/arquitetura-cpu/tests/run_modelsim.do}
```

Para automacao em terminal, na raiz do projeto com vsim no PATH:

```text
vsim -c -do "onerror {quit -force -code 1}; do tests/run_modelsim.do; quit -force -code 0"
```

Esperado: `PASS: 34 simulacoes; probes de finish/assertion/timeout verificados.`
Guardar a pasta de resultados indicada, especialmente version.log,
compile.log e summary.txt. Se falhar, guardar o log do caso tambem.
Se CPU_MODELSIM_PREPARE_ONLY=1 estiver definido, remover essa variavel:
esse modo apenas prepara arquivos e nao valida o projeto.

## Retomada

1. Ler este arquivo e conferir Git/arquivos reais antes de modificar.
2. Incorporar o resultado do laboratorio quando disponivel; corrigir
   incompatibilidades antes de declarar a parte 2 concluida.
3. Desenvolver a parte 6: QPF/QSF/SDC, dispositivo, clock, fontes, MIF
   e pinos do top. Conferir pinout e tensoes no manual da DE2-115.
   Nao declarar timing/MIF/compilacao Quartus aprovados sem executar.
4. Atualizar esta tabela e o vault ao concluir cada parte, distinguindo
   implementacao, GHDL, ModelSim, Quartus e placa.

## Parte 3 — pausa e passo (23/11/2026)

Entrada `clock_enable` adicionada ao final das portas de cpu, control_unit
e datapath, com padrao '1' para preservar as instanciacoes existentes.
Com '0', FSM, registradores, leitura/escrita da RAM e captura de falha ficam
retidos. Reset assincrono tem prioridade; nao recarrega a RAM. Sinais de
observacao reg_write/mem_write ficam zerados durante pausa/reset.
A entrada deve ser sincrona a clk. Um pulso habilita um ciclo da FSM,
nao uma instrucao completa. O clock permanece unico e continuo.

Validacao: 14 suites GHDL passaram. O novo tb_cpu_enable compara 100 ciclos
continuos com 100 passos separados por pausas de 1–3 clocks, nos cinco
programas e em LD invalido. Confere retencao, escritas, falha, reset pausado
e retomada. Quatro mutacoes (FSM sem enable, datapath sem enable, falha
sem enable e monitor de escrita ativo na pausa) foram rejeitadas.
Sintese GHDL passou, reconhecendo RAM 1024x16; o aviso ram_init_file permanece,
portanto nao comprova MIF no Quartus. Runner ModelSim ampliado para 29 casos;
execucao real continua pendente no laboratorio.

Revisao independente: sem bloqueios; seis casos reproduzidos. Limite de
cobertura: a contagem de stores observa mem_write externo, nao diretamente
o enable interno da RAM; escritas repetidas identicas poderiam escapar
se esse gate interno fosse alterado isoladamente. Gate atual revisado.

## Parte 4 — controles (23/11/2026)

Um unico modulo novo: `board_controls.vhd`. Entradas reset_n/step_n ativas
em zero e run_async ativo em um; saidas cpu_reset, clock_enable e running.
Reset assertivo assincrono, liberacao em duas bordas. Passo e modo usam
dois flip-flops de sincronizacao e filtro de amostras consecutivas.
`debounce_cycles=500000` por padrao: 10 ms se clock=50 MHz. Ajustar se o
clock do top mudar. O tempo de resposta inclui sincronizacao e filtro.

Manual: uma pressao gera um pulso de clock_enable (um ciclo da FSM).
Segurar nao repete. Botao mantido durante reset ou ao voltar do continuo
precisa ser solto antes de outro passo. Continuo: clock_enable permanece
alto, executando na velocidade do clock original. Nao ha clock derivado.
A troca de modo tambem e filtrada, portanto parar tem a latencia do filtro.
Reset bloqueia imediatamente e limpa os controles; um repique de reset
reafirma reset. Sua liberacao e sincronizada, nao filtrada por 10 ms.

Validacao local: 15 suites GHDL passaram; testes dos controles com filtro
1 e 4 cobrem repiques de pressao/soltura/modo, limiar, pressao mantida,
reset entre bordas, retorno ao manual e retomada. Tres mutacoes rejeitadas
(reset direto, filtro removido, repeticao por nivel). Sintese GHDL aprovada
com generic 1, 4 e 500000. Preparacao Tcl passou; runner ModelSim agora31
simulacoes, sem execucao real. Simulacao digital nao prova metastabilidade,
timing ou funcionamento eletrico. Integracao CPU/top fica nas partes5/7;
pinos e restricoes de timing na parte6, validacao fisica no laboratorio.

Revisao independente encontrou perda de passo quando um repique de modo
coincidia com a pressao valida. Corrigido para arbitrar pelo modo filtrado;
regressao nova falhou antes e passou depois. As 15 suites e a sintese nos
tres valores de generic passaram novamente apos a correcao.

## Parte 5 — top e observacao (23/11/2026)

`top_de2_115.vhd` integra CPU e board_controls em CLOCK_50 unico. Generics
init_file="cpu_test.mif" e debounce_cycles=500000. Nenhum QSF/pino ainda.

| Controle/saida | Funcao |
| --- | --- |
| KEY0 | Reset ativo baixo |
| KEY1 | Um ciclo por pressao no manual |
| SW0 | 0 manual, 1 continuo (velocidade do clock) |
| SW3..1 | Selecao 0 IR, 1 A, 2 B, 3 ALUOut, 4 RDM, 5 fetched, 6 writeback, 7 endereco RAM |
| HEX7..4 | PC de16 bits, HEX7 digito mais significativo |
| HEX3..0 | Valor selecionado, HEX0 digito menos significativo |
| LEDR15..0 | Valor selecionado em binario |
| LEDR16 /17 | Reset /falha de endereco |
| LEDG3..0 | Estado da FSM |
| LEDG4 /5 /6 | Zero /Overflow /modo continuo |
| LEDG7 /8 | Habilitacoes instantaneas reg_write /mem_write |

KEY2/3 e SW17..4 nao usados. HEX ativo baixo, ordem gfedcba. Seletor passa
por2FF e afeta apenas observacao; mudanca multibit pode mostrar valor
intermediario brevemente. Flags sao combinacionais, nao flags historicas.
LEDs7/8 sao pulsos curtos, sem alongamento; nao esperar leitura visual no
modo rapido. `running` indica modo continuo, mesmo quando CPU para por fault.
Para inspecao estavel, voltar ao manual e aguardar o filtro.

Validacao:16 suites GHDL passaram. Tres simulacoes do top: demo com passos,
pausa/continuo, seletores, LEDs e reset; JMP0400 com fault/reset;16 digitos
hexadecimais. Revisao sem defeitos de RTL; cobertura ampliada para diferenciar
A/B, IR/fetched, ALUOut/writeback, latencia2FF, modo e pulsos de escrita.
Overflow=1 no LED ainda nao exercitado no top (ULA coberta separadamente).
Sintese GHDL do top passou, RAM1024x16 inferida; aviso ram_init_file permanece.
Tcl preparou os MIF/manifesto; runner ModelSim agora34 casos, execucao real
pendente. Integracao fisica, pinos, timing e inicializacao RAM na FPGA nao
validados. Parte7 ainda requer bateria adicional da interface completa.

Referencia: manual Terasic DE2-115, secoes4.3–4.5:
https://www.terasic.com.tw/attachment/archive/502/DE2_115_User_manual.pdf
