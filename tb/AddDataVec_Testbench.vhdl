library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


library work;
use work.prol16_package.all;

entity Arithmetic_testbench is
end;


architecture Behaviour of Arithmetic_testbench is
    component AddDataVec
        port (
            SideA : in DataVec;
            SideB : in DataVec;
            AluResult : out DataVec;
            CarryIn : in std_ulogic;
            CarryOut : out std_ulogic;
            FuncControl : in std_ulogic);
    end component;
    signal sideASignal, sideBSignal : DataVec;
    signal dataOutSignal : DataVec;
    signal carryInSignal : std_ulogic;
    signal carryOutSignal : std_ulogic;
    signal funcControlSignal : std_ulogic;
begin
    AddDataVec_comp: AddDataVec port map(sideASignal, sideBSignal, dataOutSignal, carryInSignal, carryOutSignal, funcControlSignal);
        process begin
            sideASignal <= std_ulogic_vector(TO_UNSIGNED(1, sideASignal'length));
            sideBSignal <= std_ulogic_vector(TO_UNSIGNED(1, sideBSignal'length));
            funcControlSignal <= '0';
            carryInSignal <= '0';
            wait for 100 ns;
            assert to_integer(unsigned(dataOutSignal)) = 2
            report "Input: 1+1 Output: "& integer'image(to_integer(unsigned(dataOutSignal)));

            sideASignal <= std_ulogic_vector(TO_UNSIGNED(24, sideASignal'length));
            sideBSignal <= std_ulogic_vector(TO_UNSIGNED(1, sideBSignal'length));
            funcControlSignal <= '0';
            carryInSignal <= '0';
            wait for 100 ns;
            assert to_integer(unsigned(dataOutSignal)) = 25
            report "Input: 24+1=25 Output: "& integer'image(to_integer(unsigned(dataOutSignal)));

            sideASignal <= std_ulogic_vector(TO_UNSIGNED(26, sideASignal'length));
            sideBSignal <= std_ulogic_vector(TO_UNSIGNED(43, sideBSignal'length));
            funcControlSignal <= '0';
            carryInSignal <= '0';
            wait for 100 ns;
            assert to_integer(unsigned(dataOutSignal)) = 69
            report "Input: 26+43=69 Output: "& integer'image(to_integer(unsigned(dataOutSignal)));

            sideASignal <= std_ulogic_vector(TO_UNSIGNED(26, sideASignal'length));
            sideBSignal <= std_ulogic_vector(TO_UNSIGNED(43, sideBSignal'length));
            funcControlSignal <= '0';
            carryInSignal <= '1';
            wait for 100 ns;
            assert to_integer(unsigned(dataOutSignal)) = 70
            report "Input: 26+43+1=70 Output: "& integer'image(to_integer(unsigned(dataOutSignal)));

            sideASignal <= std_ulogic_vector(TO_UNSIGNED(2, sideASignal'length));
            sideBSignal <= std_ulogic_vector(TO_UNSIGNED(1, sideBSignal'length));
            funcControlSignal <= '1';
            carryInSignal <= '0';
            wait for 100 ns;
            assert to_integer(unsigned(dataOutSignal)) = 1
            report "Input: 2-1=1 Output: "& integer'image(to_integer(unsigned(dataOutSignal)));
        end process;
end;
