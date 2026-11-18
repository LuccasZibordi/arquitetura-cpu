library ieee;
use ieee.std_logic_1164.all;

entity immediate_extender is
    port (
        immediate_in  : in std_logic_vector(5 downto 0);
        immediate_out : out std_logic_vector(15 downto 0)
    );
end entity immediate_extender;

architecture rtl of immediate_extender is
begin
    -- Preserva os seis bits originais e replica o sinal nos dez bits novos.
    immediate_out <= (15 downto 6 => immediate_in(5)) & immediate_in;
end architecture rtl;
