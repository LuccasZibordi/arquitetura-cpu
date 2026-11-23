library ieee;
use ieee.std_logic_1164.all;

entity top_de2_115 is
    generic (init_file : string := "cpu_test.mif";
             debounce_cycles : positive := 500000);
    port (
        CLOCK_50 : in std_logic;
        KEY : in std_logic_vector(3 downto 0);
        SW : in std_logic_vector(17 downto 0);
        LEDR : out std_logic_vector(17 downto 0);
        LEDG : out std_logic_vector(8 downto 0);
        HEX0 : out std_logic_vector(6 downto 0);
        HEX1 : out std_logic_vector(6 downto 0);
        HEX2 : out std_logic_vector(6 downto 0);
        HEX3 : out std_logic_vector(6 downto 0);
        HEX4 : out std_logic_vector(6 downto 0);
        HEX5 : out std_logic_vector(6 downto 0);
        HEX6 : out std_logic_vector(6 downto 0);
        HEX7 : out std_logic_vector(6 downto 0)
    );
end entity;
architecture rtl of top_de2_115 is
    signal reset_s, enable_s, running_s, fault_s, zero_s, overflow_s : std_logic;
    signal reg_write_s, mem_write_s : std_logic;
    signal pc_s, ir_s, a_s, b_s, alu_s, rdm_s, fetched_s, wb_s, view_s : std_logic_vector(15 downto 0);
    signal state_s : std_logic_vector(3 downto 0);
    signal address_s : std_logic_vector(9 downto 0);
    signal select_meta, select_sync : std_logic_vector(2 downto 0) := "000";
    -- HEX[6:0] = g,f,e,d,c,b,a; zero acende o segmento.
    function seven_segment(n : std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        case n is
            when x"0" => return "1000000";
            when x"1" => return "1111001";
            when x"2" => return "0100100";
            when x"3" => return "0110000";
            when x"4" => return "0011001";
            when x"5" => return "0010010";
            when x"6" => return "0000010";
            when x"7" => return "1111000";
            when x"8" => return "0000000";
            when x"9" => return "0010000";
            when x"A" => return "0001000";
            when x"B" => return "0000011";
            when x"C" => return "1000110";
            when x"D" => return "0100001";
            when x"E" => return "0000110";
            when x"F" => return "0001110";
            when others => return "1111111";
        end case;
    end;
begin
    controls : entity work.board_controls
        generic map (debounce_cycles => debounce_cycles)
        port map (clk => CLOCK_50, reset_n => KEY(0), step_n => KEY(1),
                  run_async => SW(0), cpu_reset => reset_s,
                  clock_enable => enable_s, running => running_s);
    processor : entity work.cpu
        generic map (init_file => init_file)
        port map (clk => CLOCK_50, reset => reset_s, clock_enable => enable_s,
            address_fault => fault_s, pc => pc_s, instruction => ir_s,
            state => state_s, opcode => open, zero => zero_s, overflow => overflow_s,
            a => a_s, b => b_s, alu_result => alu_s, rdm => rdm_s, fetched => fetched_s,
            reg_write => reg_write_s, reg_write_addr => open, reg_write_data => wb_s,
            mem_write => mem_write_s, mem_addr => address_s, mem_write_data => open);
    process(CLOCK_50, reset_s)
    begin
        if reset_s = '1' then
            select_meta <= "000";
            select_sync <= "000";
        elsif rising_edge(CLOCK_50) then
            select_meta <= SW(3 downto 1);
            select_sync <= select_meta;
        end if;
    end process;
    with select_sync select view_s <=
        ir_s when "000", a_s when "001", b_s when "010", alu_s when "011",
        rdm_s when "100", fetched_s when "101", wb_s when "110",
        "000000" & address_s when others;
    LEDR <= fault_s & reset_s & view_s;
    LEDG <= mem_write_s & reg_write_s & running_s & overflow_s & zero_s & state_s;
    HEX0 <= seven_segment(view_s(3 downto 0));
    HEX1 <= seven_segment(view_s(7 downto 4));
    HEX2 <= seven_segment(view_s(11 downto 8));
    HEX3 <= seven_segment(view_s(15 downto 12));
    HEX4 <= seven_segment(pc_s(3 downto 0));
    HEX5 <= seven_segment(pc_s(7 downto 4));
    HEX6 <= seven_segment(pc_s(11 downto 8));
    HEX7 <= seven_segment(pc_s(15 downto 12));
end architecture;
