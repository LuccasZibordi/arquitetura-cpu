# Testes VHDL

## Banco de registradores

Com GHDL no PATH:

```bash
bash tests/run_register_file.sh
```

Nesta maquina, a copia local do simulador pode ser usada assim:

```bash
GHDL=/home/luccas/.local/opt/ghdl-6.0.0/ghdl-mcode-6.0.0-ubuntu24.04-x86_64/bin/ghdl bash tests/run_register_file.sh
```

O script usa VHDL-2008 e uma pasta temporaria, removida ao terminar.
Qualquer assertion com falha retorna codigo diferente de zero.

`register_file` oferece oito registradores de 16 bits, enderecados de
`000` (R0) a `111` (R7). R0 sempre retorna zero e ignora escritas.
R1 a R7 devem receber reset antes do uso: nao ha inicializacao implicita.

- Duas leituras combinacionais independentes (`read_addr1/2`, `read_data1/2`).
- Uma escrita na subida de `clk`, habilitada por `reg_write`.
- `reset` assincrono ativo em `1`, prioritario sobre a escrita.
- Ao ler e escrever o mesmo registrador, a leitura passa a refletir o novo
  valor depois da borda de subida e da propagacao combinacional.
- Enderecos com bits invalidos (X/U/Z) retornam zero, sem indexar fora do
  intervalo 1..7.

O testbench verifica os sete registradores gravaveis, as 64 combinacoes de
leitura, leitura simultanea do mesmo registrador, escrita desabilitada,
protecao de R0, ausencia de escrita fora da subida e reset com prioridade.

Este teste valida o banco isolado. Os testes de formatos estao descritos abaixo.
Os demais modulos nao sao compilados por este script.

## Registrador de instrucao

```bash
bash tests/run_instruction_register.sh
```

Se necessario, use a mesma variavel `GHDL` mostrada acima.
O modulo `instruction_register` armazena uma palavra completa de 16 bits:

- `instruction_in`: instrucao a capturar; `instruction_out`: instrucao atual.
- `ir_write = '1'`: captura na borda de subida de `clk`.
- `ir_write = '0'`: preserva a instrucao, mesmo que a entrada varie.
- `reset = '1'`: zera a instrucao de forma assincrona e prioritaria.
- Aplicar reset antes do uso; nao ha inicializacao implicita.

O testbench verifica captura, retencao por varios ciclos, ausencia de captura
na descida ou ao habilitar escrita com clock alto, preservacao dos 16 bits,
reset sem clock e com escrita desabilitada, prioridade e recuperacao do reset.
Os padroes usados sao palavras de teste, nao codificacoes de formatos da ISA.
Este modulo armazena a instrucao sem interpretar opcode ou campos.

## Contador de programa (PC)

```bash
bash tests/run_pc.sh
```

Se necessario, use a mesma variavel `GHDL` mostrada acima.
As portas existentes de `PC` foram preservadas:

- `next_pc`: endereco de 16 bits calculado pelo datapath.
- `pc_out`: endereco atual, carregado na subida de `clk` se `pc_write = '1'`.
- `pc_write = '0'`: mantem o endereco por quantos ciclos forem necessarios.
- `reset = '1'`: zera o PC imediatamente, independentemente do clock e da escrita.
- Aplicar reset antes do uso; nao ha inicializacao implicita.

O incremento sequencial e o calculo de destinos de saltos ficam fora deste
modulo. O PC apenas carrega `next_pc`, sem adicionar 1 ou 2 ao endereco.

O testbench verifica carga, retencao, enderecos sequenciais fornecidos pela
entrada, destinos maiores/menores, limites 0000/FFFF, preservacao dos bits,
ausencia de incremento interno, bordas do clock, reset prioritario e retomada.
Esses testes validam o PC isolado. A regra de calculo do destino J nao foi
fornecida; nao se assume extensao, deslocamento ou concatenacao com o PC.

## Extensor de imediato

```bash
bash tests/run_immediate_extender.sh
```

Se necessario, use a mesma variavel `GHDL` mostrada acima.
`immediate_extender` recebe `immediate_in` de 6 bits e produz `immediate_out`
de 16 bits, preservando o valor em complemento de dois (-32 a 31).
Os seis bits originais sao mantidos; os dez superiores repetem o bit 5.
E combinacional, sem clock, habilitacao ou reset.

Exemplos: `011111` vira `001F` (31), `100000` vira `FFE0` (-32) e
`111111` vira `FFFF` (-1), com as saidas escritas em hexadecimal.
O teste cobre todas as 64 entradas binarias, os limites e transicoes de sinal.
Isso valida a extensao isolada. No formato I, o imediato ocupa os bits 5..0.

## Formatos de instrucao

Layout transcrito da imagem fornecida por Luccas em 18/11/2026, lendo os
campos da esquerda (bit mais significativo) para a direita:

