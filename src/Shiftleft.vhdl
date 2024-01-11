library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;

library work;
use work.prol16_package.all;


entity Shiftleft is
    port (DataIn : in DataVec;
          CarryIn: in std_logic;
          DataOut : out DataVec;
          CarryOut: out std_logic);
end Shiftleft;

architecture Behavioral of Shiftleft is
begin
    DataOut <= DataIn(DataVec_length-2 downto 0) & CarryIn;
    CarryOut <= DataIn(DataVec_length-1);
end Behavioral;
