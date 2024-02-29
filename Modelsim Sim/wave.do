onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cpu_tb/ZuluClk
add wave -noupdate /cpu_tb/Reset_s
add wave -noupdate /cpu_tb/mem_we_ni_s
add wave -noupdate /cpu_tb/mem_oe_ni_s
add wave -noupdate /cpu_tb/mem_dat_io_s
add wave -noupdate /cpu_tb/mem_ce_ni_s
add wave -noupdate /cpu_tb/mem_addr_i_s
add wave -noupdate /cpu_tb/LegalOpcodePresent_s
add wave -noupdate /cpu_tb/ClkEnOpcode_s
add wave -noupdate /cpu_tb/cpu_inst/controlPath_instance/cycle
add wave -noupdate /cpu_tb/cpu_inst/controlPath_instance/nextCycle
add wave -noupdate /cpu_tb/cpu_inst/controlPath_instance/RegOpcode
add wave -noupdate /cpu_tb/cpu_inst/dataPath_instance/ClkEnOpcode
add wave -noupdate -radix decimal /cpu_tb/cpu_inst/dataPath_instance/RegOpcode
add wave -noupdate -radix decimal /cpu_tb/cpu_inst/dataPath_instance/RegSelRa
add wave -noupdate -radix decimal /cpu_tb/cpu_inst/dataPath_instance/RegSelRb
add wave -noupdate -radix decimal -childformat {{/cpu_tb/cpu_inst/dataPath_instance/registerfile_instance/registers(7) -radix decimal} {/cpu_tb/cpu_inst/dataPath_instance/registerfile_instance/registers(6) -radix decimal} {/cpu_tb/cpu_inst/dataPath_instance/registerfile_instance/registers(5) -radix decimal} {/cpu_tb/cpu_inst/dataPath_instance/registerfile_instance/registers(4) -radix decimal} {/cpu_tb/cpu_inst/dataPath_instance/registerfile_instance/registers(3) -radix decimal} {/cpu_tb/cpu_inst/dataPath_instance/registerfile_instance/registers(2) -radix decimal} {/cpu_tb/cpu_inst/dataPath_instance/registerfile_instance/registers(1) -radix decimal} {/cpu_tb/cpu_inst/dataPath_instance/registerfile_instance/registers(0) -radix decimal}} -expand -subitemconfig {/cpu_tb/cpu_inst/dataPath_instance/registerfile_instance/registers(7) {-height 16 -radix decimal} /cpu_tb/cpu_inst/dataPath_instance/registerfile_instance/registers(6) {-height 16 -radix decimal} /cpu_tb/cpu_inst/dataPath_instance/registerfile_instance/registers(5) {-height 16 -radix decimal} /cpu_tb/cpu_inst/dataPath_instance/registerfile_instance/registers(4) {-height 16 -radix decimal} /cpu_tb/cpu_inst/dataPath_instance/registerfile_instance/registers(3) {-height 16 -radix decimal} /cpu_tb/cpu_inst/dataPath_instance/registerfile_instance/registers(2) {-height 16 -radix decimal} /cpu_tb/cpu_inst/dataPath_instance/registerfile_instance/registers(1) {-height 16 -radix decimal} /cpu_tb/cpu_inst/dataPath_instance/registerfile_instance/registers(0) {-height 16 -radix decimal}} /cpu_tb/cpu_inst/dataPath_instance/registerfile_instance/registers
add wave -noupdate /cpu_tb/cpu_inst/dataPath_instance/alu_instance/AluResult
add wave -noupdate /cpu_tb/cpu_inst/dataPath_instance/RegFileIn
add wave -noupdate /cpu_tb/cpu_inst/dataPath_instance/ClkEnRegFile
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {6500000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 358
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1777362 ps}
