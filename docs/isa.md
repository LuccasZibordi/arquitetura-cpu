# ISA da CPU de 16 bits

## A ideia geral

A CPU trabalha com palavras de 16 bits. Ela tem oito registradores, R0 a R7,
tambem de 16 bits. R0 e especial: sempre le zero e nunca muda, mesmo se uma
instrucao tentar escrever nele.

O programa fica na memoria, uma instrucao por palavra. O PC guarda o endereco
da instrucao atual. Na maioria das instrucoes ele simplesmente avanca uma
posicao (PC + 1). So BEQ, BNE e JMP mudam esse caminho.

Os numeros de 0 a 15 escritos nos exemplos sao os opcodes, ou seja, o codigo
da operacao. Eles nao tem relacao com o seletor de 3 bits da ULA, que e um
controle interno do circuito.

## Como uma instrucao e escrita

Existem tres formatos. Em todos, o opcode ocupa os 4 bits mais altos.

Tipo R -- serve para as contas entre registradores:

    opcode | Ri | Rj | Rk | nao usado
       4   | 3  | 3  | 3  |    3

Ri e o registrador onde o resultado vai parar. Rj e Rk sao os dois valores de
entrada. Os 3 bits finais sao ignorados.

Tipo I -- serve para contas com um numero fixo e para acessos a memoria:

    opcode | Ri | Rj | imediato
       4   | 3  | 3  |    6

O imediato e um numero de 6 bits lido com sinal, de -32 a 31. Por exemplo,
111111 quer dizer -1 e 100000 quer dizer -32. No LD, Ri recebe o valor lido.
No ST, Ri e o valor que sera gravado. Em todos os casos, Rj e o registrador
que serve de base para o endereco.

Tipo J -- serve apenas para o salto incondicional:

    opcode | endereco
       4   |   12

O endereco de 12 bits e preenchido com zeros a esquerda ate completar 16 bits.

## As instrucoes

### ADD - soma dois registradores

Soma os valores de Rj e Rk e guarda o resultado em Ri.

`ADD R3, R1, R2` fica `0650`. Se R1 = 5 e R2 = 7, R3 passa a valer 12.

### SUB - subtrai dois registradores

Subtrai Rk de Rj e guarda o resultado em Ri.

`SUB R1, R1, R2` fica `1250`. Se R1 = 10 e R2 = 3, R1 passa a valer 7.

### AND - operacao logica E

Faz o AND bit a bit entre Rj e Rk e guarda em Ri.

`AND R3, R1, R2` fica `2650`.

### OR - operacao logica OU

Faz o OR bit a bit entre Rj e Rk e guarda em Ri.

`OR R3, R1, R2` fica `3650`.

### SLT - compara dois registradores

Compara Rj e Rk como numeros com sinal. Se Rj for menor, Ri recebe 1;
senao recebe 0. E uma forma de testar uma condicao sem usar flags.

`SLT R1, R2, R3` fica `4298`. Se R2 = 4 e R3 = 9, R1 recebe 1.

### ADDI - soma um numero fixo

Soma o imediato ao valor de Rj e guarda em Ri. Como o imediato tem sinal,
tambem serve para subtrair pequenos valores.

`ADDI R1, R0, 3` fica `5203`: R1 recebe 3.
`ADDI R1, R0, -1` fica `523F`: R1 recebe FFFF, que e -1 em 16 bits.

### LD - le da memoria

Soma o imediato a Rj, usa o resultado como endereco e guarda a palavra lida
em Ri. O endereco e limitado a 0-1023 porque a RAM tem 1024 palavras.

`LD R1, 2(R0)` fica `6202`: R1 recebe o valor guardado na memoria no
endereco 2.

### ST - grava na memoria

Soma o imediato a Rj e usa o resultado como endereco. O valor gravado e o
que esta em Ri.

`ST R3, 0(R0)` fica `7600`: o valor de R3 vai para a memoria no endereco 0.

### BEQ - pula se forem iguais

Compara Ri e Rj. Se forem iguais, o PC recebe o endereco da proxima
instrucao mais o imediato, contado em palavras. Se nao forem iguais, segue
em frente normalmente.

`BEQ R1, R0, 1` fica `8201`. Se R1 for zero e a instrucao estiver no
endereco 5, o PC vai para o endereco 7.

### BNE - pula se forem diferentes

E o contrario do BEQ: so pula quando Ri e Rj sao diferentes. O calculo do
destino e o mesmo.

`BNE R1, R0, 1` fica `9201`.

### JMP - salto incondicional

Troca o PC pelo endereco de 12 bits da instrucao, sem comparar nada.

`JMP 3` fica `A003`: o PC passa a valer 3.

### Instrucao invalida

Os opcodes 1011 a 1111 nao correspondem a nenhuma instrucao. Se um deles
aparecer, nada acontece: o PC, os registradores e a memoria ficam como
estavam. A ISA nao tem um HALT; para encerrar um programa, use `JMP` para o
proprio endereco e observe o resultado nos registradores, na memoria ou nos
displays da FPGA.

## Consulta rapida

| Opcode | Instrucao | Opcode | Instrucao |
| --- | --- | --- | --- |
| 0000 | ADD | 0101 | ADDI |
| 0001 | SUB | 0110 | LD |
| 0010 | AND | 0111 | ST |
| 0011 | OR | 1000 | BEQ |
| 0100 | SLT | 1001 | BNE |
| 1010 | JMP | 1011-1111 | invalido |

Outras regras que valem para todas: o resultado e truncado em 16 bits, sem
excecao de overflow; os sinais Zero e Overflow da ULA nao aparecem na ISA;
escrever em R0 nao tem efeito.

## Programa de demonstracao

Ele soma 1 + 2 + 3, guarda o 6 resultante na memoria e termina parado. A ideia
e: R1 conta de 3 ate 0, R2 vale 1 e R3 acumula a soma. A cada volta, R3 ganha
1 e R1 perde 1. Quando R1 chega a zero, o BEQ pula para o ST.

| Endereco | Codigo | Instrucao |
| --- | --- | --- |
| 0 | 5203 | ADDI R1,R0,3 -- comeca o contador em 3 |
| 1 | 5401 | ADDI R2,R0,1 -- o incremento e 1 |
| 2 | 5600 | ADDI R3,R0,0 -- zera a soma |
| 3 | 06D0 | ADD R3,R3,R2 -- soma mais um |
| 4 | 1250 | SUB R1,R1,R2 -- diminui o contador |
| 5 | 8201 | BEQ R1,R0,1 -- se acabou, vai para o endereco 7 |
| 6 | A003 | JMP 3 -- senao, volta para somar de novo |
| 7 | 7600 | ST R3,0(R0) -- grava 6 na memoria no endereco 0 |
| 8 | A008 | JMP 8 -- fim: PC fica parado aqui |

Ao final, R3 = 0006, a memoria no endereco 0 = 0006 e PC = 0008.
