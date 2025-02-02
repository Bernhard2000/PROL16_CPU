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

        MemRdStrobe : out std_ulogic := '1'; -- memory read strobe
        MemWrStrobe : out std_ulogic := '0'; -- memory write strobe

        ClkEnOpcode     : out std_ulogic := '1';
        ClkEnPC         : out std_ulogic;
        ClkEnRegFile    : out std_ulogic;
        SelLoad         : out std_ulogic;
        SelAddr         : out std_ulogic;
        SelPC           : out std_ulogic;
        ALU_CarryIn     : out std_ulogic;
        LegalOpcodePresent : out std_ulogic;

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

 
    signal cycle : std_ulogic_vector(2 downto 0) := Cycle_3;
    signal nextCycle : std_ulogic_vector(2 downto 0) := Cycle_1;
    signal SelLoad_sig, SelAddr_sig, ALU_CarryIn_sig : std_ulogic := '0';
    signal ClkEnOpcode_sig : std_ulogic := '1';
    signal instrTerminate : std_ulogic := '0';
    signal carryOut_sig, zeroOut_sig : std_ulogic := '0';      
    function ulogic_vector_to_OpcodeValueType(data_vector : std_ulogic_vector) return OpcodeValueType is
        variable result : OpcodeValueType;
      begin
        result.Code := data_vector(OpcodeBits-1 downto 0); --5-0
        result.Ra := data_vector(RegFileBits + OpcodeBits - 1 downto OpcodeBits); --10-6
        result.Rb := data_vector(2*RegFileBits + OpcodeBits - 1 downto RegFileBits + OpcodeBits); --15-11
        result.Imm := data_vector(DataVec_length-1 downto 0);
        return result;
      end function;
      
      
      
      function clock_cycle(lastCycle : std_ulogic_vector; instrTerminate : std_ulogic) return std_ulogic_vector is
        variable cyc : std_ulogic_vector(2 downto 0);
        begin
            if instrTerminate = '1' then
                cyc := Cycle_1;
            else
                                cyc := lastCycle(1 downto 0) & lastCycle(2);                                
                                end if;                   
              return cyc;
      end function;
