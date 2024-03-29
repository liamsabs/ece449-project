liBRary ieee;
use ieee.std_logic_1164.all;

-- flushing first 2 latches
-- adding forwarding logic

entity CONTROL is 
    port(
        Clk, Rst       : in std_logic;
        IR_In_from_TB  : in std_logic_vector (15 downto 0);
        --Data_In        : in std_logic_vector (15 downto 0);
        --Data_Out       : out std_logic_vector (15 downto 0);
        Reset_button   : in std_logic
    );
end CONTROL;

architecture behavioral of CONTROL is
    component FETCH is
        port (
            IF_Reset        : in std_logic;
            PC_reset        : in std_logic;                         -- Resets PC to [val?]
            BR_addr         : in std_logic_vector(15 downto 0);     -- branch address
            BR_CTRL         : in std_logic;                         -- input signal for PC MUX
            IF_IR_in        : in std_logic_vector(15 downto 0);     -- hardcoded Instruction in Value for Format A Test
            IR_out          : out std_logic_vector(15 downto 0);    -- recieved from memory then outputted to IF/ID register
            PC_out          : out std_logic_vector(15 downto 0)    -- PC for decoder
        );
    end component;
    component DECODE is
        port (
            Clk            : in std_logic; -- Clock Input
            Reset          : in std_logic; -- Reset
            ID_IR_in       : in std_logic_vector (15 downto 0); -- Instruction to Decode
            -- WriteBack
            WB_data        : in std_logic_vector (15 downto 0); -- Write Back data
            WB_addr        : in std_logic_vector (2 downto 0); -- Write Back address 
            WB_En          : in std_logic; -- Write Back Enable
            -- Execute and Register Write Operands
            ALU_op         : out std_logic_vector (2 downto 0); -- ALU operands
            shiftAmt       : out std_logic_vector (3 downto 0); -- shift amount
            RA_data        : out std_logic_vector (15 downto 0); -- Register A data
            RB_data        : out std_logic_vector (15 downto 0); -- Register B data
            RW_addr        : out std_logic_vector (2 downto 0); -- Register Write Address
            RW_En          : out std_logic; -- Register Write Enable
            -- Branching
            PC             : in std_logic_vector (15 downto 0); -- recieved PC+2 (needs to be decremented for branching)
            BR_addr        : out std_logic_vector (15 downto 0); -- branch address to give to FETCH
            BR_En          : out std_logic; -- Indicates that the instruction is a branch (still need to check if we can branch in EX based on BR_Op)
            BR_op          : out std_logic_vector (1 downto 0); -- branch condition
            -- For BR.SUB
            BR_sub_PC      : out std_logic_vector (15 downto 0); -- PC+2 which is written to R7 during BR_sub 
            -- I/0 Handling
            IN_En          : out std_logic; -- enables input to be read in execute stage 
            port_Out       : out std_logic_vector (15 downto 0); -- output from OUT instruction
            -- Forwarding
            RA_addr        : out std_logic_vector (2 downto 0); -- address of RA used for forwarding
            FW_A_data      : in std_logic_vector (15 downto 0); -- input data from forwarding for RA
            FW_A_En        : in std_logic; -- input to be used to determine if forwarding RA
            RB_addr        : out std_logic_vector (2 downto 0); -- address of RB used for forwarding
            FW_B_data      : in std_logic_vector (15 downto 0); -- input data from forwarding for RB
            FW_B_En        : in std_logic -- input to be used to determine if forwarding RB
        );
    end component;
    component EXECUTE is
        port (
            -- ALU Args
            ALU_op         : in std_logic_vector (2 downto 0);          -- OPCODE for ALU
            shiftAmt       : in std_logic_vector (3 downto 0);          -- Amount to shift by
            RA_data        : in std_logic_vector (15 downto 0);         -- Data for ALU A
            RB_data        : in std_logic_vector (15 downto 0);         -- Data for ALU B
            -- Register Write Data to propogate through
            RW_addr_in     : in std_logic_vector (2 downto 0);          -- IN Addr for WB stage
            RW_En_in       : in std_logic;                              -- EN for WB stage
            RW_addr_out    : out std_logic_vector (2 downto 0);         -- OUT Addr for WB stage
            RW_En_out      : out std_logic;                             -- OUT EN for WB stage
            RW_data_out    : out std_logic_vector (15 downto 0);        -- data to be written back
            -- Flags to be set
            Moverflow      : out std_logic; -- Multiplcation overflow flag output for controller
            Z_flag         : out std_logic; -- Zero flag used for testing
            N_flag         : out std_logic; -- Negative flag used for testing
            -- branching inputs
            BR_En          : in std_logic;
            BR_op          : in std_logic_vector(1 downto 0);       
            BR_CTRL        : out std_logic;
            BR_addr_in     : in std_logic_vector(15 downto 0);
            BR_addr_out    : out std_logic_vector(15 downto 0);
            BR_sub_PC      : in std_logic_vector(15 downto 0);
            -- I/O Handling
            IN_data        : in std_logic_vector (15 downto 0);
            IN_En          : in std_logic
     );
    end component;
   component WRITEBACK is
        port (
            Reset       : in std_logic;
            W_data      : in std_logic_vector (15 downto 0);
            W_addr      : in std_logic_vector (2 downto 0);
            W_En        : in std_logic;
            WB_data     : out std_logic_vector (15 downto 0);
            WB_addr     : out std_logic_vector (2 downto 0);
            WB_En       : out std_logic  
        );
    end component;
    
        -- Basic Signals
        signal Reset                 : std_logic;
        signal PC_Reset              : std_logic;   
        signal Input_sig             : std_logic_vector (15 downto 0);
        signal Output_sig            : std_logic_vector (15 downto 0);
        signal Instruction_in_sig    : std_logic_vector (15 downto 0);        
        
        -- IF/ID
        signal IF_ID_IR_In           : std_logic_vector (15 downto 0);
        signal IF_ID_IR_Out          : std_logic_vector (15 downto 0);
        signal IF_ID_PC_In           : std_logic_vector (15 downto 0);
        signal IF_IF_PC_Out          : std_logic_vector (15 downto 0);
    
        -- Decode Signals
        signal ID_Out_sig            : std_logic_vector (15 downto 0); 

        -- ID/EX
        signal ID_EX_ALU_op_In       : std_logic_vector (2 downto 0);
        signal ID_EX_ALU_op_Out      : std_logic_vector (2 downto 0);
        signal ID_EX_Shiftamt_In     : std_logic_vector (3 downto 0);
        signal ID_EX_Shiftamt_Out    : std_logic_vector (3 downto 0);
        signal ID_EX_RA_data_In      : std_logic_vector (15 downto 0);
        signal ID_EX_RA_data_Out     : std_logic_vector (15 downto 0);
        signal ID_EX_RB_data_In      : std_logic_vector (15 downto 0);
        signal ID_EX_RB_data_Out     : std_logic_vector (15 downto 0);
        signal ID_EX_RW_addr_In      : std_logic_vector (2 downto 0);
        signal ID_EX_RW_addr_Out     : std_logic_vector (2 downto 0);
        signal ID_EX_RW_En_In        : std_logic;
        signal ID_EX_RW_En_Out       : std_logic;
        signal ID_EX_IN_En_In        : std_logic;
        signal ID_EX_IN_En_Out       : std_logic;
        signal ID_EX_Out_In          : std_logic_vector (15 downto 0);
        signal ID_EX_Out_Out         : std_logic_vector (15 downto 0);
        signal ID_EX_BR_En_In        : std_logic;
        signal ID_EX_BR_En_Out       : std_logic;
        signal ID_EX_BR_Op_In        : std_logic_vector (1 downto 0);
        signal ID_EX_BR_Op_Out       : std_logic_vector (1 downto 0);
        signal ID_EX_BR_addr_In      : std_logic_vector (15 downto 0);
        signal ID_EX_BR_addr_Out     : std_logic_vector (15 downto 0);
        signal ID_EX_BR_sub_PC_In    : std_logic_vector (15 downto 0);
        signal ID_EX_BR_sub_PC_Out   : std_logic_vector (15 downto 0);
        -- TO DO add MEMORY parameters (address, enable) 

        -- Execute Signals
        signal IN_data               : std_logic_vector (15 downto 0);
        signal Z_flag, N_flag        : std_logic;
        signal Moverflow_Flag        : std_logic;
    
        -- EX/MEM
        signal EX_MEM_RW_data_In     : std_logic_vector (15 downto 0);
        signal EX_MEM_RW_data_Out    : std_logic_vector (15 downto 0);
        signal EX_MEM_RW_addr_In     : std_logic_vector (2 downto 0);
        signal EX_MEM_RW_addr_Out    : std_logic_vector (2 downto 0);
        signal EX_MEM_RW_En_In       : std_logic;
        signal EX_MEM_RW_En_Out      : std_logic;
        signal EX_MEM_BR_CTRL_In     : std_logic;
        signal EX_MEM_BR_CTRL_Out    : std_logic;
        signal EX_MEM_BR_addr_In     : std_logic_vector (15 downto 0);
        signal EX_MEM_BR_addr_Out    : std_logic_vector (15 downto 0);
        -- TO DO add MEMORY parameters (address, enable)
        
        -- MEM/WB
        signal MEM_WB_RW_data_In      : std_logic_vector (15 downto 0);
        signal MEM_WB_RW_data_Out     : std_logic_vector (15 downto 0);
        signal MEM_WB_RW_addr_In      : std_logic_vector (2 downto 0);
        signal MEM_WB_RW_addr_Out     : std_logic_vector (2 downto 0);
        signal MEM_WB_RW_En_In        : std_logic;
        signal MEM_WB_RW_En_Out       : std_logic;
        
        -- Forwarding
        signal ID_A_addr        : std_logic_vector (2 downto 0);
        signal FW_A_data        : std_logic_vector (15 downto 0);
        signal FW_A_En          : std_logic;
        signal ID_B_addr        : std_logic_vector (2 downto 0);
        signal FW_B_data        : std_logic_vector (15 downto 0);
        signal FW_B_En          : std_logic;

        -- Write-back
        signal ID_WB_data       : std_logic_vector (15 downto 0);
        signal ID_WB_addr       : std_logic_vector (2 downto 0);
        signal ID_WB_En         : std_logic;

        -- BRanching
        signal EX_IF_BR_addr    : std_logic_vector (15 downto 0);
        signal EX_IF_BR_CTRL    : std_logic;
        
