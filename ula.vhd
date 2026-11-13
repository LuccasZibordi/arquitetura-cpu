library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Operadores is
    port(
        A : in std_logic_vector(15 downto 0);
        B : in std_logic_vector(15 downto 0);
        S : out std_logic_vector(15 downto 0);
        Op : in std_logic_vector(2 downto 0)
    );
end entity Operadores;

architecture TipoR of Operadores is
    begin
        process(A, B, Op)
        begin
            case Op is
                when "000" => -- ADD
                    S <= A + B;

                when "001" => -- SUB
                    S <= A - B;

                when "010" => -- AND
                    S <= A and B;

                when "011" => -- OR
                    S <= A or B;

                when "100" => -- STL
                    if A < B then
                        S <= '1'
                    else
                        S <= '0';
                    end if;

            end case;
        end process;
end architecture TipoR;

architecture TipoI of Operadores is
    begin
        process(A, B, Op)
        begin
            case Op is
                when "101" => -- ADDI
                    S <= A + B;

                when "110" => -- LD
                    