library ieee;
use ieee.std_logic_1164.all;

library work;
use work.prol16_package.all;



entity CPU is
    port (MemIOData : inout std_logic_vector(15 downto 0);
    MemAddr : out DataVec;
    MemCE : out std_ulogic; -- low-active (Chip Enable)
    MemWE : out std_ulogic; -- low-active (Write Enable)
    MemOE : out std_ulogic; -- low-active (Output Enable)
    ClkEnOpcode : out std_ulogic;
    LegalOpcodePresent : out std_ulogic;
    Reset : in std_ulogic;
    ZuluClk : in std_ulogic);
end CPU;

architecture Behavioral of CPU is
    signal MemAddrInt : DataVec;
    signal MemCEInt : std_ulogic;
    signal MemWEInt : std_ulogic;
    signal MemOEInt : std_ulogic;
    signal ClkEnOpcodeInt : std_ulogic;
    signal LegalOpcodePresentInt : std_ulogic;
    signal ResetInt : std_ulogic;
    signal ZuluClkInt : std_ulogic;

    begin
--TODO implementation
end Behavioral;