# Validacao de 23/11/2026

Base: main, commit 34270c5. Correcoes locais posteriores, sem commit/push.
Escopo: tres lacunas encontradas na auditoria contra o roteiro PDF de 21/11.

## Mudancas verificadas

- Enderecos fora de 0000–03FF bloqueados antes do acesso fisico a RAM.
  `address_fault` fica registrado; controle e datapath param ate reset.
  A soma de enderecos continua modular em 16 bits, conforme a ISA documentada.
- Demo grava Mem[16], rele em R4 e termina no loop JMP 9. Testada duas vezes
  por reset, com codigo original preservado, R3=R4=Mem[16]=0003 e uma escrita
  por execucao. Reset nao recarrega o MIF nem limpa RAM.
- Programa 4 verifica BEQ/BNE tomados e nao tomados, loop com imediato -2,
  R0 e opcode invalido. Confere a sequencia executada, nao apenas o resultado.
- Monitores contam escritas na RAM: uma escrita indevida de zero tambem falha.
- Diagramas, tabela de ciclos e declaracoes de cobertura foram corrigidos.

## Evidencias

Os testes novos falharam antes das correcoes: escrita da demo fora de Mem[16],
caminho incompleto do programa de saltos e LD negativo escrevendo no banco.

```bash
GHDL=/home/luccas/.local/opt/ghdl-6.0.0/ghdl-mcode-6.0.0-ubuntu24.04-x86_64/bin/ghdl bash tests/run_all.sh
```

Resultado: 13 suites passaram. Incluem quatro programas completos, demo
repetida e oito cenarios de enderecamento. Programas 1/2/3/4: 38/38/32/69
ciclos ate detectar o loop final; os testes observam mais tres bordas depois.

Em copias temporarias, os testes rejeitaram nove mutacoes:
BEQ desativado, BNE desativado, condicao de salto invertida, extensor sem
sinal, offset do branch sem sinal, validacao de LD/ST removida, validacao
de busca removida, gate de leitura RAM removido e demo voltando a gravar
sobre o codigo.

VCDs dos quatro programas gerados com:

```bash
VCD_DIR=/tmp/cpu-waves GHDL=/caminho/para/ghdl bash tests/run_programs.sh
```

A tabela de LD em [programs.md](programs.md) foi conferida contra o VCD:
RAM recebe o endereco na borda 5 (45 ns), RDM captura na borda 6 (55 ns)
e banco na borda 7 (65 ns). As ondas sao geradas sob demanda, fora do Git.

Sintese GHDL da CPU integrada passou e identificou RAM 1024×16. O aviso
`unhandled attribute ram_init_file` e uma limitacao desse fluxo: nao prova
inicializacao MIF na FPGA. Para reproduzir, analisar os 15 fontes RTL na
ordem de [cpu.md](cpu.md), depois executar `ghdl --synth --std=08 cpu`.
Sintaxe Bash e `git diff --check` tambem foram verificados.

## Revisao independente

Revisao do RTL, integracao e testes nao apontou outra falha funcional.
Apontou uma lacuna de cobertura: retirar o gate de leitura da RAM ainda
passava. O teste agora verifica que `fetched` fica retido na primeira busca
invalida. A mutacao passou a falhar por leitura indevida, e as 13 suites
passaram novamente com o circuito correto.

## O que falta para a placa

Quartus e ModelSim nao estavam no PATH desta sessao; nao foi feita compilacao
nessas ferramentas. Nao ha projeto QPF/QSF/SDC nem top da DE2-115 no checkout.

1. Quartus Prime Lite 20.1 informado pelo grupo; confirmar versao numerica
   do ModelSim-Altera e criterios do enunciado completo.
2. Definir interface da placa: reset, execucao continua/passo, LEDs/displays
   e indicacao de address_fault; sincronizar entradas e tratar repique.
3. Criar top, pinos/dispositivo e clock constraints. Se houver passo manual,
   implementar habilitacao coerente de todos os elementos sequenciais.
4. Validar inferencia/inicializacao da RAM, uso de recursos e timing no Quartus.
5. Programar a placa, comparar resultados, repetir por reset e guardar evidencias.
6. Fechar relatorio e apresentacao com o fluxo reproduzivel e as limitacoes.

Os testes desta rodada permitem avancar para essa preparacao; nao comprovam
funcionamento fisico, timing ou cumprimento de requisitos nao disponibilizados.
