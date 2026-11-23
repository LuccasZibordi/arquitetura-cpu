# Parte 4 — controles da CPU

Escopo autorizado: preparar reset, sincronizacao, filtro de repique e modos
manual/continuo para integrar ao top na parte 5. Sem alterar a ISA/CPU.

Decisoes de implementacao: um modulo board_controls, clock unico, reset e
passo externos ativos em zero; run_async ativo em um. Reset assertivo
assincrono e liberacao por dois flip-flops. Passo e modo atravessam dois
flip-flops e exigem debounce_cycles amostras consecutivas para mudar.
Padrao 500000 ciclos (10 ms se clock=50 MHz); generic reduzido nos testes.
Modo continuo habilita a CPU em todas as bordas. Manual produz um enable de
um ciclo por pressao. Botao mantido durante reset ou transicao de modo
precisa ser solto antes de um novo passo. Reset tem prioridade.

Um modulo evita fragmentar quatro funcoes pequenas em varios arquivos;
CPU continua recebendo clock original e clock_enable. Divisor para exibicao
lenta e pinos nao fazem parte desta etapa. Sincronizacao reduz risco de
metastabilidade; simulacao digital nao valida comportamento analogico.

Sequencia:
1. Escrever teste comportamental, demonstrar falha com interface vazia.
2. Implementar reset/sincronizacao/debounce/enable.
3. Testar repiques, pressao mantida, alternancia de modos, reset fora da
   borda, botao mantido durante reset, debounce=1 e valor maior.
4. Integrar runners GHDL/ModelSim, regressao e sintese; revisao independente.
5. Atualizar checkpoint do projeto e vault. ModelSim/Quartus/placa pendentes.
