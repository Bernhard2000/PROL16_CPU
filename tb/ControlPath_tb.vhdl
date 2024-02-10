library ieee;
use ieee.std_logic_1164.all;

library work;
use work.prol16_package.all;


entity ControlPath_tb is
end ControlPath_tb;

architecture behavior of ControlPath_tb is 
    component ControlPath is
    port ( 
        Reset : in std_ulogic; -- reset inpunt
        ZuluClk : in std_ulogic; -- clock input

        MemRdStrobe : out std_ulogic; -- memory read strobe
        MemWrStrobe : out std_ulogic -- memory write strobe
    );
    end component;
    
    signal reset, zuluclk : std_ulogic := '0';
    signal memrd, memwr : std_ulogic;
begin
    dut: ControlPath port map (
        Reset => reset,
        ZuluClk => zuluclk,
        MemRdStrobe => memrd,
        MemWrStrobe => memwr
    );
    
  ZuluClk <= not ZuluClk after 100ns;

end behavior;