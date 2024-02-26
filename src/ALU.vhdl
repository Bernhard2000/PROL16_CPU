----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/30/2023 06:24:40 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


library work;
use work.prol16_package.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( SideA : in DataVec;
           SideB : in DataVec;
           CarryIn : in STD_ULOGIC;
           FuncControl : in STD_ULOGIC_VECTOR (3 downto 0);
           AluResult : out DataVec;
           CarryOut : out STD_ULOGIC;
           ZeroOut : out STD_ULOGIC);
end ALU;

architecture Behavioral of ALU is
    signal aAndB : DataVec;
    signal aOrB : DataVec;
    signal aXorB : DataVec;
    signal notA : DataVec;
    
    signal shift_left_Sig : DataVec;
    signal shift_right_Sig : Datavec;
    
    signal sideB_Sig : DataVec;
    signal adderResult_Sig : DataVec;
    signal aluResult_Sig : DataVec;
    signal carryOutLeftS_Sig : STD_ULOGIC;
    signal carryOutRightS_Sig : STD_ULOGIC;
    signal carryOutAdder_Sig : STD_ULOGIC;

    
    component Shiftleft
        port (DataIn : in DataVec;
            CarryIn: in std_logic;
            DataOut : out DataVec;
            CarryOut: out std_logic);
    end component;
    component Shiftright
        port (DataIn : in DataVec;
            CarryIn: in std_logic;
            DataOut : out DataVec;
            CarryOut: out std_logic);
    end component;
    
    component AddDataVec
        port (
            SideA : in DataVec;
            SideB : in DataVec;
            AluResult : out DataVec;
            CarryIn : in std_ulogic;
            CarryOut : out std_ulogic;
            FuncControl : in std_ulogic);
    end component;
    
begin
    shiftLeft_comp: Shiftleft port map(SideA, CarryIn, shift_left_Sig, carryOutLeftS_Sig);
    shiftRight_comp: Shiftright port map(SideA, CarryIn, shift_right_Sig, carryOutRightS_Sig);
    addDataVec_comp: AddDataVec port map (SideA => sideA, SideB => sideB_Sig, AluResult => adderResult_Sig, CarryIn => CarryIn, CarryOut => carryOutAdder_Sig, FuncControl => FuncControl(0));   
    
    aAndB <= SideA and SideB;
    aOrB <= SideA or SideB;
    aXorB <= SideA xor SideB;
    notA <= not SideA; 
    
    with FuncControl select
        aluResult_Sig <= SideA when ALU_SideA,
                     SideB when ALU_SideB,
                     aAndB when ALU_AandB,
                     aOrB when ALU_AorB,
                     aXorB when ALU_AxorB,
                     notA when ALU_NotA,
                     shift_left_Sig when ALU_ShiftALeft,
                     shift_right_Sig when ALU_ShiftARight,
                     adderResult_Sig when ALU_AplusBplusCarry,
                     adderResult_Sig when ALU_AminusBminusCarry,
                     adderResult_Sig when ALU_A_INC,
                     adderResult_Sig when ALU_A_DEC,
                     DataVec_DontCare when others;
                     
                 
    with FuncControl select   
        CarryOut <= carryOutLeftS_Sig when ALU_ShiftALeft,
                    carryOutRightS_Sig when ALU_ShiftARight,
                    carryOutAdder_Sig when ALU_AplusBplusCarry,
                    carryOutAdder_Sig when ALU_AminusBminusCarry,
                    '0' when others;      
    
    with FuncControl select  
       sideB_Sig <= std_ulogic_vector(TO_UNSIGNED(1, DataVec_length)) when ALU_A_INC,
                    std_ulogic_vector(TO_UNSIGNED(1, DataVec_length)) when ALU_A_DEC,
                    SideB when others;              
    AluResult <= aluResult_Sig;
    
    process_ZeroOut : process(aluResult_Sig)
    begin
        report "ALUResult: " &integer'image(to_integer(unsigned(aluResult_Sig))) & "Func: " &integer'image(to_integer(unsigned(FuncControl))) & "SideA: " &integer'image(to_integer(unsigned(SideA)));
        if unsigned(aluResult_Sig) = 0 then
            ZeroOut <= '1';
        else 
            ZeroOut <= '0';
        end if;
    end process;
end Behavioral;
