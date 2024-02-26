library ieee;
use ieee.std_logic_1164.all;


package prol16_package is
    constant DataVec_length : natural := 16;
    constant FuncControl_Width : natural := 4;
    constant DataVec_DontCare : std_ulogic_vector := "----------------";
    subtype DataVec is std_ulogic_vector (DataVec_length - 1 downto 0); 
    subtype FuncControlVec is std_ulogic_vector (FuncControl_Width - 1 downto 0);

    ---------------------------------------------------------------------------
    -- bit structure of opcode...
    ---------------------------------------------------------------------------
    constant OpcodeBits : integer := 6;
    constant OpcodeMax
     : integer := (2**OpcodeBits)-1;
    constant RegFileBits : integer := 5;
    constant RegFileMax : integer := (2**RegFileBits)-1; -- Ra,Rb = 0 to RegFileMax
    type OpcodeValueType is record -- 16 bit
    Code : std_ulogic_vector(OpcodeBits-1 downto 0);
    Ra : std_ulogic_vector(RegFileBits-1 downto 0);
    Rb : std_ulogic_vector(RegFileBits-1 downto 0);
    Imm : DataVec; -- optional (for instructions with immediate value)
    end record;
    subtype OpcodeRange is natural range 15 downto 10;
    subtype RaRange
     is natural range 7 downto 5; --size of register file=8
    subtype RbRange
     is natural range 2 downto 0; --size of register file=8
    subtype OpcodeVec
     is std_ulogic_vector(5 downto 0); -- bits of opcode
    ---------------------------------------------------------------------------
    
    ---------------------------------------------------------------------------
    -- actual size of register file...
    ---------------------------------------------------------------------------
    constant SizeOfRegFile : integer := 8;
    subtype RegFileRange is natural range 0 to (SizeOfRegFile-1);
    subtype RegFileVec is std_ulogic_vector(2 downto 0); --register file select
    
    type RegFile is array((SizeOfRegFile - 1) downto 0) of DataVec;
    

    constant ResetActive : std_ulogic := '1';

    subtype ALUFuncVec is std_ulogic_vector(3 downto 0);
    --FuncControl
    constant ALU_SideA : FuncControlVec := "0000";
    constant ALU_SideB : FuncControlVec := "0001";
    constant ALU_AandB : FuncControlVec := "0010";
    constant ALU_AorB : FuncControlVec := "0011";
    constant ALU_AxorB : FuncControlVec := "0100";
    constant ALU_NotA : FuncControlVec := "0101";
    constant ALU_ShiftALeft : FuncControlVec := "0110";
    constant ALU_ShiftARight : FuncControlVec := "0111";
    constant ALU_AplusBplusCarry : FuncControlVec := "1000";
    constant ALU_AminusBminusCarry : FuncControlVec := "1001";
    constant ALU_A_INC : FuncControlVec := "1010";
    constant ALU_A_DEC : FuncControlVec := "1011";
    constant ALU_DONT_CARE : FuncControlVec := "0000";
    
    
    
    --Opcodes
    constant OP_NOP : OpcodeVec := "000000";
    constant OP_SLEEP : std_ulogic_vector(OpcodeBits-1 downto 0) := "000001";
    constant OP_LOADI : OpcodeVec := "000010";
    constant OP_LOAD : std_ulogic_vector(OpcodeBits-1 downto 0) := "000011";
    constant OP_STORE : std_ulogic_vector(OpcodeBits-1 downto 0) := "000100";
    constant OP_JUMP : std_ulogic_vector(OpcodeBits-1 downto 0) := "001000";
    constant OP_JUMPC : std_ulogic_vector(OpcodeBits-1 downto 0) := "001010";
    constant OP_JUMPZ : std_ulogic_vector(OpcodeBits-1 downto 0) := "001011";
    constant OP_MOVE : std_ulogic_vector(OpcodeBits-1 downto 0) := "001100";
    constant OP_AND : std_ulogic_vector(OpcodeBits-1 downto 0) := "010000";
    constant OP_OR : std_ulogic_vector(OpcodeBits-1 downto 0) := "010001";
    constant OP_XOR : std_ulogic_vector(OpcodeBits-1 downto 0) := "010010";
    constant OP_NOT : std_ulogic_vector(OpcodeBits-1 downto 0) := "010011";
    constant OP_ADD : std_ulogic_vector(OpcodeBits-1 downto 0) := "010100";
    constant OP_ADDC : std_ulogic_vector(OpcodeBits-1 downto 0) := "010101";
    constant OP_SUB : std_ulogic_vector(OpcodeBits-1 downto 0) := "010110";
    constant OP_SUBC : std_ulogic_vector(OpcodeBits-1 downto 0) := "010111";
    constant OP_COMP : std_ulogic_vector(OpcodeBits-1 downto 0) := "011000";
    constant OP_INC : std_ulogic_vector(OpcodeBits-1 downto 0) := "011010";
    constant OP_DEC : std_ulogic_vector(OpcodeBits-1 downto 0) := "011011";
    constant OP_SHL : std_ulogic_vector(OpcodeBits-1 downto 0) := "011100";
    constant OP_SHR : std_ulogic_vector(OpcodeBits-1 downto 0) := "011101";
    constant OP_SHLC : std_ulogic_vector(OpcodeBits-1 downto 0) := "011110";
    constant OP_SHRC : std_ulogic_vector(OpcodeBits-1 downto 0) := "011111";

    --Cycle Control
    constant Cycle_1 : std_ulogic_vector(2 downto 0) := "001";
    constant Cycle_2 : std_ulogic_vector(2 downto 0) := "010";
    constant Cycle_3 : std_ulogic_vector(2 downto 0) := "100";
end package;
