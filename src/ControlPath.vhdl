library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;



library work;
use work.prol16_package.all;


entity ControlPath is
    port ( 
        Reset : in std_ulogic; -- reset inpunt
        ZuluClk : in std_ulogic; -- clock input
        
        RegOpcode : in OpcodeVec;
        ALU_CarryOut    : in std_ulogic;
        ALU_ZeroOut     : in std_ulogic;

        MemRdStrobe : out std_ulogic; -- memory read strobe
        MemWrStrobe : out std_ulogic; -- memory write strobe

        ClkEnOpcode     : out std_ulogic;
        ClkEnPC         : out std_ulogic;
        ClkEnRegFile    : out std_ulogic;
        SelLoad         : out std_ulogic;
        SelAddr         : out std_ulogic;
        SelPC           : out std_ulogic;
        ALU_CarryIn     : out std_ulogic;

         ---------------------------------- [ ALU ] ------------------------
         ALUFunc : out std_ulogic_vector(3 downto 0) -- selects the function of the ALU        
    );
end ControlPath;


architecture Behavioral of ControlPath is  
    component CounterShifter is
        generic ( Size : natural := 1); -- data width is 2^n (2^1=2 Bits)
        port (
            PortA : in std_ulogic_vector(2**Size-1 downto 0); -- data input
            PortQ : out std_ulogic_vector(2**Size-1 downto 0); -- data result
            ShiftDigits : in std_ulogic_vector(Size-1 downto 0) -- shift width
        );
    end component;

 
    signal cycle : std_ulogic_vector(2 downto 0) := Cycle_1;
    signal ClkEnPC_sig, ClkEnRegFile_sig, SelPC_sig, SelLoad_sig, SelAddr_sig, ClkEnOpcode_sig : std_ulogic;
    signal instrTerminate : std_ulogic;
    
    
    function ulogic_vector_to_OpcodeValueType(data_vector : std_ulogic_vector) return OpcodeValueType is
        variable result : OpcodeValueType;
      begin
        result.Code := data_vector(OpcodeBits-1 downto 0); --5-0
        result.Ra := data_vector(RegFileBits + OpcodeBits - 1 downto OpcodeBits); --10-6
        result.Rb := data_vector(2*RegFileBits + OpcodeBits - 1 downto RegFileBits + OpcodeBits); --15-11
        result.Imm := data_vector(DataVec_length-1 downto 0);
        return result;
      end function;
