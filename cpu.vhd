library ieee;
use ieee.std_logic_1164.all;

-- CPU completa: unidade de controle + caminho de dados. A memoria esta dentro
-- do datapath e e inicializada pelo MIF informado no generic.
entity cpu is
    generic (
        init_file : string := "cpu_test.mif"
    );
    port (
        clk, reset : in std_logic;

        -- Observacao da execucao
        pc          : out std_logic_vector(15 downto 0);
        instruction : out std_logic_vector(15 downto 0);
        state       : out std_logic_vector(3 downto 0);
        opcode      : out std_logic_vector(3 downto 0);
        zero        : out std_logic;
        overflow    : out std_logic;
        a, b        : out std_logic_vector(15 downto 0);
        alu_result  : out std_logic_vector(15 downto 0);
        rdm         : out std_logic_vector(15 downto 0);
        fetched     : out std_logic_vector(15 downto 0);
        reg_write   : out std_logic;
        reg_write_addr : out std_logic_vector(2 downto 0);
        reg_write_data : out std_logic_vector(15 downto 0);
        mem_write   : out std_logic;
        mem_addr    : out std_logic_vector(9 downto 0);
        mem_write_data : out std_logic_vector(15 downto 0)
    );
end entity cpu;

architecture rtl of cpu is
    signal pc_write_c, ir_write_c, reg_write_c : std_logic;
    signal reg_a_write_c, reg_b_write_c, alu_out_write_c : std_logic;
    signal rem_write_c, rdm_write_c : std_logic;
    signal mem_read_c, mem_write_c : std_logic;
    signal alu_op_c : std_logic_vector(2 downto 0);
    signal read_addr2_sel_c, alu_b_sel_c, mem_addr_sel_c, wb_sel_c : std_logic;
    signal pc_sel_c : std_logic_vector(1 downto 0);

    signal opcode_s, state_s : std_logic_vector(3 downto 0);
    signal zero_s, overflow_s : std_logic;
    signal pc_s, instruction_s, a_s, b_s, alu_s, rdm_s, fetched_s : std_logic_vector(15 downto 0);
    signal reg_data_s : std_logic_vector(15 downto 0);
    signal reg_sel_s : std_logic_vector(2 downto 0);
    signal mem_addr_s : std_logic_vector(9 downto 0);
    signal mem_word_s : std_logic_vector(15 downto 0);
begin
    datapath_unit : entity work.datapath
        generic map (init_file => init_file)
        port map (
            clk => clk, reset => reset,
            pc_write => pc_write_c, ir_write => ir_write_c, reg_write => reg_write_c,
            reg_a_write => reg_a_write_c, reg_b_write => reg_b_write_c,
            alu_out_write => alu_out_write_c, rem_write => rem_write_c,
            rdm_write => rdm_write_c, mem_read => mem_read_c, mem_write => mem_write_c,
            alu_op => alu_op_c, read_addr2_sel => read_addr2_sel_c,
            alu_b_sel => alu_b_sel_c, mem_addr_sel => mem_addr_sel_c,
            pc_sel => pc_sel_c, wb_sel => wb_sel_c,
            opcode => opcode_s, zero => zero_s, overflow => overflow_s,
            pc_out => pc_s, instruction => instruction_s,
            a_out => a_s, b_out => b_s, alu_result => alu_s,
            rdm_out => rdm_s, fetched_word => fetched_s,
            reg_write_addr => reg_sel_s, reg_write_data => reg_data_s,
            mem_addr => mem_addr_s, mem_write_data => mem_word_s
        );

    control : entity work.control_unit
        port map (
            clk => clk, reset => reset, opcode => opcode_s, zero => zero_s,
            pc_write => pc_write_c, ir_write => ir_write_c, reg_write => reg_write_c,
            reg_a_write => reg_a_write_c, reg_b_write => reg_b_write_c,
            alu_out_write => alu_out_write_c, rem_write => rem_write_c,
            rdm_write => rdm_write_c, mem_read => mem_read_c, mem_write => mem_write_c,
            alu_op => alu_op_c, read_addr2_sel => read_addr2_sel_c,
            alu_b_sel => alu_b_sel_c, mem_addr_sel => mem_addr_sel_c,
            pc_sel => pc_sel_c, wb_sel => wb_sel_c, state_out => state_s
        );

    pc <= pc_s;
    instruction <= instruction_s;
    state <= state_s;
    opcode <= opcode_s;
    zero <= zero_s;
    overflow <= overflow_s;
    a <= a_s;
    b <= b_s;
    alu_result <= alu_s;
    rdm <= rdm_s;
    fetched <= fetched_s;
    reg_write <= reg_write_c;
    reg_write_addr <= reg_sel_s;
    reg_write_data <= reg_data_s;
    mem_write <= mem_write_c;
    mem_addr <= mem_addr_s;
    mem_write_data <= mem_word_s;
end architecture rtl;
