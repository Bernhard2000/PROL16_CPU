library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;


library work;
use work.prol16_package.all;

entity AddDataVec is
    port (
        SideA : in DataVec;
        SideB : in DataVec;
        AluResult : out DataVec;
        CarryIn : in std_ulogic;
        CarryOut : out std_ulogic;
        FuncControl : in std_ulogic);
end AddDataVec;

architecture adder of AddDataVec is 
    procedure Add (A,B:DataVec; CI:std_ulogic;
        signal SUM:out DataVec; signal CO:out std_ulogic) is
        variable Tmp : unsigned(DataVec'high+1 downto 0); -- one bit more (for carry)
    begin
        Tmp :=(unsigned('0' & A) + unsigned('0' & B)) + CI;
        SUM <= std_ulogic_vector(Tmp(DataVec'range)); -- type conversion
        CO <= Tmp(DataVec'high+1);
    end procedure;
    
begin
    process_ALU :  process(SideA, SideB, CarryIn, FuncControl)
    begin
        case FuncControl is
            when '0' => Add(SideA,SideB,CarryIn,AluResult,CarryOut);
            when '1' => Add(SideA, not SideB, not CarryIn,AluResult,CarryOut);
            when others => AluResult <= SideA;
        end case;
    end process;
end adder;