| Formato | 15..12 | 11..9 | 8..6 | 5..3 | 2..0 |
| --- | --- | --- | --- | --- | --- |
| R | Opcode | Ri | Rj | Rk | Nao usado |
| I | Opcode | Ri | Rj | Imediato de 6 bits (5..0) | continuacao |
| J | Opcode | Endereco de 12 bits (11..0) | continuacao | continuacao | continuacao |

```bash
bash tests/run_instruction_formats.sh
```

O testbench conecta instruction_register ao immediate_extender e verifica:

- R: palavra A770, campos distintos Ri=3/Rj=5/Rk=6 e preservacao dos bits nao usados.
- I: palavras B5E1/B5C0/B5DF/B5E0/B5FF, Ri=2/Rj=7 e imediatos -31/0/31/-32/-1.
- J: palavras CABC/C000/CFFF, preservando o endereco bruto de 12 bits.
- Retencao dos tres formatos quando ir_write=0, inclusive a saida do extensor.

A, B e C sao opcodes sinteticos para testar preservacao de bits; nao sao
atribuicoes de operacoes reais. Estes testes verificam armazenamento,
campos e extensao de sinal, sem implementar um decodificador ou executar
instrucoes. A imagem nao especifica operacoes, papeis de origem/destino dos
registradores nem como o endereco J gera o proximo PC.

## Caminho de dados

```bash
GHDL=/caminho/para/ghdl bash tests/run_datapath.sh
```

`tb_datapath.vhd` usa `datapath_test.mif`, copiado para um diretorio
temporario como nos outros testes. O banco de registradores comeca zerado e o
testbench dirige os sinais de controle borda a borda, sem unidade de controle.

A sequencia verifica a busca em duas bordas (a RAM so entrega a palavra no
ciclo seguinte), a captura de Rj e Rk/Ri em reg_a/reg_b, o calculo da ULA com
o operando B vindo do imediato ou do banco, a gravacao e a releitura da RAM,
o retorno de alu_out ou RDM ao banco, um BEQ nao tomado, um BEQ tomado, um JMP
e a preservacao do PC diante de um opcode invalido. O teste tambem confirma que
o REM captura a saida combinacional da ULA, e nao o alu_out antigo.

## Unidade de controle

```bash
GHDL=/caminho/para/ghdl bash tests/run_control_unit.sh
```

`tb_control_unit.vhd` testa `decoder.vhd` e `control_unit.vhd` isolados: dirige
`opcode` e `zero`, e confere `state_out` e os 14 sinais de controle em cada
estado. A sequencia cobre ADD/SUB/AND/OR/SLT, ADDI, LD, ST, BEQ e BNE tomados
e nao tomados, JMP, opcode invalido, reset no meio da sequencia e a ausencia
de `reg_write`/`mem_write` onde nao deve haver escrita. O codigo dos estados
esta em [docs/control_unit.md](../docs/control_unit.md).

## CPU integrada

```bash
GHDL=/caminho/para/ghdl bash tests/run_cpu.sh
```

`tb_cpu.vhd` instancia `cpu.vhd` com `cpu_test.mif` e roda o programa da ISA
desde o reset. Acompanha as escritas pelas portas de observacao e verifica o
estado final: PC = 0008, R3 = 0003, Mem[0] = 0003 e o JMP final no IR. A
interface completa e a lista de arquivos estao em
[docs/cpu.md](../docs/cpu.md).

## Executar todas as suites

```bash
GHDL=/home/luccas/.local/opt/ghdl-6.0.0/ghdl-mcode-6.0.0-ubuntu24.04-x86_64/bin/ghdl bash tests/run_all.sh
```

Com GHDL no PATH, basta `bash tests/run_all.sh`. São onze suítes, incluindo banco, registrador de instrução, PC, extensor,
formatos, ULA, registradores da ULA e memória.


## ULA (alu.vhd)

`alu.vhd` substitui o antigo `ula.vhd` incompleto; a entidade agora e `alu`.
Interface: entradas `A`, `B` (16 bits), `Op` (3 bits); saidas `S` (16 bits),
`Zero` e `Overflow` (1 bit cada). Circuito combinacional, sem clock/reset.

| Op | Operacao | Resultado |
| --- | --- | --- |
| 000 | ADD | A + B, 16 bits inferiores |
| 001 | SUB | A - B, 16 bits inferiores |
| 010 | AND | A and B |
| 011 | OR | A or B |
| 100 | SLT | 0001 se signed(A) < signed(B), senao 0000 |
| 101/110/111 | Nao utilizado | 0000 |

Esses seletores sao controles internos, nao opcodes da ISA. ADDI e calculos
aritmeticos de enderecos podem usar ADD, com operandos selecionados externamente.
A ULA nao acessa memoria nem decodifica instrucoes.

