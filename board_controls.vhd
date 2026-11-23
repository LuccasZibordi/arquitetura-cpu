library ieee;
use ieee.std_logic_1164.all;

entity board_controls is
    generic (debounce_cycles : positive := 500000);
    port (
        clk : in std_logic;
        reset_n, step_n, run_async : in std_logic;
        cpu_reset, clock_enable, running : out std_logic
    );
end entity;

architecture rtl of board_controls is
    signal reset_pipe : std_logic_vector(1 downto 0) := "11";
    signal reset_s : std_logic;
    -- Bit 0: step_n; bit 1: run_async. Inicializar step como pressionado
    -- impede passo fantasma quando o usuario segura o botao durante reset.
    signal meta, synced, filtered : std_logic_vector(1 downto 0) := "00";
    signal previous_step, previous_run, armed, step_pulse : std_logic := '0';
begin
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            reset_pipe <= "11";
        elsif rising_edge(clk) then
            reset_pipe <= reset_pipe(0) & '0';
        end if;
    end process;
    reset_s <= reset_pipe(1);
    cpu_reset <= reset_s;

    process(clk, reset_s)
    begin
        if reset_s = '1' then
            meta <= "00";
            synced <= "00";
        elsif rising_edge(clk) then
            meta <= run_async & step_n;
            synced <= meta;
        end if;
    end process;

    filters : for i in 0 to 1 generate
        signal count : natural range 0 to debounce_cycles - 1 := 0;
    begin
        process(clk, reset_s)
        begin
            if reset_s = '1' then
                filtered(i) <= '0';
                count <= 0;
            elsif rising_edge(clk) then
                if synced(i) = filtered(i) then
                    count <= 0;
                elsif count = debounce_cycles - 1 then
                    filtered(i) <= synced(i);
                    count <= 0;
                else
                    count <= count + 1;
                end if;
            end if;
        end process;
    end generate;

    process(clk, reset_s)
    begin
        if reset_s = '1' then
            previous_step <= '0';
            previous_run <= '0';
            armed <= '0';
            step_pulse <= '0';
        elsif rising_edge(clk) then
            previous_step <= filtered(0);
            previous_run <= filtered(1);
            step_pulse <= '0';
            if filtered(1) = '1' or filtered(1) /= previous_run then
                armed <= '0';
            elsif filtered(0) = '1' and synced(0) = '1' then
                armed <= '1';
            elsif filtered(0) = '0' and previous_step = '1' then
                if armed = '1' then
                    step_pulse <= '1';
                end if;
                armed <= '0';
            end if;
        end if;
    end process;

    running <= filtered(1) and not reset_s;
    clock_enable <= (filtered(1) or step_pulse) and not reset_s;
end architecture;
