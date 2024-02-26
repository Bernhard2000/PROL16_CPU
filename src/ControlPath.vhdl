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
    signal instrTerminate : std_ulogic := '0';
    
    signal MemRdStrobe_sig : std_ulogic := '1';
    signal MemWrStrobe_sig : std_ulogic := '0';
    
    
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
                                report "Old cycle: " & integer'image(to_integer(unsigned(lastCycle))); 
                                                            cyc := Cycle_1;
                                                            report "Terminated, New clock cycle: " & integer'image(to_integer(unsigned(cyc))); 
                                                            else
                                report "Old cycle: " & integer'image(to_integer(unsigned(lastCycle))); 
                                cyc := lastCycle(1 downto 0) & lastCycle(2);
                                report "New clock cycle: " & integer'image(to_integer(unsigned(cyc)));   
                                
                                end if;                   
              return cyc;
      end function;
begin

    clockCycle: process(ZuluClk, Reset, instrTerminate) is
    variable cyc : std_ulogic_vector(2 downto 0) := Cycle_1;
    begin
           ClkEnOpCode <= instrTerminate;

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
        MemWrStrobe <= MemWrStrobe_sig;
        MemRdStrobe <= MemRdStrobe_sig;
        if rising_edge(ZuluClk) then
            case cycle is
                when Cycle_1 =>
                    MemRdStrobe_sig <= '0';
                    MemWrStrobe_sig <= '0'; 
                when Cycle_2 =>
                    if RegOpCode =  OP_STORE then
                        MemWrStrobe_sig <= '1';
                        MemRdStrobe_sig <= '0';
                     elsif RegOpCode = OP_LOAD or RegOpCode = OP_LOADI then
                        MemWrStrobe_sig <= '0';
                        MemRdStrobe_sig <= '1';
                     else
                        MemWrStrobe_sig <= '0';
                        MemRdStrobe_sig <= '1'; 
                     end if;
                when Cycle_3 =>
                    MemWrStrobe_sig <= '0';
                    MemRdStrobe_sig <= '1';
                when others =>
                    report "Unreachable clock cycle: " & integer'image(to_integer(unsigned(cycle))); 
                    MemWrStrobe_sig <= '0';
                    MemRdStrobe_sig <= '1';
            end case;
        end if;
    end process readWriteFlag;

    readOpCode: process(ZuluClk, Reset, RegOpcode) is
        variable opCode : OpcodeVec;
        variable stop : std_ulogic:= '0';
        variable clkEnPC_var : std_ulogic;
    begin
           instrTerminate <= stop;
           ClkEnPC <= clkEnPC_var;
       if rising_edge(ZuluClk) then
       
        case cycle is
            when Cycle_1 => --increment PC
                report "Cycle 1: Increment PC";
                stop := '0';
                clkEnPC_var := '1';
                SelPC <= '1';
                ALU_CarryIn <= '0';
                --ClkEnOpcode <= '0';
                SelAddr <= '0';
                SelLoad <= 'X';
                ClkEnRegFile <= '0';
                AluFunc <= ALU_A_INC;   
                cycle <= clock_cycle(cycle, stop);
            when Cycle_2 =>

                report "Cycle 2, Instr: Opcode: " &integer'image(to_integer(unsigned(RegOpcode)));
                --ClkEnOpcode <= '0';
case RegOpcode is 
                                    when OP_LOADI | OP_LOAD | OP_STORE =>
                                        stop := '0';
                                    when others =>
                                        SelAddr <= '0';
                                        stop := '1';
                                    end case;           
                                    
                                                                cycle <= clock_cycle(cycle, stop);
     
                    case RegOpcode is 
                        when OP_LOADI =>
                            report "LOADI";
                            SelAddr <= '0';
                            SelLoad <= '1';
                            ClkEnRegFile <= '1';
            
                            AluFunc <= ALU_A_INC;
                            clkEnPC_var := '1';
                            SelPC <= '1';

                        when OP_LOAD =>
                            report "LOAD";
                            SelAddr <= '1';
                            SelLoad <= '1';
                            ClkEnRegFile <= '0';
            
                            AluFunc <= ALU_DONT_CARE;
                            clkEnPC_var := '0';
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
                            ClkEnPC <= '0';
                        when OP_AND =>
                            report "AND";
                            AluFunc <= ALU_AandB;
                            SelPC <= '0';
                            SelLoad <= '0';
                            ClkEnPC <= '0';
                        when OP_OR =>
                            report "OR";
                            AluFunc <= ALU_AorB;
                            SelPC <= '0';
                            SelLoad <= '0';
                            ClkEnPC <= '0';
                        when OP_XOR =>
                            report "XOR";
                            AluFunc <= ALU_AxorB;
                            SelPC <= '0';
                            SelLoad <= '0';
                            ClkEnPC <= '0';
                        when OP_NOT =>
                            report "NOT";
                            AluFunc <= ALU_NotA;
                            SelPC <= '0';
                            SelLoad <= '0';
                            clkEnPC_var := '0';
                        when OP_NOP =>
                            report "NOP";
                            AluFunc <= "XXXX";
                            SelPC <= '0';
                            SelLoad <= '0';
                            clkEnPC_var := '0';
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
                            ClkEnPC <= '0';
                        when OP_ADDC => 
                            report "ADDC";
                            AluFunc <= ALU_AplusBplusCarry;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            ClkEnPC <= '0';
                        when OP_SUB => 
                            report "SUB";
                            AluFunc <= ALU_AminusBminusCarry;
                            SelPC <= 'X';
                            ClkEnPC <= '0';
                            ALU_CarryIn <= '0';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                        when OP_SUBC => 
                            report "SUBC";
                            AluFunc <= ALU_AminusBminusCarry;
                            SelPC <= 'X';
                            ClkEnPC <= '0';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                        when OP_COMP => 
                            report "COMP";
                            AluFunc <= ALU_AminusBminusCarry;
                            SelPC <= 'X';
                            ClkEnPC <= '0';
                            ALU_CarryIn <= '1';
                            ClkENRegFile <= '1';
                        when OP_INC =>
                            report "INC";
                            AluFunc <= ALU_A_INC;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            ClkEnPC <= '0';
                        when OP_DEC =>
                            report "DEC";
                            AluFunc <= ALU_A_DEC;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            ClkEnPC <= '0';
                        when OP_SHL => 
                            report "SHL";
                            ALUFunc <= ALU_ShiftALeft;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            ALU_CarryIn <= '0';
                            ClkEnPC <= '0';
                        when OP_SHR =>
                            report "SHR";
                            ALUFunc <= ALU_ShiftARight;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            ALU_CarryIn <= '0';
                            ClkEnPC <= '0';
                        when OP_SHRC => 
                            report "SHRC";
                            ALUFunc <= ALU_ShiftARight;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            ClkEnPC <= '0';
                        when OP_SHLC => 
                            report "SHLC";
                            ALUFunc <= ALU_ShiftALeft;
                            SelPC <= 'X';
                            SelLoad <= '0';
                            ClkENRegFile <= '1';
                            ClkEnPC <= '0';
                        when others =>
                            AluFunc <= "XXXX";
                            SelPC <= 'X';
                            SelLoad <= 'X';
                            ClkEnPC <= '0';
                            report "Illegal instruction";
                        end case;
            when Cycle_3 =>
                            cycle <= clock_cycle(cycle, instrTerminate);
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
    end if;

                
    end process readOpCode;
end Behavioral;

