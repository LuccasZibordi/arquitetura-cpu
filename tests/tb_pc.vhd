library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_pc is
end entity;

architecture test of tb_pc is
    signal clk, reset, pc_write : std_logic := '0';
    signal next_pc : std_logic_vector(15 downto 0) := x"0000";
    signal pc_out : std_logic_vector(15 downto 0);
begin
    dut : entity work.PC
        port map (
            clk => clk, reset => reset, pc_write => pc_write,
            next_pc => next_pc, pc_out => pc_out
        );

    stimulus : process
        procedure check(expected : std_logic_vector(15 downto 0);
                        message_text : string) is
        begin
            wait for 1 ns;
            assert pc_out = expected report message_text severity failure;
        end procedure;

        procedure tick is
        begin
            clk <= '1';
            wait for 1 ns;
            clk <= '0';
            wait for 1 ns;
        end procedure;

        procedure load(address_value : std_logic_vector(15 downto 0)) is
        begin
            next_pc <= address_value;
            wait for 1 ns;
            tick;
            check(address_value, "PC nao carregou o endereco fornecido");
        end procedure;
    begin
        reset <= '1';
        check(x"0000", "Reset inicial sem clock falhou");
        reset <= '0';
        pc_write <= '1';
        next_pc <= x"0001";
        check(x"0000", "PC mudou antes da subida");
        clk <= '1';
        check(x"0001", "PC nao carregou na subida");

        next_pc <= x"0002";
        check(x"0001", "PC mudou com clock alto");
        clk <= '0';
        check(x"0001", "PC mudou na descida");
        tick;
        check(x"0002", "Segundo endereco nao foi carregado");

        -- O destino vem do datapath: saltos para frente e para tras.
        load(x"A53C");
        load(x"0010");
        load(x"8001");
        load(x"FFFF");
        load(x"0000");
        load(x"5AC3");
        -- Manter next_pc constante nao deve causar incremento interno.
        tick;
        check(x"5AC3", "PC incrementou sem receber novo endereco");

        pc_write <= '0';
        next_pc <= x"1234";
        wait for 1 ns;
        tick;
        next_pc <= x"FEDC";
        wait for 1 ns;
        tick;
        check(x"5AC3", "PC nao foi preservado com pc_write desabilitado");

        clk <= '1';
        wait for 1 ns;
        pc_write <= '1';
        check(x"5AC3", "Habilitar escrita com clock alto alterou PC");
        clk <= '0';
        check(x"5AC3", "PC mudou na descida apos habilitacao");
        tick;
        check(x"FEDC", "PC nao retomou escrita apos habilitacao");

        pc_write <= '0';
        reset <= '1';
        check(x"0000", "Reset sem clock e sem escrita falhou");
        pc_write <= '1';
        next_pc <= x"1234";
        wait for 1 ns;
        tick;
        check(x"0000", "Reset nao teve prioridade sobre escrita");
        reset <= '0';
        check(x"0000", "Soltar reset alterou PC sem clock");
        tick;
        check(x"1234", "PC nao retomou escrita apos reset");

        report "PASS: PC (carga, retencao, destinos, bordas e reset)" severity note;
        finish;
    end process;
end architecture;
