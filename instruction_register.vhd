library ieee;
use ieee.std_logic_1164.all;

entity instruction_register is
    port (
        clk             : in std_logic;
        reset           : in std_logic;
        ir_write        : in std_logic;
        instruction_in  : in std_logic_vector(15 downto 0);
        instruction_out : out std_logic_vector(15 downto 0)
    );
end entity instruction_register;

architecture rtl of instruction_register is
begin
    -- Armazena a palavra completa; a decodificacao e feita fora deste modulo.
    -- Reset assincrono ativo em 1, com prioridade sobre a captura.
    process(clk, reset)
    begin
        if reset = '1' then
            instruction_out <= (others => '0');
        elsif rising_edge(clk) then
            if ir_write = '1' then
                instruction_out <= instruction_in;
            end if;
        end if;
    end process;
end architecture rtl;
