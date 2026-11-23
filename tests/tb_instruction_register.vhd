library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_instruction_register is
end entity;

architecture test of tb_instruction_register is
    signal clk, reset, ir_write : std_logic := '0';
    signal instruction_in : std_logic_vector(15 downto 0) := x"0000";
    signal instruction_out : std_logic_vector(15 downto 0);
begin
    dut : entity work.instruction_register
        port map (
            clk => clk, reset => reset, ir_write => ir_write,
            instruction_in => instruction_in,
            instruction_out => instruction_out
        );

    stimulus : process
        procedure check(expected : std_logic_vector(15 downto 0);
                        message_text : string) is
        begin
            wait for 1 ns;
            assert instruction_out = expected report message_text severity failure;
        end procedure;

        procedure tick is
        begin
            clk <= '1';
            wait for 1 ns;
            clk <= '0';
            wait for 1 ns;
        end procedure;
    begin
        reset <= '1';
        check(x"0000", "Reset inicial sem clock falhou");
        reset <= '0';
        ir_write <= '1';
        instruction_in <= x"A53C";
        check(x"0000", "Instrucao mudou antes da subida");
        clk <= '1';
        check(x"A53C", "Instrucao nao foi capturada na subida");

        instruction_in <= x"5AC3";
        check(x"A53C", "Entrada alterou instrucao com clock alto");
        clk <= '0';
        check(x"A53C", "Instrucao mudou na descida");
        tick;
        check(x"5AC3", "Segunda instrucao nao foi capturada");

        ir_write <= '0';
        instruction_in <= x"FFFF";
        wait for 1 ns;
        tick;
        tick;
        check(x"5AC3", "Escrita desabilitada nao reteve instrucao");

        -- Habilitar escrita enquanto clk esta alto nao basta para capturar.
        clk <= '1';
        wait for 1 ns;
        ir_write <= '1';
        check(x"5AC3", "Habilitacao sem subida alterou instrucao");
        clk <= '0';
        wait for 1 ns;
        tick;
        check(x"FFFF", "Palavra com todos os bits em 1 nao foi capturada");
        instruction_in <= x"0000";
        wait for 1 ns;
        tick;
        check(x"0000", "Palavra zero nao foi capturada");

        instruction_in <= x"8001";
        wait for 1 ns;
        tick;
        check(x"8001", "Bits extremos nao foram preservados");
        ir_write <= '0';
        reset <= '1';
        check(x"0000", "Reset assincrono com escrita desabilitada falhou");

        ir_write <= '1';
        instruction_in <= x"1234";
        wait for 1 ns;
        tick;
        check(x"0000", "Reset nao teve prioridade sobre escrita");
        reset <= '0';
        check(x"0000", "Soltar reset capturou sem clock");
        tick;
        check(x"1234", "Escrita apos reset falhou");

        report "PASS: instruction_register (captura, retencao, bordas e reset)" severity note;
        finish;
    end process;
end architecture;