begin

    clockCycle: process(ZuluClk, Reset) is
    begin
         if Reset = '1' then
           cycle <= Cycle_1;
          report "Reset";
        elsif rising_edge(ZuluClk) then
            if instrTerminate = '1' then
               cycle <= Cycle_1;
               report "Terminate instruction";
           else
                cycle <= cycle(1 downto 0) & cycle(2);
                report "New clock cycle: " & integer'image(to_integer(unsigned(cycle))); 
           end if;
      end if;
           
           
    end process clockCycle;
    
    readWriteFlag: process(ZuluClk, cycle) is
    begin
        if rising_edge(ZuluClk) then
            case cycle is
                when Cycle_1 =>
                    MemRdStrobe <= '1';
                    MemWrStrobe <= '0'; 
                when Cycle_2 =>
                    if RegOpCode =  OP_STORE then
                        MemWrStrobe <= '1';
                        MemRdStrobe <= '0';
                     elsif RegOpCode = OP_LOAD or RegOpCode = OP_LOADI then
                        MemWrStrobe <= '0';
                        MemRdStrobe <= '1';
                     else
                        MemWrStrobe <= '0';
                        MemRdStrobe <= '0'; 
                     end if;
                when Cycle_3 =>
                    MemWrStrobe <= '0';
                    MemRdStrobe <= '1';
                when others =>
                    report "Unreachable clock cycle: " & integer'image(to_integer(unsigned(cycle))); 
                    MemWrStrobe <= '0';
                    MemRdStrobe <= '1';
            end case;
        end if;
    end process readWriteFlag;

    readOpCode: process(ZuluClk, Reset, RegOpcode) is
        variable opCode : OpcodeVec;
    begin
       ClkEnOpCode <= instrTerminate;
       if rising_edge(ZuluClk) then

        case cycle is
            when Cycle_1 => --increment PC
                report "Increment PC";
                instrTerminate <= '1';
                ClkEnPC <= '1';
                SelPC <= '1';
                ALU_CarryIn <= '0';
                --ClkEnOpcode <= '0';
                SelAddr <= '0';
                SelLoad <= 'X';
                ClkEnRegFile <= '0';
                AluFunc <= ALU_A_INC;           
            when Cycle_2 =>
                report "Opcode: " &integer'image(to_integer(unsigned(RegOpcode)));
                --ClkEnOpcode <= '0';
                    case RegOpcode is 
                        when OP_LOADI | OP_LOAD | OP_STORE =>
                            instrTerminate <= '0';
                        when others =>
                            instrTerminate <= '1';
                        end case;             

                    case RegOpcode is 
                        when OP_LOADI =>
                            report "LOADI";
                            SelAddr <= '0';
                            SelLoad <= '1';
                            ClkEnRegFile <= '1';
            
                            AluFunc <= ALU_A_INC;
                            ClkEnPC <= '1';
                            SelPC <= '1';

                        when OP_LOAD =>
                            report "LOAD";
                            SelAddr <= '1';
                            SelLoad <= '1';
                            ClkEnRegFile <= '0';
            
                            AluFunc <= ALU_DONT_CARE;
                            ClkEnPC <= '0';
                            SelPC <= 'X';

                        when OP_STORE =>
                            report "STORE";
                            SelAddr <= '1';
                            SelLoad <= 'X';
                            ClkEnRegFile <= '0';
            
                            AluFunc <= ALU_DONT_CARE;
                            ClkEnPC <= '1';
                            SelPC <= '1';
                        when OP_JUMP =>
                            report "JUMP";
                            SelPC <= '0';
                            ClkEnPC <= '1';
                            SelLoad <= 'X';
                            AluFunc <= "XXXX";
                        when OP_JUMPC =>
                            report "JUMPC";
                            if ALU_CarryOut = '1' then
                                SelPC <= '0';
                                ClkEnPC <= '1';
                                SelLoad <= 'X';
                                AluFunc <= "XXXX";
                            else
                                SelPC <= 'X';
                                ClkEnPC <= '0';
                                SelLoad <= 'X';
                                AluFunc <= "XXXX";
                            end if;
                        when OP_JUMPZ =>
                            report "JUMPZ";
                            if ALU_ZeroOut = '1' then
                                SelPC <= '0';
                                ClkEnPC <= '1';
                                SelLoad <= 'X';
                                AluFunc <= "XXXX";
                            else
                                SelPC <= 'X';
                                ClkEnPC <= '0';
                                SelLoad <= 'X';
                                AluFunc <= "XXXX";
                            end if;
                        when OP_MOVE =>
                        report "MOVE";
                            AluFunc <= ALU_SideB;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            SelLoad <= '0';
                        when OP_AND =>
                            report "AND";
                            AluFunc <= ALU_AandB;
                            SelPC <= '0';
                            SelLoad <= '0';
                        when OP_OR =>
                            report "OR";
                            AluFunc <= ALU_AorB;
                            SelPC <= '0';
                            SelLoad <= '0';
                        when OP_XOR =>
                            report "XOR";
                            AluFunc <= ALU_AxorB;
                            SelPC <= '0';
                            SelLoad <= '0';
                        when OP_NOT =>
                            report "NOT";
                            AluFunc <= ALU_NotA;
                            SelPC <= '0';
                            SelLoad <= '0';
                        when OP_NOP =>
                            report "NOP";
                            AluFunc <= "XXXX";
                            SelPC <= '0';
                            SelLoad <= '0';
                        when OP_SLEEP =>
                            report "SLEEP";
                            AluFunc <= "XXXX";
                            SelPC <= 'X';
                            SelLoad <= 'X';
                            assert false report "Simulation finished" severity failure;
                          when OP_ADD =>
                            report "ADD";
                            AluFunc <= ALU_AplusBplusCarry;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ALU_CarryIn <= '0';
                            ClkENRegFile <= '1';
                        when OP_ADDC => 
                            report "ADDC";
                            AluFunc <= ALU_AplusBplusCarry;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                        when OP_SUB => 
                            report "SUB";
                            AluFunc <= ALU_AminusBminusCarry;
                            SelPC <= 'X';
                            ClkEnPC <= '0';
                            ALU_CarryIn <= '0';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            instrTerminate <= '1';
                        when OP_SUBC => 
                            report "SUBC";
                            AluFunc <= ALU_AminusBminusCarry;
                            SelPC <= 'X';
                            ClkEnPC <= '0';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            instrTerminate <= '1';
                        when OP_COMP => 
                            report "COMP";
                            AluFunc <= ALU_AminusBminusCarry;
                            SelPC <= 'X';
                            ClkEnPC <= '0';
                            ALU_CarryIn <= '1';
                            ClkENRegFile <= '1';
                            instrTerminate <= '1';
                        when OP_INC =>
                            report "INC";
                            AluFunc <= ALU_A_INC;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            instrTerminate <= '1';
                        when OP_DEC =>
                            report "DEC";
                            AluFunc <= ALU_A_DEC;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            instrTerminate <= '1';
                        when OP_SHL => 
                            report "SHL";
                            ALUFunc <= ALU_ShiftALeft;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            ALU_CarryIn <= '0';
                            instrTerminate <= '1';
                        when OP_SHR =>
                            report "SHR";
                            ALUFunc <= ALU_ShiftARight;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            ALU_CarryIn <= '0';
                            instrTerminate <= '1';
                        when OP_SHRC => 
                            report "SHRC";
                            ALUFunc <= ALU_ShiftARight;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            instrTerminate <= '1';
                        when OP_SHLC => 
                            report "SHLC";
                            ALUFunc <= ALU_ShiftALeft;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            instrTerminate <= '1';
                        when others =>
                            AluFunc <= "XXXX";
                            SelPC <= 'X';
                            SelLoad <= 'X';
                            instrTerminate <= '1';
                            report "Illegal instruction";
                        end case;
            when Cycle_3 =>
                --ClkEnOpcode <= '1';
                instrTerminate <= '1';
                SelAddr <= '0';
                ClkEnRegFile <= '1';
                ClkEnPC <= '0';


                case RegOpCode is
                    when OP_LOADI =>
                        AluFunc <= "XXXX";
                        SelLoad <= 'X';
                        SelPC <= 'X';
                    when OP_LOAD =>
                        AluFunc <= "XXXX";
                        SelLoad <= 'X';
                        SelPC <= 'X';
                    when OP_STORE =>
                        AluFunc <= "XXXX";
                        SelLoad <= 'X';
                        SelPC <= 'X';
                    when others =>
                        AluFunc <= "XXXX";
                        SelPC <= 'X';
                        SelLoad <= 'X';
                end case;
            when others => 
                ALUFunc <= "XXXX";      
        end case;
