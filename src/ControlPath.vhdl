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
    signal instrTerminate : std_ulogic := '0';
    
    
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
                                --report "Old cycle: " & integer'image(to_integer(unsigned(lastCycle))); 
                                                            cyc := Cycle_1;
                                                            --report "Terminated, New clock cycle: " & integer'image(to_integer(unsigned(cyc))); 
                                                            else
                                --report "Old cycle: " & integer'image(to_integer(unsigned(lastCycle))); 
                                cyc := lastCycle(1 downto 0) & lastCycle(2);
                                --report "New clock cycle: " & integer'image(to_integer(unsigned(cyc)));   
                                
                                end if;                   
              return cyc;
      end function;
begin

    clockCycle: process(ZuluClk, Reset, instrTerminate) is
    variable cyc : std_ulogic_vector(2 downto 0) := Cycle_1;
    begin

         if Reset = '1' then
           cyc := Cycle_1;
          report "Reset";
         end if;
        if rising_edge(ZuluClk) then --TODO mit variablen
                    if instrTerminate = '1' then
                        --report "Old cycle: " & integer'image(to_integer(unsigned(cyc))); 
                                                    cyc := Cycle_1;
                          --                          report "Terminated, New clock cycle: " & integer'image(to_integer(unsigned(cyc))); 
                                                    else
                        --report "Old cycle: " & integer'image(to_integer(unsigned(cyc))); 
                        cyc := cyc(1 downto 0) & cyc(2);
                        --report "New clock cycle: " & integer'image(to_integer(unsigned(cyc)));   
                        
                        end if;
                                
             
      end if;
                     --cycle <= cyc;
           
    end process clockCycle;
    
    readWriteFlag: process(ZuluClk, cycle) is
    variable rd : std_ulogic := '1';
    variable wr : std_ulogic := '0';
    begin
        MemWrStrobe <= wr;
        MemRdStrobe <= rd;
        if rising_edge(ZuluClk) then
            case cycle is
                when Cycle_1 =>
                    rd := '0';
                    wr := '0';
                when Cycle_2 =>
                    if RegOpCode =  OP_STORE then
                        report "STORE";
                        wr := '1';
                        rd := '0';
                     else
                        wr := '0';
                        rd := '1';
                     end if;
                when Cycle_3 =>
                    wr := '0';
                    rd := '1';
                when others =>
                    report "Unreachable clock cycle: " & integer'image(to_integer(unsigned(cycle))); 
                    wr := '0';
                    rd := '1';
            end case;
        end if;
    end process readWriteFlag;

    readOpCode: process(ZuluClk, Reset, RegOpcode) is
        variable opCode : OpcodeVec;
        variable stop : std_ulogic := '1';
        variable clkEnPC_var : std_ulogic := '0';
        variable selPC_var : std_ulogic := '0';
        variable aluFunc_var : std_ulogic_vector(3 downto 0) := ALU_DONT_CARE;
        variable selAddr_var : std_ulogic := '0';
        variable selLoad_var : std_ulogic := '0';
        variable clkEnRegFile_var : std_ulogic := '0';
        variable alu_CarryIn_var : std_ulogic := '0';
    begin
            instrTerminate <= stop;
            ClkEnOpCode <= stop;
            ClkEnPC <= clkEnPC_var;
            SelPC <= selPC_var;
            AluFunc <= aluFunc_var;
            SelAddr <= selAddr_var;
            SelLoad <= selLoad_var;
            ClkEnRegFile <= clkEnRegFile_var;
            ALU_CarryIn <= alu_CarryIn_var;
       if rising_edge(ZuluClk) then
        case cycle is
            when Cycle_1 => --increment PC
                report "Cycle 1: Increment PC";
                stop := '0';
                clkEnPC_var := '1';
                selPC_var := '1';
                alu_CarryIn_var := '0';
                selAddr_var := '0';
                selLoad_var := 'X';
                clkEnRegFile_var := '0';
                aluFunc_var := ALU_A_INC;
                cycle <= clock_cycle(cycle, stop);
            when Cycle_2 =>
