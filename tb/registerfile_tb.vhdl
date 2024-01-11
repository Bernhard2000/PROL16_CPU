----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/30/2023 07:35:21 PM
-- Design Name: 
-- Module Name: Registerfile_Testbench - Behavioral
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

entity Registerfile_Testbench is
end Registerfile_Testbench;


architecture Behavioral of Registerfile_Testbench is
    component RegisterFile is
        port(
            RegFileIn : in DataVec;
            RegSelRa : in std_ulogic_vector(RegFileBits-1 downto 0);
            RegSelRb : std_ulogic_vector(RegFileBits-1 downto 0);
            ClkEnRegFile : in std_ulogic;
            Clk : in std_ulogic;
            Reset : in std_ulogic;
            RaValue : out DataVec;
            RbValue : out DataVec
        );
    end component;
    
    signal RegFileIn : DataVec;
    signal RegSelRa : std_ulogic_vector(RegFileBits-1 downto 0);
    signal RegSelRb : std_ulogic_vector(RegFileBits-1 downto 0);
    signal ClkEnRegFile : std_ulogic;
    signal Clk : std_ulogic;
    signal Reset : std_ulogic;
    signal SelLoad : std_ulogic;
    signal RaValue, RbValue : DataVec;
    signal zeroOut_Sig : std_ulogic;
    signal funcControl_Sig : std_ulogic_vector(3 downto 0);
    signal aluResult_Sig : DataVec;


begin
    register_comp: RegisterFile port map(RegFileIn, RegSelRa, RegSelRb, ClkEnRegFile, Clk, Reset, RaValue, RbValue);
    process begin
        ClkEnRegFile <= '1';
        Clk <= '0';
        wait for 10 ns;
        Clk <= '1';
        wait for 10 ns;
        --State: All registers 0
        RegFileIn <= std_ulogic_vector(TO_UNSIGNED(24, RaValue'length));
        RegSelRa <= std_ulogic_vector(TO_UNSIGNED(0, RegSelRa'length));
        RegSelRb <= std_ulogic_vector(TO_UNSIGNED(1, RegSelRb'length));
        assert to_integer(unsigned(RaValue)) = 0
        report "Input: 24, Stored: 0, Output: "& integer'image(to_integer(unsigned(RaValue)));
        assert to_integer(unsigned(RaValue)) = 0
        report "Stored: 0, Output: "& integer'image(to_integer(unsigned(RbValue)));

        Clk <= '0';
        wait for 10 ns;
        Clk <= '1';
        wait for 10 ns;
        

        --State: Reg0: 24, others 0
        RegFileIn <= std_ulogic_vector(TO_UNSIGNED(128, RaValue'length));
        RegSelRa <= std_ulogic_vector(TO_UNSIGNED(1, RegSelRa'length));
        RegSelRb <= std_ulogic_vector(TO_UNSIGNED(0, RegSelRb'length));
        assert to_integer(unsigned(RaValue)) = 0
        report "Ra: Input: 128, Stored: 0, Output: "& integer'image(to_integer(unsigned(RaValue)));
        assert to_integer(unsigned(RaValue)) = 0
        report "Rb: Stored: 24, Output: "& integer'image(to_integer(unsigned(RbValue)));

        Clk <= '0';
        wait for 10 ns;
        Clk <= '1';
        wait for 10 ns;

        --State: Reg0: 24, Reg1: 128, others 0
        RegFileIn <= std_ulogic_vector(TO_UNSIGNED(256, RaValue'length));
        RegSelRa <= std_ulogic_vector(TO_UNSIGNED(2, RegSelRa'length));
        RegSelRb <= std_ulogic_vector(TO_UNSIGNED(1, RegSelRb'length));
        assert to_integer(unsigned(RaValue)) = 0
        report "Ra: Input: 256, Stored: 0, Output: "& integer'image(to_integer(unsigned(RaValue)));
        assert to_integer(unsigned(RaValue)) = 0
        report "Rb: Stored: 128, Output: "& integer'image(to_integer(unsigned(RbValue)));

        Clk <= '0';
        wait for 10 ns;
        Clk <= '1';
        wait for 10 ns;
        
         --State: Reg0: 24, Reg1: 128, Reg2: 256 others 0
        RegFileIn <= std_ulogic_vector(TO_UNSIGNED(512, RaValue'length));
        RegSelRa <= std_ulogic_vector(TO_UNSIGNED(0, RegSelRa'length));
        RegSelRb <= std_ulogic_vector(TO_UNSIGNED(2, RegSelRb'length));
        assert to_integer(unsigned(RaValue)) = 0
        report "Ra: Input: 512, Stored: 24, Output: "& integer'image(to_integer(unsigned(RaValue)));
        assert to_integer(unsigned(RaValue)) = 0
        report "Rb: Stored: 256, Output: "& integer'image(to_integer(unsigned(RbValue)));

        Clk <= '0';
        wait for 10 ns;
        Clk <= '1';
        wait for 10 ns;
        
        --State: Reg0: 24, Reg1: 128, Reg2: 256 others 0
        RegFileIn <= std_ulogic_vector(TO_UNSIGNED(1024, RaValue'length));
        RegSelRa <= std_ulogic_vector(TO_UNSIGNED(0, RegSelRa'length));
        RegSelRb <= std_ulogic_vector(TO_UNSIGNED(0, RegSelRb'length));
        assert to_integer(unsigned(RaValue)) = 512
        report "Ra: Input: 1024, Stored: 512, Output: "& integer'image(to_integer(unsigned(RaValue)));
        assert to_integer(unsigned(RaValue)) = 512
        report "Rb: Stored: 256, Output: "& integer'image(to_integer(unsigned(RbValue)));

        Clk <= '0';
        wait for 10 ns;
        Clk <= '1';
        wait for 10 ns;
    end process;

end Behavioral;
