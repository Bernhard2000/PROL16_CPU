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
    
    signal ClkEnPC_sig : std_ulogic;
    signal ClkEnOpCode_sig : std_ulogic;
    signal ClkEnRegFile_sig : std_ulogic;
    signal SelPC_sig : std_ulogic;
    signal SelLoad_sig : std_ulogic;
    signal RegOpcode_sig : OpcodeVec;
    signal SelAddr_sig : std_ulogic;
    
    signal CarryIn_sig : std_ulogic;
    signal CarryOut_sig : std_ulogic;
    signal ZeroOut_sig : std_ulogic;
    
    signal ALUFunc : std_ulogic_vector(3 downto 0);
    signal MemWrData, MemRdData : DataVec;
    
    signal MemRdStrobe, MemWrStrobe : std_ulogic;
    
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
        
     component ControlPath is
     port ( 
             Reset : in std_ulogic; -- reset inpunt
             ZuluClk : in std_ulogic; -- clock input
     
             MemRdStrobe : out std_ulogic; -- memory read strobe
             MemWrStrobe : out std_ulogic; -- memory write strobe
             
              ---------------------------------- [ ALU ] ------------------------
       
            ZeroOut : out std_ulogic; -- connects to ZeroOut output of ALU
            ALUFunc : in std_ulogic_vector(3 downto 0); -- selects the function
            -- Of the ALU
            ---------------------------------- [ MEM ] ------------------------
            MemAddr : out DataVec; -- address wires of memory
            MemWrData : out DataVec; -- data wires for writing the memory
            MemRdData : in DataVec -- data wires for reading the memory
         );
     
     end component;

begin
--TODO implementation
    dataPath_instance : DataPath
    port map(
        ClkEnPC => ClkEnPC_sig, -- clock enable of register PC
        ClkEnRegFile => ClkEnRegFile_sig, -- clock enable of register file
        ClkEnOpcode => ClkEnOpcode_sig, -- clock enable of register Opcode
        SelPC => SelPC_sig, -- selectInput of SelPC-MUX
        SelLoad => SelLoad_sig, -- selectInput of SelLoad-MUX
        SelAddr => SelAddr_sig, -- selectInput of SelAddr-MUX
        RegOpcode => RegOpcode_sig, -- current opcode info CoreControl
        ---------------------------------- [ ALU ] ------------------------
        CarryIn => CarryIn_sig, -- connects to carryIn input of ALU
        CarryOut => CarryOut_sig, -- connects to carryOut output of ALU
        ZeroOut => ZeroOut_sig, -- connects to ZeroOut output of ALU
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
    
    controlPath_instance : ControlPath
    port map (
        Reset => Reset,
        ZuluClk => ZuluClk,    
        MemRdStrobe => MemRdStrobe,
        MemWrStrobe => MemWrStrobe,
        ZeroOut => ZeroOut_sig,
        ALUFunc => AlUFunc,            
        MemAddr => MemAddr,
        MemWrData => MemWrData,
        MemRdData => MemRdData
    );
    
    
end Behavioral;