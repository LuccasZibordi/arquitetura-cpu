library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_alu_registers is end entity;
architecture test of tb_alu_registers is
    signal clk, reset : std_logic := '0';
    signal wa, wb, wo : std_logic := '0';
    signal da, db, qa, qb, result, saved : std_logic_vector(15 downto 0) := (others => '0');
    signal op : std_logic_vector(2 downto 0) := "000";
    signal zero, overflow : std_logic;
begin
    ra : entity work.reg_a port map (clk, reset, wa, da, qa);
    rb : entity work.reg_b port map (clk, reset, wb, db, qb);
    unit_alu : entity work.alu port map (qa, qb, op, result, zero, overflow);
    ro : entity work.alu_out port map (clk, reset, wo, result, saved);
    stimulus : process
        procedure check(a, b, output_value : std_logic_vector(15 downto 0)) is
        begin
            wait for 1 ns;
            assert qa = a report "reg_a incorreto" severity failure;
            assert qb = b report "reg_b incorreto" severity failure;
            assert saved = output_value report "alu_out incorreto: esperado=" & to_hstring(output_value) & " obtido=" & to_hstring(saved) severity failure;
        end procedure;
        procedure tick is
        begin
            -- Give the combinational ALU time to settle before sampling.
            wait for 1 ns;
            clk <= '1'; wait for 1 ns;
            clk <= '0'; wait for 1 ns;
        end procedure;
    begin
        reset <= '1'; check(x"0000", x"0000", x"0000");
        reset <= '0';
        da <= x"0007"; db <= x"0003"; wa <= '1'; wb <= '1';
        check(x"0000", x"0000", x"0000");
        tick; check(x"0007", x"0003", x"0000");
        wa <= '0'; wb <= '0'; wo <= '1';
        tick; check(x"0007", x"0003", x"000A");
        -- All enabled: result register captures the PREVIOUS operands' result.
        da <= x"FFFF"; db <= x"0001"; wa <= '1'; wb <= '1';
        tick; check(x"FFFF", x"0001", x"000A");
        wa <= '0'; wb <= '0';
        tick; check(x"FFFF", x"0001", x"0000");
        -- Independent enables and high/low bits preserved.
        wo <= '0'; wa <= '1'; da <= x"A53C"; db <= x"5555";
        tick; check(x"A53C", x"0001", x"0000");
        wa <= '0'; wb <= '1'; db <= x"5AC3";
        tick; check(x"A53C", x"5AC3", x"0000");
        wb <= '0'; wo <= '1'; op <= "011";
        tick; check(x"A53C", x"5AC3", x"FFFF");
        -- Disabled registers retain data over multiple cycles, inputs and op change.
        wo <= '0'; da <= x"1234"; db <= x"4321"; op <= "010";
        tick; tick; check(x"A53C", x"5AC3", x"FFFF");
        -- Enabling while clock is high is not an edge.
        clk <= '1'; wait for 1 ns;
        wa <= '1'; wb <= '1'; wo <= '1';
        check(x"A53C", x"5AC3", x"FFFF");
        clk <= '0'; check(x"A53C", x"5AC3", x"FFFF");
        tick; check(x"1234", x"4321", x"0000");
        op <= "011"; tick; check(x"1234", x"4321", x"5335");
        -- Asynchronous reset without enables, then priority with all enabled.
        wa <= '0'; wb <= '0'; wo <= '0'; reset <= '1';
        check(x"0000", x"0000", x"0000");
        wa <= '1'; wb <= '1'; wo <= '1'; da <= x"7FFF"; db <= x"0001";
        tick; check(x"0000", x"0000", x"0000");
        reset <= '0'; op <= "000";
        check(x"0000", x"0000", x"0000");
        tick; check(x"7FFF", x"0001", x"0000");
        assert overflow = '1' and zero = '0' report "Flags do resultado atual incorretas" severity failure;
        wa <= '0'; wb <= '0'; tick;
        check(x"7FFF", x"0001", x"8000");
        report "PASS: reg_a, reg_b, alu_out (bordas, enables, reset e caminho integrado)" severity note;
        finish;
    end process;
end architecture;
