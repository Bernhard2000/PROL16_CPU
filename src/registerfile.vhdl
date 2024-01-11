library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



library work;
use work.prol16_package.all;

entity RegisterFile is
    port(
        RegFileIn : in DataVec;
        RegSelRa : in std_ulogic_vector(RegFileBits-1 downto 0);
        RegSelRb : in std_ulogic_vector(RegFileBits-1 downto 0);
        ClkEnRegFile : in std_ulogic;
        Clk : in std_ulogic;
        Reset : in std_ulogic;
        RaValue : out DataVec;
        RbValue : out DataVec
    );
end RegisterFile;

architecture Behavioural of RegisterFile is
signal registers : RegFile;

begin               
   writeRegFile : process (Clk, Reset) is
   begin
        if Reset = ResetActive then
            Registers <= (others => (others => '0')); 

        elsif rising_Edge(Clk) then  
            
            --Have to use this abomination to implement writing to the RegFile for the Elaborated Design to make sense.
            for i in Registers'range loop
                    if i = unsigned(RegSelRa) then
                        if ClkEnRegFile = '1' then
                            Registers(i) <= RegFileIn;  -- Write
                    end if;
                end if;
            end loop;
            
            --Nicer Solution that results in ROM-Blocks being used for no appearant reason.
            --if ClkEnRegFile = '1' then
            --    Registers(to_integer(unsigned(RegSelRa))) <= RegFileIn;  -- Write
            --end if; 
        end if;
         
   end process;  
   RaValue <= Registers(to_integer(unsigned(RegSelRa)));
   RbValue <= Registers(to_integer(unsigned(RegSelRb)));            
end Behavioural;