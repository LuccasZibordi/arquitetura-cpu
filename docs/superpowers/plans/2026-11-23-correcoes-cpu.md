# Correções da CPU — plano de implementação

> Execução nesta sessão com testes antes das correções e revisão independente ao final.

**Objetivo:** fechar as três lacunas da auditoria autorizadas por Luccas.
**Arquitetura:** verificar os endereços completos antes de usar os 10 bits da RAM; bloquear efeitos e reter uma falha até reset. Preservar a RAM no reset, movendo o resultado da demo para 0010. Testar saltos pela sequência efetiva e por resultados que distingam caminhos.
**Tecnologia:** VHDL-2008, GHDL, Bash. Sem dependências novas na regressão.
**Referência:** auditoria desta sessão e roteiro PDF de 21/11.

## Contrato
- RAM continua 1024×16 e registradores continuam de 16 bits.
- Falha de endereço em busca ou LD/ST bloqueia acesso, congela execução e expõe address_fault até reset. Aritmética continua modular em 16 bits.
- Nenhuma alteração de opcode. Nenhum commit/push ou implementação de placa nesta rodada.

## Tarefas
- [x] Regressão da demo: duas execuções por reset, resultado em Mem[16], leitura de retorno e código inicial preservado. Executar antes/depois de mudar cpu_test.mif.
- [x] Programa 4: conferir cada decisão BEQ/BNE, tomados/não tomados, incluindo imediato negativo; detectar mutações que desativam/invertem saltos. Reforçar monitor de escritas indevidas.
- [x] Teste integrado de endereços: LD/ST -1 e 0400, JMP 0400, branch negativo fora da RAM, passagem de 03FF para 0400; bloquear escrita e verificar retenção/recuperação por reset. Controle positivo para 03FF válido.
- [x] Implementar proteção no datapath, parada no controle e saída no topo; validar programas existentes.
- [x] Corrigir docs de demonstração, sinais/ciclos e cobertura. Registrar pré-requisitos reais de Quartus/DE2-115.
- [x] Regressão completa, mutações direcionadas, síntese GHDL, revisão independente e atualização do vault.

## Foco de revisão
Bloqueio antes do primeiro acesso inválido; ausência de laço combinacional fault/enable; reset sem limpar RAM; endereços limítrofes válidos; teste de salto incapaz de passar por caminho alternativo.

## Registro da execucao

- Decisao: trabalhar no checkout solicitado e preservar alteracoes sem commit;
  correcao autorizada pelo usuario apos auditoria, sem reabrir aprovacao.
- Demo: teste falhou por escrita no codigo; corrigido MIF e testada repeticao
  e releitura. PC final agora 0009 por incluir LD de verificacao.
- Saltos: teste falhou com programa antigo; programa novo passa e mutacoes
  BEQ/BNE/condicao/offset sao detectadas.
- Enderecos: teste falhou por LD negativo escrever no banco; protecao passa
  oito cenarios e regressao inteira. Sem novo opcode nem mudanca de capacidade.
- Sintese GHDL passou, aviso ram_init_file registrado; nao substitui Quartus.
- Revisao independente: lacuna na prova de bloqueio da leitura corrigida;
  mutacao sem gate agora falha, circuito correto passa as 13 suites.
- Documentacao e memoria atualizadas. Nenhuma pendencia funcional adicional
  identificada no escopo; Quartus/FPGA permanecem nao validados.
