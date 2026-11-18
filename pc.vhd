library ieee;
use ieee.std_logic_1164.all;

entity PC is
    port(
        clk : in std_logic;
        reset : in std_logic;
        pc_write : in std_logic;
        next_pc : in std_logic_vector(15 downto 0);
        pc_out : out std_logic_vector(15 downto 0)
    );
end entity PC;

architecture rtl of PC is
begin
    -- O datapath calcula next_pc (avanco sequencial ou destino de salto).
    -- Reset assincrono ativo em 1, com prioridade sobre a carga.
    process(clk, reset)
    begin
        if reset = '1' then
            pc_out <= (others => '0');
        elsif rising_edge(clk) then
            if pc_write = '1' then
                pc_out <= next_pc;
            end if;
        end if;
    end process;
end architecture rtl;