case RegOpcode is 
                                    when OP_LOADI | OP_LOAD | OP_STORE =>
                                        stop := '0';
                                    when others =>
                                        selAddr_var := '0';
                                        stop := '1';
                                    end case;           
                                    
                                                                cycle <= clock_cycle(cycle, stop);
     
                    case RegOpcode is 
                        when OP_LOADI =>
                            report "LOADI";
                            selAddr_var := '0';
                            selLoad_var := '1';
                            clkEnRegFile_var := '1';
            
                            aluFunc_var := ALU_A_INC;
                            clkEnPC_var := '1';
                            selPC_var := '1';

                        when OP_LOAD =>
                            report "LOAD";
                            selAddr_var := '1';
                            selLoad_var := '1';
                            clkEnRegFile_var := '1';
            
                            aluFunc_var := ALU_DONT_CARE;
                            clkEnPC_var := '0';
                            selPC_var := 'X';

                        when OP_STORE =>
                            report "STORE";
                            selAddr_var := '1';
                            selLoad_var := 'X';
                            clkEnRegFile_var := '0';
            
                            aluFunc_var := ALU_DONT_CARE;
                            clkEnPC_var := '0';
                            selPC_var := 'X';
                        when OP_JUMP =>
                            report "JUMP";
                            selPC_var := '0';
                            clkEnPC_var := '1';
                            selLoad_var := 'X';
                            aluFunc_var := "XXXX";
                        when OP_JUMPC =>
                            report "JUMPC";
                            if ALU_CarryOut = '1' then
                                selPC_var := '0';
                                clkEnPC_var := '1';
                                selLoad_var := 'X';
                                aluFunc_var := "XXXX";
                            else
                                selPC_var := 'X';
                                clkEnPC_var := '0';
                                selLoad_var := 'X';
                                aluFunc_var := "XXXX";
                            end if;
                        when OP_JUMPZ =>
                            report "JUMPZ";
                            if ALU_ZeroOut = '1' then
                                selPC_var := '0';
                                clkEnPC_var := '1';
                                selLoad_var := 'X';
                                aluFunc_var := "XXXX";
                            else
                                selPC_var := 'X';
                                clkEnPC_var := '0';
                                selLoad_var := 'X';
                                aluFunc_var := "XXXX";
                            end if;
                        when OP_MOVE =>
                        report "MOVE";
                            aluFunc_var := ALU_SideB;
                            selPC_var := 'X';
                            selLoad_var := '0';
                            selLoad_var := '0';
                            clkEnPC_var := '0';
                        when OP_AND =>
                            report "AND";
                            aluFunc_var := ALU_AandB;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnPC_var := '0';
                        when OP_OR =>
                            report "OR";
                            aluFunc_var := ALU_AorB;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnPC_var := '0';
                        when OP_XOR =>
                            report "XOR";
                            aluFunc_var := ALU_AxorB;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnPC_var := '0';
                        when OP_NOT =>
                            report "NOT";
                            aluFunc_var := ALU_NotA;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnPC_var := '0';
                        when OP_NOP =>
                            report "NOP";
                            aluFunc_var := "XXXX";
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnPC_var := '0';
                        when OP_SLEEP =>
                            report "SLEEP";
                            aluFunc_var := "XXXX";
                            selPC_var := 'X';
                            selLoad_var := 'X';
                            assert false report "Simulation finished" severity failure;
                          when OP_ADD =>
                            report "ADD";
                            aluFunc_var := ALU_AplusBplusCarry;
                            selPC_var := '0';
                            selLoad_var := '0';
                            alu_CarryIn_var := '0';
                            clkEnRegFile_var := '1';
                            clkEnPC_var := '0';
                        when OP_ADDC => 
                            report "ADDC";
                            aluFunc_var := ALU_AplusBplusCarry;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnRegFile_var := '1';
                            clkEnPC_var := '0';
                        when OP_SUB => 
                            report "SUB";
                            aluFunc_var := ALU_AminusBminusCarry;
                            selPC_var := '0';
                            clkEnPC_var := '0';
                            alu_CarryIn_var := '0';
                            selLoad_var := '0';
                            clkEnRegFile_var := '1';
                        when OP_SUBC => 
                            report "SUBC";
                            aluFunc_var := ALU_AminusBminusCarry;
                            selPC_var := '0';
                            clkEnPC_var := '0';
                            selLoad_var := '0';
                            clkEnRegFile_var := '1';
                        when OP_COMP => 
                            report "COMP";
                            aluFunc_var := ALU_AminusBminusCarry;
                            selPC_var := '0';
                            clkEnPC_var := '0';
                            alu_CarryIn_var := '1';
                            clkEnRegFile_var := '1';
                        when OP_INC =>
                            report "INC";
                            aluFunc_var := ALU_A_INC;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnRegFile_var := '1';
                            clkEnPC_var := '0';
                        when OP_DEC =>
                            report "DEC";
                            aluFunc_var := ALU_A_DEC;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnRegFile_var := '1';
                            clkEnPC_var := '0';
                        when OP_SHL => 
                            report "SHL";
                            ALUFunc <= ALU_ShiftALeft;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnRegFile_var := '1';
                            alu_CarryIn_var := '0';
                            clkEnPC_var := '0';
                        when OP_SHR =>
                            report "SHR";
                            ALUFunc <= ALU_ShiftARight;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnRegFile_var := '1';
                            alu_CarryIn_var := '0';
                            clkEnPC_var := '0';
                        when OP_SHRC => 
                            report "SHRC";
                            ALUFunc <= ALU_ShiftARight;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnRegFile_var := '1';
                            clkEnPC_var := '0';
                        when OP_SHLC => 
                            report "SHLC";
                            ALUFunc <= ALU_ShiftALeft;
                            selPC_var := '0';
                            selLoad_var := '0';
                            clkEnRegFile_var := '1';
                            clkEnPC_var := '0';
                        when others =>
                            aluFunc_var := "XXXX";
                            selPC_var := 'X';
                            selLoad_var := 'X';
                            clkEnPC_var := '0';
                            report "Illegal instruction";
                        end case;
            when Cycle_3 =>
                            cycle <= clock_cycle(cycle, instrTerminate);
                --ClkEnOpcode <= '1';
                stop := '1';
                selAddr_var := '0';
                clkEnRegFile_var := '0';
                clkEnPC_var := '0';


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
                end case;
            when others => 
                ALUFunc <= "XXXX";      
        end case;        
    end if;

                
    end process readOpCode;
end Behavioral;

