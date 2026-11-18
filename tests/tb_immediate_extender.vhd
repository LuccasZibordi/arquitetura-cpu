library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_immediate_extender is
end entity;

architecture test of tb_immediate_extender is
    signal immediate_in : std_logic_vector(5 downto 0) := "000000";
    signal immediate_out : std_logic_vector(15 downto 0);
begin
    dut : entity work.immediate_extender
        port map (immediate_in => immediate_in, immediate_out => immediate_out);

    stimulus : process
        procedure check(input_value : std_logic_vector(5 downto 0);
                        expected : std_logic_vector(15 downto 0)) is
        begin
            immediate_in <= input_value;
            wait for 1 ns;
            assert immediate_out = expected
                report "Extensao incorreta para " & to_string(input_value)
                severity failure;
        end procedure;
        variable expected_integer : integer;
    begin
        -- Casos conhecidos e transicoes entre sinais, sem clock nem reset.
        check("000000", x"0000");
        check("100000", x"FFE0"); -- -32
        check("011111", x"001F"); -- 31
        check("111111", x"FFFF"); -- -1
        check("000001", x"0001"); -- 1
        check("100001", x"FFE1"); -- -31
        check("000000", x"0000");

        -- Oraculo aritmetico: codigos 32..63 representam valores -32..-1.
        for code in 0 to 63 loop
            immediate_in <= std_logic_vector(to_unsigned(code, 6));
            if code < 32 then
                expected_integer := code;
            else
                expected_integer := code - 64;
            end if;
            wait for 1 ns;
            assert to_integer(signed(immediate_out)) = expected_integer
                report "Valor assinado incorreto no codigo " & integer'image(code)
                severity failure;
            assert immediate_out(5 downto 0) = immediate_in
                report "Bits originais alterados" severity failure;
        end loop;

        report "PASS: immediate_extender (64 entradas e limites de sinal)" severity note;
        finish;
    end process;
end architecture;
