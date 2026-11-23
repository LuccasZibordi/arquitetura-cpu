library ieee;
use ieee.std_logic_1164.all;

-- Decodificacao puramente combinacional do opcode da ISA. As decisoes que
-- dependem de estado ou de flags ficam na unidade de controle.
entity decoder is
    port (
        opcode         : in  std_logic_vector(3 downto 0);
        alu_op         : out std_logic_vector(2 downto 0);
        alu_b_sel      : out std_logic; -- 0 = reg_b, 1 = imediato
        read_addr2_sel : out std_logic; -- 0 = Rk, 1 = Ri
        wb_sel         : out std_logic; -- 0 = ULA, 1 = RDM
        is_invalid     : out std_logic;
        is_branch      : out std_logic;
        is_load        : out std_logic;
        is_store       : out std_logic;
        is_jump        : out std_logic;
        branch_on_zero : out std_logic -- 1 = BEQ, 0 = BNE
    );
end entity decoder;

architecture rtl of decoder is
begin
    process(all)
    begin
        alu_op <= "000";
        alu_b_sel <= '0';
        read_addr2_sel <= '0';
        wb_sel <= '0';
        is_invalid <= '0';
        is_branch <= '0';
        is_load <= '0';
        is_store <= '0';
        is_jump <= '0';
        branch_on_zero <= '0';

        case opcode is
            when "0000" => alu_op <= "000"; -- ADD
            when "0001" => alu_op <= "001"; -- SUB
            when "0010" => alu_op <= "010"; -- AND
            when "0011" => alu_op <= "011"; -- OR
            when "0100" => alu_op <= "100"; -- SLT
            when "0101" =>                 -- ADDI
                alu_b_sel <= '1';
                read_addr2_sel <= '1';
            when "0110" =>                 -- LD
                alu_b_sel <= '1';
                read_addr2_sel <= '1';
                wb_sel <= '1';
                is_load <= '1';
            when "0111" =>                 -- ST
                alu_b_sel <= '1';
                read_addr2_sel <= '1';
                is_store <= '1';
            when "1000" =>                 -- BEQ
                alu_op <= "001";
                read_addr2_sel <= '1';
                is_branch <= '1';
                branch_on_zero <= '1';
            when "1001" =>                 -- BNE
                alu_op <= "001";
                read_addr2_sel <= '1';
                is_branch <= '1';
            when "1010" => is_jump <= '1'; -- JMP
            when others => is_invalid <= '1';
        end case;
    end process;
end architecture rtl;
