# Programas completos

Os quatro programas abaixo usam os opcodes reais da ISA — os testes de
formato R/I/J usam opcodes sinteticos e nao executam instrucoes. Cada imagem
de memoria e carregada pela RAM dentro do datapath atraves do generic
`init_file` do `cpu.vhd`.

| Programa | MIF | Instrucoes exercitadas | Resultado esperado |
| --- | --- | --- | --- |
| 1 | `p1_arith.mif` | ADD, SUB, AND, OR, SLT, ADDI negativo, JMP | R1=0007, R2=FFFF, R3=0006, R4=0008, R5=0007, R6=FFFF, R7=0001, PC=0007 |
| 2 | `p2_limit.mif` | limites -32/+31, ADD sem estouro signed, SLT falso | R1=FFE0, R2=001F, R3=FFFF, R4=001F, R5=003E, R6=FFFF, R7=0000, PC=0007 |
| 3 | `p3_mem.mif` | LD, ST, ADD com 7FFF+1, endereco efetivo por imediato | R1=7FFF, R2=0001, R3=8000, R4=8000, Mem[0011]=8000, PC=0005 |
| 4 | `p4_r0_jump.mif` | R0, BEQ/BNE tomados e nao tomados, desvio negativo, JMP, opcode invalido | R1=0003, R2=0003, R0=0000, PC=000D |

O programa 4 confirma R0 pelo resultado de ADD R2,R0,R1. BEQ e BNE
iniciais devem saltar sobre loops de erro (JMP 3 e JMP 5); depois ambos
sao exercitados sem desvio. R2 conta de 3 ate 0 usando BNE com imediato -2.
Um opcode F e ignorado antes do JMP final. O teste confere cada instrucao
visitada, alem do resultado: 0,1,2,4,6,7,8,9,10,9,10,9,10,11,12,13.
Desativar BEQ ou BNE faz a verificacao falhar.

Os valores de PC na tabela sao observados depois do JMP final. Durante a
busca desse JMP, o PC avanca temporariamente uma palavra. Os registradores
sao acompanhados pelas escritas do banco; o programa 3 verifica a memoria
tambem pela releitura em R4. Escritas inesperadas, inclusive de zero, falham.

## Execucao

```bash
GHDL=/caminho/para/ghdl bash tests/run_programs.sh
```

O testbench `tb_program.vhd` e parametrizado pelo generic `program` (1 a 4).
Ele aplica reset, acompanha as escritas no banco e na memoria pelas portas de
observacao e compara o estado final com a tabela acima. Ha limite de 500
ciclos por programa para detectar travamentos.

Para gerar formas de onda:

```bash
VCD_DIR=/tmp/opencode/waves GHDL=/caminho/para/ghdl bash tests/run_programs.sh
```

## Ciclos e latencia da memoria

A RAM registra `data_out` na subida do clock quando `mem_read=1`. Por isso a
palavra lida so fica valida no ciclo seguinte. A busca de instrucao usa dois
estados e qualquer LD usa tres estados apos o calculo do endereco.

Trecho do programa 3 (`LD R1,16(R0)`), valores imediatamente antes de cada
borda de subida. Os seletores e mem_read sao sinais internos do datapath:

| Borda | `state` | `mem_addr_sel` | `mem_addr` | `mem_read` | `fetched` | `rdm` | `reg_write` |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | FETCH0 (0) | 0 | 0000 | 1 | indefinido | 0000 | 0 |
| 2 | FETCH1 (1) | 0 | 0000 | 0 | 6210 | 0000 | 0 |
| 3 | DECODE (2) | 0 | 0001 | 0 | 6210 | 0000 | 0 |
| 4 | ADDR (4) | 0 | 0001 | 0 | 6210 | 0000 | 0 |
| 5 | READ_MEM (5) | 1 | 0010 | 1 | 6210 | 0000 | 0 |
| 6 | LATCH_RDM (6) | 0 | 0001 | 0 | 7FFF | 0000 | 0 |
| 7 | WB (9) | 0 | 0001 | 0 | 7FFF | 7FFF | 1 |

Na borda 5 a RAM recebe o endereco 16 (`0010`); logo apos essa borda,
`fetched` passa a `7FFF`. O RDM captura a palavra na borda 6, e R1 na borda 7.
Em LATCH_RDM o endereco volta ao PC, mas mem_read=0 preserva a saida da RAM. O `ST R3,17(R0)` do mesmo programa usa `WRITE_MEM` (estado 7) com
`mem_write=1`, `mem_addr=0011` e `mem_write_data=8000`.

A forma de onda completa gerada no VCD contem `pc`, `instruction`, `state`,
`mem_write`, `mem_addr`, `mem_write_data`, `fetched`, `rdm`, `reg_write`,
`reg_write_addr` e `reg_write_data`, o que permite conferir tanto a sequencia
de estados quanto a latencia da memoria.
