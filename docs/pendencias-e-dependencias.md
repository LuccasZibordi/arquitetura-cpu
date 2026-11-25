# Pendências antes dos testes na placa

Atualizado em 25/11/2026, revisão do checkout main/fd9d217.

## Resultado da revisão

Não foi identificado bloqueio de RTL nos cenários revisados. As 16 suítes
GHDL foram executadas novamente com sucesso (37 mensagens PASS). Os seis
SOF conferem com `entrega/placa/SHA256.txt`. As 106 atribuições de pinos
coincidem com o QSF de referência fornecido, sem pinos duplicados.

QPF/QSF/SDC, top, imagens MIF e seis SOF já existem. Os relatórios recebidos
em `entrega/evidencias` registram 35 simulações ModelSim e compilação Quartus
com timing positivo; não foram reexecutados nesta sessão. A reprodução em
pasta limpa está documentada em `progresso.md` (24/11).

## O que falta

1. No laboratório: conferir revisão da DE2-115, FPGA, tensões/jumpers,
   alimentação, driver e identificação JTAG. A referência de pinagem não
   substitui conferir a unidade física.
2. Programar e executar os testes do
   [PDF de bancada](../entrega/Roteiro%20de%20testes%20-%20DE2-115.pdf).
   Registrar nome/hash do SOF, PC, estado, seletores, resultados e fotos.
3. Investigar qualquer divergência física antes de declarar aprovação.
4. Conferir o enunciado integral do professor e requisitos de relatório/
   apresentação. A documentação técnica não prova conformidade acadêmica.

## Preparação concluída nesta revisão

- PDF existente ampliado para oito páginas: conexão/JTAG, controles,
  estados, demo, pausa, reset, memória, overflow, falha e quatro programas.
- Instruções usam valores observáveis: retorno no estado 9, PC junto do
  estado e releitura da RAM. Banco R0–R7 não tem seletor direto no top.
- Documentos antigos de retomada corrigidos; memória persistente atualizada.
- Nenhum RTL, MIF, QSF, SDC ou SOF alterado. Não é necessária recompilação
  por causa destas alterações documentais.

## Dependências

Para usar as imagens existentes: Programmer/USB-Blaster e placa.
Para nova compilação: Quartus Lite 20.1 com Cyclone IV, sem precisar da placa.
Para simular: GHDL ou ModelSim, sem precisar da placa.
Para reconstruir o PDF: Python com reportlab; executar
`python docs/tools/gerar_roteiro_pdf.py` na raiz do projeto.

Comandos de reprodução no Windows e troca de MIF: `entrega/LEIA-ME.md`.
Evidência local desta revisão: `entrega/evidencias/ghdl-2026-11-25.log`.
