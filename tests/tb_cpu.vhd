library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;

entity tb_cpu is
end entity tb_cpu;

architecture sim of tb_cpu is
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

    signal last_r4 : std_logic_vector(15 downto 0) := x"0000";
    signal store_count : natural := 0;
    signal last_r3 : std_logic_vector(15 downto 0) := x"0000";
    signal last_mem16 : std_logic_vector(15 downto 0) := x"0000";
begin
    clock : process
    begin
        loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
    end process;

    dut : entity work.cpu
        generic map (init_file => "cpu_test.mif")
        port map (
            clk => clk, reset => reset,
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
        if reset = '1' then
            last_r3 <= x"0000";
            last_r4 <= x"0000";
            last_mem16 <= x"0000";
            store_count <= 0;
        else
            if reg_write = '1' and reg_write_addr = "011" then
                last_r3 <= reg_write_data;
            end if;
            if reg_write = '1' and reg_write_addr = "100" then
                last_r4 <= reg_write_data;
            end if;
            if mem_write = '1' then
                assert mem_addr = "0000010000"
                    report "demo escreveu fora da area de dados (Mem[16])" severity failure;
                last_mem16 <= mem_write_data;
                store_count <= store_count + 1;
            end if;
        end if;
    end process;

    stimulus : process
        variable cycles : natural;
    begin
        for execution in 1 to 2 loop
            reset <= '1';
            wait until rising_edge(clk);
            wait until falling_edge(clk);
            assert pc = x"0000" and state = x"0" severity failure;
            reset <= '0';
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            wait for 1 ns;
            assert instruction = x"5203"
                report "reset encontrou codigo sobrescrito" severity failure;
            cycles := 0;
            while not (pc = x"0009" and instruction = x"A009" and state = x"0")
                  and cycles < 300 loop
                wait until rising_edge(clk); wait for 1 ns;
                cycles := cycles + 1;
            end loop;
            assert cycles < 300 report "timeout na demo" severity failure;
            assert last_r3 = x"0003" and last_r4 = x"0003"
                and last_mem16 = x"0003" and store_count = 1
                report "demo: soma, releitura ou numero de escritas incorreto" severity failure;
            wait until falling_edge(clk);
        end loop;
        report "PASS: demo executada duas vezes por reset, Mem[16]=R3=R4=3";
        finish;
    end process;
end architecture sim;