`Zero=1` se e somente se S=0000, inclusive SLT falso e seletores nao usados.
`Overflow` sinaliza estouro **com sinal** em ADD/SUB; nas demais operacoes e 0.
O resultado nao satura: 7FFF+0001=8000 com Overflow=1; FFFF+0001=0000 com
Overflow=0 (carry nao e overflow signed). 8000+8000=0000 ativa ambas as flags.
SLT compara diretamente os operandos com sinal, sem depender do sinal da subtracao.
Entradas devem ter bits binarios validos; X/U/Z nao representam operandos suportados.

```bash
bash tests/run_alu.sh
```

`tb_alu.vhd` verifica 266 vetores: casos explicitos das cinco operacoes,
mascaras, Zero, overflow positivo/negativo, carry sem overflow e seletores
nao usados. Um oraculo inteiro independente verifica ADD/SUB/SLT para 81
pares de valores, incluindo os extremos -32768/32767, negativos e igualdade.
Tambem verifica limpeza de Overflow apos mudanca de operacao.

## Registradores de operandos e resultado

`reg_a`, `reg_b` e `alu_out` oferecem a mesma interface:

- `clk`, `reset`, `write_enable`: entradas de 1 bit.
- `data_in`, `data_out`: entrada/saida de 16 bits.
- Reset assincrono ativo alto, prioritario, zerando a saida.
- Captura na subida com write_enable=1; retencao caso contrario.
- Aplicar reset antes do uso; nao ha inicializacao implicita.

Cada instancia tem sua propria habilitacao. Conectar reg_a/reg_b a A/B da ULA
e S a data_in de alu_out. Zero/Overflow sao combinacionais e **nao** ficam
armazenados em alu_out: se forem necessarios depois, o controle deve prever
sua captura separadamente.

Se os tres registradores forem habilitados na mesma borda, alu_out captura o
resultado dos operandos anteriores. Para obter o resultado dos novos operandos,
capturar A/B em uma borda e o resultado em uma borda posterior. Operacao e
operandos precisam estar estaveis antes da captura do resultado.

```bash
bash tests/run_alu_registers.sh
```

`tb_alu_registers.vhd` conecta os quatro modulos reais e cobre habilitacoes
independentes, retencao, preservacao de bits, subida/descida, habilitacao com
clock alto, reset sem escrita/clock, prioridade/recuperacao de reset e ciclos
de captura do resultado. Esses testes nao constituem execucao de CPU completa.

## Sintese dos novos componentes

Com o mesmo GHDL usado nos testes, para cada entidade:

```bash
ghdl --synth --std=08 alu.vhd -e alu
ghdl --synth --std=08 reg_a.vhd -e reg_a
ghdl --synth --std=08 reg_b.vhd -e reg_b
ghdl --synth --std=08 alu_out.vhd -e alu_out
```

A sintese GHDL nao substitui place-and-route, analise de temporizacao ou teste em FPGA.

## RAM, REM e RDM

```bash
bash tests/run_memory.sh
```

A RAM tem uma porta compartilhada para instruções e dados, com 1024 palavras
de 16 bits. Cada endereço de 10 bits seleciona uma palavra entre 0 e 1023.
A seleção do endereço de 10 bits a partir do PC ou da ULA de 16 bits será
definida na integração do datapath.

| Sinais na subida de `clk` | Operação |
| --- | --- |
| `write_enable = 1` | Grava `data_in` em `address` e mantém `data_out`, inclusive se `read_enable = 1` |
| `write_enable = 0`, `read_enable = 1` | Atualiza `data_out` com a palavra em `address` após a borda |
| Ambas desabilitadas | Preserva as palavras e a última saída |

O REM pode ser usado para manter o endereço estável entre etapas. Com ele,
uma leitura pode carregar o REM na primeira borda, ler a RAM na segunda e
capturar `data_out` no RDM na terceira. A saída da RAM só é válida após a
primeira leitura. REM e RDM têm reset assíncrono ativo alto e habilitação
de escrita independente. O reset dos registradores preserva a RAM.

O arquivo `memory_test.mif` contém palavras de teste para a RAM. O genérico
`init_file` seleciona o MIF. No Quartus, o atributo `ram_init_file` vincula
a imagem à RAM inferida. O teste GHDL lê a mesma imagem; para usar outro MIF
na simulação, mantenha o cabeçalho e a formatação do exemplo, com endereços
HEX de três dígitos, dados HEX de quatro dígitos e uma atribuição por linha.
O carregador de simulação aceita linhas vazias, endereços individuais e
faixas inclusivas, seguindo o formato do arquivo de exemplo.

O testbench verifica a inicialização nos limites e na faixa zerada, a
escrita, a prioridade da escrita sobre uma leitura simultânea, a retenção,
a latência entre REM, RAM e RDM e a preservação da RAM após reset.
