library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;


library work;
use work.prol16_package.all;

entity DataPath is
    port (
    ClkEnPC
    : in std_ulogic; -- clock enable of register PC
    ClkEnRegFile : in std_ulogic; -- clock enable of register file
    ClkEnOpcode : in std_ulogic; -- clock enable of register Opcode
    SelPC
     : in std_ulogic; -- selectInput of SelPC-MUX
    SelLoad
     : in std_ulogic; -- selectInput of SelLoad-MUX
    SelAddr
     : in std_ulogic; -- selectInput of SelAddr-MUX
    RegOpcode
     : out OpcodeVec; -- current opcode info CoreControl
    ---------------------------------- [ ALU ] ------------------------
    CarryIn
     : in std_ulogic; -- connects to carryIn input of ALU
    CarryOut
     : out std_ulogic; -- connects to carryOut output of ALU
    ZeroOut
     : out std_ulogic; -- connects to ZeroOut output of ALU
    ALUFunc
     : in std_ulogic_vector(3 downto 0); -- selects the function
    -- Of the ALU
    ---------------------------------- [ MEM ] ------------------------
    MemAddr
     : out DataVec; -- address wires of memory
    MemWrData
     : out DataVec; -- data wires for writing the memory
    MemRdData
     : in DataVec; -- data wires for reading the memory
    ---------------------------------- [ clk,reset ] ------------------
    Reset
     : in std_ulogic; -- reset inpunt
    ZuluClk
     : in std_ulogic); -- clock input
end DataPath;
architecture Behavioral of DataPath is

component RegisterFile is
    port(
        RegFileIn : in DataVec;
        RegSelRa : in std_ulogic_vector(RegFileBits-1 downto 0);
        RegSelRb : std_ulogic_vector(RegFileBits-1 downto 0);
        ClkEnRegFile : in std_ulogic;
        Clk : in std_ulogic;
        Reset : in std_ulogic;
        RaValue : out DataVec;
        RbValue : out DataVec
    );
end component;

component ALU is
    port(
        SideA : in DataVec;
        SideB : in DataVec;
        AluResult : out DataVec;
        CarryIn : in std_ulogic;
        CarryOut : out std_ulogic;
        ZeroOut : out std_ulogic;
        FuncControl : in FuncControlVec
    );
end component;

component OpCodeToALUFunc is 
    port ( 
        OpCode : in std_ulogic_vector(OpcodeBits-1 downto 0);
        AluFunc : out FuncControlVec
    );
end component;

function ulogic_vector_to_OpcodeValueType(data_vector : std_ulogic_vector) return OpcodeValueType is
      variable result : OpcodeValueType;
    begin
      result.Code := data_vector(DataVec_length - 1 downto DataVec_length - OpcodeBits); --5-0
      result.Ra := data_vector(2*RegFileBits - 1 downto RegFileBits); --10-6
      result.Rb := data_vector(RegFileBits - 1 downto 0); --15-11
      result.Imm := data_vector(DataVec_length-1 downto 0);
      return result;
    end function;
    
    function OpcodeValueType_default return OpcodeValueType is
    variable result : OpcodeValueType;
        begin
          result.Code := (others => '0'); --5-0
          result.Ra := (others => '0'); --10-6
          result.Rb := (others => '0'); --15-11
          result.Imm := (others => '0');
          return result;
        end function;
    
signal AluResult_sig : DataVec;
signal RaValue, RbValue : DataVec := (others => '0');
signal aluSideA : DataVec := (others => '0');
signal regPC : DataVec := (others => '0');
signal RegFileIn : DataVec;
signal RegTmpRa, RegTmpRb : DataVec := (others => '0');
signal RegSelRa : std_ulogic_vector(RegFileBits-1 downto 0);
signal RegSelRb : std_ulogic_vector(RegFileBits-1 downto 0);
signal RegOpcode_sig : OpcodeVec := (others => '0');
signal RegOpcode_sig_s : OpcodeVec := (others => '0');

begin

    with SelLoad select
                RegFileIn <= AluResult_sig when '0',
                             MemRdData when '1',
                             (others => 'X') when others;
          

    registerfile_instance : RegisterFile
    port map (
        RegFileIn => RegFileIn,
        RegSelRa => RegSelRa,
        RegSelRb => RegSelRb, 
        ClkEnRegFile => ClkEnRegFile,
        Clk => ZuluClk,
        Reset => Reset,
        RaValue => RaValue,
        RbValue => RbValue
    );
    
    alu_instance : ALU
    port map (
        SideA => aluSideA,
        SideB => RegTmpRb,
        AluResult => AluResult_sig,
        CarryIn => CarryIn,
        CarryOut => CarryOut,
        ZeroOut => ZeroOut,
        FuncControl => ALUFunc
    );
    
    ALUResult <= ALUResult_sig;
    
    writePC : process(ZuluClk, Reset, SelPC) is
    begin
        if Reset = ResetActive then
            report "Reset PC";
            RegPC <= (others => '0');
        elsif rising_edge(ZuluCLK) then
            if ClkEnPC = '1' then
                case SelPC is
                    when '0' => RegPC <= RaValue;
                    when '1' => RegPC <= AluResult_sig;
                    when others => RegPC <= (others => 'X');
                end case;
            end if;
        end if;
    end process;

    writeRegTmpRa : process(ZuluClk, Reset) is
    begin
        if Reset = ResetActive then
            RegTmpRa <= (others => '0');
        elsif rising_edge(ZuluCLK) then
            RegTmpRa <= RaValue;
                            report "RaValue: " &integer'image(to_integer(unsigned(RaValue)));
        end if;
    end process;

    writeRegTmpRb : process(ZuluClk, Reset) is
        begin
            if Reset = ResetActive then
                RegTmpRb <= (others => '0');
            elsif rising_edge(ZuluClk) then
                RegTmpRb <= RbValue;
                report "RegTmpRb: " &integer'image(to_integer(unsigned(RbValue)));
                                    --report "SelAddr: " &std_logic'image(SelAddr);
            end if;
    end process;
    



                

    writeOpcode : process(ZuluClk, Reset, ClkEnOpcode, MemRdData) is
        variable opcodeValue : OpcodeValueType := OpcodeValueType_default;
    begin
        if Reset = ResetActive then
            RegOpcode_sig <= (others => '0');
            RegSelRa <= (others => '0');
            RegSelRb <= (others => '0');
        elsif rising_edge(ZuluClk) then
                --report "Test: CLKEnOpcode: " &std_logic'image(ClkEnOpcode);
            if ClkEnOpcode = '1' then
                opcodeValue := ulogic_vector_to_OpcodeValueType(MemRdData);
                RegOpcode_sig <= opcodeValue.Code;
                        RegSelRa <= opcodeValue.Ra;
                        RegSelRb <= opcodeValue.Rb;
                --report "DataPath: Ra: "&integer'image(to_integer(unsigned(opcodeValue.Ra))) & "Rb: " &integer'image(to_integer(unsigned(opcodeValue.Rb)));
            end if;
        end if;
        
    end process;
       

    With SelAddr select MemAddr <= RegPC when '0', RegTmpRb when '1', (others => 'X') when others;
 
    AluSideA <= RegTmpRa when SelPC = '0' else RegPC;
    MemWrData <= RegTmpRa;
    RegOpcode <= RegOpcode_sig;

end Behavioral;
