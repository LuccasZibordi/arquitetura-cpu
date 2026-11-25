"""Gera o roteiro de bancada. Requer reportlab (pip install reportlab)."""
from pathlib import Path
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'entrega/Roteiro de testes - DE2-115.pdf'
styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name='BodyCPU', fontName='Helvetica', fontSize=10, leading=14, spaceAfter=9))
styles.add(ParagraphStyle(name='CellCPU', fontName='Helvetica', fontSize=9, leading=12))
styles['Title'].fontSize=24
styles['Title'].leading=28
styles['Heading1'].textColor=colors.HexColor('#173B57')
story=[]
def p(s): story.append(Paragraph(s, styles['BodyCPU']))
def title(n,s):
    if story: story.append(PageBreak())
    p('GUIA DE BANCADA • CPU 16 BITS • REVISÃO 25/11/2026')
    story.append(Paragraph(f'{n}. {s}',styles['Title']))
    story.append(Spacer(1,12))
def h(s): story.append(Paragraph(s,styles['Heading2']))
def table(rows,widths):
    t=Table([[Paragraph(str(c),styles['CellCPU']) for c in row] for row in rows],colWidths=widths,repeatRows=1,hAlign='LEFT')
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#E2EBF2')),('VALIGN',(0,0),(-1,-1),'TOP'),('GRID',(0,0),(-1,-1),.3,colors.HexColor('#BBC8D2')),('LEFTPADDING',(0,0),(-1,-1),7),('RIGHTPADDING',(0,0),(-1,-1),7),('TOPPADDING',(0,0),(-1,-1),6),('BOTTOMPADDING',(0,0),(-1,-1),6)]))
    story.append(t); story.append(Spacer(1,10))

title(1,'Antes de ir ao laboratório')
p('<b>Objetivo:</b> testar a CPU na DE2-115, conferir controles, execução, memória, aritmética, desvios e proteção de endereço. Siga as páginas em ordem. Todos os números de PC, instruções e dados são <b>hexadecimais</b>; a contagem de passos é decimal.')
h('O que foi conferido em 25/11')
p('Checkout de referência: fd9d217. As 16 suítes GHDL passaram novamente (37 mensagens PASS, pois há cenários parametrizados). Os seis SOF conferem com entrega/placa/SHA256.txt. As 106 atribuições de pinos coincidem com DE2_115_pin_assignments.qsf, sem pinos duplicados. Nenhuma mudança de RTL foi necessária nesta revisão.')
p('Evidências recebidas no repositório: ModelSim com 35 simulações aprovadas; Quartus Lite 20.1 com compilação e timing. O resumo registra folgas mínimas de setup 5,009 ns e hold 0,181 ns, TNS zero; relatórios registram dois M9K e MIF. Essas ferramentas não foram reexecutadas nesta revisão. <b>Os testes físicos continuam pendentes.</b>')
h('Levar para a bancada')
p('Pasta completa do projeto ou entrega/Arquitetura-CPU.zip extraído; este PDF; os seis SOF de entrega/placa; computador com Quartus Programmer e driver USB-Blaster; placa e alimentação apropriadas; cabo USB; celular para fotos; manual correspondente à revisão da placa.')
table([['Imagem em entrega/placa','Finalidade'],['demo.sof','Primeira programação; reset, passos, pausa e resultado 0003.'],['top_memory.sof','Overflow, escrita interrompida, escrita válida, falha e persistência da RAM.'],['p1_arith.sof / p2_limit.sof','Operações da ULA, imediatos negativos e limites.'],['p3_mem.sof / p4_r0_jump.sof','Carga/escrita/releitura; R0 e caminhos de desvio.']],[190,325])
p('<b>Não é necessário recompilar só para usar estas imagens.</b> Se VHDL, QSF ou SDC mudar, faça compilação completa e nova validação de timing. Alterar apenas o MIF exige atualizar a imagem e gerar outro SOF, conforme entrega/LEIA-ME.md.')
p('A aprovação acadêmica ainda depende do enunciado integral e dos critérios do professor. Este guia verifica o comportamento implementado; não substitui essa conferência.')

