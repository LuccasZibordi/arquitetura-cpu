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
- Enderecos devem conter apenas bits binarios validos.

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

## Executar todas as suites

```bash
GHDL=/home/luccas/.local/opt/ghdl-6.0.0/ghdl-mcode-6.0.0-ubuntu24.04-x86_64/bin/ghdl bash tests/run_all.sh
```

Com GHDL no PATH, basta `bash tests/run_all.sh`. Sao cinco suites: banco,
registrador de instrucao, PC, extensor e formatos. A ULA incompleta nao faz
parte destas suites.