begin

           FetchStage : FETCH port map (
            Reset       => Reset,
            PC_reset    => Reset_button,
            BR_addr     => EX_MEM_BR_addr_Out,
            BR_CTRL     => EX_MEM_BR_CTRL_Out,
            IR_out      => IF_ID_IR_In,       
            IF_IR_in    => Instruction_in_sig,
            PC_out      => IF_ID_PC_In          
        );
        
        Decoder : DECODE port map (
            Clk       => Clk, 
            Reset     => Reset,     
            ID_IR_in  => IF_ID_IR_Out,
            WB_data   => ID_WB_data,
            WB_addr   => ID_WB_addr,
            WB_En     => ID_WB_En,
            ALU_op    => ID_EX_ALU_op_In,         
            shiftAmt  => ID_EX_Shiftamt_In,       
            RA_data   => ID_EX_RA_data_In,         
            RB_data   => ID_EX_RB_data_In,         
            RW_addr   => ID_EX_RW_addr_In,        
            RW_En     => ID_EX_RW_En_In,
            PC        => IF_ID_PC_Out,
            B_addr    => ID_EX_B_addr_In,
            B_En      => ID_EX_B_En_In,
            B_op      => ID_EX_B_Op_In,
            BR_sub_PC => ID_EX_B_sub_PC_In,
            IN_En     => ID_EX_IN_En_In,          
            port_Out  => Output_sig,         
            RA_addr   => ID_A_addr,
            FW_A_data => FW_A_data,
            FW_A_En   => FW_A_En,
            RB_addr   => ID_B_addr,
            FW_B_data => FW_B_data,
            FW_B_En   => FW_B_En  
        );
        
        ExecuteStage : EXECUTE port map (
            ALU_op      => ID_EX_ALU_op_Out,     
            shiftAmt    => ID_EX_Shiftamt_Out,    
            RA_data     => ID_EX_RA_data_Out,   
            RB_data     => ID_EX_RB_data_Out,
            RW_addr_in  => ID_EX_RW_addr_Out,
            RW_En_in    => ID_EX_RW_En_Out,
            RW_addr_out => EX_WB_RW_addr_In,
            RW_En_out   => EX_WB_RW_En_In,        
            RW_data_out => EX_WB_RW_data_In, 
            Moverflow   => Moverflow_flag,
            Z_flag      => Z_flag,          
            N_flag      => N_flag,
            BR_En       => ID_EX_BR_En_Out,
            BR_op       => ID_EX_BR_Op_Out,
            BR_CTRL     => EX_IF_BR_CTRL_In,
            BR_addr_in  => ID_EX_BR_addr_Out,
            BR_addr_out => EX_IF_BR_addr_In,
            BR_sub_PC   => ID_EX_BR_sub_PC_Out,
            IN_data     => Input_sig,      
            IN_En       => ID_EX_IN_En_Out     
        );
        
        WriteBackStage: WRITEBACK port map (
            Clk       => Clk, 
            Reset     => Reset,
            W_data    => EX_WB_RW_data_Out, 
            W_addr    => EX_WB_RW_addr_Out,         
            W_En      => EX_WB_RW_En_Out,            
            WB_data   => ID_WB_data,   
            WB_addr   => ID_WB_addr,  
            WB_En     => ID_WB_En      
        );
        
        Clk_sig <= Clk;
        Rst_sig <= Rst;
        Instruction_in_sig <= IR_In_from_TB; 
   
    FWD : process(Clk, Rst, IR_in_from_TB, EX_WB_RW_data, WB_ID_data, ID_A_addr, ID_B_addr, EX_WB_RW_addr, WB_ID_addr)
    begin        
        -- Forwarding logic
        if EX_WB_RW_addr = ID_A_addr then
            FW_A_data <= EX_WB_RW_data;
        elsif EX_WB_RW_addr = ID_B_addr then
            FW_B_data <= EX_WB_RW_data;
        elsif WB_ID_addr = ID_A_addr then
            FW_A_data <= WB_ID_data;
        elsif WB_ID_addr = ID_B_addr then
            FW_B_data <= WB_ID_data;
        end if;
    end FWD process; 
    
    IF_ID : process (Clk, EX_MEM_BR_CTRL_Out, Reset)
    begin
        if falling_edge(Clk) then
            if EX_MEM_BR_CTRL_Out = '1' then
                IF_ID_IR_Out <= (others => '0');
                IF_ID_PC_Out <= (others => '0');
            else
                IF_ID_IR_Out <= IF_ID_IR_In;
                IF_ID_PC_Out <= IF_ID_PC_In;
            end if;
        end if;
        if Reset ='1' then
            IF_ID_IR_Out <= (others => '0');
            IF_ID_PC_Out <= (others => '0');
        end if;
    end IF_ID process;

    ID_EX : process (Clk, EX_MEM_BR_CTRL_Out, Reset, ID_EX_ALU_op_In, 
    ID_EX_Shiftamt_In, ID_EX_RA_data_In, ID_EX_RB_data_In, ID_EX_RW_addr_In, 
    ID_EX_RW_En_In, ID_EX_IN_En_In, ID_EX_Out_In, ID_EX_BR_En_In, ID_EX_BR_Op_In, 
    ID_EX_BR_addr_In, ID_EX_BR_sub_PC_In)
    begin
        if falling_edge(Clk) then
            if EX_MEM_BR_CTRL_Out = '1' or Reset = '1' then
                ID_EX_ALU_op_Out <= (others => '0');
                ID_EX_Shiftamt_Out <= (others => '0');
                ID_EX_RA_data_Out <= (others => '0');
                ID_EX_RB_data_Out <= (others => '0');
                ID_EX_RW_addr_Out <= (others => '0');
                ID_EX_RW_En_Out <= '0';
                ID_EX_IN_En_Out <= '0';
                ID_EX_Out_Out <= (others => '0');
                ID_EX_BR_En_Out <= '0';
                ID_EX_BR_Op_Out <= (others => '0');
                ID_EX_BR_addr_Out <= (others => '0');
                ID_EX_BR_sub_PC_Out <= (others => '0');
            else
                ID_EX_ALU_op_Out <= ID_EX_ALU_op_In;
                ID_EX_Shiftamt_Out <= ID_EX_Shiftamt_In;
                ID_EX_RA_data_Out <= ID_EX_RA_data_In;
                ID_EX_RB_data_Out <= ID_EX_RB_data_In;
                ID_EX_RW_addr_Out <= ID_EX_RW_addr_In;
                ID_EX_RW_En_Out <= ID_EX_RW_En_In;
                ID_EX_IN_En_Out <= ID_EX_IN_En_In;
                ID_EX_Out_Out <= ID_EX_Out_In;
                ID_EX_BR_En_Out <= ID_EX_BR_En_In;
                ID_EX_BR_Op_Out <= ID_EX_BR_Op_In;
                ID_EX_BR_addr_Out <= ID_EX_BR_addr_In;
                ID_EX_BR_sub_PC_Out <= ID_EX_BR_sub_PC_In;
            end if;
        end if;
        if Reset = '1' then
            ID_EX_ALU_op_Out <= (others => '0');
            ID_EX_Shiftamt_Out <= (others => '0');
            ID_EX_RA_data_Out <= (others => '0');
            ID_EX_RB_data_Out <= (others => '0');
            ID_EX_RW_addr_Out <= (others => '0');
            ID_EX_RW_En_Out <= '0';
            ID_EX_IN_En_Out <= '0';
            ID_EX_Out_Out <= (others => '0');
            ID_EX_BR_En_Out <= '0';
            ID_EX_BR_Op_Out <= (others => '0');
            ID_EX_BR_addr_Out <= (others => '0');
            ID_EX_BR_sub_PC_Out <= (others => '0');
        end if;
    end ID_EX process;

    EX_MEM : process (EX_MEM_RW_data_In, EX_MEM_RW_addr_In, EX_MEM_RW_En_In, 
    EX_MEM_BR_CTRL_In, EX_MEM_BR_CTRL_In, EX_MEM_BR_addr_In)
    begin
        if falling_edge(Clk) then
            if EX_MEM_BR_CTRL_Out = '1' then
                EX_MEM_RW_data_Out <= (others => '0');
                EX_MEM_RW_addr_Out <= (others => '0');
                EX_MEM_RW_En_Out <= '0';
                EX_MEM_BR_CTRL_Out <= '0';
                EX_MEM_BR_addr_Out <= (others => '0');
            else
                EX_MEM_RW_data_Out <= EX_MEM_RW_data_In;
                EX_MEM_RW_addr_Out <= EX_MEM_RW_addr_In;
                EX_MEM_RW_En_Out <= EX_MEM_RW_En_In;
                EX_MEM_BR_CTRL_Out <= EX_MEM_BR_CTRL_In;
                EX_MEM_BR_addr_Out <= EX_MEM_BR_addr_In;
            end if;
        end if;
        if Reset = '1' then
            EX_MEM_RW_data_Out <= (others => '0');
            EX_MEM_RW_addr_Out <= (others => '0');
            EX_MEM_RW_En_Out <= '0';
            EX_MEM_BR_CTRL_Out <= '0';
            EX_MEM_BR_addr_Out <= (others => '0');
        end if;
    end EX_MEM process;

    MEM_WB : process (Clk, MEM_WB_RW_data_In, MEM_WB_RW_addr_In, MEM_WB_RW_En_In)
    begin
        if falling_edge(Clk) then
            MEM_WB_RW_data_Out <= (others => '0');
            MEM_WB_RW_addr_Out <= (others => '0');
            MEM_WB_RW_En_Out <= '0';
        else
            MEM_WB_RW_data_Out <= MEM_WB_RW_data_In;
            MEM_WB_RW_addr_Out <= MEM_WB_RW_addr_In;
            MEM_WB_RW_En_Out <= MEM_WB_RW_En_In;
        end if;
        if Reset = '1' then
            MEM_WB_RW_data_Out <= (others => '0');
            MEM_WB_RW_addr_Out <= (others => '0');
            MEM_WB_RW_En_Out <= '0';    
        end if;
    end MEM_WB process;
        
end behavioral;
