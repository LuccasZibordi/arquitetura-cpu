library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_instruction_formats is
end entity;

architecture test of tb_instruction_formats is
    signal clk, reset, ir_write : std_logic := '0';
    signal instruction_in : std_logic_vector(15 downto 0) := x"0000";
    signal instruction_out, extended_immediate : std_logic_vector(15 downto 0);
begin
    ir : entity work.instruction_register
        port map (
            clk => clk, reset => reset, ir_write => ir_write,
            instruction_in => instruction_in, instruction_out => instruction_out
        );

    extender : entity work.immediate_extender
        port map (
            immediate_in => instruction_out(5 downto 0),
            immediate_out => extended_immediate
        );

    stimulus : process
        procedure capture(word : std_logic_vector(15 downto 0)) is
        begin
            clk <= '0';
            instruction_in <= word;
            ir_write <= '1';
            wait for 1 ns;
            clk <= '1';
            wait for 1 ns;
            clk <= '0';
            wait for 1 ns;
            assert instruction_out = word report "Instrucao capturada incorretamente" severity failure;
        end procedure;

        procedure hold_instruction(word : std_logic_vector(15 downto 0)) is
        begin
            ir_write <= '0';
            instruction_in <= not word;
            wait for 1 ns;
            clk <= '1';
            wait for 1 ns;
            clk <= '0';
            wait for 1 ns;
            assert instruction_out = word report "Formato nao foi retido com ir_write=0" severity failure;
        end procedure;

        procedure check_i(word, expected_immediate : std_logic_vector(15 downto 0)) is
        begin
            capture(word);
            assert instruction_out(15 downto 12) = "1011" report "Opcode I incorreto" severity failure;
            assert instruction_out(11 downto 9) = "010" report "Ri I incorreto" severity failure;
            assert instruction_out(8 downto 6) = "111" report "Rj I incorreto" severity failure;
            assert extended_immediate = expected_immediate report "Imediato I estendido incorretamente" severity failure;
        end procedure;
    begin
        reset <= '1';
        wait for 1 ns;
        reset <= '0';

        -- Tipo R: A | 3 | 5 | 6 | 000. A e apenas um opcode de teste.
        capture(x"A770");
        assert instruction_out(15 downto 12) = "1010" report "Opcode R incorreto" severity failure;
        assert instruction_out(11 downto 9) = "011" report "Ri R incorreto" severity failure;
        assert instruction_out(8 downto 6) = "101" report "Rj R incorreto" severity failure;
        assert instruction_out(5 downto 3) = "110" report "Rk R incorreto" severity failure;
        assert instruction_out(2 downto 0) = "000" report "Bits nao usados R incorretos" severity failure;
        hold_instruction(x"A770");
        -- O IR armazena ate os bits nao usados; nao os interpreta nem limpa.
        capture(x"A777");
        assert instruction_out(15 downto 3) = "1010011101110" report "Campos R afetados pelos bits nao usados" severity failure;
        assert instruction_out(2 downto 0) = "111" report "IR descartou bits nao usados" severity failure;
        report "PASS: formato R" severity note;

        -- Tipo I: B | 2 | 7 | imediato. B e apenas um opcode de teste.
        check_i(x"B5E1", x"FFE1"); -- 100001 = -31
        hold_instruction(x"B5E1");
        assert extended_immediate = x"FFE1" report "Extensor seguiu entrada nao capturada" severity failure;
        check_i(x"B5C0", x"0000"); -- 0
        check_i(x"B5DF", x"001F"); -- 31
        check_i(x"B5E0", x"FFE0"); -- -32
        check_i(x"B5FF", x"FFFF"); -- -1
        report "PASS: formato I e extensao de sinal" severity note;

        -- Tipo J: C | ABC. Campo bruto, sem supor regra de salto.
        capture(x"CABC");
        assert instruction_out(15 downto 12) = "1100" report "Opcode J incorreto" severity failure;
        assert instruction_out(11 downto 0) = x"ABC" report "Endereco J incorreto" severity failure;
        hold_instruction(x"CABC");
        capture(x"C000");
        assert instruction_out(11 downto 0) = x"000" report "Endereco minimo J incorreto" severity failure;
        capture(x"CFFF");
        assert instruction_out(11 downto 0) = x"FFF" report "Endereco maximo J incorreto" severity failure;
        report "PASS: formato J" severity note;

        report "PASS: tres formatos R/I/J" severity note;
        finish;
    end process;
end architecture;
