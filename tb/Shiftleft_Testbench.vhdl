library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


library work;
use work.cpu_package.all;

entity Shiftleft_testbench is
end;


architecture Behaviour of Shiftleft_testbench is
    component Shiftleft
        port (DataIn : in DataVec;
            CarryIn: in std_logic;
            DataOut : out DataVec;
            CarryOut: out std_logic);
    end component;
    signal dataInSignal: std_ulogic_vector(Data_Width-1 downto 0);
    signal dataOutSignal : std_ulogic_vector(Data_Width-1 downto 0);
    signal carryInSignal : std_ulogic;
    signal carryOutSignal : std_ulogic;
begin
    shiftLeft_comp: Shiftleft port map(dataInSignal, carryInSignal, dataOutSignal, carryOutSignal);
        process begin
            dataInSignal <= std_ulogic_vector(TO_UNSIGNED(1, dataInSignal'length));
            carryInSignal <= '0';
            wait for 100 ns;
            assert to_integer(unsigned(dataOutSignal)) = 2
            report "Input: 1 Output: "& integer'image(to_integer(unsigned(dataOutSignal)));

            dataInSignal <= std_ulogic_vector(TO_UNSIGNED(65535, dataInSignal'length));
            carryInSignal <= '0';
            wait for 100 ns;
            assert to_integer(unsigned(dataOutSignal)) = 65534
            report "Input: 655535 Output: "& integer'image(to_integer(unsigned(dataOutSignal)));

            dataInSignal <= std_ulogic_vector(TO_UNSIGNED(1, dataInSignal'length));
            carryInSignal <= '1';
            wait for 100 ns;
            assert to_integer(unsigned(dataOutSignal)) = 3
            report "Input: 1 & 1 Output: "& integer'image(to_integer(unsigned(dataOutSignal)));


            dataInSignal <= std_ulogic_vector(TO_UNSIGNED(65535, dataInSignal'length));
            carryInSignal <= '1';
            wait for 100 ns;
            assert to_integer(unsigned(dataOutSignal)) = 65535
            report "Input: 655535 & 1 Output: "& integer'image(to_integer(unsigned(dataOutSignal)));
        end process;
end;
