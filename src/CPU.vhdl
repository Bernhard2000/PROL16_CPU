library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.prol16_package.all;



entity CPU is
    port (MemIOData : inout std_logic_vector(15 downto 0);
    MemAddr : out DataVec;
    MemCE : out std_ulogic := '0'; -- low-active (Chip Enable)
    MemWE : out std_ulogic := '1'; -- low-active (Write Enable)
    MemOE : out std_ulogic := '0'; -- low-active (Output Enable)
    ClkEnOpcode : out std_ulogic;
    LegalOpcodePresent : out std_ulogic;
    Reset : in std_ulogic;
    ClkEnPC : out std_ulogic;
    ZuluClk : in std_ulogic;
    RegOpCode : out OpcodeVec);
end CPU;

architecture Behavioral of CPU is    
    signal ClkEnPC_sig : std_ulogic := '0';
    signal ClkEnOpCode_sig : std_ulogic := '0';
    signal ClkEnRegFile_sig : std_ulogic := '0';
    signal SelPC_sig : std_ulogic := '0';
    signal SelLoad_sig : std_ulogic := '0';
    signal RegOpcode_sig : OpcodeVec := (others => '0');
    signal SelAddr_sig : std_ulogic := '0';
    
    signal CarryIn_sig : std_ulogic := '0';
    signal CarryOut_sig : std_ulogic := '0';
    signal ZeroOut_sig : std_ulogic := '0';
    
    signal ALUFunc : std_ulogic_vector(3 downto 0);
    signal MemWrData, MemRdData : DataVec;
    
    signal MemRdStrobe : std_ulogic := '1';
    signal MemWrStrobe : std_ulogic := '0';
    signal memCE_sig, memOE_sig, memWE_sig : std_ulogic;
    
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
             
             RegOpcode : in OpcodeVec;
             ALU_CarryOut    : in std_ulogic;
             ALU_ZeroOut     : in std_ulogic;
     
             MemRdStrobe : out std_ulogic; -- memory read strobe
             MemWrStrobe : out std_ulogic; -- memory write strobe
     
             ClkEnOpcode     : out std_ulogic;
             ClkEnPC         : out std_ulogic;
             ClkEnRegFile    : out std_ulogic;
             SelLoad         : out std_ulogic;
             SelAddr         : out std_ulogic;
             SelPC           : out std_ulogic;
             ALU_CarryIn     : out std_ulogic;
     
              ---------------------------------- [ ALU ] ------------------------
              ALUFunc : out std_ulogic_vector(3 downto 0) -- selects the function of the ALU        
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
        
        RegOpcode => RegOpcode_sig,
        ALU_CarryOut => CarryOut_sig,
        ALU_ZeroOut => ZeroOut_sig, -- connects to ZeroOut output of ALU
        
        MemRdStrobe => MemRdStrobe,
        MemWrStrobe => MemWrStrobe,
        
        ClkEnOpcode => ClkEnOpcode_sig,
        ClkEnPC => ClkEnPC_sig,
        ClkEnRegFile => ClkEnRegFile_sig,
        SelPC => SelPC_sig, -- selectInput of SelPC-MUX
        SelLoad => SelLoad_sig, -- selectInput of SelLoad-MUX
        SelAddr => SelAddr_sig, -- selectInput of SelAddr-MUX
          
        ALU_CarryIn => CarryIn_sig, -- connects to carryIn input of ALU         
        ALUFunc => ALUFunc -- selects the function
    );

    RegOpCode <= RegOpcode_sig;
    ClkEnOpcode <= ClkEnOpcode_sig;
    ClkEnPC <= ClkEnPC_sig;
        
    MemIOData <= to_stdlogicvector(MemWrData) when (memWE_sig = '0' and memCE_sig = '0') else (others => 'Z');
    MemRdData <= std_ulogic_vector(MemIOData);
    

    MemCE <= memCE_sig;
    MemOE <= memOE_sig;
    MemWE <= memWE_sig;
    

MemorySignals: process (ZuluCLK)
begin
    if MemRdStrobe = '1' then
        memCE_sig <= '0';
        memOE_sig <= '0';
        memWE_sig <= '1';
    elsif MemWrStrobe = '1' then
        memCE_sig <= '0';
        memOE_sig <= '1';
        memWE_sig <= '0';
    else 
        memCE_sig <= '1';
        memOE_sig <= '1';
        memWE_sig <= '1';
    end if;
end process;
end Behavioral;
