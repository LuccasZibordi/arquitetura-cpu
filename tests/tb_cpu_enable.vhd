library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;

entity tb_cpu_enable is
    generic (init_file : string := "cpu_test.mif"; expect_fault : boolean := false);
end entity;

architecture test of tb_cpu_enable is
    type observed_t is record
        pc, instruction, a, b, alu_result, rdm, fetched : std_logic_vector(15 downto 0);
        reg_data, mem_data : std_logic_vector(15 downto 0);
        state, opcode : std_logic_vector(3 downto 0);
        reg_addr : std_logic_vector(2 downto 0);
        mem_addr : std_logic_vector(9 downto 0);
        zero, overflow, fault : std_logic;
    end record;
    type observations_t is array (natural range <>) of observed_t;
    signal observed : observations_t(0 to 1);
    signal reset : std_logic_vector(0 to 1) := "11";
    signal enable : std_logic_vector(0 to 1) := "10";
    signal reg_write, mem_write : std_logic_vector(0 to 1);
    signal clk : std_logic := '0';
begin
    clk <= not clk after 5 ns;
    cpus : for i in 0 to 1 generate
        dut : entity work.cpu
            generic map (init_file => init_file)
            port map (
                clk => clk, reset => reset(i), clock_enable => enable(i),
                address_fault => observed(i).fault,
                pc => observed(i).pc, instruction => observed(i).instruction,
                state => observed(i).state, opcode => observed(i).opcode,
                zero => observed(i).zero, overflow => observed(i).overflow,
                a => observed(i).a, b => observed(i).b, alu_result => observed(i).alu_result,
                rdm => observed(i).rdm, fetched => observed(i).fetched,
                reg_write => reg_write(i), reg_write_addr => observed(i).reg_addr,
                reg_write_data => observed(i).reg_data,
                mem_write => mem_write(i), mem_addr => observed(i).mem_addr,
                mem_write_data => observed(i).mem_data
            );
    end generate;

    stimulus : process
        variable history : observations_t(1 to 100);
        variable held : observed_t;
        variable expected_stores, actual_stores : natural := 0;
    begin
        -- Guarda a trajetoria continua. A segunda CPU ainda esta em reset,
        -- com RAM independente; comparar somente estado final esconderia erros.
        wait until falling_edge(clk); reset(0) <= '0';
        for step in history'range loop
            wait until rising_edge(clk);
            if mem_write(0) = '1' then expected_stores := expected_stores + 1; end if;
            wait for 1 ns; history(step) := observed(0);
        end loop;
        wait until falling_edge(clk);
        reset(1) <= '0'; wait for 1 ns;

        for step in history'range loop
            -- Pausa em TODOS os estados alcancados, com duracoes diferentes.
            held := observed(1);
            for idle in 1 to (step mod 3) + 1 loop
                wait until rising_edge(clk); wait for 1 ns;
                assert observed(1) = held report "estado mudou durante pausa" severity failure;
                assert reg_write(1) = '0' and mem_write(1) = '0'
                    report "habilitacao de escrita ativa durante pausa" severity failure;
            end loop;
            wait until falling_edge(clk); enable(1) <= '1';
            wait until rising_edge(clk);
            if mem_write(1) = '1' then actual_stores := actual_stores + 1; end if;
            wait for 1 ns;
            assert observed(1) = history(step)
                report "passo difere da execucao continua, ciclo " & integer'image(step)
                severity failure;
            wait until falling_edge(clk); enable(1) <= '0'; wait for 1 ns;
        end loop;
        assert actual_stores = expected_stores report "escritas diferentes entre modos" severity failure;
        assert (observed(1).fault = '1') = expect_fault
            report "caso de falha nao foi exercitado corretamente" severity failure;

        -- Reset precisa funcionar mesmo com a CPU pausada/fault retido.
        reset(1) <= '1'; wait for 1 ns;
        assert observed(1).pc = x"0000" and observed(1).state = x"0"
            and observed(1).instruction = x"0000" and observed(1).a = x"0000"
            and observed(1).b = x"0000" and observed(1).alu_result = x"0000"
            and observed(1).rdm = x"0000" and observed(1).fault = '0'
            report "reset nao teve prioridade sobre pausa/falha" severity failure;
        wait until falling_edge(clk); reset(1) <= '0'; wait for 1 ns;
        held := observed(1);
        for idle in 1 to 3 loop
            wait until rising_edge(clk); wait for 1 ns;
            assert observed(1) = held report "CPU avancou apos reset sem enable" severity failure;
        end loop;
        wait until falling_edge(clk); enable(1) <= '1';
        wait until rising_edge(clk); wait for 1 ns;
        assert observed(1).pc = x"0000" and observed(1).state = x"1"
            and observed(1).fault = '0' report "retomada apos reset falhou" severity failure;
        report "PASS: pausa/passo equivalente a 100 ciclos continuos: " & init_file;
        finish;
    end process;
end architecture;
