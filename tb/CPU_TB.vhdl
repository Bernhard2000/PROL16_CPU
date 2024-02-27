 library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.prol16_package.all;

entity CPU_TB is
end CPU_TB;

architecture CPU_TB_behav of CPU_TB is
component memory
    port (
      mem_addr_i : in std_ulogic_vector(15 downto 0);  -- address input
      mem_dat_io : inout std_logic_vector(15 downto 0);   -- data i/o
      mem_ce_ni : in std_ulogic;    -- chip enable (low active)
      mem_oe_ni : in std_ulogic;    -- output enable (low active)
      mem_we_ni : in std_ulogic);   -- write enable (low active)
  end component;
  
 component CPU
    port (
        MemIOData : inout std_logic_vector(15 downto 0);
        MemAddr : out DataVec;
        MemCE : out std_ulogic; -- low-active (Chip Enable)
        MemWE : out std_ulogic; -- low-active (Write Enable)
        MemOE : out std_ulogic; -- low-active (Output Enable)
        ClkEnOpcode : out std_ulogic;
        LegalOpcodePresent : out std_ulogic;
        Reset : in std_ulogic;
        ClkEnPC : out std_ulogic;
        ZuluClk : in std_ulogic;
        RegOpCode : out OpcodeVec;
        ClkEnRegfile : out std_ulogic;
            SelLoad : out std_ulogic;
            ZeroOut : out std_ulogic;
            SelAddr : out std_ulogic;
                 ALUResult : out DataVec 
    );
end component; 
  
    signal ZuluClk : std_ulogic := '0';
    signal mem_ce_ni_s : std_ulogic := '0';
    signal mem_oe_ni_s : std_ulogic := '0';
    signal mem_we_ni_s : std_ulogic := '1';
    signal mem_addr_i_s : std_ulogic_vector(DataVec_length - 1 downto 0) := (others => '0');
    signal mem_dat_io_s : std_logic_vector(DataVec_length - 1 downto 0) := (others => '0');
    
    signal ClkEnOpcode_s : std_ulogic := '0';
    signal LegalOpcodePresent_s : std_ulogic := '0';
    signal Reset_s : std_ulogic := '0';
    signal ClkEnRegfile : std_ulogic;
    
    signal ClkEnPC : std_ulogic;
    signal RegOpCode : OpcodeVec;
    signal SelLoad : std_ulogic;
    signal ZeroOut : std_ulogic;
    signal SelAddr : std_ulogic;
    signal ALUResult : DataVec;
    
begin

  ZuluClk <= not ZuluClk after 100ns;

  memory_inst : memory
    port map (
      mem_addr_i => mem_addr_i_s,
      mem_dat_io => mem_dat_io_s,
      mem_ce_ni => mem_ce_ni_s,
      mem_oe_ni => mem_oe_ni_s,
      mem_we_ni => mem_we_ni_s);
      
  cpu_inst : CPU 
  port map (
      MemIOData => mem_dat_io_s,
      MemAddr => mem_addr_i_s,
      MemCE => mem_ce_ni_s,
      MemWE => mem_we_ni_s,
      MemOE => mem_oe_ni_s,
      ClkEnOpcode => ClkEnOpcode_s,
      LegalOpcodePresent => LegalOpcodePresent_s,
      Reset => Reset_s,
      ZuluClk => ZuluClk,
      ClkEnPC => ClkEnPC,
      RegOpCode => RegOpCode,
      ClkEnRegfile => ClkEnRegfile,
      SelLoad => SelLoad,
      ZeroOut => ZeroOut,
      SelAddr => SelAddr,
      ALUResult => ALUResult
      ); 
end CPU_TB_behav;
