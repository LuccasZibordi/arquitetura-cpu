library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_register_file is
end entity;

architecture test of tb_register_file is
    signal clk, reset, reg_write : std_logic := '0';
    signal read_addr1, read_addr2, write_addr : std_logic_vector(2 downto 0) := "000";
    signal write_data : std_logic_vector(15 downto 0) := x"0000";
    signal read_data1, read_data2 : std_logic_vector(15 downto 0);
    type values_type is array (0 to 7) of std_logic_vector(15 downto 0);
    constant values : values_type :=
        (x"0000", x"0001", x"8000", x"FFFF", x"AAAA", x"5555", x"1234", x"FEDC");
begin
    dut : entity work.register_file
        port map (
            clk => clk, reset => reset, reg_write => reg_write,
            read_addr1 => read_addr1, read_addr2 => read_addr2,
            write_addr => write_addr, write_data => write_data,
            read_data1 => read_data1, read_data2 => read_data2
        );

    stimulus : process
        procedure tick is
        begin
            clk <= '1';
            wait for 1 ns;
            clk <= '0';
            wait for 1 ns;
        end procedure;

        procedure check_pair(a, b : natural;
                             expected_a, expected_b : std_logic_vector(15 downto 0)) is
        begin
            read_addr1 <= std_logic_vector(to_unsigned(a, 3));
            read_addr2 <= std_logic_vector(to_unsigned(b, 3));
            wait for 1 ns;
            assert read_data1 = expected_a report "Leitura 1 incorreta: R" & integer'image(a) severity failure;
            assert read_data2 = expected_b report "Leitura 2 incorreta: R" & integer'image(b) severity failure;
        end procedure;
    begin
        -- Reset sem borda de clock.
        reset <= '1';
        wait for 1 ns;
        for i in 0 to 7 loop
            check_pair(i, 7-i, x"0000", x"0000");
        end loop;
        reset <= '0';
        reg_write <= '1';

        -- Cada registrador gravavel: sem escrita antecipada, ambas as portas
        -- observam o valor novo depois da borda de subida.
        for i in 1 to 7 loop
            write_addr <= std_logic_vector(to_unsigned(i, 3));
            write_data <= values(i);
            check_pair(i, i, x"0000", x"0000");
            tick;
            check_pair(i, i, values(i), values(i));
        end loop;

        -- Todas as 64 combinacoes de leitura, sem clock.
        reg_write <= '0';
        for a in 0 to 7 loop
            for b in 0 to 7 loop
                check_pair(a, b, values(a), values(b));
            end loop;
        end loop;

        -- Habilitacao de escrita desativada preserva o valor.
        write_addr <= "011";
        write_data <= x"0000";
        tick;
        check_pair(3, 4, x"FFFF", x"AAAA");

        -- Escrita em R0 e ignorada, inclusive nas duas portas simultaneas.
        reg_write <= '1';
        write_addr <= "000";
        write_data <= x"FFFF";
        tick;
        check_pair(0, 0, x"0000", x"0000");
        check_pair(1, 7, x"0001", x"FEDC");

        -- Alterar dados com clock alto ou na descida nao pode escrever.
        write_addr <= "010";
        write_data <= x"1357";
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
        check_pair(2, 1, x"1357", x"0001");
        write_data <= x"2468";
        check_pair(2, 1, x"1357", x"0001");
        clk <= '0';
        check_pair(2, 1, x"1357", x"0001");
        tick;
        check_pair(2, 1, x"2468", x"0001");

        -- Reset limpa dados existentes sem clock e vence escrita simultanea.
        reset <= '1';
        wait for 1 ns;
        for i in 0 to 7 loop
            check_pair(i, 7-i, x"0000", x"0000");
        end loop;
        tick;
        check_pair(2, 2, x"0000", x"0000");
        reset <= '0';
        tick;
        check_pair(2, 0, x"2468", x"0000");

        report "PASS: register_file (reset, escrita, duas leituras e R0)" severity note;
        finish;
    end process;
end architecture;
