library ieee;
use ieee.std_logic_1164.all;

entity alu_out is
    port (clk, reset, write_enable : in std_logic;
          data_in : in std_logic_vector(15 downto 0);
          data_out : out std_logic_vector(15 downto 0));
end entity;
architecture rtl of alu_out is
begin
    -- Reset assincrono ativo alto; captura habilitada apenas na subida.
    process(clk, reset)
    begin
        if reset = '1' then
            data_out <= (others => '0');
        elsif rising_edge(clk) then
            if write_enable = '1' then
                data_out <= data_in;
            end if;
        end if;
    end process;
end architecture;
