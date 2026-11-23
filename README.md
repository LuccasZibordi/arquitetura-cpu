# Arquitetura CPU

Componentes de uma CPU de 16 bits em VHDL-2008.

**Ponto de retomada:** [progresso por etapas](docs/progresso.md).
Levantamento inicial feito; runner ModelSim preparado, com execucao real
pendente no laboratorio. Proxima implementacao: habilitacao de pausa/passo.

| Arquivo | Funcao |
| --- | --- |
| register_file.vhd | Banco 8 x 16, R0 fixo zero, duas leituras e uma escrita |
| instruction_register.vhd | Captura habilitada da instrucao de 16 bits |
| pc.vhd | Captura habilitada do proximo endereco, calculado externamente |
| immediate_extender.vhd | Extensao com sinal de 6 para 16 bits |
| alu.vhd | ADD, SUB, AND, OR, SLT signed, Zero e Overflow |
| reg_a.vhd / reg_b.vhd | Captura independente dos operandos |
| alu_out.vhd | Captura do resultado da ULA |
| memory.vhd | RAM síncrona de 1024 palavras de 16 bits, inicializada por MIF |
| memory_address_register.vhd | Registrador de endereço da memória (REM), 10 bits |
| memory_data_register.vhd | Registrador de dados da memória (RDM), 16 bits |
| datapath.vhd | Liga PC, IR, banco, ULA, registradores e RAM; controles entram pela porta |
| decoder.vhd | Traduz o opcode em seletor da ULA, seletores e tipo de instrucao |
| control_unit.vhd | Maquina de estados que gera os sinais de controle do datapath |
| cpu.vhd | Topo que liga controle e datapath, com sinais de observacao |

Todos os registradores usam subida do clock e reset assincrono ativo alto.
O arquivo ula.vhd incompleto foi substituido por alu.vhd (entidade alu).
A CPU completa esta integrada em `cpu.vhd` e documentada em
[docs/cpu.md](docs/cpu.md). A ISA esta em [docs/isa.md](docs/isa.md), o caminho
de dados em [docs/datapath.md](docs/datapath.md), o controle em
[docs/control_unit.md](docs/control_unit.md) e os programas de teste em
[docs/programs.md](docs/programs.md). A validacao e por simulacao, sem
validacao FPGA.

## Testes

Com GHDL no PATH:

```bash
bash tests/run_all.sh
```

Nesta maquina:

```bash
GHDL=/home/luccas/.local/opt/ghdl-6.0.0/ghdl-mcode-6.0.0-ubuntu24.04-x86_64/bin/ghdl bash tests/run_all.sh
```

As treze suítes usam diretorios temporarios e falham ao detectar uma assertion.
Veja [interfaces, operacoes, flags e cobertura](tests/README.md).

## Proxima etapa: DE2-115

A regressao integrada inclui falha de endereco (0000–03FF), repeticao da
demo por reset e verificacao dos caminhos BEQ/BNE. O sinal `address_fault`
para a CPU ate reset e deve ficar visivel na interface da placa.

Antes de considerar a entrega concluida:
- Conferir o enunciado completo e a versao numerica do ModelSim-Altera.
- Criar o top da DE2-115, projeto QPF/QSF e restricoes SDC; selecionar pinos,
  clock, reset sincronizado na liberacao, LEDs/displays e modo de execucao.
- Se houver passo manual, tratar sincronizacao/repique e usar habilitacao
  de clock para avancar toda a CPU, incluindo RAM, de forma consistente.
- Compilar no Quartus, conferir RAM/MIF, recursos e timing, programar e
  repetir a demonstracao na placa. GHDL nao substitui essa verificacao.
- Reunir formas de onda, evidencias da placa e relatorio/apresentacao.

Estado e evidencias desta rodada: [validacao](docs/validation.md).

Ferramentas informadas pelo grupo: **Quartus Prime Lite Edition 20.1** e
**ModelSim-Altera, VHDL**. A distribuicao oficial correspondente e
**ModelSim-Intel FPGA Edition / Starter Edition 2020.1**, pacote **20.1.0.711**.
Esta e a referencia do instalador, ainda nao uma verificacao da instalacao do grupo.
Fonte: [notas oficiais, tabela 5](https://cdrdv2-public.intel.com/704577/rn-qts-std-dev-support-20-1-683593-704577.pdf).
A DE2-115 utiliza a familia **Cyclone IV E**, componente **EP4CE115F29C7N**,
conforme a [especificacao oficial](https://www.altera.com/asap/offering/po-3170/de2-115-fpga-development-and-education-kit).
O codigo EP4CE115F29C7 informado pelo grupo e consistente com essa placa;
a unidade fisica ainda nao foi inspecionada nesta sessao.
O [Quartus Lite 20.1](https://www.altera.com/downloads/fpga-development-tools/quartus-prime-lite-edition-design-software-version-20-1-windows)
oferece o pacote de suporte Cyclone IV; conferir sua instalacao no computador
usado para compilar. A compatibilidade deste projeto ainda depende da compilacao.

Pendências para retomar em outro computador: [roteiro e dependências](docs/pendencias-e-dependencias.md).
