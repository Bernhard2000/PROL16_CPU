library ieee;
use ieee.std_logic_1164.all;


library work;
use work.prol16_package.all;


entity ControlPath is
    port ( 
        Reset : in std_ulogic; -- reset inpunt
        ZuluClk : in std_ulogic; -- clock input

        MemRdStrobe : out std_ulogic; -- memory read strobe
        MemWrStrobe : out std_ulogic; -- memory write strobe
        
         ---------------------------------- [ ALU ] ------------------------
  
       ZeroOut : out std_ulogic; -- connects to ZeroOut output of ALU
       ALUFunc : out std_ulogic_vector(3 downto 0); -- selects the function
       -- Of the ALU
       ---------------------------------- [ MEM ] ------------------------
       MemAddr : out DataVec; -- address wires of memory
       MemWrData : out DataVec; -- data wires for writing the memory
       MemRdData : in DataVec -- data wires for reading the memory
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

    signal ALU_CarryOut : std_ulogic;
    signal ALU_ZeroOut : std_ulogic;
    signal ALU_CarryIn : std_ulogic;
    signal cycle : std_ulogic_vector(2 downto 0);
    signal ClkEnPC, ClkEnRegFile, SelPC, SelLoad, SelAddr, ClkEnOpcode : std_ulogic; 
    signal RegOpcode : OpCodeVec;
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
           if rising_edge(ZuluClk) then
                cycle <= cycle(1 downto 0) & cycle(2);
           end if;
           if Reset = '1' then
                cycle <= Cycle_1;
           end if;
    end process clockCycle;
    
    readWriteFlag: process(ZuluClk, cycle) is
    begin
        if rising_edge(ZuluClk) then
            case cycle is
                when Cycle_1 =>
                    MemRdStrobe <= '0';
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
                    report "Unreachable clock cycle"; 
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
        if instrTerminate = '1' then
            cycle <= Cycle_1;
            instrTerminate <= '0';
        end if;

        case cycle is
            when Cycle_1 => --increment PC
                ClkEnPC <= '1';
                SelPC <= '1';
                ClkEnOpcode <= '0';
                SelAddr <= 'X';
                SelLoad <= 'X';
                ClkEnRegFile <= '0';
                AluFunc <= ALU_A_INC;           
            when Cycle_2 =>
                ClkEnOpcode <= '0';
                    case RegOpcode is 
                        when OP_LOADI | OP_LOAD | OP_STORE =>
                            instrTerminate <= '0';
                        when others =>
                            instrTerminate <= '1';
                        end case;             

                    case RegOpcode is 
                        when OP_LOADI =>
                            SelAddr <= '0';
                            SelLoad <= '1';
                            ClkEnRegFile <= '1';
            
                            AluFunc <= ALU_A_INC;
                            ClkEnPC <= '1';
                            SelPC <= '1';

                        when OP_LOAD =>
                            SelAddr <= '1';
                            SelLoad <= '1';
                            ClkEnRegFile <= '0';
            
                            AluFunc <= ALU_DONT_CARE;
                            ClkEnPC <= '0';
                            SelPC <= 'X';

                        when OP_STORE =>
                            SelAddr <= '1';
                            SelLoad <= 'X';
                            ClkEnRegFile <= '0';
            
                            AluFunc <= ALU_DONT_CARE;
                            ClkEnPC <= '1';
                            SelPC <= '1';
                        when OP_JUMP =>
                            SelPC <= '0';
                            ClkEnPC <= '1';
                            SelLoad <= 'X';
                            AluFunc <= "XXXX";
                        when OP_JUMPC =>
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
                            AluFunc <= ALU_SideB;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            SelLoad <= '0';
                        when OP_AND =>
                            AluFunc <= ALU_AandB;
                            SelPC <= '0';
                            SelLoad <= '0';
                        when OP_OR =>
                            AluFunc <= ALU_AorB;
                            SelPC <= '0';
                            SelLoad <= '0';
                        when OP_XOR =>
                            AluFunc <= ALU_AxorB;
                            SelPC <= '0';
                            SelLoad <= '0';
                        when OP_NOT =>
                            AluFunc <= ALU_NotA;
                            SelPC <= '0';
                            SelLoad <= '0';
                        when OP_NOP =>
                            AluFunc <= "XXXX";
                            SelPC <= 'X';
                            SelLoad <= 'X';
                        when OP_SLEEP =>
                            AluFunc <= "XXXX";
                            SelPC <= 'X';
                            SelLoad <= 'X';
                        when OP_ADD =>
                            AluFunc <= ALU_AplusBplusCarry;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ALU_CarryIn <= '0';
                            ClkENRegFile <= '1';
                        when OP_ADDC => 
                            AluFunc <= ALU_AplusBplusCarry;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                        when OP_SUB => 
                            AluFunc <= ALU_AminusBminusCarry;
                            SelPC <= 'X';
                            ClkEnPC <= '0';
                            ALU_CarryIn <= '0';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            instrTerminate <= '1';
                        when OP_SUBC => 
                            AluFunc <= ALU_AminusBminusCarry;
                            SelPC <= 'X';
                            ClkEnPC <= '0';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            instrTerminate <= '1';
                        when OP_COMP => 
                            AluFunc <= ALU_AminusBminusCarry;
                            SelPC <= 'X';
                            ClkEnPC <= '0';
                            ALU_CarryIn <= '1';
                            ClkENRegFile <= '1';
                            instrTerminate <= '1';
                        when OP_INC =>
                            AluFunc <= ALU_A_INC;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            instrTerminate <= '1';
                        when OP_DEC =>
                            AluFunc <= ALU_A_DEC;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            instrTerminate <= '1';
                        when OP_SHL => 
                            ALUFunc <= ALU_ShiftALeft;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            ALU_CarryIn <= '0';
                            instrTerminate <= '1';
                        when OP_SHR =>
                            ALUFunc <= ALU_ShiftARight;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            ALU_CarryIn <= '0';
                            instrTerminate <= '1';
                        when OP_SHRC => 
                            ALUFunc <= ALU_ShiftARight;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            instrTerminate <= '1';
                        when OP_SHLC => 
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
                cycle <= Cycle_1;
                ClkEnOpcode <= '1';
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

