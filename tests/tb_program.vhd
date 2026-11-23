library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;

entity tb_program is
    generic (
        program : integer := 1
    );
end entity tb_program;

architecture sim of tb_program is
    type regs_t is array (0 to 7) of std_logic_vector(15 downto 0);

    function program_file(p : integer) return string is
    begin
        case p is
            when 1 => return "p1_arith.mif";
            when 2 => return "p2_limit.mif";
            when 3 => return "p3_mem.mif";
            when 4 => return "p4_r0_jump.mif";
            when others => return "p1_arith.mif";
        end case;
    end function;

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

    signal seen_regs : regs_t := (others => x"0000");
    signal last_mem_addr : std_logic_vector(9 downto 0) := (others => '0');
    signal last_mem_data : std_logic_vector(15 downto 0) := x"0000";
begin
    clock : process
    begin
        loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
    end process;

    dut : entity work.cpu
        generic map (init_file => program_file(program))
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
        if reset = '0' then
            if reg_write = '1' and reg_write_addr /= "000" then
                seen_regs(to_integer(unsigned(reg_write_addr))) <= reg_write_data;
            end if;
            if mem_write = '1' then
                last_mem_addr <= mem_addr;
                last_mem_data <= mem_write_data;
            end if;
        end if;
    end process;

    stimulus : process
        variable exp_regs : regs_t := (others => x"0000");
        variable exp_pc : std_logic_vector(15 downto 0) := x"0000";
        variable cycles : integer := 0;
    begin
        case program is
            when 1 =>
                exp_regs := (x"0000", x"0007", x"FFFF", x"0006", x"0008",
                             x"0007", x"FFFF", x"0001");
                exp_pc := x"0007";
            when 2 =>
                exp_regs := (x"0000", x"FFE0", x"001F", x"FFFF", x"001F",
                             x"003E", x"FFFF", x"0000");
                exp_pc := x"0007";
            when 3 =>
                exp_regs := (x"0000", x"7FFF", x"0001", x"8000", x"8000",
                             x"0000", x"0000", x"0000");
                exp_pc := x"0005";
            when 4 =>
                exp_regs := (x"0000", x"0003", x"0003", x"0000", x"0000",
                             x"0000", x"0000", x"0000");
                exp_pc := x"0007";
            when others =>
                assert false report "programa desconhecido" severity failure;
        end case;

        wait for 1 ns;
        assert pc = x"0000" and state = x"0"
            report "reset nao levou ao estado inicial" severity failure;
        reset <= '0';

        while (pc /= exp_pc or seen_regs /= exp_regs) and cycles < 500 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            cycles := cycles + 1;
        end loop;

        for i in 1 to 3 loop
            wait until rising_edge(clk);
            wait for 1 ns;
        end loop;

        assert cycles < 500
            report "timeout no programa " & integer'image(program) &
                   " pc=" & to_hstring(pc) & " ciclos=" & integer'image(cycles)
            severity failure;
        assert pc = exp_pc
            report "PC final errado no programa " & integer'image(program) &
                   ": " & to_hstring(pc) severity failure;
        assert seen_regs = exp_regs
            report "registradores finais errados no programa " & integer'image(program)
            severity failure;

        if program = 3 then
            assert last_mem_addr = "0000010001" and last_mem_data = x"8000"
                report "Mem[17] final errado: addr=" & to_hstring(last_mem_addr) &
                       " dado=" & to_hstring(last_mem_data)
                severity failure;
        else
            assert last_mem_data = x"0000"
                report "programa " & integer'image(program) & " gravou na memoria"
                severity failure;
        end if;

        report "PASS: programa " & integer'image(program) & " (" &
               program_file(program) & "), " & integer'image(cycles) & " ciclos"
            severity note;
        finish;
    end process;
end architecture sim;
