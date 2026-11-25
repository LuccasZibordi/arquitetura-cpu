# Arquitetura CPU

Componentes de uma CPU de 16 bits em VHDL-2008.

**Ponto de retomada:** [progresso por etapas](docs/progresso.md).
O [guia da entrega](entrega/LEIA-ME.md) reúne os comandos de reprodução,
as imagens de programação e o [roteiro de testes na placa](entrega/Roteiro%20de%20testes%20-%20DE2-115.pdf).
**Lembrete de laboratório:** testar a demo na DE2-115. Os controles, os resultados esperados e o espaço para registrar a evidência estão no [roteiro da placa](docs/progresso.md#parte-9--lembrete-para-o-laboratório).

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
[docs/programs.md](docs/programs.md). Há validação por simulação e relatórios de compilação/timing Quartus.
A validação física na FPGA permanece pendente.

## Testes

Com GHDL no PATH:

```bash
bash tests/run_all.sh
```

O Quartus Prime Lite 20.1 e o ModelSim Starter 2020.1 foram verificados no Windows.
Para compilar, abrir `cpu_de2_115.qpf` ou executar na raiz do projeto:

~~~text
quartus_sh --flow compile cpu_de2_115
~~~

O arquivo de programação é `.build/quartus/cpu_de2_115.sof`.
A regressão ModelSim, a reprodução em pasta limpa e os testes físicos pendentes
estão no [registro de progresso](docs/progresso.md).
