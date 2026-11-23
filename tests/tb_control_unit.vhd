library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity tb_control_unit is
end entity tb_control_unit;

architecture sim of tb_control_unit is
    signal clk : std_logic := '0';
    signal reset : std_logic := '1';
    signal opcode : std_logic_vector(3 downto 0) := x"0";
    signal zero : std_logic := '0';

    signal pc_write, ir_write, reg_write : std_logic;
    signal reg_a_write, reg_b_write, alu_out_write : std_logic;
    signal rem_write, rdm_write : std_logic;
    signal mem_read, mem_write : std_logic;
    signal alu_op : std_logic_vector(2 downto 0);
    signal read_addr2_sel, alu_b_sel, mem_addr_sel : std_logic;
    signal pc_sel : std_logic_vector(1 downto 0);
    signal wb_sel : std_logic;
    signal state_out : std_logic_vector(3 downto 0);

    type opcode_array is array (natural range <>) of std_logic_vector(3 downto 0);
begin
    clock : process
    begin
        loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
    end process;

    dut : entity work.control_unit
        port map (
            clk => clk, reset => reset, opcode => opcode, zero => zero,
            pc_write => pc_write, ir_write => ir_write, reg_write => reg_write,
            reg_a_write => reg_a_write, reg_b_write => reg_b_write,
            alu_out_write => alu_out_write, rem_write => rem_write,
            rdm_write => rdm_write, mem_read => mem_read, mem_write => mem_write,
            alu_op => alu_op, read_addr2_sel => read_addr2_sel,
            alu_b_sel => alu_b_sel, mem_addr_sel => mem_addr_sel,
            pc_sel => pc_sel, wb_sel => wb_sel, state_out => state_out
        );

    stimulus : process
        procedure tick(
            constant op : in std_logic_vector(3 downto 0) := "----";
            constant z  : in std_logic := 'Z'
        ) is
        begin
            wait until falling_edge(clk);
            if op /= "----" then
                opcode <= op;
            end if;
            if z /= 'Z' then
                zero <= z;
            end if;
            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure;

        procedure check(
            constant st  : in std_logic_vector(3 downto 0);
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
            assert state_out = st
                report "estado " & to_hstring(state_out) & ", esperado " & to_hstring(st)
                severity failure;
            assert pc_write = pcw and ir_write = irw and reg_write = rgw and
                  reg_a_write = aw and reg_b_write = bw and alu_out_write = ow and
                  rem_write = rw and rdm_write = dw and mem_read = mrd and
                  mem_write = mwr and alu_op = op and read_addr2_sel = a2 and
                  alu_b_sel = bs and mem_addr_sel = mas and wb_sel = wbs and
                  pc_sel = ps
                report "sinais errados no estado " & to_hstring(st) &
                       " pcw=" & std_logic'image(pc_write) &
                       " irw=" & std_logic'image(ir_write) &
                       " rgw=" & std_logic'image(reg_write) &
                       " aw=" & std_logic'image(reg_a_write) &
                       " bw=" & std_logic'image(reg_b_write) &
                       " ow=" & std_logic'image(alu_out_write) &
                       " rw=" & std_logic'image(rem_write) &
                       " dw=" & std_logic'image(rdm_write) &
                       " mrd=" & std_logic'image(mem_read) &
                       " mwr=" & std_logic'image(mem_write) &
                       " op=" & to_hstring(alu_op) &
                       " a2=" & std_logic'image(read_addr2_sel) &
                       " bs=" & std_logic'image(alu_b_sel) &
                       " mas=" & std_logic'image(mem_addr_sel) &
                       " wbs=" & std_logic'image(wb_sel) &
                       " ps=" & to_hstring(pc_sel)
                severity failure;
        end procedure;
    begin
        wait for 1 ns;
        check(x"0", mrd => '1'); -- reset assincrono: FETCH0

        wait until rising_edge(clk); -- primeira subida ainda com reset alto
        wait for 1 ns;
        reset <= '0';

        -- ADD, SUB, AND, OR, SLT: o seletor da ULA e o proprio opcode.
        for i in 0 to 4 loop
            tick(std_logic_vector(to_unsigned(i, 4)));
            check(x"1", irw => '1', pcw => '1');
            tick;
            check(x"2", aw => '1', bw => '1');
            tick;
            check(x"3", op => std_logic_vector(to_unsigned(i, 3)), ow => '1');
            tick;
            check(x"9", rgw => '1');
            tick;
            check(x"0", mrd => '1');
        end loop;

        -- ADDI
        tick(x"5");
        check(x"1", irw => '1', pcw => '1');
        tick;
        check(x"2", aw => '1', bw => '1', a2 => '1');
        tick;
        check(x"3", op => "000", ow => '1', bs => '1');
        tick;
        check(x"9", rgw => '1');
        tick;
        check(x"0", mrd => '1');

        -- LD
        tick(x"6");
        check(x"1", irw => '1', pcw => '1');
        tick;
        check(x"2", aw => '1', bw => '1', a2 => '1');
        tick;
        check(x"4", op => "000", ow => '1', rw => '1', bs => '1');
        tick;
        check(x"5", mrd => '1', mas => '1');
        tick;
        check(x"6", dw => '1');
        tick;
        check(x"9", rgw => '1', wbs => '1');
        tick;
        check(x"0", mrd => '1');

        -- ST: nenhuma escrita no banco.
        tick(x"7");
        check(x"1", irw => '1', pcw => '1');
        tick;
        check(x"2", aw => '1', bw => '1', a2 => '1');
        tick;
        check(x"4", op => "000", ow => '1', rw => '1', bs => '1');
        tick;
        check(x"7", mwr => '1', mas => '1');
        tick;
        check(x"0", mrd => '1');

        -- BEQ nao tomado
        tick(x"8", '0');
        check(x"1", irw => '1', pcw => '1');
        tick;
        check(x"2", aw => '1', bw => '1', a2 => '1');
        tick(x"8", '0');
        check(x"8", op => "001");
        tick;
        check(x"0", mrd => '1');

        -- BEQ tomado
        tick(x"8", '1');
        check(x"1", irw => '1', pcw => '1');
        tick;
        check(x"2", aw => '1', bw => '1', a2 => '1');
        tick(x"8", '1');
        check(x"8", op => "001", pcw => '1', ps => "01");
        tick;
        check(x"0", mrd => '1');

        -- BNE tomado (zero = 0) e nao tomado (zero = 1)
        tick(x"9", '0');
        check(x"1", irw => '1', pcw => '1');
        tick;
        check(x"2", aw => '1', bw => '1', a2 => '1');
        tick(x"9", '0');
        check(x"8", op => "001", pcw => '1', ps => "01");
        tick;
        check(x"0", mrd => '1');

        tick(x"9", '1');
        check(x"1", irw => '1', pcw => '1');
        tick;
        check(x"2", aw => '1', bw => '1', a2 => '1');
        tick(x"9", '1');
        check(x"8", op => "001");
        tick;
        check(x"0", mrd => '1');

        -- JMP: PC recebe o endereco de 12 bits ja em DECODE.
        tick(x"A");
        check(x"1", irw => '1', pcw => '1');
        tick;
        check(x"2", pcw => '1', ps => "10");
        tick;
        check(x"0", mrd => '1');

        -- Invalido: ignorado, sem escrita, PC ja avancou em FETCH1.
        tick(x"F");
        check(x"1", irw => '1', pcw => '1');
        tick;
        check(x"2");
        tick;
        check(x"0", mrd => '1');

        -- Reset no meio da sequencia.
        tick(x"5");
        check(x"1", irw => '1', pcw => '1');
        reset <= '1';
        wait for 1 ns;
        check(x"0", mrd => '1');
        wait until falling_edge(clk);
        reset <= '0';

        report "PASS: control_unit (decoder, estados, saltos, reset e opcode invalido)"
            severity note;
        finish;
    end process;
end architecture sim;
