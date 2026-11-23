# No Transcript do ModelSim: do tests/run_modelsim.do
# Cada simulacao usa um processo separado: std.env.finish encerra com sucesso,
# assertion/error e timeout encerram com erro. Nao requer Python nem Bash.
namespace eval cpu_regression {
    variable root [file normalize [file join [file dirname [info script]] ..]]

    proc write_file {path contents} {
        set channel [open $path w]
        puts $channel $contents
        close $channel
    }

    proc execute {label command} {
        puts "Executando $label"
        set failed [catch {exec {*}$command 2>@1} output options]
        write_file "$label.log" $output
        if {$failed} {
            return -options $options $output
        }
        return $output
    }

    proc tool {name} {
        if {[info exists ::env(MODELSIM_BIN)]} {
            set directory $::env(MODELSIM_BIN)
        } else {
            set directory [file dirname [info nameofexecutable]]
        }
        if {$::tcl_platform(platform) eq "windows"} {append name .exe}
        set path [file join $directory $name]
        if {![file executable $path]} {
            error "Ferramenta ausente: $path. Defina MODELSIM_BIN com a pasta dos executaveis."
        }
        return [file normalize $path]
    }

    proc main {} {
        variable root
        set build [file join $root .build "modelsim-[pid]-[clock clicks]"]
        file mkdir $build
        puts "Resultados: $build"
        set previous [pwd]
        cd $build
        set failed [catch {
            foreach image [glob [file join $root *.mif]] {
                file copy $image .
            }
            # As mesmas oito imagens usadas em run_address_fault.sh.
            set images {
                {623F A001} {5205 723F A002} {6210 6440 A002}
                {6210 7440 A002} {5201 A400} {803E} {A3FF}
                {6210 6440 7440 A3FF}
            }
            set scenario 0
            foreach words $images {
                incr scenario
                set text "DEPTH = 1024;\nWIDTH = 16;\nADDRESS_RADIX = HEX;\nDATA_RADIX = HEX;\nCONTENT BEGIN\n"
                append text {[000..3FF] : 0000;} \n
                set address 0
                foreach word $words {
                    append text [format "%03X : %s;\n" $address $word]
                    incr address
                }
                set base 0400
                set boundary FACE
                if {$scenario == 7} {set boundary 0000}
                if {$scenario == 8} {set base 03FF; set boundary A3FF}
                append text "010 : $base;\n3FF : $boundary;\nEND;"
                write_file "address_$scenario.mif" $text
            }

            write_file run_one.do {
onerror {quit -force -code 1}
onbreak {quit -force -code 1}
set BreakOnAssertion 2
onfinish exit
run 100 us
puts "FAIL: timeout; o testbench nao executou std.env.finish"
quit -force -code 2
}
            # Verifica o proprio fluxo antes de confiar nos resultados da CPU.
            write_file tb_runner_probe.vhd {
entity tb_runner_probe is
    generic (mode : natural := 0);
end entity;
architecture test of tb_runner_probe is
begin
    process
    begin
        if mode = 1 then
            assert false report "PROBE_ASSERTION" severity failure;
        elsif mode = 2 then
            wait;
        end if;
        std.env.finish;
        wait;
    end process;
end architecture;
}
            set rtl {pc instruction_register memory register_file immediate_extender
                     reg_a reg_b alu alu_out memory_address_register memory_data_register
                     datapath decoder control_unit cpu}
            set sources {}
            foreach unit $rtl {lappend sources [file join $root "$unit.vhd"]}
            foreach source [lsort [glob [file join $root tests tb_*.vhd]]] {
                lappend sources $source
            }
            foreach source $sources {
                if {![file isfile $source]} {error "Fonte ausente: $source"}
            }
            write_file sources.txt [join $sources \n]

            if {[info exists ::env(CPU_MODELSIM_PREPARE_ONLY)] &&
                $::env(CPU_MODELSIM_PREPARE_ONLY) eq "1"} {
                puts "PREPARADO apenas: nenhuma compilacao ou simulacao ModelSim executada."
            } else {
                set vlib [tool vlib]
                set vmap [tool vmap]
                set vcom [tool vcom]
                set vsim [tool vsim]
                execute version [list $vsim -version]
                execute ini [list $vmap -c]
                execute library [list $vlib work]
                execute mapping [list $vmap work [file join $build work]]
                execute compile [list $vcom -2008 -work work {*}$sources tb_runner_probe.vhd]
                set common [list $vsim -c -onfinish exit -do {do run_one.do}]
                foreach mode {0 1 2} {
                    set bad [catch {
                        execute "probe_$mode" [concat $common [list -gmode=$mode work.tb_runner_probe]]
                    } message options]
                    if {$mode == 0 && $bad} {error "Probe finish falhou: $message"}
                    if {$mode != 0} {
                        set expected [expr {$mode == 1 ? "PROBE_ASSERTION" : "FAIL: timeout"}]
                        if {!$bad || [string first $expected $message] < 0 ||
                            ![dict exists $options -errorcode] ||
                            [lindex [dict get $options -errorcode] 0] ne "CHILDSTATUS"} {
                            error "Probe $mode nao detectou a falha esperada: $message"
                        }
                    }
                }
                set count 0
                foreach unit {register_file instruction_register pc immediate_extender
                              instruction_formats alu alu_registers memory datapath control_unit cpu} {
                    execute $unit [concat $common [list work.tb_$unit]]
                    incr count
                }
                foreach program {1 2 3 4} {
                    execute "program_$program" [concat $common [list -gprogram=$program work.tb_program]]
                    incr count
                }
                foreach scenario {1 2 3 4 5 6 7 8} {
                    file copy -force "address_$scenario.mif" address_test.mif
                    execute "address_$scenario" [concat $common [list -gscenario=$scenario work.tb_address_fault]]
                    incr count
                }
                set summary "PASS: $count simulacoes; probes de finish/assertion/timeout verificados."
                write_file summary.txt $summary
                puts $summary
            }
        } message options]
        cd $previous
        if {$failed} {
            puts "FAIL: $message\nConsulte os logs em $build"
            return -options $options $message
        }
        return $build
    }
}
cpu_regression::main
