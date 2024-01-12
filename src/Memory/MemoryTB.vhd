library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.prol16_package.all;

entity MemoryTB is
end MemoryTB;

architecture MemoryTB_behav of MemoryTB is
component memory
    port (
      mem_addr_i : in std_ulogic_vector(15 downto 0);  -- address input
      mem_dat_io : inout std_logic_vector(15 downto 0);   -- data i/o
      mem_ce_ni : in std_ulogic;    -- chip enable (low active)
      mem_oe_ni : in std_ulogic;    -- output enable (low active)
      mem_we_ni : in std_ulogic);   -- write enable (low active)
  end component;
  
    signal ZuluClk : std_ulogic := '0';
    signal mem_ce_ni_s : std_ulogic := '0';
    signal mem_oe_ni_s : std_ulogic := '0';
    signal mem_we_ni_s : std_ulogic := '1';
    signal mem_addr_i_s : std_ulogic_vector(DataVec_length - 1 downto 0) := (others => '0');
    signal mem_dat_io_s : std_logic_vector(DataVec_length - 1 downto 0);
    signal mem_ctr : std_ulogic := '0';
  
begin

  ZuluClk <= not ZuluClk after 100ns;

  memory_inst : memory
    port map (
      mem_addr_i => mem_addr_i_s,
      mem_dat_io => mem_dat_io_s,
      mem_ce_ni => mem_ce_ni_s,
      mem_oe_ni => mem_oe_ni_s,
      mem_we_ni => mem_we_ni_s);

  process (ZuluClk) is
  begin
	if rising_edge(ZuluClk) then
		if (mem_ctr = '0') then
			mem_ce_ni_s <= '0';
    			mem_oe_ni_s <= '0';
    			mem_we_ni_s <= '1';
			mem_ctr <= '1';
		elsif (mem_ctr = '1') then
			mem_ce_ni_s <= '1';
    			mem_oe_ni_s <= '1';
    			mem_we_ni_s <= '1';
			mem_addr_i_s <= std_ulogic_vector(to_unsigned(to_integer(unsigned(mem_addr_i_s)) + 1, 16));
			mem_ctr <= '0';
		end if;
	end if;
  end process;
end MemoryTB_behav;
