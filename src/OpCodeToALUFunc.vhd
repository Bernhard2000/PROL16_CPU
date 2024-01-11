----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/19/2023 07:12:56 PM
-- Design Name: 
-- Module Name: OpCodeToALUFunc - Behavioral
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

library work;
use work.prol16_package.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity OpCodeToALUFunc is
    port ( 
        OpCode : in std_ulogic_vector(OpcodeBits-1 downto 0);
        AluFunc : out FuncControlVec
    );
end OpCodeToALUFunc;

architecture Behavioral of OpCodeToALUFunc is
    
begin
    AluFunc <= ALU_AandB when OpCode = OP_AND else
               ALU_AorB when OpCode = OP_OR else
               ALU_AxorB when OpCode = OP_XOR else
               ALU_NotA when OpCode = OP_NOT else
               ALU_ShiftALeft when OpCode = OP_SHL else
               ALU_ShiftARight when OpCode = OP_SHR else
               ALU_ShiftALeft when OpCode = OP_SHLC else
               ALU_ShiftARight when OpCode = OP_SHRC else
               ALU_AplusBplusCarry when OpCode = OP_ADD else  
               ALU_AplusBplusCarry when OpCode = OP_ADDC else  
               ALU_AplusBplusCarry when OpCode = OP_INC else 
               ALU_AminusBminusCarry when OpCode = OP_SUB else 
               ALU_AminusBminusCarry when OpCode = OP_SUBC else 
               ALU_AminusBminusCarry when OpCode = OP_DEC else
               ALU_DONT_CARE;
end Behavioral;
