library ieee;
use ieee.std_logic_1164.all;

-- Unidade de controle da CPU. Gera os enables e seletores do datapath.
-- A decodificacao estatica do opcode esta em decoder.vhd.
entity control_unit is
    port (
        clk, reset : in std_logic;
        opcode     : in std_logic_vector(3 downto 0);
        zero       : in std_logic;

        pc_write, ir_write, reg_write : out std_logic;
        reg_a_write, reg_b_write, alu_out_write : out std_logic;
        rem_write, rdm_write : out std_logic;
        mem_read, mem_write : out std_logic;
        alu_op         : out std_logic_vector(2 downto 0);
        read_addr2_sel : out std_logic;
        alu_b_sel      : out std_logic;
        mem_addr_sel   : out std_logic;
        pc_sel         : out std_logic_vector(1 downto 0);
        wb_sel         : out std_logic;
        state_out      : out std_logic_vector(3 downto 0)
    );
end entity control_unit;

architecture rtl of control_unit is
    type state_t is (FETCH0, FETCH1, DECODE, EXEC, ADDR,
                     READ_MEM, LATCH_RDM, WRITE_MEM, CMP, WB);
    signal state : state_t := FETCH0;
    signal next_state : state_t;

    signal dec_alu_op : std_logic_vector(2 downto 0);
    signal dec_alu_b_sel, dec_read_addr2_sel, dec_wb_sel : std_logic;
    signal dec_is_invalid, dec_is_branch, dec_is_load, dec_is_store : std_logic;
    signal dec_is_jump, dec_branch_on_zero : std_logic;
begin
    decoder_unit : entity work.decoder
        port map (
            opcode => opcode,
            alu_op => dec_alu_op,
            alu_b_sel => dec_alu_b_sel,
            read_addr2_sel => dec_read_addr2_sel,
            wb_sel => dec_wb_sel,
            is_invalid => dec_is_invalid,
            is_branch => dec_is_branch,
            is_load => dec_is_load,
            is_store => dec_is_store,
            is_jump => dec_is_jump,
            branch_on_zero => dec_branch_on_zero
        );

    sequencial : process(clk, reset)
    begin
        if reset = '1' then
            state <= FETCH0;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    combinacional : process(all)
    begin
        pc_write <= '0';
        ir_write <= '0';
        reg_write <= '0';
        reg_a_write <= '0';
        reg_b_write <= '0';
        alu_out_write <= '0';
        rem_write <= '0';
        rdm_write <= '0';
        mem_read <= '0';
        mem_write <= '0';
        alu_op <= "000";
        read_addr2_sel <= '0';
        alu_b_sel <= '0';
        mem_addr_sel <= '0';
        pc_sel <= "00";
        wb_sel <= '0';
        next_state <= FETCH0;

        case state is
            when FETCH0 =>
                -- A RAM entrega a palavra so na proxima borda.
                mem_read <= '1';
                next_state <= FETCH1;

            when FETCH1 =>
                ir_write <= '1';
                pc_write <= '1';
                next_state <= DECODE;

            when DECODE =>
                read_addr2_sel <= dec_read_addr2_sel;
                if dec_is_invalid = '0' and dec_is_jump = '0' then
                    reg_a_write <= '1';
                    reg_b_write <= '1';
                end if;
                if dec_is_jump = '1' then
                    pc_write <= '1';
                    pc_sel <= "10";
                    next_state <= FETCH0;
                elsif dec_is_invalid = '1' then
                    -- Instrucao ignorada: o PC ja avancou em FETCH1.
                    next_state <= FETCH0;
                elsif dec_is_branch = '1' then
                    next_state <= CMP;
                elsif dec_is_load = '1' or dec_is_store = '1' then
                    next_state <= ADDR;
                else
                    next_state <= EXEC;
                end if;

            when EXEC =>
                alu_op <= dec_alu_op;
                alu_b_sel <= dec_alu_b_sel;
                alu_out_write <= '1';
                next_state <= WB;

            when ADDR =>
                alu_op <= dec_alu_op;
                alu_b_sel <= dec_alu_b_sel;
                alu_out_write <= '1';
                rem_write <= '1';
                if dec_is_load = '1' then
                    next_state <= READ_MEM;
                else
                    next_state <= WRITE_MEM;
                end if;

            when READ_MEM =>
                mem_read <= '1';
                mem_addr_sel <= '1';
                next_state <= LATCH_RDM;

            when LATCH_RDM =>
                rdm_write <= '1';
                next_state <= WB;

            when WRITE_MEM =>
                mem_write <= '1';
                mem_addr_sel <= '1';
                next_state <= FETCH0;

            when CMP =>
                alu_op <= dec_alu_op;
                alu_b_sel <= dec_alu_b_sel;
                -- alu_op = SUB e alu_b_sel = 0 vem do decoder; mantidos aqui
                -- para que zero continue refletindo a comparacao de A e B.
                if zero = dec_branch_on_zero then
                    pc_write <= '1';
                    pc_sel <= "01";
                end if;
                next_state <= FETCH0;

            when WB =>
                wb_sel <= dec_wb_sel;
                reg_write <= '1';
                next_state <= FETCH0;
        end case;
    end process;

    state_out <= x"0" when state = FETCH0  else
                 x"1" when state = FETCH1  else
                 x"2" when state = DECODE  else
                 x"3" when state = EXEC    else
                 x"4" when state = ADDR    else
                 x"5" when state = READ_MEM else
                 x"6" when state = LATCH_RDM else
                 x"7" when state = WRITE_MEM else
                 x"8" when state = CMP     else
                 x"9";
end architecture rtl;
