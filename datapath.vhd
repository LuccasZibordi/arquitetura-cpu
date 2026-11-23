library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Caminho de dados da CPU de 16 bits. Os sinais de controle entram pela porta
-- e serao gerados pela unidade de controle; opcode/zero/overflow sao devolvidos
-- para que a controle possa decidir o proximo estado.
entity datapath is
    generic (
        init_file : string := "memory_test.mif"
    );
    port (
        clk   : in std_logic;
        reset : in std_logic;
        address_fault : out std_logic := '0';

        pc_write, ir_write, reg_write : in std_logic;
        reg_a_write, reg_b_write, alu_out_write : in std_logic;
        rem_write, rdm_write : in std_logic;
        mem_read, mem_write : in std_logic;

        alu_op         : in std_logic_vector(2 downto 0);
        read_addr2_sel : in std_logic; -- 0 = Rk, 1 = Ri
        alu_b_sel      : in std_logic; -- 0 = reg_b, 1 = imediato
        mem_addr_sel   : in std_logic; -- 0 = PC, 1 = REM
        pc_sel         : in std_logic_vector(1 downto 0); -- 00 = PC+1, 01 = desvio, 10 = JMP
        wb_sel         : in std_logic; -- 0 = ULA, 1 = RDM

        opcode : out std_logic_vector(3 downto 0);
        zero, overflow : out std_logic;
        pc_out, instruction, a_out, b_out, alu_result : out std_logic_vector(15 downto 0);
        rdm_out, fetched_word : out std_logic_vector(15 downto 0);
        reg_write_addr : out std_logic_vector(2 downto 0);
        reg_write_data : out std_logic_vector(15 downto 0);
        mem_addr : out std_logic_vector(9 downto 0);
        mem_write_data : out std_logic_vector(15 downto 0)
    );
end entity datapath;

architecture rtl of datapath is
    signal fault_latched : std_logic := '0';
    signal invalid_address, run_ok : std_logic;
    signal pc_current, pc_plus_one, branch_target, jmp_target, pc_next : std_logic_vector(15 downto 0);
    signal instruction_word : std_logic_vector(15 downto 0) := (others => '0');
    signal mem_address, rem_address : std_logic_vector(9 downto 0);
    signal mem_data, store_data : std_logic_vector(15 downto 0);
    signal ri, rj, rk, addr2 : std_logic_vector(2 downto 0) := (others => '0');
    signal imm16 : std_logic_vector(15 downto 0);
    signal read1, read2 : std_logic_vector(15 downto 0);
    signal a_value, b_value, alu_b, alu_s, out_value, rdm_value, wb_value : std_logic_vector(15 downto 0);
begin
    -- Verifica os 16 bits ANTES de truncar para a porta fisica da RAM.
    -- O controle recebe somente a falha registrada: nao ha realimentacao
    -- combinacional entre fault e os enables que originam a verificacao.
    invalid_address <= '1' when
        (mem_read = '1' and mem_addr_sel = '0' and pc_current(15 downto 10) /= "000000") or
        (rem_write = '1' and alu_s(15 downto 10) /= "000000") else '0';
    run_ok <= not (fault_latched or invalid_address or reset);
    address_fault <= fault_latched;

    process(clk, reset)
    begin
        if reset = '1' then
            fault_latched <= '0';
        elsif rising_edge(clk) then
            if invalid_address = '1' then
                fault_latched <= '1';
            end if;
        end if;
    end process;

    opcode <= instruction_word(15 downto 12);
    ri <= instruction_word(11 downto 9);
    rj <= instruction_word(8 downto 6);
    rk <= instruction_word(5 downto 3);
    addr2 <= ri when read_addr2_sel = '1' else rk;

    -- PC ja aponta para a instrucao seguinte quando o desvio e calculado.
    pc_plus_one <= std_logic_vector(unsigned(pc_current) + 1);
    branch_target <= std_logic_vector(unsigned(pc_current) + unsigned(imm16));
    jmp_target <= x"0" & instruction_word(11 downto 0);
    pc_next <= branch_target when pc_sel = "01" else
               jmp_target   when pc_sel = "10" else
               pc_plus_one;

    mem_address <= pc_current(9 downto 0) when mem_addr_sel = '0' else rem_address;
    store_data <= b_value;
    alu_b <= imm16 when alu_b_sel = '1' else b_value;
    wb_value <= rdm_value when wb_sel = '1' else out_value;

    pc_unit : entity work.PC
        port map (clk => clk, reset => reset, pc_write => (pc_write and run_ok),
                  next_pc => pc_next, pc_out => pc_current);

    ir_unit : entity work.instruction_register
        port map (clk => clk, reset => reset, ir_write => (ir_write and run_ok),
                  instruction_in => mem_data, instruction_out => instruction_word);

    ram : entity work.memory
        generic map (init_file => init_file)
        port map (clk => clk, read_enable => (mem_read and run_ok), write_enable => (mem_write and run_ok),
                  address => mem_address, data_in => store_data, data_out => mem_data);

    regs : entity work.register_file
        port map (clk => clk, reset => reset, reg_write => (reg_write and run_ok),
                  read_addr1 => rj, read_addr2 => addr2, write_addr => ri,
                  write_data => wb_value, read_data1 => read1, read_data2 => read2);

    extender : entity work.immediate_extender
        port map (immediate_in => instruction_word(5 downto 0), immediate_out => imm16);

    reg_a_unit : entity work.reg_a
        port map (clk => clk, reset => reset, write_enable => (reg_a_write and run_ok),
                  data_in => read1, data_out => a_value);

    reg_b_unit : entity work.reg_b
        port map (clk => clk, reset => reset, write_enable => (reg_b_write and run_ok),
                  data_in => read2, data_out => b_value);

    alu_unit : entity work.alu
        port map (A => a_value, B => alu_b, Op => alu_op,
                  S => alu_s, Zero => zero, Overflow => overflow);

    alu_out_unit : entity work.alu_out
        port map (clk => clk, reset => reset, write_enable => (alu_out_write and run_ok),
                  data_in => alu_s, data_out => out_value);

    rem_unit : entity work.memory_address_register
        port map (clk => clk, reset => reset, write_enable => (rem_write and run_ok),
                  data_in => alu_s(9 downto 0), data_out => rem_address);

    rdm_unit : entity work.memory_data_register
        port map (clk => clk, reset => reset, write_enable => (rdm_write and run_ok),
                  data_in => mem_data, data_out => rdm_value);

    pc_out <= pc_current;
    instruction <= instruction_word;
    a_out <= a_value;
    b_out <= b_value;
    alu_result <= out_value;
    rdm_out <= rdm_value;
    fetched_word <= mem_data;
    reg_write_addr <= ri;
    reg_write_data <= wb_value;
    mem_addr <= mem_address;
    mem_write_data <= store_data;
end architecture rtl;
