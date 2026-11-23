# Pendências e dependências para concluir a CPU

Ponto de retomada: 23/11/2026, após a parte 5. Próxima implementação:
parte 6, configuração do projeto Quartus. Este documento complementa
[progresso.md](progresso.md), que contém o histórico e o mapa dos controles.
Não é necessário refazer as partes já implementadas.

## O que precisa de cada ambiente

| Trabalho | Quartus instalado? | Placa conectada? |
| --- | --- | --- |
| Escrever/revisar VHDL, testes, QPF/QSF/SDC | Não; validação dos arquivos Quartus exige a ferramenta depois | Não |
| Simular com GHDL | Não | Não |
| Rodar regressão ModelSim | Precisa do ModelSim instalado; não precisa abrir o Quartus | Não |
| Validar configuração, sintetizar, ajustar posicionamento/roteamento, analisar timing e gerar .sof | Sim, com suporte Cyclone IV | Não |
| Programar a FPGA e observar botões, LEDs, displays e memória real | Programmer e driver USB-Blaster; projeto já compilado | Sim, DE2-115 alimentada e conectada |

Portanto, podemos preparar a parte 6 neste computador. Para concluí-la com
validação real e executar a parte 8, precisamos do computador com Quartus.
A placa só é necessária na parte 9. Sua revisão, dispositivo e posições dos
jumpers precisam ser confirmados para validar as escolhas elétricas antes
da programação; isso pode ser consultado no manual e confirmado depois na unidade.