title(2,'Conectar e programar')
p('<b>1 — Conferência física.</b> Com a placa desligada, confira DE2-115, FPGA EP4CE115F29C7 e revisão. Compare jumpers/tensões com o manual e com cpu_de2_115.qsf. Há saídas em 2,5 V e 3,3 V: não altere todos os padrões para um único valor. Peça apoio do responsável pelo laboratório se a configuração elétrica não estiver identificada.')
p('<b>2 — Preparar JTAG.</b> Deixe SW19 (RUN/PROG) em RUN, conforme o manual Terasic. SW19 é a chave de configuração; não é SW0 da CPU. Conecte o cabo à porta USB-Blaster, use a alimentação indicada para a unidade e ligue a placa.')
p('<b>3 — Abrir o Programmer.</b> No Quartus: Tools → Programmer. Em Hardware Setup, selecione USB-Blaster. Use Mode = JTAG e Auto Detect. A cadeia deve identificar o FPGA EP4CE115. Se não identificar, não avance: consulte o diagnóstico na página 8.')
p('<b>4 — Selecionar o arquivo.</b> Associe entrega/placa/demo.sof à linha do FPGA (Change File ou Add File, conforme a janela). Evite linhas duplicadas para o mesmo dispositivo. Confira nome e caminho; marque Program/Configure e clique Start. Espere 100% e mensagem de sucesso. Fotografe a tela.')
p('<b>5 — Iniciar de forma conhecida.</b> Ponha SW0=0 e SW3=SW2=SW1=0. Pressione KEY0 por cerca de 0,2 s, solte e espere 0,2 s. PC (HEX7..4) e estado (LEDG3..0) devem ser zero. LEDR16 acende durante reset e apaga ao soltar; LEDR17 deve ficar apagado.')
h('Toda troca de imagem')
p('Mantenha SW0=0; repita a seleção/programação com o SOF indicado e aplique KEY0. Reprogramar inicializa a RAM com o MIF da imagem. <b>KEY0 reinicia registradores e controle, mas preserva a RAM.</b> Depois de desligar a placa, reprograme o SOF antes de repetir os testes; não presuma que a imagem JTAG permanece.')
h('Identificar exatamente a imagem')
p('Compare o hash com entrega/placa/SHA256.txt. No PowerShell, a partir da raiz: <font face="Courier">Get-FileHash entrega/placa/demo.sof -Algorithm SHA256</font>. Registre o hash completo na ficha ou anexe a saída. Nome de arquivo sozinho não identifica sua versão.')
p('Referência oficial do procedimento JTAG: <link href="https://www.terasic.com.tw/wiki/images/f/ff/DE2_115_User_manual_2013.pdf" color="blue">Terasic DE2-115 User Manual, seção 4.1</link>. Use o manual da revisão física para a conferência elétrica.')

title(3,'Como ler os controles')
table([['Controle / indicador','Interpretação'],['KEY0 / KEY1','Reset / um ciclo da máquina de estados. Um passo NÃO executa necessariamente uma instrução inteira.'],['SW0 / LEDG6','0 = manual; 1 = contínuo a 50 MHz. LEDG6 confirma o modo filtrado, mesmo se houver falha.'],['HEX7..4 / HEX3..0','PC / dado escolhido. HEX7 e HEX3 são os dígitos mais significativos.'],['LEDR15..0','Mesmo dado dos quatro displays inferiores, em binário. LEDR0 é o bit de peso 1.'],['LEDR16 / LEDR17','Reset ativo / falha de endereço, retida até KEY0.'],['LEDG3..0','Estado, lido em binário. Ex.: 9 = 1001: LEDG3 e LEDG0 acesos.'],['LEDG4 / LEDG5','Zero / overflow da operação atual. Não guardam histórico.'],['LEDG7 / LEDG8','Pulsos de escrita no banco / RAM. Curtos demais para exigir observação a olho, inclusive no passo.']],[155,360])
table([['SW3 SW2 SW1','HEX3..0 mostra','SW3 SW2 SW1','HEX3..0 mostra'],['0 0 0','IR: instrução capturada','1 0 0','RDM: dado capturado da RAM'],['0 0 1','Operando A','1 0 1','Última palavra lida da RAM'],['0 1 0','Operando B','1 1 0','Dado de retorno ao banco'],['0 1 1','Resultado retido (ALUOut)','1 1 1','Endereço atual da RAM']],[95,162,95,163])
p('Leia o seletor na ordem <b>SW3, SW2, SW1</b>. Exemplo: RDM = SW3 ligado, SW2 e SW1 desligados. SW0 continua controlando o modo. Os seletores não escolhem R0–R7 diretamente: A/B são operandos internos e retorno é o dado que será escrito no estado 9.')
p('<b>Estados:</b> 0 busca; 1 captura de instrução; 2 decodificação; 3 execução ULA; 4 cálculo de endereço; 5 leitura RAM; 6 captura RDM; 7 escrita RAM; 8 comparação; 9 retorno ao banco. O estado parado indica a ação que ocorrerá no próximo passo.')
p('Para cada passo, pressione e solte KEY1 por pelo menos 0,1 s em cada fase. Segurar não repete. Espere 0,2 s depois de mudar SW0 ou o seletor antes de anotar. O filtro de passo/modo é de cerca de 10 ms. KEY2/3 e SW4..17 não são usados.')

