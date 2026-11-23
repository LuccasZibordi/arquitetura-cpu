library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_alu is end entity;
architecture test of tb_alu is
    signal a, b, result : std_logic_vector(15 downto 0) := (others => '0');
    signal op : std_logic_vector(2 downto 0) := "000";
    signal zero, overflow : std_logic;
begin
    dut : entity work.alu port map (A => a, B => b, Op => op,
                                   S => result, Zero => zero, Overflow => overflow);
    stimulus : process
        procedure check(operation : std_logic_vector(2 downto 0);
                        lhs, rhs, expected : std_logic_vector(15 downto 0);
                        expected_overflow : std_logic := '0') is
            variable expected_zero : std_logic := '0';
        begin
            a <= lhs; b <= rhs; op <= operation;
            wait for 1 ns;
            if expected = x"0000" then expected_zero := '1'; end if;
            assert result = expected
                report "Resultado incorreto: op=" & to_hstring(operation) &
                       " A=" & to_hstring(lhs) & " B=" & to_hstring(rhs) &
                       " esperado=" & to_hstring(expected) & " obtido=" & to_hstring(result)
                severity failure;
            assert zero = expected_zero report "Zero incorreto" severity failure;
            assert overflow = expected_overflow report "Overflow incorreto" severity failure;
        end procedure;
        type integers is array (natural range <>) of integer;
        constant values : integers := (-32768, -32767, -123, -1, 0, 1, 123, 32766, 32767);
        variable arithmetic : integer;
        variable flag : std_logic;
    begin
        check("000", x"0002", x"0003", x"0005");
        check("000", x"7FFF", x"0001", x"8000", '1');
        check("010", x"AAAA", x"5555", x"0000"); -- clear overflow
        check("000", x"8000", x"FFFF", x"7FFF", '1');
        check("011", x"AAAA", x"5555", x"FFFF");
        check("000", x"8000", x"8000", x"0000", '1'); -- Zero and Overflow together
        check("000", x"FFFF", x"0001", x"0000"); -- carry, no signed overflow
        check("001", x"7FFF", x"FFFF", x"8000", '1');
        check("100", x"8000", x"7FFF", x"0001"); -- signed, not subtraction sign
        check("001", x"8000", x"0001", x"7FFF", '1');
        check("100", x"7FFF", x"8000", x"0000");
        check("001", x"0000", x"0001", x"FFFF");
        check("001", x"1234", x"1234", x"0000");
        check("010", x"A53C", x"0FF0", x"0530");
        check("011", x"A53C", x"0FF0", x"AFFC");
        check("010", x"FFFF", x"8000", x"8000");
        check("011", x"0000", x"0000", x"0000");
        -- Independent integer oracle for signed arithmetic and comparison.
        for i in values'range loop
            for j in values'range loop
                for operation in 0 to 1 loop
                    if operation = 0 then arithmetic := values(i) + values(j);
                    else arithmetic := values(i) - values(j); end if;
                    flag := '0';
                    if arithmetic < -32768 or arithmetic > 32767 then flag := '1'; end if;
                    check(std_logic_vector(to_unsigned(operation, 3)),
                          std_logic_vector(to_signed(values(i), 16)),
                          std_logic_vector(to_signed(values(j), 16)),
                          std_logic_vector(to_unsigned(arithmetic mod 65536, 16)), flag);
                end loop;
                arithmetic := 0;
                if values(i) < values(j) then arithmetic := 1; end if;
                check("100", std_logic_vector(to_signed(values(i), 16)),
                      std_logic_vector(to_signed(values(j), 16)),
                      std_logic_vector(to_unsigned(arithmetic, 16)));
            end loop;
        end loop;
        for operation in 5 to 7 loop
            check("000", x"7FFF", x"0001", x"8000", '1');
            check(std_logic_vector(to_unsigned(operation, 3)), x"FFFF", x"FFFF", x"0000");
        end loop;
        report "PASS: ALU (266 vetores, cinco operacoes, Zero e overflow signed)" severity note;
        finish;
    end process;
end architecture;
