# Entrega técnica • CPU de 16 bits

Para a bancada, abra **Roteiro de testes - DE2-115.pdf** e use os arquivos da pasta **placa**. Os testes físicos estão pendentes. O hash de cada imagem está em placa/SHA256.txt.

## Reproduzir no Windows

No pacote ZIP, extraia todo o conteúdo antes de começar. Abra PowerShell na raiz, onde está cpu_de2_115.qpf. Os comandos abaixo usam o diretório padrão do Quartus Lite 20.1.

~~~powershell
$quartus = 'C:/intelFPGA_lite/20.1/quartus/bin64'
& "$quartus/quartus_sh.exe" --flow compile cpu_de2_115
~~~

A imagem da demo fica em .build/quartus/cpu_de2_115.sof. Para reproduzir uma variante, trabalhe numa cópia limpa do projeto já compilada. Copie o MIF escolhido sobre cpu_test.mif nessa cópia, execute os dois comandos abaixo e guarde o SOF com o nome da variante. Para top_memory use tests/top_memory.mif. Os quatro programas p1 a p4 estão na raiz.

~~~powershell
Copy-Item p3_mem.mif cpu_test.mif -Force
& "$quartus/quartus_cdb.exe" cpu_de2_115 --update_mif
& "$quartus/quartus_asm.exe" cpu_de2_115
~~~

## Repetir os 35 testes ModelSim

Execute na raiz de uma cópia com o cpu_test.mif original da demo. A configuração gravável evita depender de permissão de escrita na instalação.

~~~powershell
$env:MODELSIM_BIN = 'C:/intelFPGA_lite/20.1/modelsim_ase/win32aloem'
$env:MODELSIM = Join-Path $env:TEMP ('cpu-' + [guid]::NewGuid() + '.ini')
Copy-Item (Join-Path $env:MODELSIM_BIN '../modelsim.ini') $env:MODELSIM
(Get-Item $env:MODELSIM).IsReadOnly = $false
$env:CPU_MODELSIM_PREPARE_ONLY = $null
& "$env:MODELSIM_BIN/vsim.exe" -c -do 'if {[catch {source [file normalize tests/run_modelsim.do]} msg]} {puts $msg; quit -force -code 1}; quit -force -code 0'
~~~

O script grava summary.txt, version.log e os logs de cada cenário em .build/modelsim-*. A pasta evidencias acompanha a entrega com os resultados já obtidos.

## Demonstração e formas de onda

Abra Apresentacao.html no navegador e avance com Page Down. A demonstração física segue o roteiro de bancada. Para inspecionar a forma de onda da simulação, abra evidencias/p3_mem.wlf no ModelSim ou importe p3_mem.vcd em um visualizador VCD. Dentro de tb_program, examine clk, state, pc, fetched, rdm, reg_write e mem_write. No primeiro LD, fetched passa a 7FFF antes de o RDM capturar esse valor. No ST, o endereço é 0011 e o dado é 8000. O LD seguinte recupera 8000.

A documentação técnica completa acompanha os fontes em docs/. A conferência dos critérios acadêmicos depende do enunciado integral do professor.
