library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;
entity tb_top_de2_115 is
    generic (fault_case : boolean := false; digits_case : boolean := false);
end entity;
architecture test of tb_top_de2_115 is
    signal clk : std_logic := '0';
    signal keys : std_logic_vector(3 downto 0) := "1110";
    signal sw : std_logic_vector(17 downto 0) := (others => '0');
    signal lr : std_logic_vector(17 downto 0);
    signal lg : std_logic_vector(8 downto 0);
    signal writes, stores : natural := 0;
    type displays_t is array(0 to 7) of std_logic_vector(6 downto 0);
    signal hex : displays_t;
    type digits_t is array(0 to 15) of std_logic_vector(6 downto 0);
    constant digits : digits_t := ("1000000","1111001","0100100","0110000",
        "0011001","0010010","0000010","1111000","0000000","0010000",
        "0001000","0000011","1000110","0100001","0000110","0001110");
    function image_name return string is
    begin
        if digits_case then return "top_digits.mif"; end if;
        if fault_case then return "top_fault.mif"; end if;
        return "cpu_test.mif";
    end;
    function word(h : displays_t; start : natural) return std_logic_vector is
        variable result : std_logic_vector(15 downto 0);
        variable found : boolean;
    begin
        for i in 0 to 3 loop
            found := false;
            for d in 0 to 15 loop
                if h(start+i) = digits(d) then
                    result(i*4+3 downto i*4) := std_logic_vector(to_unsigned(d,4));
                    found := true;
                end if;
            end loop;
            assert found report "display invalido" severity failure;
        end loop;
        return result;
    end;
begin
    clk <= not clk after 5 ns;
    dut : entity work.top_de2_115
        generic map(init_file => image_name, debounce_cycles => 2)
        port map(clk,keys,sw,lr,lg,hex(0),hex(1),hex(2),hex(3),hex(4),hex(5),hex(6),hex(7));
    process(clk)
    begin
        if rising_edge(clk) then
            if lg(7) = '1' then
                assert lg(3 downto 0) = x"9" report "LED reg_write fora de WB" severity failure;
                writes <= writes + 1;
            end if;
            if lg(8) = '1' then
                assert lg(3 downto 0) = x"7" report "LED mem_write fora de ST" severity failure;
                stores <= stores + 1;
            end if;
        end if;
    end process;
    process
        variable held : displays_t;
        variable saw_operands, saw_load : boolean := false;
        procedure cycles(n : positive) is
        begin for i in 1 to n loop wait until rising_edge(clk); wait for 1 ns; end loop; end;
        procedure step is
        begin keys(1) <= '0'; cycles(10); keys(1) <= '1'; cycles(10); end;
        procedure select_view(n : natural; expected : std_logic_vector(15 downto 0)) is
        begin
            sw(3 downto 1) <= std_logic_vector(to_unsigned(n,3)); cycles(4);
            assert word(hex,0) = expected and lr(15 downto 0) = expected
                report "observacao incorreta, selecao " & integer'image(n) severity failure;
        end;
    begin
        cycles(2);
        assert lr(16) = '1' and word(hex,4) = x"0000" report "reset/top" severity failure;
        assert lg(5 downto 4) = "01" report "flags no reset" severity failure;
        keys(0) <= '1'; cycles(10);
        assert lr(16) = '0' and lg(3 downto 0) = x"0" report "liberacao reset" severity failure;
        if digits_case then
            for d in 0 to 15 loop
                step; step;
                assert hex(0) = digits(d) and hex(1) = digits(d)
                    and hex(2) = digits(d) and hex(3) = digits(15)
                    and word(hex,4) = std_logic_vector(to_unsigned(d+1,16))
                    report "digito hexadecimal incorreto" severity failure;
                step;
            end loop;
            report "PASS: top todos os digitos hexadecimais";
            finish;
        end if;
        step;
        assert lg(3 downto 0) = x"1" and word(hex,4) = x"0000" report "primeiro passo" severity failure;
        step;
        assert lg(3 downto 0) = x"2" and word(hex,4) = x"0001" report "segundo passo" severity failure;
        if not fault_case then
            assert word(hex,0) = x"5203" report "IR nos displays" severity failure;
            -- Busca seguinte: palavra da RAM ja mudou, IR ainda nao.
            step; step; step; step;
            select_view(0,x"5203"); select_view(5,x"5401");
            sw(3 downto 1) <= "000";
            cycles(1);
            assert word(hex,0) = x"5401" report "seletor sem primeiro estagio" severity failure;
            cycles(1);
            assert word(hex,0) = x"5203" report "seletor sem segundo estagio" severity failure;
            -- Valores diferentes detectam trocas de fios no mux.
            for i in 1 to 90 loop
                step;
                if word(hex,4) = x"0004" and lg(3 downto 0) = x"3" and not saw_operands then
                    select_view(1,x"0000"); select_view(2,x"0001");
                    assert lg(5 downto 4) = "00" report "flags ADD" severity failure;
                    saw_operands := true;
                end if;
                if word(hex,4) = x"0009" and lg(3 downto 0) = x"9" then
                    select_view(3,x"0010"); select_view(6,x"0003");
                    saw_load := true;
                    exit;
                end if;
            end loop;
            assert writes > 0 and stores = 1 report "LEDs de escrita nao refletem programa" severity failure;
            assert saw_operands and saw_load report "pontos de observacao nao atingidos" severity failure;
        
        end if;
        held := hex; cycles(12);
        assert hex = held report "CPU nao pausou no top" severity failure;
        sw(0) <= '1'; cycles(12);
        assert lg(6) = '1' report "LED modo continuo" severity failure;
        cycles(108); sw(0) <= '0'; cycles(12);
        assert lg(6) = '0' report "modo continuo nao parou" severity failure;
        if fault_case then
            assert lr(17) = '1' report "fault nao visivel" severity failure;
            held := hex; step;
            assert hex = held report "passo ultrapassou fault" severity failure;
        else
            assert lr(17) = '0' report "fault inesperado" severity failure;
            -- Parar em FETCH0 do JMP terminal torna endereco/PC deterministas.
            for i in 1 to 3 loop
                exit when lg(3 downto 0) = x"0";
                step;
            end loop;
            assert lg(3 downto 0) = x"0" and word(hex,4) = x"0009"
                report "loop terminal nao alcancado" severity failure;
            select_view(0,x"A009"); select_view(1,x"0000"); select_view(2,x"0000");
            select_view(3,x"0010"); select_view(4,x"0003"); select_view(5,x"A009");
            select_view(6,x"0010"); select_view(7,x"0009");
        end if;
        keys(0) <= '0'; cycles(2); sw <= (others => '0');
        assert lr(17) = '0' and word(hex,4) = x"0000" report "reset nao limpou CPU" severity failure;
        keys(0) <= '1'; cycles(10); step;
        assert lg(3 downto 0) = x"1" report "reinicio top" severity failure;
        report "PASS: top DE2-115 fault=" & boolean'image(fault_case);
        finish;
    end process;
end architecture;