title(4,'Demo: reset, passo e pausa')
p('<b>Imagem: demo.sof.</b> Programe, selecione IR (000), SW0=0 e aplique KEY0. Registre um vídeo dos controles e fotos dos marcos abaixo.')
table([['Momento','PC','Estado','IR / observação'],['Após reset','0000','0','0000; LEDR17 apagado.'],['1ª pressão de KEY1','0000','1','Mantenha por 1 s: PC/estado não avançam de novo.'],['Soltar e pressionar de novo','0001','2','5203: instrução inicial capturada.'],['3ª pressão','0001','3','5203; operação pronta para executar.'],['4ª pressão','0001','9','Seletor 011 ou 110: 0003.'],['5ª pressão','0001','0','Escrita no banco concluída; pronto para próxima busca.']],[155,60,60,240])
h('Execução contínua e retenção')
p('Coloque SW0=1 por 1 s, depois volte a 0 e espere 0,2 s. LEDG6 deve acender no contínuo e apagar no manual. Selecione RDM (100): deve mostrar <b>0003</b>. Selecione IR (000): deve mostrar <b>A009</b>. Deixe sem tocar por 2 s: PC, estado e dado devem permanecer estáveis.')
p('No laço final, o PC pode parar em <b>0009 ou 000A</b>, conforme o estado. Para comparar um ponto exato, dê passos até estado 0: PC=0009 e IR=A009. O PC temporariamente avançar na busca do JMP é esperado.')
h('Ausência de passos involuntários')
p('Em manual, segure KEY1 e aplique KEY0 sem soltar KEY1. Solte KEY0, aguarde 0,2 s e confirme estado 0. Solte KEY1, espere 0,2 s e pressione: somente agora deve ir ao estado 1. Durante contínuo, mantenha KEY1 pressionado, volte SW0=0, espere e confira retenção; solte antes de tentar o próximo passo.')
h('Repetição')
p('Com SW0=0, aplique KEY0 e repita a sequência inicial e o contínuo. Reprograme demo.sof e repita uma terceira vez. Nas três rodadas: primeira instrução 5203, RDM final 0003, falha apagada. Isso verifica repetição com RAM preservada e com RAM recarregada.')
p('<b>Aprovação:</b> cada pressão gera só um ciclo; segurar não repete; pausa retém valores; retorno ao manual não cria passos; resultado e reset se repetem. LEDG7/8 invisíveis não são falha por si só.')

title(5,'Memória, overflow e falha')
p('<b>Imagem: top_memory.sof.</b> O programa lê Mem[0010]=7FFF, soma 1, grava 8000 no mesmo endereço e salta para 0400, fora da RAM válida 0000–03FF. Faça tudo em manual. Em cada etapa confira <b>PC e estado juntos</b>; o mesmo PC aparece em vários estados.')
table([['Etapa','Como fazer e o que deve acontecer'],['A — Interromper leitura','Após programação/reset, avance até PC=0001, estado 5 (0101). Seletor 101: 6210. A leitura de dados ainda não aconteceu. Aplique KEY0 e confira PC/estado zero.'],['B — Confirmar dado inicial','Avance até PC=0001, estado 9 (1001). Seletor 100: 7FFF. O dado passou da RAM para RDM.'],['C — Interromper escrita','Avance até PC=0003, estado 7 (0111). Seletor 111: 0010; seletor 010: 8000. Espere 2 s sem KEY1. Aplique KEY0 ANTES de autorizar outro passo.'],['D — Conferir que não escreveu','Após esse reset, avance até PC=0001, estado 9. Seletor 100 ainda deve ser 7FFF. Se vier 8000, houve escrita indevida ou um passo extra antes do reset.'],['E — Observar overflow','Continue até PC=0002, estado 3 (0011). LEDG5 deve estar aceso (7FFF + 1). Dê um passo: estado 9; seletor 011 mostra 8000. Observe a flag antes do passo; ela não é histórica.'],['F — Autorizar escrita','Continue até PC=0003, estado 7. Dê exatamente um passo: estado 0. Agora a escrita de 8000 em 0010 foi autorizada.'],['G — Provocar falha','Continue: estado 1 → 2 (PC=0004, IR=A400) → 0 (PC=0400). Mais um passo tenta buscar em 0400 e acende LEDR17. PC deve ficar 0400. Não exija estado 0 após detectar a falha.'],['H — Confirmar parada','Anote PC/estado/IR. Tente dois passos; devem ficar iguais. Ligue SW0 por 1 s: LEDG6 acende, mas PC/estado/IR continuam retidos. Volte SW0=0.'],['I — Reset e persistência','Aplique KEY0: LEDR17 apaga. Avance até PC=0001, estado 9, seletor 100: agora deve ler 8000. Não execute nova soma/escrita antes desta leitura.'],['J — Recarregar RAM','Reprograme top_memory.sof, aplique reset e avance até PC=0001, estado 9. Seletor 100 deve voltar a 7FFF.']],[115,400])
p('<b>Aprovação:</b> leitura 7FFF antes da escrita, 8000 após escrita e reset, 7FFF após reprogramação; overflow visível no estado correto; endereço inválido para a CPU até reset. Fotografar D, E, G, I e J.')

