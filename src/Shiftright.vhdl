library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;

library work;
use work.prol16_package.all;


entity Shiftright is
    port (DataIn : in DataVec;
          CarryIn : in std_logic;
          DataOut : out DataVec;
          CarryOut: out std_logic);
end Shiftright;

architecture Behavioral of Shiftright is
begin
    DataOut <= CarryIn & DataIn(DataVec_length-1 downto 1) ;
    CarryOut <= DataIn(0);
end Behavioral;
