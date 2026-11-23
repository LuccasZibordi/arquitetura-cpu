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

    signal last_r3 : std_logic_vector(15 downto 0) := x"0000";
    signal last_mem0 : std_logic_vector(15 downto 0) := x"0000";
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

    -- Registra a ultima escrita em R3 e na palavra 0 da memoria.
    monitor : process
    begin
        wait until rising_edge(clk);
        if reset = '0' then
            if reg_write = '1' and reg_write_addr = "011" then
                last_r3 <= reg_write_data;
            end if;
            if mem_write = '1' and mem_addr = "0000000000" then
                last_mem0 <= mem_write_data;
            end if;
        end if;
    end process;

    stimulus : process
        variable cycles : integer := 0;
    begin
        wait for 1 ns;
        assert pc = x"0000" and state = x"0"
            report "reset nao levou ao estado inicial" severity failure;
        reset <= '0';

        while (last_mem0 = x"0000" or pc /= x"0008" or instruction /= x"A008")
              and cycles < 300 loop
            wait until rising_edge(clk);
            cycles := cycles + 1;
        end loop;
        wait for 1 ns;

        assert cycles < 300
            report "programa nao terminou: pc=" & to_hstring(pc) & " ciclos=" & integer'image(cycles)
            severity failure;
        assert pc = x"0008"
            report "PC final diferente de 0008" severity failure;
        assert instruction = x"A008"
            report "IR final nao contem o JMP 8" severity failure;
        assert last_r3 = x"0003"
            report "R3 final diferente de 3: " & to_hstring(last_r3) severity failure;
        assert last_mem0 = x"0003"
            report "Mem[0] final diferente de 3: " & to_hstring(last_mem0) severity failure;

        report "PASS: cpu integrada (demo desde o reset, PC=0008, R3=3, Mem[0]=3)"
            severity note;
        finish;
    end process;
end architecture sim;