--        case RegOpcode is 
--        when OP_LOADI =>
--            if cycle = "00" then   
--                ClkEnOpcode <= '0';
--                SelAddr <= 'X';
--                SelLoad <= 'X';
--                ClkEnRegFile <= '0';
--
--                AluFunc <= ALU_A_INC;
--                ClkEnPC <= '1';
--                SelPC <= '1';
--            elsif cycle = "01" then
--                ClkEnOpcode <= '0';
--                SelAddr <= '0';
--                SelLoad <= '1';
--                ClkEnRegFile <= '1';
--
--                AluFunc <= ALU_A_INC;
--                ClkEnPC <= '1';
--                SelPC <= '1';
--
--            elsif cycle = "10" then
--                ClkEnOpcode <= '1';
--                SelAddr <= '0';
--                SelLoad <= 'X';
--                ClkEnRegFile <= '0';
--
--                AluFunc <= "XXXX";
--                ClkEnPC <= '0';
--                SelPC <= 'X';
--            end if;            
--
--        when OP_ADD =>
--            if cycle = "00" then   
--                ClkEnOpcode <= '0';
--                SelAddr <= 'X';
--                SelLoad <= 'X';
--                ClkEnRegFile <= '0';
--
--                AluFunc <= ALU_A_INC;
--                ClkEnPC <= '1';
--                SelPC <= '1';
--            elsif cycle = "01" then
--                ClkEnOpcode <= '1';
--                SelAddr <= '0';
--                SelLoad <= '0';
--                ClkEnRegFile <= '1';
--
--                AluFunc <= ALU_AplusBplusCarry;
--                ClkEnPC <= '0';
--                SelPC <= '1';
--            end if;
--
--        when OP_LOAD =>
--            if cycle = "00" then   
--                ClkEnOpcode <= '0';
--                SelAddr <= 'X';
--                SelLoad <= 'X';
--                ClkEnRegFile <= '0';
--
--                AluFunc <= ALU_A_INC;
--                ClkEnPC <= '1';
--                SelPC <= '1';
--            elsif cycle = "01" then
--                ClkEnOpcode <= '0';
--                SelAddr <= '1';
--                SelLoad <= '1';
--                ClkEnRegFile <= '0';
--
--                AluFunc <= ALU_DONT_CARE;
--                ClkEnPC <= '0';
--                SelPC <= 'X';
--
--            elsif cycle = "10" then
--                ClkEnOpcode <= '1';
--                SelAddr <= '0';
--                SelLoad <= 'X';
--                ClkEnRegFile <= '0';
--
--                AluFunc <= "XXXX";
--                ClkEnPC <= '0';
--                SelPC <= 'X';
--            end if;
--
--        when OP_NOP =>
--            if cycle = "00" then   
--                ClkEnOpcode <= '0';
--                SelAddr <= 'X';
--                SelLoad <= 'X';
--                ClkEnRegFile <= '0';
--
--                AluFunc <= ALU_A_INC;
--                ClkEnPC <= '1';
--                SelPC <= '1';
--
--            elsif cycle = "01" then
--                ClkEnOpcode <= '1';
--                SelAddr <= 'X';
--                SelLoad <= 'X';
--                ClkEnRegFile <= '0';
--
--                AluFunc <= "XXXX";
--                ClkEnPC <= '0';
--                SelPC <= 'X';
--            end if;
--
--        when OP_SLEEP =>
--            if cycle = "00" then   
--                ClkEnOpcode <= '0';
--                SelAddr <= 'X';
--                SelLoad <= 'X';
--                ClkEnRegFile <= '0';
--
--                AluFunc <= ALU_DONT_CARE;
--                ClkEnPC <= '0';
--                SelPC <= 'X';
--            elsif cycle = "01" then
--                ClkEnOpcode <= '1';
--                SelAddr <= 'X';
--                SelLoad <= 'X';
--                ClkEnRegFile <= '0';
--
--                AluFunc <= ALU_DONT_CARE;
--                ClkEnPC <= '0';
--                SelPC <= 'X';
--            end if;
--
--        when OP_STORE =>
--            if cycle = "00" then   
--                ClkEnOpcode <= '0';
--                SelAddr <= 'X';
--                SelLoad <= 'X';
--                ClkEnRegFile <= '0';
--
--                AluFunc <= ALU_A_INC;
--                ClkEnPC <= '1';
--                SelPC <= '1';
--            elsif cycle = "01" then
--                ClkEnOpcode <= '0';
--                SelAddr <= '1';
--                SelLoad <= 'X';
--                ClkEnRegFile <= '0';
--
--                AluFunc <= ALU_DONT_CARE;
--                ClkEnPC <= '1';
--                SelPC <= '1';
--                MemWrStrobe <= '1';
--
--            elsif cycle = "10" then
--                ClkEnOpcode <= '1';
--                SelAddr <= '0';
--                SelLoad <= 'X';
--                ClkEnRegFile <= '0';
--
--                AluFunc <= ALU_DONT_CARE;
--                ClkEnPC <= '0';
--                SelPC <= 'X';
--            end if;
--
--        when OP_AND => 
--            if cycle = "00" then   
--                ClkEnOpcode <= '0';
--                SelAddr <= 'X';
--                SelLoad <= 'X';
--                ClkEnRegFile <= '0';
--
--                AluFunc <= ALU_A_INC;
--                ClkEnPC <= '1';
--                SelPC <= '1';
--            elsif cycle = "01" then
--                ClkEnOpcode <= '1';
--                SelAddr <= '0';
--                SelLoad <= '0';
--                ClkEnRegFile <= '1';
--
--                AluFunc <= ALU_AandB;
--                ClkEnPC <= '0';
--                SelPC <= '1';
--            end if;
--
--        when OP_OR => 
--            if cycle = "00" then   
--                ClkEnOpcode <= '0';
--                SelAddr <= 'X';
--                SelLoad <= 'X';
--                ClkEnRegFile <= '0';
--
--                AluFunc <= ALU_A_INC;
--                ClkEnPC <= '1';
--                SelPC <= '1';
--            elsif cycle = "01" then
--                ClkEnOpcode <= '1';
--                SelAddr <= '0';
--                SelLoad <= '0';
--                ClkEnRegFile <= '1';
--
--                AluFunc <= ALU_AorB;
--                ClkEnPC <= '0';
--                SelPC <= '1';
--            end if;
--
--        when OP_XOR => 
--            if cycle = "00" then   
--                ClkEnOpcode <= '0';
--                SelAddr <= 'X';
--                SelLoad <= 'X';
--                ClkEnRegFile <= '0';
--
--                AluFunc <= ALU_A_INC;
--                ClkEnPC <= '1';
--                SelPC <= '1';
--            elsif cycle = "01" then
--                ClkEnOpcode <= '1';
--                SelAddr <= '0';
--                SelLoad <= '0';
--                ClkEnRegFile <= '1';
--
--                AluFunc <= ALU_AxorB;
--                ClkEnPC <= '0';
--                SelPC <= '1';
--            end if;
--
--        when OP_NOT => 
--            if cycle = "00" then   
--                ClkEnOpcode <= '0';
--                SelAddr <= 'X';
--                SelLoad <= 'X';
--                ClkEnRegFile <= '0';
--                
--                AluFunc <= ALU_A_INC;
--                ClkEnPC <= '1';
--                SelPC <= '1';
--            elsif cycle = "01" then
--                ClkEnOpcode <= '1';
--                SelAddr <= '0';
--                SelLoad <= '0';
--                ClkEnRegFile <= '1';
--
--                AluFunc <= ALU_NotA;
--                ClkEnPC <= '0';
--                SelPC <= '1';
--            end if;
--            
--        when others =>                    
--                AluFunc <= ALU_DONT_CARE;
--                ClkEnPC <= 'X';
--                SelPC <= 'X';
--                ClkEnOpcode <= 'X';
--                SelAddr <= 'X';
--                SelLoad <= 'X';
--                ClkEnRegFile <= 'X';
--
--        end case;
        
        
    end if;

                
    end process readOpCode;
end Behavioral;

