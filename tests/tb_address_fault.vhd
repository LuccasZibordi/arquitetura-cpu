library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity tb_address_fault is
    generic (scenario : positive := 1);
end entity tb_address_fault;

architecture sim of tb_address_fault is
    signal fault : std_logic;
    signal writes : natural := 0;
    signal loaded : std_logic := '0';
    signal clk : std_logic := '0';
    signal reset : std_logic := '1';

    signal pc, instruction : std_logic_vector(15 downto 0);
    signal state, opcode : std_logic_vector(3 downto 0);
    signal zero, overflow : std_logic;
    signal a, b, alu_result, rdm, fetched : std_logic_vector(15 downto 0);
    signal reg_write, mem_write : std_logic;
    signal reg_write_addr : std_logic_vector(2 downto 0);
    signal reg_write_data : std_logic_vector(15 downto 0);
    signal mem_addr : std_logic_vector(9 downto 0);
    signal mem_write_data : std_logic_vector(15 downto 0);

begin
    clock : process
    begin
        loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
    end process;

    dut : entity work.cpu
        generic map (init_file => "address_test.mif")
        port map (
            clk => clk, reset => reset, address_fault => fault,
            pc => pc, instruction => instruction, state => state,
            opcode => opcode, zero => zero, overflow => overflow,
            a => a, b => b, alu_result => alu_result, rdm => rdm,
            fetched => fetched, reg_write => reg_write,
            reg_write_addr => reg_write_addr, reg_write_data => reg_write_data,
            mem_write => mem_write, mem_addr => mem_addr,
            mem_write_data => mem_write_data
        );

    monitor : process
    begin
        wait until rising_edge(clk);
        if reset = '0' then
            if mem_write = '1' then
                assert scenario = 8 and mem_addr = "1111111111" and mem_write_data = x"A3FF"
                    report "escrita indevida/alias na RAM" severity failure;
                writes <= writes + 1;
            end if;
            if reg_write = '1' then
                if scenario = 1 then
                    assert false report "LD negativo escreveu no banco" severity failure;
                elsif scenario = 3 then
                    assert reg_write_addr /= "010" report "LD 0400 escreveu no banco" severity failure;
                elsif scenario = 8 and reg_write_addr = "010" then
                    assert reg_write_data = x"A3FF" report "leitura de 03FF falhou" severity failure;
                    loaded <= '1';
                end if;
            end if;
        end if;
    end process;

    stimulus : process
        variable stopped_pc : std_logic_vector(15 downto 0);
        variable stopped_state : std_logic_vector(3 downto 0);
        variable cycles : natural := 0;
        variable invalid_fetch : boolean;
        variable previous_fetched : std_logic_vector(15 downto 0);
    begin
        wait for 1 ns; reset <= '0';
        if scenario = 8 then
            for i in 1 to 80 loop
                wait until rising_edge(clk); wait for 1 ns;
                assert fault = '0' report "endereco valido causou falha" severity failure;
            end loop;
            assert writes = 1 and loaded = '1' report "limite valido nao exercitado" severity failure;
        else
            while fault /= '1' and cycles < 80 loop
                wait until rising_edge(clk);
                -- Amostra antes dos deltas da borda: uma leitura por alias
                -- mudaria fetched mesmo que o controle parasse em seguida.
                invalid_fetch := state = x"0" and unsigned(pc) > 1023;
                previous_fetched := fetched;
                wait for 1 ns;
                if invalid_fetch then
                    assert fetched = previous_fetched
                        report "busca invalida leu RAM por alias" severity failure;
                end if;
                cycles := cycles + 1;
            end loop;
            assert fault = '1' report "endereco invalido nao sinalizou falha" severity failure;
            stopped_pc := pc; stopped_state := state;
            for i in 1 to 12 loop
                wait until rising_edge(clk); wait for 1 ns;
                assert fault = '1' and pc = stopped_pc and state = stopped_state
                    and reg_write = '0' and mem_write = '0'
                    report "CPU nao permaneceu parada apos falha" severity failure;
            end loop;
            wait until falling_edge(clk); reset <= '1'; wait for 1 ns;
            assert fault = '0' and pc = x"0000" and state = x"0"
                report "reset nao limpou falha" severity failure;
            wait until falling_edge(clk); reset <= '0';
            wait until rising_edge(clk); wait for 1 ns;
            assert state = x"1" and fault = '0' report "CPU nao retomou apos reset" severity failure;
        end if;
        report "PASS: enderecamento, caso " & integer'image(scenario);
        finish;
    end process;
end architecture sim;
