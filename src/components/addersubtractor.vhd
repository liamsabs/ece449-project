-- 1-bit Full adder 
----------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity FullAdder_1bit is 
    Port (
        a, b, Cin: in std_logic;
        Sum, Cout: out std_logic 
    );
end FullAdder_1bit;

architecture Behavioral of FullAdder_1bit is 
begin
    Sum <= a xor b xor Cin;
    Cout <= (a and b) or (a and Cin) or (b and Cin);
end Behavioral;
----------------------------------------------------------

-- 16-bit Full Adder 
----------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity FullAdder_16bit is
    Port (
        A, B: in std_logic_vector (15 downto 0);
        Cin: in std_logic;
        Sum: out std_logic_vector (15 downto 0); 
        Cout: out std_logic
    );
end FullAdder_16bit;

architecture Behavioral of FullAdder_16bit is
    --signals
    signal C : std_logic_vector (14 downto 0);

    --components
    component FullAdder_1bit is 
        Port ( a, b, Cin : in std_logic;
            Sum, Cout : out std_logic );
    end component;

    begin

        fulladder_bit0: FullAdder_1bit port map (A(0), B(0), Cin, Sum(0), C(0));
        fulladder_bit1: FullAdder_1bit port map (A(1), B(1), C(0), Sum(1), C(1));
        fulladder_bit2: FullAdder_1bit port map (A(2), B(2), C(1), Sum(2), C(2));
        fulladder_bit3: FullAdder_1bit port map (A(3), B(3), C(2), Sum(3), C(3));
        fulladder_bit4: FullAdder_1bit port map (A(4), B(4), C(3), Sum(4), C(4));
        fulladder_bit5: FullAdder_1bit port map (A(5), B(5), C(4), Sum(5), C(5));
        fulladder_bit6: FullAdder_1bit port map (A(6), B(6), C(5), Sum(6), C(6));
        fulladder_bit7: FullAdder_1bit port map (A(7), B(7), C(6), Sum(7), C(7));
        fulladder_bit8: FullAdder_1bit port map (A(8), B(8), C(7), Sum(8), C(8));
        fulladder_bit9: FullAdder_1bit port map (A(9), B(9), C(8), Sum(9), C(9));
        fulladder_bit10: FullAdder_1bit port map (A(10), B(10), C(9), Sum(10), C(10));
        fulladder_bit11: FullAdder_1bit port map (A(11), B(11), C(10), Sum(11), C(11));
        fulladder_bit12: FullAdder_1bit port map (A(12), B(12), C(11), Sum(12), C(12));
        fulladder_bit13: FullAdder_1bit port map (A(13), B(13), C(12), Sum(13), C(13));
        fulladder_bit14: FullAdder_1bit port map (A(14), B(14), C(13), Sum(14), C(14));
        fulladder_bit15: FullAdder_1bit port map (A(15), B(15), C(14), Sum(15), Cout);

end Behavioral;
------------------------------------------------------------------------------

-- 16-bit Adder Subtractor
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity adderSubtractor_16bit is
    Port (
        A, B: in std_logic_vector (15 downto 0);
         Sub: in std_logic;
         Sum: out std_logic_vector (15 downto 0);
         Cout: out std_logic
    );
end adderSubtractor_16bit;

architecture behavioral of AdderSubtractor_16bit is
    -- Signal Definition 
    Signal Bsub : std_logic_vector (15 downto 0);

    -- Component Definition
    component FullAdder_16bit is
        Port (
            A, B: in std_logic_vector (15 downto 0);
            Cin: in std_logic;
            Sum: out std_logic_vector (15 downto 0); 
            Cout: out std_logic
        );
    end component;

    begin 
        process(Bsub, B, Sub)
        begin
        invert_bits_b : for i in 0 to 15 loop
            Bsub(i) <= B(i) xor Sub;    
        end loop invert_bits_b;
        end process;

        Add: FullAdder_16bit port map (A, Bsub, Sub, Sum, Cout);
        
end behavioral;
------------------------------------------------------------------------------