title(6,'Aritmética e limites')
p('<b>Imagens: p1_arith.sof e p2_limit.sof.</b> Programe uma por vez, aplique reset e mantenha SW0=0. Selecione retorno ao banco (110). Avance até estado 9, anote PC e valor, dê um passo para concluir a escrita e continue até o próximo estado 9.')
p('Há sete escritas em cada programa. O PC já aponta para a próxima instrução quando se observa estado 9. Compare a linha pelo PC, não apenas pela ordem das anotações. Os valores são de 16 bits; FFFF representa -1 em complemento de dois.')
table([['PC no estado 9','Destino','p1_arith: esperado','p2_limit: esperado'],['0001','R1','0007','FFE0 (-32)'],['0002','R2','FFFF (-1)','001F (+31)'],['0003','R3','0006','FFFF'],['0004','R4','0008','001F'],['0005','R5','0007','003E'],['0006','R6','FFFF','FFFF'],['0007','R7','0001','0000']],[120,75,160,160])
h('Final de cada programa')
p('Depois da sétima escrita, dê passos até o JMP final ter sido executado: estado 0 e PC=0007. Selecione IR (000): A007. No contínuo e depois de pausar, PC pode ser 0007 ou 0008. Se precisar do valor exato, avance novamente até estado 0.')
h('O que cada imagem cobre')
p('<b>p1:</b> ADDI com positivo/negativo; ADD; SUB; AND; OR; SLT verdadeiro. <b>p2:</b> extremos do imediato de 6 bits (-32/+31), soma sem estouro signed e SLT falso. O teste de overflow é o da página 5 ou o programa p3; p2 não deve ser usado como prova de overflow.')
h('Critério de aprovação e evidência')
p('Todos os sete valores e o laço final devem coincidir, com LEDR17 apagado. Filme as sete paradas no estado 9, ou fotografe cada uma com seletor e PC visíveis. Um laço final correto sozinho não prova que todas as operações deram resultado correto.')
p('Se um valor divergir, registre antes de resetar: nome/hash do SOF, PC, estado, IR (000), A (001), B (010), ALUOut (011) e retorno (110). Trocar os seletores em pausa não executa instruções.')

