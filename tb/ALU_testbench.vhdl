library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


library work;
use work.prol16_package.all;

entity ALU_testbench is
end;


architecture Behaviour of ALU_testbench is
    component ALU
        port (
            SideA : in DataVec;
            SideB : in DataVec;
            AluResult : out DataVec;
            CarryIn : in std_ulogic;
            CarryOut : out std_ulogic;
            ZeroOut : out std_ulogic;
            FuncControl : in FuncControlVec);
    end component;
    signal sideASignal, sideBSignal : DataVec;
    signal dataOutSignal : DataVec;
    signal carryInSignal : std_ulogic;
    signal carryOutSignal : std_ulogic;
    signal funcControlSignal : std_ulogic;
begin
    ALU_comp: ALU port map (sideASignal, sideBSignal, dataOutSignal, carryInSignal, carryOutSignal, funcControlSignal);
    process begin:
        sideASignal < "00";
    end process;
end;

