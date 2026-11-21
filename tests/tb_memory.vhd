library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;

entity tb_memory is
end entity;

architecture test of tb_memory is
    signal clk, reset, mar_write, mdr_write, mem_read, mem_write : std_logic := '0';
    signal address_in, address : std_logic_vector(9 downto 0) := (others => '0');
    signal write_data, read_data, mdr_data : std_logic_vector(15 downto 0);
begin
    mar : entity work.memory_address_register
        port map (clk, reset, mar_write, address_in, address);

    ram : entity work.memory
        port map (clk, mem_read, mem_write, address, write_data, read_data);

    mdr : entity work.memory_data_register
        port map (clk, reset, mdr_write, read_data, mdr_data);

    stimulus : process
        procedure tick is
        begin
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end procedure;
    begin
        reset <= '1';
        wait for 1 ns;
        assert address = "0000000000" and mdr_data = x"0000" severity failure;
        reset <= '0';

        -- Le o endereco anterior quando REM e RAM atuam na mesma borda.
        address_in <= "0000000001";
        mar_write <= '1';
        mem_read <= '1';
        tick;
        assert address = "0000000001" and read_data = x"1234"
            report "Carga do REM ou leitura inicial incorreta" severity failure;

        -- O RDM captura o dado anterior; a RAM atualiza a saida apos a borda.
        mar_write <= '0';
        address_in <= "1111111111";
        mdr_write <= '1';
        wait for 1 ns;
        assert mdr_data = x"0000" and read_data = x"1234" severity failure;
        tick;
        assert address = "0000000001" and read_data = x"ABCD" and mdr_data = x"1234"
            report "Latencia da leitura ou do RDM incorreta" severity failure;

        mem_read <= '0';
        mar_write <= '1';
        tick;
        assert address = "1111111111" and read_data = x"ABCD" and mdr_data = x"ABCD"
            report "A RAM deve manter a saida quando ociosa" severity failure;

        mar_write <= '0';
        mdr_write <= '0';
        mem_read <= '1';
        tick;
        assert read_data = x"FACE" and mdr_data = x"ABCD"
            report "Ultimo endereco do MIF ou retencao do RDM incorreto" severity failure;

        write_data <= x"DEAD";
        wait for 1 ns;
        mem_write <= '1';
        wait for 1 ns;
        assert read_data = x"FACE" severity failure;
        tick;
        assert read_data = x"FACE" report "Escrita deve preservar a saida registrada" severity failure;
        mem_write <= '0';
        tick;
        assert read_data = x"DEAD" report "Escrita nao persistiu" severity failure;

        -- O reset zera os registradores sem clock e preserva as palavras da RAM.
        mar_write <= '1';
        mdr_write <= '1';
        reset <= '1';
        wait for 1 ns;
        assert address = "0000000000" and mdr_data = x"0000" severity failure;
        tick;
        assert address = "0000000000" and mdr_data = x"0000" and read_data = x"1234"
            report "Reset deve ter prioridade nos registradores" severity failure;
        reset <= '0';
        tick;
        tick;
        assert read_data = x"DEAD" and mdr_data = x"1234"
            report "Reset dos registradores alterou o conteudo da RAM" severity failure;

        address_in <= "0000000010";
        tick;
        tick;
        assert read_data = x"0000" report "Faixa zerada do MIF incorreta" severity failure;

        -- Um pulso de escrita restrito ao nivel alto/descida nao grava.
        mem_read <= '0';
        mem_write <= '1';
        write_data <= x"BEEF";
        wait for 1 ns;
        clk <= '0';
        wait for 1 ns;
        mem_write <= '0';
        mem_read <= '1';
        tick;
        assert read_data = x"0000" report "Escrita fora da borda de subida" severity failure;

        report "Testes da RAM, REM e RDM passaram" severity note;
        finish;
    end process;
end architecture;
