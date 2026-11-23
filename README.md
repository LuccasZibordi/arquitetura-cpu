# Arquitetura CPU

Componentes de uma CPU de 16 bits em VHDL-2008.

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

Todos os registradores usam subida do clock e reset assincrono ativo alto.
O arquivo ula.vhd incompleto foi substituido por alu.vhd (entidade alu).
Ainda nao ha integracao final nem validacao FPGA. A ISA esta em
[docs/isa.md](docs/isa.md), o caminho de dados em [docs/datapath.md](docs/datapath.md)
e a unidade de controle em [docs/control_unit.md](docs/control_unit.md).
A validacao atual e por simulacao
de componentes e do caminho reg_a/reg_b -> ULA -> alu_out, sem validacao FPGA.

## Testes

Com GHDL no PATH:

```bash
bash tests/run_all.sh
```

Nesta maquina:

```bash
GHDL=/home/luccas/.local/opt/ghdl-6.0.0/ghdl-mcode-6.0.0-ubuntu24.04-x86_64/bin/ghdl bash tests/run_all.sh
```

As dez suites usam diretorios temporarios e falham ao detectar uma assertion.
Veja [interfaces, operacoes, flags e cobertura](tests/README.md).
