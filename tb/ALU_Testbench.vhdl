----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/30/2023 07:35:21 PM
-- Design Name: 
-- Module Name: ALU_Testbench - Behavioral
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
use IEEE.NUMERIC_STD.all;

library work;
use work.prol16_package.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU_Testbench is
end ALU_Testbench;


architecture Behavioral of ALU_Testbench is
    component ALU 
        Port ( SideA : in DataVec;
               SideB : in DataVec;
               CarryIn : in STD_ULOGIC;
               FuncControl : in STD_ULOGIC_VECTOR (3 downto 0);
               AluResult : out DataVec;
               CarryOut : out STD_ULOGIC;
               ZeroOut : out STD_ULOGIC);
    end component;
    
    signal sideA_Sig, sideB_Sig : DataVec;
    signal carryIn_Sig : std_ulogic;
    signal carryOut_Sig : std_ulogic;
    signal zeroOut_Sig : std_ulogic;
    signal funcControl_Sig : std_ulogic_vector(3 downto 0);
    signal aluResult_Sig : DataVec;


begin
    alu_comp: ALU port map(sideA_Sig, sideB_Sig, carryIn_Sig, funcControl_Sig, aluResult_Sig , carryOut_Sig, zeroOut_Sig);
    process begin
        --SideA
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(24, sideA_Sig'length));
        sideB_Sig <= std_ulogic_vector(TO_UNSIGNED(69, sideA_Sig'length));
        carryIn_Sig <= '0';
        funcControl_Sig <= "0000";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 24
        report "Input: SideA 24 Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
        --SideB
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(24, sideA_Sig'length));
        sideB_Sig <= std_ulogic_vector(TO_UNSIGNED(69, sideA_Sig'length));
        funcControl_Sig <= "0001";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 69
        report "Input: SideB 69 Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
        --SideA AND SideB
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(21, sideA_Sig'length)); --10101
        sideB_Sig <= std_ulogic_vector(TO_UNSIGNED(6, sideA_Sig'length));  --00110
        funcControl_Sig <= "0010";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 4
        report "Input: 21 AND 6 = 4 Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
        --SideA OR SideB
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(21, sideA_Sig'length)); --10101
        sideB_Sig <= std_ulogic_vector(TO_UNSIGNED(6, sideA_Sig'length));  --00110
        funcControl_Sig <= "0011";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 23
        report "Input: 21 OR 6 = 23 Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
        --SideA OR SideB
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(23, sideA_Sig'length));
        sideB_Sig <= std_ulogic_vector(TO_UNSIGNED(104, sideA_Sig'length));
        funcControl_Sig <= "0011";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 127
        report "Input: 23 OR 104 = 127 Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
        --SideA XOR SideB
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(21, sideA_Sig'length)); --10101
        sideB_Sig <= std_ulogic_vector(TO_UNSIGNED(6, sideA_Sig'length));  --00110
        funcControl_Sig <= "0100";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 19
        report "Input: 21 XOR 6 = 19 Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
        --NOT SideA
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(21, sideA_Sig'length)); --10101
        funcControl_Sig <= "0101";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 65514
        report "Input: NOT 21 = 65514 Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
        --Shift left
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(128, sideA_Sig'length));
        carryIn_Sig <= '0';
        funcControl_Sig <= "0110";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 256
        report "Input: Shift Left 128, Carry 0 = 256  Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
        --Shift left carryIn
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(128, sideA_Sig'length));
        carryIn_Sig <= '1';
        funcControl_Sig <= "0110";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 257
        report "Input: Shift Left 128, Carry 1 = 257  Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
        
        --Shift right
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(128, sideA_Sig'length));
        carryIn_Sig <= '0';
        funcControl_Sig <= "0111";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 64
        report "Input: Shift right 128, Carry 0 = 64 Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
        --Shift right CarryIn
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(128, sideA_Sig'length));
        carryIn_Sig <= '1';
        funcControl_Sig <= "0111";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 32832
        report "Input: Shift right 128, Carry 1 = 32832 Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
        --SideA + SideB + CarryIn
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(12894, sideA_Sig'length));
        sideB_Sig <= std_ulogic_vector(TO_UNSIGNED(246, sideA_Sig'length)); 
        carryIn_Sig <= '1';
        funcControl_Sig <= "1000";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 13141
        report "Input: 12894 + 246 + 1 = 13141 Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
        --SideA - SideB - CarryIn
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(146, sideA_Sig'length));
        sideB_Sig <= std_ulogic_vector(TO_UNSIGNED(17, sideA_Sig'length)); 
        carryIn_Sig <= '1';
        funcControl_Sig <= "1001";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 128
        report "Input: 146 - 17 - 1 = 128 Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
        --SideA - SideB - CarryIn
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(146, sideA_Sig'length));
        sideB_Sig <= std_ulogic_vector(TO_UNSIGNED(17, sideA_Sig'length)); 
        carryIn_Sig <= '0';
        funcControl_Sig <= "1001";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 129
        report "Input: 146 - 17 = 129 Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
        --SideA - SideB - CarryIn
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(2305, sideA_Sig'length));
        sideB_Sig <= std_ulogic_vector(TO_UNSIGNED(2305, sideA_Sig'length)); 
        carryIn_Sig <= '0';
        funcControl_Sig <= "1001";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 0
        report "Input: 2305 - 2305 - 0 Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
        assert zeroOut_Sig = '1'
        report "AluResult: " &integer'image(to_integer(unsigned(aluResult_Sig))) & ", ZeroOut: 0";  
    
        --SideA + 1
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(24, sideA_Sig'length));
        carryIn_Sig <= '0';
        funcControl_Sig <= "1010";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 25
        report "Input: 24 + 1 = 25  Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
        --SideA - 1
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(24, sideA_Sig'length));
        carryIn_Sig <= '0';
        funcControl_Sig <= "1011";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 23
        report "Input: 24 - 1 = 23  Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
        --Invalid command
        sideA_Sig <= std_ulogic_vector(TO_UNSIGNED(24, sideA_Sig'length));
        sideB_Sig <= std_ulogic_vector(TO_UNSIGNED(17, sideA_Sig'length)); 
        carryIn_Sig <= '1';
        funcControl_Sig <= "1111";
        wait for 100 ns;
        assert to_integer(unsigned(aluResult_Sig)) = 0
        report "Input: INVALID = 0 Output: "& integer'image(to_integer(unsigned(aluResult_Sig)));
        
    end process;

end Behavioral;
