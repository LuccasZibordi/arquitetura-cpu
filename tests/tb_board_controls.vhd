library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;

entity tb_board_controls is
    generic (filter_cycles : positive := 4);
end entity;

architecture test of tb_board_controls is
    signal clk : std_logic := '0';
    signal reset_n, step_n : std_logic := '0';
    signal run_async, rst, ce, running : std_logic := '0';
    signal ticks : natural := 0;
begin
    clk <= not clk after 5 ns;
    dut : entity work.board_controls
        generic map (debounce_cycles => filter_cycles)
        port map (clk, reset_n, step_n, run_async, rst, ce, running);
    process(clk)
    begin
        if rising_edge(clk) and ce = '1' then ticks <= ticks + 1; end if;
    end process;
    process
        variable before : natural;
        procedure cycles(n : positive) is
        begin
            for i in 1 to n loop wait until rising_edge(clk); wait for 1 ns; end loop;
        end procedure;
        procedure settle is
        begin cycles(filter_cycles + 8); end procedure;
    begin
        wait for 2 ns;
        assert rst = '1' and ce = '0' report "reset inicial" severity failure;
        reset_n <= '1';
        wait until rising_edge(clk); wait for 1 ns;
        assert rst = '1' report "reset liberado antes dos dois clocks" severity failure;
        cycles(1);
        assert rst = '0' report "reset nao liberou" severity failure;
        settle;
        assert ticks = 0 report "passo fantasma: botao mantido no reset" severity failure;
        step_n <= '1'; settle;
        before := ticks;
        -- Repique de uma amostra nao pode vencer filtro maior que um.
        if filter_cycles > 1 then
            step_n <= '0'; cycles(1); step_n <= '1'; settle;
            assert ticks = before report "repique gerou passo" severity failure;
        end if;
        if filter_cycles > 1 then
            run_async <= '1'; cycles(filter_cycles - 1); run_async <= '0'; settle;
            assert running = '0' and ticks = before
                report "repique do modo iniciou execucao" severity failure;
            step_n <= '0'; cycles(filter_cycles - 1); step_n <= '1'; settle;
            assert ticks = before report "pressao abaixo do limiar aceita" severity failure;
        end if;
        step_n <= '0'; settle;
        assert ticks = before + 1 report "pressao nao gerou exatamente um passo" severity failure;
        settle;
        assert ticks = before + 1 report "botao mantido repetiu passo" severity failure;
        if filter_cycles > 1 then
            step_n <= '1'; cycles(filter_cycles - 1); step_n <= '0'; settle;
            assert ticks = before + 1 report "repique de soltura rearmou passo" severity failure;
        end if;
        step_n <= '1'; settle; step_n <= '0'; settle;
        assert ticks = before + 2 report "segunda pressao perdida" severity failure;
        -- Continuo habilita cada ciclo; botao mantido nao gera passo ao sair.
        run_async <= '1'; settle;
        assert running = '1' and ce = '1' report "modo continuo nao entrou" severity failure;
        before := ticks; cycles(5);
        assert ticks = before + 5 report "continuo perdeu ciclos" severity failure;
        run_async <= '0'; settle;
        assert running = '0' and ce = '0' report "modo manual nao voltou" severity failure;
        before := ticks; settle;
        assert ticks = before report "passo fantasma na troca de modo" severity failure;
        step_n <= '1'; settle; step_n <= '0'; settle;
        assert ticks = before + 1 report "passo apos troca de modo" severity failure;
        run_async <= '1'; settle;
        -- Reset assertivo entre bordas bloqueia imediatamente a execucao.
        wait until falling_edge(clk); wait for 2 ns; reset_n <= '0'; wait for 1 ns;
        assert rst = '1' and ce = '0' report "reset nao assincrono/prioritario" severity failure;
        run_async <= '0'; cycles(3); before := ticks;
        reset_n <= '1'; settle;
        assert ticks = before report "passo fantasma apos segundo reset" severity failure;
        step_n <= '1'; settle; step_n <= '0'; settle;
        assert ticks = before + 1 report "nao retomou apos reset" severity failure;
        if filter_cycles > 1 then
            step_n <= '1'; settle; before := ticks;
            step_n <= '0'; cycles(filter_cycles);
            run_async <= '1'; cycles(1); run_async <= '0'; settle;
            assert running = '0' and ticks = before + 1
                report "repique de modo descartou passo valido" severity failure;
        end if;
        report "PASS: controles, debounce=" & integer'image(filter_cycles);
        finish;
    end process;
end architecture;
