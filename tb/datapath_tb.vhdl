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

entity Datapath_Testbench is
end Datapath_Testbench;


architecture Behavioral of Datapath_Testbench is
    component DataPath is
        port (
    ClkEnPC : in std_ulogic; -- clock enable of register PC
    ClkEnRegFile : in std_ulogic; -- clock enable of register file
    ClkEnOpcode : in std_ulogic; -- clock enable of register Opcode
    SelPC
     : in std_ulogic; -- selectInput of SelPC-MUX
    SelLoad
     : in std_ulogic; -- selectInput of SelLoad-MUX
    SelAddr
     : in std_ulogic; -- selectInput of SelAddr-MUX
    RegOpcode
     : out OpcodeVec; -- current opcode info CoreControl
    ---------------------------------- [ ALU ] ------------------------
    CarryIn
     : in std_ulogic; -- connects to carryIn input of ALU
    CarryOut
     : out std_ulogic; -- connects to carryOut output of ALU
    ZeroOut
     : out std_ulogic; -- connects to ZeroOut output of ALU
    ALUFunc
     : in std_ulogic_vector(3 downto 0); -- selects the function
    -- Of the ALU
    ---------------------------------- [ MEM ] ------------------------
    MemAddr
     : out DataVec; -- address wires of memory
    MemWrData
     : out DataVec; -- data wires for writing the memory
    MemRdData
     : in DataVec; -- data wires for reading the memory
    ---------------------------------- [ clk,reset ] ------------------
    Reset
     : in std_ulogic; -- reset inpunt
    ZuluClk
     : in std_ulogic); -- clock input
    end component;
    
    signal ClkEnPC : std_ulogic;
    signal ClkEnRegFile : std_ulogic;
    signal ClkEnOpcode : std_ulogic;
    signal SelPC : std_ulogic;
    signal SelLoad : std_ulogic;
    signal SelAddr : std_ulogic;
    signal RegOpcode : OpcodeVec;
    signal CarryIn : std_ulogic;
    signal CarryOut : std_ulogic;
    signal ZeroOut : std_ulogic;
    signal ALUFunc : std_ulogic_vector(3 downto 0);
    signal MemAddr : DataVec;
    signal MemWrData : DataVec;
    signal MemRdData : DataVec;
    signal Reset : std_ulogic;
    signal ZuluClk : std_ulogic;


begin
    register_comp: DataPath port map(ClkEnPC => ClkEnPC, ClkEnRegFile => ClkEnRegFile, ClkEnOpcode => ClkEnOpcode, SelPC => SelPC, SelLoad => SelLoad, SelAddr => SelAddr, RegOpcode => RegOpcode, CarryIn => CarryIn, CarryOut => CarryOut, ZeroOut => ZeroOut, ALUFunc => ALUFunc, MemAddr => MemAddr, MemWrData => MemWrData, MemRdData => MemRdData, Reset => Reset, ZuluClk => ZuluClk);
    process begin
        ClkEnRegFile <= '1';
        ZuluClk <= '0';
        wait for 10 ns;
        ZuluClk <= '1';
        wait for 10 ns;
        --State: All registers 0
        

        ZuluClk <= '0';
        wait for 10 ns;
        ZuluClk <= '1';
        wait for 10 ns;
        

        --State: Reg0: 0, others 0
        MemRdData <= std_ulogic_vector(TO_UNSIGNED(0, MemRdData'length));
        ALUFunc <= ALU_SideA;
        assert to_integer(unsigned(RaValue)) = 0
        report "Ra: Input: 128, Stored: 0, Output: "& integer'image(to_integer(unsigned(RaValue)));
        assert to_integer(unsigned(RaValue)) = 0
        report "Rb: Stored: 24, Output: "& integer'image(to_integer(unsigned(RbValue)));

        ZuluClk <= '0';
        wait for 10 ns;
        ZuluClk <= '1';
        wait for 10 ns;

        --State: Reg0: 24, Reg1: 128, others 0
        RegFileIn <= std_ulogic_vector(TO_UNSIGNED(256, RaValue'length));
        RegSelRa <= std_ulogic_vector(TO_UNSIGNED(2, RegSelRa'length));
        RegSelRb <= std_ulogic_vector(TO_UNSIGNED(1, RegSelRb'length));
        assert to_integer(unsigned(RaValue)) = 0
        report "Ra: Input: 128, Stored: 0, Output: "& integer'image(to_integer(unsigned(RaValue)));
        assert to_integer(unsigned(RaValue)) = 0
        report "Rb: Stored: 128, Output: "& integer'image(to_integer(unsigned(RbValue)));

        ZuluClk <= '0';
        wait for 10 ns;
        ZuluClk <= '1';
        wait for 10 ns;
    end process;

end Behavioral;