title(7,'Carga, escrita e desvios')
h('p3_mem.sof — latência e releitura')
p('Programe, aplique reset e use manual. No primeiro LD (PC=0001), pare no estado 5: seletor 101 mostra 6210. Dê um passo para estado 6: seletor 101 mostra 7FFF e RDM (100) ainda mostra 0000. Dê outro passo para estado 9: RDM passa a 7FFF. O próximo passo grava no banco.')
table([['Ponto de observação','Seletor','Valor esperado'],['PC=0001, estado 9','110','7FFF, retorno para R1'],['PC=0002, estado 9','110','0001, retorno para R2'],['PC=0003, estado 3','LEDG5','Aceso antes da soma terminar'],['PC=0003, estado 9','110','8000, retorno para R3'],['PC=0004, estado 7','111 / 010','0011 endereço / 8000 dado a gravar'],['PC=0005, estado 9','100 ou 110','8000, releitura para R4'],['Após JMP final, estado 0','000','IR=A005 e PC=0005']],[285,80,150])
p('No estado 7, a escrita ainda aguarda o próximo passo. A releitura 8000 é a evidência observável de que o ST funcionou. Depois de pausar o laço, RDM permanece 8000; o PC pode ser 0005 ou 0006.')
h('p4_r0_jump.sof — caminhos de execução')
p('Reprograme com p4, aplique reset e use manual. Anote o PC <b>somente em cada chegada ao estado 0</b>, incluindo o zero após reset. Não anote a mesma pausa duas vezes. Sequência esperada até o primeiro laço final:')
p('<font face="Courier">0000, 0001, 0002, 0004, 0006, 0007, 0008,<br/>0009, 000A, 0009, 000A, 0009, 000A, 000B,<br/>000C, 000D</font>')
p('A tentativa inicial de escrever R0 não deve alterar seu valor. Em PC=000C, estado 9, selecione retorno (110): <b>0003</b> (ADD R2,R0,R1). O opcode F em 000C é ignorado. Depois do JMP final, estado 0: PC=000D e IR=A00D. No laço, PC pode alternar entre 000D e 000E.')
p('<b>Falha típica:</b> laço em 0003 ou 0005 indica caminho de desvio incorreto. Exigir toda a sequência também verifica os desvios não tomados e o laço com imediato negativo. O teste só passa se sequência, retorno 0003 e laço final coincidirem.')

title(8,'Diagnóstico e registro')
table([['Sintoma','Verificação imediata'],['USB-Blaster ausente / cadeia vazia','Alimentação, cabo na porta USB-Blaster, driver, Hardware Setup e SW19=RUN. Confira cadeia/jumpers no manual da revisão.'],['Programmer acusa incompatibilidade','Confira FPGA detectado, imagem associada à linha correta e alvo EP4CE115F29C7. Não force outro dispositivo.'],['KEY1 não avança','SW0=0? LEDG6 apagado? LEDR17 apagado? Solte KEY1 por 0,2 s antes de pressionar. Após falha, KEY0 é necessário.'],['PC parece um acima do final','Pode ser a busca do JMP. Compare PC junto do estado; avance até estado 0.'],['Dado inesperado / LED invertido','Confira SW3..1, ordem HEX7..4 versus HEX3..0 e imagem carregada. B e D aparecem como b/d nos displays.'],['LED de overflow não fica aceso','Observe manualmente no estado 3 e PC indicado. Flag não é armazenada. Pulsos LEDG7/8 não servem como confirmação visual de escrita.'],['top_memory lê 8000 após KEY0','Esperado se o ST já foi executado. KEY0 preserva RAM; reprogramar deve restaurar 7FFF.'],['Resultado divergente persistente','Registre evidência antes do reset. Confira SHA-256 e repita com SOF conhecido. Se recompilado, guarde logs, MIF e timing novos.']],[180,335])
h('Ficha de bancada — preencher, não presumir aprovação')
p('Data/hora: __________________ Equipe: ___________________________<br/>Placa/revisão: __________________ Quartus/driver: __________________<br/>Arquivo/hash: __________________________________________________')
table([['Teste','Passou / falhou / não feito','Evidência e valor observado'],['Demo: reset / passo / modos','',''],['Demo: repetição / reprogramação','',''],['Memória: interrupção / persistência','',''],['Overflow / falha / recuperação','',''],['p1 / p2: sete retornos cada','',''],['p3: latência / escrita / releitura','',''],['p4: sequência / R0 / laço','','']],[210,135,170])
p('Anexe fotos/vídeo com PC, estado, seletor e dado visíveis. Para cada falha, registre a sequência exata de ações. Só marque “validado na placa” após executar os testes e guardar resultados. Fontes locais: top_de2_115.vhd, control_unit.vhd, MIFs, tests/tb_top_de2_115.vhd, docs/programs.md e entrega/evidencias/.')

def footer(c,d):
    c.setStrokeColor(colors.HexColor('#AABCCB')); c.line(40,39,555,39)
    c.setFont('Helvetica',8); c.drawString(40,27,'CPU 16 bits • DE2-115 • Testes físicos pendentes até registro da equipe')
    c.drawRightString(555,27,str(d.page))
SimpleDocTemplate(str(OUT),pagesize=A4,rightMargin=40,leftMargin=40,topMargin=35,bottomMargin=50,title='Roteiro de testes na DE2-115',author='Projeto Arquitetura CPU').build(story,onFirstPage=footer,onLaterPages=footer)
print(OUT)