begin
        ClkEnOpcode <= instrTerminate;        
        
    setCycle : process(ZuluCLK, Reset, nextCycle) is
    begin
              if reset = '1' then
                    cycle <= Cycle_3;
              elsif rising_edge(ZuluCLK) then
                    cycle <= nextCycle;
              end if;
   end process;
        
    setNextCycle: process(Reset, RegOpcode, cycle) is
    variable stop : std_ulogic := '0';
    begin        
         if Reset = '1' then
          nextCycle <= Cycle_1;
          stop := '1';
          instrTerminate <= '1';
          MemWrStrobe <= '0';
          MemRdStrobe <= '1';
          report "Reset";
          else
          case cycle is
                              when Cycle_1 =>
                                  stop := '0';
                                  MemWrStrobe <= '0';
                                  MemRdStrobe <= '0';
                              when Cycle_2 =>
                                  case RegOpcode is 
                                      when OP_STORE => 
                                          MemWrStrobe <= '1';
                                          MemRdStrobe <= '0';
                                          stop := '0';
                                      when OP_LOADI | OP_LOAD =>
                                          stop := '0';
                                          MemWrStrobe <= '0';
                                          MemRdStrobe <= '1';
                                      when others =>
                                          stop := '1';
                                          MemWrStrobe <= '0';
                                          MemRdStrobe <= '1';
                                      end case;                
                              when Cycle_3 =>
                                  stop := '1';
                                      MemWrStrobe <= '0';
                                      MemRdStrobe <= '1';
                              when others => 
                                  stop := '1';
                                  MemWrStrobe <= '0';                                                                                
                                  MemRdStrobe <= '1';
                         end case; 
                    instrTerminate <= stop;

                    if stop = '1' then
                        nextCycle <= Cycle_1;
                        stop := '0';
                    else
                        nextCycle <= cycle(1 downto 0) & cycle(2);
                        end if;  
               
               end if;
    end process;
    
    setFlags: process(ZuluCLK, carryOut_sig, zeroOut_sig, cycle, ALU_ZeroOut, ALU_CarryOut) is
    begin
        if rising_edge(ZuluCLK) then
            if cycle = Cycle_2 then
                case RegOpCode is
                when OP_AND | OP_OR | OP_XOR | OP_NOT =>
                    carryOut_sig <= '0';
                    zeroOut_sig <= ALU_ZeroOut;
                when OP_ADD | OP_ADDC | OP_SUB | OP_SUBC | OP_COMP | OP_INC | OP_DEC | OP_SHL | OP_SHR | OP_SHLC | OP_SHRC => 
                    carryOut_sig <= ALU_CarryOut;
                    zeroOut_sig <= ALU_ZeroOut;
                when others => 
                    carryOut_sig <= carryOut_sig;
                    zeroOut_sig <= zeroOut_sig;
                end case;
            else 
                carryOut_sig <= carryOut_sig;
                zeroOut_sig <= zeroOut_sig;
        end if;   
       end if; 
    end process;
    
   

    readOpCode: process(cycle, RegOpCode, zeroOut_sig, carryOut_sig) is
        variable stop : std_ulogic := '0';
        variable cyc : std_ulogic_vector(2 downto 0) := "001";
        variable clkEnPC_var : std_ulogic := '0';
        variable selPC_var : std_ulogic := '0';
        variable aluFunc_var : std_ulogic_vector(3 downto 0) := ALU_DONT_CARE;
        variable selAddr_var : std_ulogic := '1';
        variable selLoad_var : std_ulogic := '0';
        variable clkEnRegFile_var : std_ulogic := '0';
        variable alu_CarryIn_var : std_ulogic := '0';
        variable legalOpCode : std_ulogic := '1';
    begin
        case cycle is
            when Cycle_1 => --increment PC
                stop := '0';
                selAddr_var := '0';
                alu_CarryIn_var := '0';
                clkEnRegFile_var := '0';
                legalOpCode := '1';
                clkEnPC_var := '1';
                selLoad_var := 'X';


                case RegOpCode is
                    when OP_JUMP => 
                         report "JUMP";
                         selPC_var := '0';
                         aluFunc_var := "XXXX";
                    when OP_JUMPZ => 
                        report "JUMPZ";
                        if zeroOut_sig = '1' then
                            report "DO JUMPZ";
                            selPC_var := '0';
                            aluFunc_var := "XXXX";
                        else
                            selPC_var := '1';
                            aluFunc_var := ALU_A_INC;
                        end if;
                    when OP_JUMPC =>
                        report "JUMPC";
                        if carryOut_sig = '1' then
                            report "DO JUMPC";
                            selPC_var := '0';
                            aluFunc_var := "XXXX";
                        else
                            report "Increment PC";
                            selPC_var := '1';
                            aluFunc_var := ALU_A_INC;
                        end if; 
                    when others =>
                        selPC_var := '1';
                        aluFunc_var := ALU_A_INC;
                end case;                                                     
                               
            when Cycle_2 =>
                    legalOpCode := '1';
                    case RegOpcode is 
                                    when OP_LOADI | OP_LOAD | OP_STORE =>
                                        stop := '0';
                                    when others =>
                                        stop := '1';
                                    end case;           
                                         
                    case RegOpcode is 
                        when OP_LOADI =>
                            report "LOADI";
                            selAddr_var := '0';
                            selLoad_var := '1';
                            clkEnRegFile_var := '1';
            
                            aluFunc_var := ALU_A_INC;
                            clkEnPC_var := '1';
                            selPC_var := '1';
                            alu_CarryIn_var := '0';
                        when OP_LOAD =>
                            report "LOAD";
                            selAddr_var := '1';
                            selLoad_var := '1';
                            clkEnRegFile_var := '1';
            
                            aluFunc_var := ALU_DONT_CARE;
                            clkEnPC_var := '0';
                            selPC_var := 'X';
                            alu_CarryIn_var := 'X';
                        when OP_STORE =>
                            report "STORE";
                            selAddr_var := '1';
                            selLoad_var := 'X';
                            clkEnRegFile_var := '0';
            
                            aluFunc_var := ALU_DONT_CARE;
                            clkEnPC_var := '0';
                            selPC_var := 'X';
                            alu_CarryIn_var := 'X';
                        when OP_JUMP =>
                            aluFunc_var := "XXXX";
                            selPC_var := '0';
                            selLoad_var := 'X';
                            clkEnPC_var := '0';
                            clkEnRegFile_var := '0';
                            selAddr_var := '0';
                            alu_CarryIn_var := 'X';
                        when OP_JUMPC =>
                            aluFunc_var := "XXXX";
                            selPC_var := '0';
                            selLoad_var := 'X';
                            clkEnPC_var := '0';
                            clkEnRegFile_var := '0';
                            selAddr_var := '0';
                            alu_CarryIn_var := 'X';
                        when OP_JUMPZ =>
                            aluFunc_var := "XXXX";
                            selPC_var := '0';
                            selLoad_var := 'X';
                            clkEnPC_var := '0';
                            clkEnRegFile_var := '0';
                            selAddr_var := '0';
                            alu_CarryIn_var := 'X';
                        when OP_MOVE =>
                        report "MOVE";
                            aluFunc_var := ALU_SideB;
                            selPC_var := 'X';
                            clkEnRegFile_var := '1';
                            selLoad_var := '0';
                            clkEnPC_var := '0';
                            selAddr_var := '0';
                            alu_CarryIn_var := '0';
                        when OP_AND =>
                            report "AND";
                            aluFunc_var := ALU_AandB;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnPC_var := '0';
                            clkEnRegFile_var := '1';
                            selAddr_var := '0';
                            alu_CarryIn_var := '0';
                        when OP_OR =>
                            report "OR";
                            aluFunc_var := ALU_AorB;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnPC_var := '0';
                            clkEnRegFile_var := '1';
                            selAddr_var := '0';
                            alu_CarryIn_var := '0';
                        when OP_XOR =>
                            report "XOR";
                            aluFunc_var := ALU_AxorB;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnPC_var := '0';
                            clkEnRegFile_var := '1';
                            selAddr_var := '0';
                            alu_CarryIn_var := '0';
                        when OP_NOT =>
                            report "NOT";
                            aluFunc_var := ALU_NotA;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnPC_var := '0';
                            clkEnRegFile_var := '1';
                            selAddr_var := '0';
                            alu_CarryIn_var := '0';
                        when OP_NOP =>
                            report "NOP";
                            aluFunc_var := "XXXX";
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnPC_var := '0';
                            clkEnRegFile_var := '0';
                            selAddr_var := '0';
                            alu_CarryIn_var := '0';
                        when OP_SLEEP =>
                            report "SLEEP";
                            aluFunc_var := "XXXX";
                            selPC_var := 'X';
                            selLoad_var := 'X';
                            clkEnRegFile_var := 'X';
                            clkEnPC_var := '0';
                            selAddr_var := '0';
                            alu_CarryIn_var := 'X';
                            assert false report "Simulation finished" severity failure;
                          when OP_ADD =>
                            report "ADD";
                            aluFunc_var := ALU_AplusBplusCarry;
                            selPC_var := '0';
                            selLoad_var := '0';
                            alu_CarryIn_var := '0';
                            clkEnRegFile_var := '1';
                            clkEnPC_var := '0';
                            selAddr_var := '0';
                        when OP_ADDC => 
                            report "ADDC";
                            aluFunc_var := ALU_AplusBplusCarry;
                            selPC_var := '0';
                            selLoad_var := '0';
                            alu_CarryIn_var := carryOut_sig;
                            clkEnRegFile_var := '1';
                            clkEnPC_var := '0';
                            selAddr_var := '0';
                        when OP_SUB => 
                            report "SUB";
                            aluFunc_var := ALU_AminusBminusCarry;
                            selPC_var := '0';
                            clkEnPC_var := '0';
                            alu_CarryIn_var := '0';
                            selLoad_var := '0';
                            ClkEnRegFile_var := '1';
                            selAddr_var := '0';
                        when OP_SUBC => 
                            report "SUBC";
                            aluFunc_var := ALU_AminusBminusCarry;
                            selPC_var := '0';
                            clkEnPC_var := '0';
                            alu_CarryIn_var := carryOut_sig;
                            selLoad_var := '0';
                            clkEnRegFile_var := '1';
                            selAddr_var := '0';
                        when OP_COMP => 
                            report "COMP";
                            aluFunc_var := ALU_AminusBminusCarry;
                            selPC_var := '0';
                            clkEnPC_var := '0';
                            alu_CarryIn_var := '0';
                            clkEnRegFile_var := '0';
                            selLoad_var := 'X';
                            selAddr_var := '0';
                        when OP_INC =>
                            report "INC";
                            aluFunc_var := ALU_A_INC;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnRegFile_var := '1';
                            clkEnPC_var := '0';
                            selAddr_var := '0';
                            alu_CarryIn_var := '0';
                        when OP_DEC =>
                            report "DEC";
                            aluFunc_var := ALU_A_DEC;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnRegFile_var := '1';
                            clkEnPC_var := '0';
                            selAddr_var := '0';
                            alu_CarryIn_var := '0';
                        when OP_SHL => 
                            report "SHL";
                            aluFunc_var := ALU_ShiftALeft;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnRegFile_var := '1';
                            alu_CarryIn_var := '0';
                            clkEnPC_var := '0';
                            selAddr_var := '0';
                        when OP_SHR =>
                            report "SHR";
                            aluFunc_var := ALU_ShiftARight;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnRegFile_var := '1';
                            alu_CarryIn_var := '0';
                            clkEnPC_var := '0';
                            selAddr_var := '0';
                        when OP_SHRC => 
                            report "SHRC";
                            aluFunc_var := ALU_ShiftARight;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnRegFile_var := '1';
                            clkEnPC_var := '0';
                            selAddr_var := '0';
                            alu_CarryIn_var := carryOut_sig;
                        when OP_SHLC => 
                            report "SHLC";
                            aluFunc_var := ALU_ShiftALeft;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnRegFile_var := '1';
                            clkEnPC_var := '0';
                            selAddr_var := '0';
                            alu_CarryIn_var := carryOut_sig;
                        when others =>
                            aluFunc_var := "XXXX";
                            selPC_var := 'X';
                            selLoad_var := 'X';
                            clkEnPC_var := '0';
                            legalOpCode := '0';
                            clkEnRegFile_var := 'X';
                            selAddr_var := '0';
                            alu_CarryIn_var := 'X';
                            report "Illegal instruction";
                        end case;
            when Cycle_3 =>
                stop := '1';
                selAddr_var := '0';
                clkEnRegFile_var := '0';
                clkEnPC_var := '0';
                legalOpCode := '1';
                alu_CarryIn_var := 'X';

                case RegOpCode is
                    when OP_LOADI =>
                        aluFunc_var := "XXXX";
                        selLoad_var := '1';
                        selPC_var := 'X';
                    when OP_LOAD =>
                        aluFunc_var := "XXXX";
                        selLoad_var := '0';
                        selPC_var := 'X';
                    when OP_STORE =>
                        aluFunc_var := "XXXX";
                        selLoad_var := 'X';
                        selPC_var := 'X';
                    when others =>
                        aluFunc_var := "XXXX";
                        selPC_var := 'X';
                        selLoad_var := 'X';
                        legalOpCode := '0';
                end case;
            when others => 
                aluFunc_var := "XXXX";  
                legalOpCode := '0';  
                clkEnPC_var := '0';
                clkEnRegFile_var := '0';
                selLoad_var := 'X';
                selAddr_var := '0';
                selPC_var := 'X';
                alu_CarryIn_var := 'X';
                stop := '1';
        end case;      
        ClkEnPC <= clkEnPC_var;
        SelPC <= selPC_var;
        AluFunc <= aluFunc_var;
        SelAddr <= selAddr_var;
        SelLoad <= selLoad_var;
        ClkEnRegFile <= clkEnRegFile_var;
        ALU_CarryIn <= alu_CarryIn_var;  
        LegalOpcodePresent <= legalOpCode;
    end process readOpCode;
end Behavioral;
