library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
    port (
        clk        : in std_logic;
        reset      : in std_logic;
        reg_write  : in std_logic;
        read_addr1 : in std_logic_vector(2 downto 0);
        read_addr2 : in std_logic_vector(2 downto 0);
        write_addr : in std_logic_vector(2 downto 0);
        write_data : in std_logic_vector(15 downto 0);
        read_data1 : out std_logic_vector(15 downto 0);
        read_data2 : out std_logic_vector(15 downto 0)
    );
end entity register_file;

architecture rtl of register_file is
    type register_array is array (1 to 7) of std_logic_vector(15 downto 0);
    signal registers : register_array;
begin
    -- R0 e constante: apenas R1 a R7 precisam de armazenamento.
    -- Reset assincrono ativo em nivel alto, com prioridade sobre escrita.
    process(clk, reset)
    begin
        if reset = '1' then
            registers <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if reg_write = '1' and write_addr /= "000" then
                registers(to_integer(unsigned(write_addr))) <= write_data;
            end if;
        end if;
    end process;

    -- Portas independentes de leitura combinacional.
    read_data1 <= (others => '0') when read_addr1 = "000" else
                  registers(to_integer(unsigned(read_addr1)));
    read_data2 <= (others => '0') when read_addr2 = "000" else
                  registers(to_integer(unsigned(read_addr2)));
end architecture rtl;
