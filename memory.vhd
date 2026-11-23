library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- synthesis translate_off
use std.textio.all;
-- synthesis translate_on

entity memory is
    generic (
        init_file : string := "memory_test.mif"
    );
    port (
        clk          : in  std_logic;
        read_enable  : in  std_logic;
        write_enable : in  std_logic;
        address      : in  std_logic_vector(9 downto 0);
        data_in      : in  std_logic_vector(15 downto 0);
        data_out     : out std_logic_vector(15 downto 0)
    );
end entity memory;

architecture rtl of memory is
    type ram_type is array (0 to 1023) of std_logic_vector(15 downto 0);

    -- synthesis translate_off
    -- Le o subconjunto HEX usado em memory_test.mif na simulacao.
    impure function load_mif(file_name : string) return ram_type is
        file image : text open read_mode is file_name;
        variable row : line;
        variable contents : ram_type := (others => (others => '0'));
        variable first_address, last_address : std_logic_vector(11 downto 0);
        variable word : std_logic_vector(15 downto 0);
        variable token : character;

        procedure expect_line(expected : string) is
        begin
            assert not endfile(image) report "MIF incompleto" severity failure;
            readline(image, row);
            assert row.all = expected report "Linha MIF esperada: " & expected severity failure;
        end procedure;

        procedure expect_token(expected : character) is
        begin
            read(row, token);
            assert token = expected report "Separador invalido no MIF" severity failure;
        end procedure;
    begin
        expect_line("DEPTH = 1024;");
        expect_line("WIDTH = 16;");
        expect_line("ADDRESS_RADIX = HEX;");
        expect_line("DATA_RADIX = HEX;");
        expect_line("CONTENT BEGIN");

        while not endfile(image) loop
            readline(image, row);
            if row.all = "END;" then
                return contents;
            end if;

            if row.all'length > 0 then
                if row.all(row.all'low) = '[' then
                    expect_token('[');
                    hread(row, first_address);
                    expect_token('.');
                    expect_token('.');
                    hread(row, last_address);
                    expect_token(']');
                else
                    hread(row, first_address);
                    last_address := first_address;
                end if;

                expect_token(' ');
                expect_token(':');
                hread(row, word);
                expect_token(';');
                assert unsigned(first_address) <= unsigned(last_address)
                    and unsigned(last_address) < contents'length
                    report "Endereco fora do intervalo da RAM no MIF" severity failure;
                for index in to_integer(unsigned(first_address)) to to_integer(unsigned(last_address)) loop
                    contents(index) := word;
                end loop;
            end if;
        end loop;
        assert false report "MIF sem END;" severity failure;
        return contents;
    end function;
    -- synthesis translate_on

    signal ram : ram_type
        -- synthesis translate_off
        := load_mif(init_file)
        -- synthesis translate_on
        ;

    attribute ram_init_file : string;
    attribute ram_init_file of ram : signal is init_file;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if write_enable = '1' then
                ram(to_integer(unsigned(address))) <= data_in;
            elsif read_enable = '1' then
                data_out <= ram(to_integer(unsigned(address)));
            end if;
        end if;
    end process;
end architecture rtl;
