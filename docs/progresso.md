# Progresso da conclusao do projeto

Atualizado em 23/11/2026. Base main/34270c5; alteracoes locais preservadas,
sem commit/push. Este arquivo e o ponto de retomada da implementacao.
Relatorio academico e apresentacao continuam fora desta rodada; o registro
de progresso foi solicitado pelo grupo.

## Onde paramos

**Parte 1: levantamento realizado; requisitos completos ainda pendentes.**
**Parte 2: script preparado; falta executar no ModelSim do laboratorio.**
**Proxima implementacao: parte 3, habilitacao de pausa/passo da CPU.**

Luccas confirmou que Quartus/ModelSim e a DE2-115 ficam em outro computador,
no laboratorio. Nao procurar/instalar novamente essas ferramentas neste
computador ao recuperar o contexto. Nao confundir versao do pacote oficial
com versao observada na instalacao do laboratorio.

| Parte | Entrega | Estado |
| --- | --- | --- |
| 1 | Requisitos, ferramentas e acesso a placa | Levantamento feito; enunciado integral e instalacao do laboratorio nao inspecionados |
| 2 | Regressao no ModelSim | Script preparado; execucao real pendente |
| 3 | Habilitacao global para pausa/passo | Nao iniciada |
| 4 | Reset, sincronizadores, repique e controles | Nao iniciada |
| 5 | Top DE2-115, LEDs e displays | Nao iniciada |
| 6 | QPF/QSF/SDC, fontes, MIF e pinos | Nao iniciada |
| 7 | Testes da interface, pausa e passo | Nao iniciada |
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

`tests/run_modelsim.do` executa 23 simulacoes: 11 testbenches basicos/integrados,
quatro programas e oito cenarios de enderecamento. Usa VHDL-2008, biblioteca
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

Esperado: `PASS: 23 simulacoes; probes de finish/assertion/timeout verificados.`
Guardar a pasta de resultados indicada, especialmente version.log,
compile.log e summary.txt. Se falhar, guardar o log do caso tambem.
Se CPU_MODELSIM_PREPARE_ONLY=1 estiver definido, remover essa variavel:
esse modo apenas prepara arquivos e nao valida o projeto.

## Retomada

1. Ler este arquivo e conferir Git/arquivos reais antes de modificar.
2. Incorporar o resultado do laboratorio quando disponivel; corrigir
   incompatibilidades antes de declarar a parte 2 concluida.
3. Desenvolver a parte 3 com testes: pausa retem FSM, registradores, RAM e
   falha; um pulso de habilitacao avanca um ciclo; reset tem prioridade.
   Nao usar botao como clock nem parar so a FSM deixando a RAM ativa.
4. Atualizar esta tabela e o vault ao concluir cada parte, distinguindo
   implementacao, GHDL, ModelSim, Quartus e placa.
