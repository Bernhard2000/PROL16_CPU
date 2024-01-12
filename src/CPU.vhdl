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
    
    signal ClkEnPC : std_ulogic;
    signal ClkEnRegFile : std_ulogic;
    signal SelPC : std_ulogic;
    signal SelLoad : std_ulogic;
    signal SelAddr, ClkEnOpcode, ALU_CarryIn, ALU_CarryOut, ALU_ZeroOut : std_ulogic;
    signal RegOpcode : OpcodeVec;
    
    signal ALUFunc : std_ulogic_vector(3 downto 0);
    signal MemWrData, MemRdData : DataVec;
    
    component DataPath is
            port (
                ClkEnPC : in std_ulogic; -- clock enable of register PC
                ClkEnRegFile : in std_ulogic; -- clock enable of register file
                ClkEnOpcode : in std_ulogic; -- clock enable of register Opcode
                SelPC : in std_ulogic; -- selectInput of SelPC-MUX
                SelLoad : in std_ulogic; -- selectInput of SelLoad-MUX
                SelAddr : in std_ulogic; -- selectInput of SelAddr-MUX
                RegOpcode : out OpcodeVec; -- current opcode info CoreControl
                ---------------------------------- [ ALU ] ------------------------
                CarryIn : in std_ulogic; -- connects to carryIn input of ALU
                CarryOut : out std_ulogic; -- connects to carryOut output of ALU
                ZeroOut : out std_ulogic; -- connects to ZeroOut output of ALU
                ALUFunc : in std_ulogic_vector(3 downto 0); -- selects the function
                -- Of the ALU
                ---------------------------------- [ MEM ] ------------------------
                MemAddr : out DataVec; -- address wires of memory
                MemWrData : out DataVec; -- data wires for writing the memory
                MemRdData : in DataVec; -- data wires for reading the memory
                ---------------------------------- [ clk,reset ] ------------------
                Reset : in std_ulogic; -- reset inpunt
                ZuluClk : in std_ulogic -- clock input
            ); 
        end component;

begin
--TODO implementation
    dataPath_instance : DataPath
    port map(
        ClkEnPC => ClkEnPC, -- clock enable of register PC
        ClkEnRegFile => ClkEnRegFile, -- clock enable of register file
        ClkEnOpcode => ClkEnOpcode, -- clock enable of register Opcode
        SelPC => SelPC, -- selectInput of SelPC-MUX
        SelLoad => SelLoad, -- selectInput of SelLoad-MUX
        SelAddr => SelAddr, -- selectInput of SelAddr-MUX
        RegOpcode => RegOpcode, -- current opcode info CoreControl
        ---------------------------------- [ ALU ] ------------------------
        CarryIn => ALU_CarryIn, -- connects to carryIn input of ALU
        CarryOut => ALU_CarryOut, -- connects to carryOut output of ALU
        ZeroOut => ALU_ZeroOut, -- connects to ZeroOut output of ALU
        ALUFunc => ALUFunc, -- selects the function
        -- Of the ALU
        ---------------------------------- [ MEM ] ------------------------
        MemAddr => MemAddr, -- address wires of memory
        MemWrData => MemWrData, -- data wires for writing the memory
        MemRdData => MemRdData, -- data wires for reading the memory
        ---------------------------------- [ clk,reset ] ------------------
        Reset => Reset, -- reset inpunt
        ZuluClk => ZuluClk -- clock input
    );
end Behavioral;