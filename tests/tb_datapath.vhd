library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;

entity tb_datapath is
end entity tb_datapath;

architecture sim of tb_datapath is
    signal clk : std_logic := '0';
    signal reset : std_logic := '1';

    signal pc_write, ir_write, reg_write : std_logic := '0';
    signal reg_a_write, reg_b_write, alu_out_write : std_logic := '0';
    signal rem_write, rdm_write : std_logic := '0';
    signal mem_read, mem_write : std_logic := '0';
    signal alu_op : std_logic_vector(2 downto 0) := "000";
    signal read_addr2_sel, alu_b_sel, mem_addr_sel, wb_sel : std_logic := '0';
    signal pc_sel : std_logic_vector(1 downto 0) := "00";

    signal opcode : std_logic_vector(3 downto 0);
    signal zero, overflow : std_logic;
    signal pc_out, instruction, a_out, b_out, alu_result : std_logic_vector(15 downto 0);
    signal rdm_out, fetched_word : std_logic_vector(15 downto 0);

begin
    clock : process
    begin
        loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
    end process;

    dut : entity work.datapath
        generic map (init_file => "datapath_test.mif")
        port map (
            clk => clk, reset => reset,
            pc_write => pc_write, ir_write => ir_write, reg_write => reg_write,
            reg_a_write => reg_a_write, reg_b_write => reg_b_write,
            alu_out_write => alu_out_write, rem_write => rem_write,
            rdm_write => rdm_write, mem_read => mem_read, mem_write => mem_write,
            alu_op => alu_op, read_addr2_sel => read_addr2_sel,
            alu_b_sel => alu_b_sel, mem_addr_sel => mem_addr_sel,
            pc_sel => pc_sel, wb_sel => wb_sel,
            opcode => opcode, zero => zero, overflow => overflow,
            pc_out => pc_out, instruction => instruction,
            a_out => a_out, b_out => b_out, alu_result => alu_result,
            rdm_out => rdm_out, fetched_word => fetched_word
        );

    stimulus : process
        -- Aplica os controles na descida e observa o efeito na subida seguinte.
        procedure step(
            constant pcw : in std_logic := '0';
            constant irw : in std_logic := '0';
            constant rgw : in std_logic := '0';
            constant aw  : in std_logic := '0';
            constant bw  : in std_logic := '0';
            constant ow  : in std_logic := '0';
            constant rw  : in std_logic := '0';
            constant dw  : in std_logic := '0';
            constant mrd : in std_logic := '0';
            constant mwr : in std_logic := '0';
            constant op  : in std_logic_vector(2 downto 0) := "000";
            constant a2  : in std_logic := '0';
            constant bs  : in std_logic := '0';
            constant mas : in std_logic := '0';
            constant wbs : in std_logic := '0';
            constant ps  : in std_logic_vector(1 downto 0) := "00"
        ) is
        begin
            wait until falling_edge(clk);
            pc_write <= pcw; ir_write <= irw; reg_write <= rgw;
            reg_a_write <= aw; reg_b_write <= bw; alu_out_write <= ow;
            rem_write <= rw; rdm_write <= dw;
            mem_read <= mrd; mem_write <= mwr;
            alu_op <= op; read_addr2_sel <= a2; alu_b_sel <= bs;
            mem_addr_sel <= mas; wb_sel <= wbs; pc_sel <= ps;
            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure;
    begin
        step;
        assert pc_out = x"0000" and instruction = x"0000" and alu_result = x"0000"
            and rdm_out = x"0000" report "reset do datapath falhou" severity failure;
        reset <= '0';

        -- 0: ADDI R1,R0,3 -- imediato na B da ULA, resultado volta ao banco.
        step(mrd => '1');
        step(irw => '1', pcw => '1');
        assert instruction = x"5203" and pc_out = x"0001" and opcode = x"5"
            and fetched_word = x"5203"
            report "busca de 5203 falhou" severity failure;
        step(a2 => '1', aw => '1', bw => '1');
        assert a_out = x"0000" and b_out = x"0000"
            report "operandos de ADDI falharam" severity failure;
        step(op => "000", bs => '1', ow => '1');
        assert alu_result = x"0003" report "ADDI nao gerou 3" severity failure;
        step(rgw => '1');

        -- 1: ADDI R2,R0,1
        step(mrd => '1');
        step(irw => '1', pcw => '1');
        assert instruction = x"5401" and pc_out = x"0002"
            report "busca de 5401 falhou" severity failure;
        step(a2 => '1', aw => '1', bw => '1');
        step(op => "000", bs => '1', ow => '1');
        assert alu_result = x"0001" report "ADDI nao gerou 1" severity failure;
        step(rgw => '1');

        -- 2: ADD R4,R1,R2 -- observa os dois registradores escritos antes.
        step(mrd => '1');
        step(irw => '1', pcw => '1');
        assert instruction = x"0850" and pc_out = x"0003"
            report "busca de 0850 falhou" severity failure;
        step(aw => '1', bw => '1');
        assert a_out = x"0003" and b_out = x"0001"
            report "captura de R1 e R2 falhou" severity failure;
        step(op => "000", ow => '1');
        assert alu_result = x"0004" report "ADD nao gerou 4" severity failure;
        step(rgw => '1');

        -- 3: LD R1,0(R0) -- le 5203, que ainda esta no endereco 0.
        step(mrd => '1');
        step(irw => '1', pcw => '1');
        assert instruction = x"6200" and pc_out = x"0004"
            report "busca de 6200 falhou" severity failure;
        step(a2 => '1', aw => '1', bw => '1');
        step(op => "000", bs => '1', ow => '1', rw => '1');
        step(mrd => '1', mas => '1');
        step(dw => '1');
        assert rdm_out = x"5203" report "LD nao leu 5203" severity failure;
        step(rgw => '1', wbs => '1');

        -- 4: ST R4,0(R0) -- grava 4 no endereco 0.
        step(mrd => '1');
        step(irw => '1', pcw => '1');
        assert instruction = x"7800" and pc_out = x"0005"
            report "busca de 7800 falhou" severity failure;
        step(a2 => '1', aw => '1', bw => '1');
        assert b_out = x"0004" report "ST nao capturou R4" severity failure;
        step(op => "000", bs => '1', ow => '1', rw => '1');
        step(mwr => '1', mas => '1');

        -- 5: BEQ R1,R0,1 -- R1 = 5203, nao deve desviar.
        step(mrd => '1');
        step(irw => '1', pcw => '1');
        assert instruction = x"8201" and pc_out = x"0006"
            report "busca de 8201 falhou" severity failure;
        step(a2 => '1', aw => '1', bw => '1');
        assert a_out = x"0000" and b_out = x"5203"
            report "operandos do BEQ falharam" severity failure;
        step(op => "001");
        assert zero = '0' and pc_out = x"0006"
            report "BEQ deveria nao ser tomado" severity failure;

        -- 6: LD R1,0(R0) de novo -- agora o endereco 0 vale 4.
        step(mrd => '1');
        step(irw => '1', pcw => '1');
        assert instruction = x"6200" and pc_out = x"0007"
            report "segunda busca de 6200 falhou" severity failure;
        step(a2 => '1', aw => '1', bw => '1');
        step(op => "000", bs => '1', ow => '1', rw => '1');
        step(mrd => '1', mas => '1');
        step(dw => '1');
        assert rdm_out = x"0004" report "ST nao gravou 4 na memoria" severity failure;
        step(rgw => '1', wbs => '1');

        -- 7: JMP 9 -- alvo zero-estendido vem do campo end da instrucao.
        step(mrd => '1');
        step(irw => '1', pcw => '1');
        assert instruction = x"A009" and pc_out = x"0008"
            report "busca de A009 falhou" severity failure;
        step(a2 => '1', aw => '1', bw => '1', pcw => '1', ps => "10");
        assert pc_out = x"0009" report "JMP nao cargou 9 no PC" severity failure;

        -- 8: BEQ R0,R0,3 -- tomado: PC = 10 + 3 = 13.
        step(mrd => '1');
        step(irw => '1', pcw => '1');
        assert instruction = x"8003" and pc_out = x"000A"
            report "busca de 8003 falhou" severity failure;
        step(a2 => '1', aw => '1', bw => '1');
        step(op => "001", pcw => '1', ps => "01");
        assert zero = '1' and pc_out = x"000D"
            report "BEQ tomado nao calculou o destino" severity failure;

        -- 13: FC00 -- opcode invalido congela o PC se o controle nao escrever.
        step(mrd => '1');
        step(irw => '1');
        assert instruction = x"FC00" and pc_out = x"000D" and opcode = x"F"
            and fetched_word = x"FC00"
            report "instrucao invalida falhou" severity failure;
        step;
        assert pc_out = x"000D" and instruction = x"FC00" and rdm_out = x"0004"
            report "estado mudou com opcode invalido" severity failure;

        report "PASS: datapath (busca, operandos, ULA, memoria, banco, desvio e salto)"
            severity note;
        finish;
    end process;
end architecture sim;
