library ieee;
use ieee.std_logic_1164.all;

entity WRITEBACK is
    port (
        Reset       : in std_logic;
        W_data      : in std_logic_vector (15 downto 0);
        W_addr      : in std_logic_vector (2 downto 0);
        W_En        : in std_logic;
        WB_data     : out std_logic_vector (15 downto 0);
        WB_addr     : out std_logic_vector (2 downto 0);
        WB_En       : out std_logic  
    );
end WRITEBACK;

architecture behavioral of WRITEBACK is
begin
    process (Reset, W_data, W_addr, W_En)
    begin
        if Reset = '1' then
            WB_data <= (others => '0');
            WB_addr <= (others => '0');
            WB_En   <= '0';   
        else
            WB_data <= W_data;
            WB_addr <= W_addr;
            WB_En <= W_En;
        end if;
    end process;
 end behavioral;