Referência do fluxo de compilação, que gera arquivos de programação antes
da configuração do dispositivo:
[guia oficial Quartus Standard](https://www.intel.com/programmable/technical-pdfs/683283.pdf).

## Estado confirmado antes da pausa

- CPU integrada, verificação de endereços, programas e testes existentes.
- Parte 3: clock_enable para pausa/passo; reset prioritário.
- Parte 4: reset, sincronizadores, debounce e controles manual/contínuo.
- Parte 5: top_de2_115 com CPU/controles, LEDs e oito displays.
- Última execução: 16 suítes GHDL passaram; síntese GHDL do top passou e
  reconheceu RAM 1024×16. O aviso ram_init_file não suportado permanece:
  isso **não comprova inicialização da RAM no Quartus/FPGA**.
- Runner ModelSim preparado para 34 simulações, incluindo probes de erro e
  timeout. Preparação Tcl verificada; **ModelSim real ainda não executado**.
- QPF/QSF/SDC ainda não criados. Nenhuma compilação Quartus ou teste físico.
- Existem alterações locais e arquivos não rastreados: copiar o diretório
  completo ou registrar as alterações no Git antes de levar ao laboratório.
  Copiar apenas o último commit não transporta toda a implementação atual.

## Pendências e critérios de conclusão

| Parte | O que falta | Dependências | Evidência de conclusão |
| --- | --- | --- | --- |
| 1 | Confrontar com enunciado integral; confirmar ferramentas instaladas e alvo | Enunciado do professor; acesso ao computador do laboratório | Checklist dos requisitos e versões reais registradas |
| 2 | Executar tests/run_modelsim.do e corrigir incompatibilidades | ModelSim com VHDL-2008; fontes e MIF completos | 34 casos e probes aprovados; version.log, compile.log e summary.txt |
| 6 | Criar QPF/QSF/SDC, fontes, top, dispositivo, MIF, pinos e padrões elétricos | Parte 5; manual/pinout DE2-115; Quartus para validar | Projeto abre, arquivos são encontrados e constraints são reconhecidas |
| 7 | Ampliar testes da interface integrada | Top/controles/CPU e GHDL; ModelSim para repetir | Cenários adicionais passam e defeitos encontrados são corrigidos |
| 8 | Compilação completa, inferência de RAM/MIF, recursos, timing e .sof | Parte 6; Quartus Lite 20.1 com Cyclone IV; regressões aprovadas | Relatórios revisados e .sof gerado sem erros bloqueantes |
| 9 | Programação e ensaios físicos | Parte 8; placa, alimentação, cabo/USB-Blaster e driver | Resultados observados na placa e registrados |
| 10 | Reproduzir a entrega em diretório limpo | Fontes/configuração finais, ferramentas e resultados anteriores | Simulação/compilação reproduzíveis; artefato associado à versão testada |

### Parte 6 — configuração a criar

- Projeto e revisão Quartus com top-level `top_de2_115`.
- Família Cyclone IV E e dispositivo alvo EP4CE115F29C7; confirmar unidade.
- Listar somente fontes de síntese, incluindo board_controls/top; excluir
  testbenches. Usar VHDL-2008 e caminhos portáveis.
- Incluir cpu_test.mif e verificar propagação do generic init_file até a RAM.
- Mapear CLOCK_50, KEY, SW, LEDR, LEDG e HEX0–7 com manual/pinout oficial;
  tratar portas não usadas e conferir tensões dos bancos/jumpers.
- SDC para clock de 50 MHz (20 ns), sincronizadores, reset e entradas
  assíncronas. Justificar exceções sem ocultar caminhos internos da CPU.
- Revisar avisos de pinos, clocks e caminhos sem restrições no Quartus.

### Parte 7 — cobertura que ainda merece fechar

Já há testes de integração do top; esta etapa amplia a cobertura, não começa
do zero. Acrescentar cenários de reset durante execução/acessos, alternância
de modo e pressões próximas entre si, pausas em acessos de memória e retorno
após falha. Exercitar Overflow=1 no LED do top. Melhorar a observação de
escritas reais na RAM durante pausa: o teste atual conta o sinal externo,
o que pode não detectar uma escrita interna repetida com valor idêntico.
Repetir a regressão ModelSim após mudanças. Simulação não mede metastabilidade.

### Parte 8 — comprovações específicas do Quartus

Verificar RAM em blocos de memória adequados, conteúdo inicial do MIF,
ausência de latches/clocks derivados inesperados, consumo de recursos e
setup/hold/recovery/removal aplicáveis. Investigar avisos de sincronização,
restrições ignoradas e caminhos sem constraints. Corrigir problemas e
reexecutar testes/compilação conforme necessário. Guardar relatórios do
Compiler/Fitter/Timing Analyzer e o .sof com identificação das fontes usadas.
Não basta o compilador terminar para considerar timing e RAM validados.

### Parte 9 — só aqui a placa é necessária

Confirmar dispositivo/revisão/jumpers, detectar USB-Blaster/JTAG, carregar
.sof e testar: reset, um passo por pressão, botão mantido, modo contínuo,
seleção dos displays, resultado da demo, repetição por reset e sinalização
de falha. Testar programas de aritmética, memória, desvio e overflow conforme
a matriz de validação. Reset não recarrega RAM: programas que alteram código
ou dados precisam considerar isso. Confirmar inicialização após reprogramar.

### Parte 10 — entrega técnica reproduzível

Recompilar em pasta limpa, repetir simulações, conferir inclusão de todos
os MIF/fontes/constraints e registrar versões/comandos. Levar também os logs
de laboratório. O relatório acadêmico e a apresentação permanecem fora do
escopo solicitado; se o enunciado os exigir, continuam pendências da entrega
acadêmica, separadas da conclusão técnica.

## Como retomar no laboratório

1. Levar a pasta completa atualizada e obter o enunciado integral.
2. Confirmar Quartus Prime Lite 20.1 com suporte Cyclone IV. A referência
   esperada do simulador é ModelSim-Intel FPGA/Starter 2020.1; registrar a
   versão instalada, sem confundir com pacote 20.1.0.711.
3. Rodar o script ModelSim conforme [progresso.md](progresso.md#rodar-no-laboratorio).
   Não deixar CPU_MODELSIM_PREPARE_ONLY=1 definido; isso apenas prepara arquivos.
4. Criar/conferir os arquivos da parte 6 e compilar no Quartus. Ainda não há
   nome de projeto Quartus nem comando de compilação pronto neste checkout.
5. Corrigir incompatibilidades e fechar a cobertura da parte 7; repetir
   simulações e compilação quando houver alterações relevantes.
6. Guardar logs, relatórios e .sof. Agendar a placa somente após essa preparação.

Fluxo de dependências: partes 1/2 pendentes podem avançar em paralelo com
6/7; parte 8 depende do projeto Quartus e das correções; parte 9 depende do
.sof validado e da placa; parte 10 consolida a reprodução do conjunto final.
