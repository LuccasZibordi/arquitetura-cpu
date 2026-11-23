library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    port (A, B : in std_logic_vector(15 downto 0);
          Op : in std_logic_vector(2 downto 0);
          S : out std_logic_vector(15 downto 0);
          Zero, Overflow : out std_logic);
end entity;
architecture rtl of alu is
begin
    process(all)
        variable result_value : std_logic_vector(15 downto 0);
        variable overflow_value : std_logic;
    begin
        result_value := (others => '0');
        overflow_value := '0';
        case Op is
            when "000" =>
                result_value := std_logic_vector(signed(A) + signed(B));
                -- Soma: operandos de mesmo sinal, resultado de sinal oposto.
                overflow_value := (not (A(15) xor B(15))) and
                                  (result_value(15) xor A(15));
            when "001" =>
                result_value := std_logic_vector(signed(A) - signed(B));
                -- Subtracao: operandos de sinais diferentes e resultado
                -- com sinal diferente do primeiro operando.
                overflow_value := (A(15) xor B(15)) and
                                  (result_value(15) xor A(15));
            when "010" =>
                result_value := A and B;
            when "011" =>
                result_value := A or B;
            when "100" =>
                if signed(A) < signed(B) then
                    result_value(0) := '1';
                end if;
            when others =>
                null; -- Seletores nao utilizados: resultado e overflow zero.
        end case;
        S <= result_value;
        Overflow <= overflow_value;
        if result_value = x"0000" then
            Zero <= '1';
        else
            Zero <= '0';
        end if;
    end process;
end architecture;
