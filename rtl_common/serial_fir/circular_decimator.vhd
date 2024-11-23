library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.math_helpers.all;
use ieee.fixed_pkg.all;

--TODO some LLM code in there, stringent verification needed
entity circular_decimator is
    generic (
        BUFFER_SIZE        : natural := 64;
        BUFF_COUNT_WIDTH   : natural := natural(clog2(BUFFER_SIZE));
        SIGNAL_WIDTH       : natural := 16;
        FRAC_BITS          : natural := 8;
        WHOLE_BITS         : natural := SIGNAL_WIDTH - FRAC_BITS;
        DECIMATE_RATIO     : natural := 1; --should NOT be less than 1
        SYN_RAMSTYLE       : string  := "registers"
    );
    port (
        i_core_clk              : in  std_logic;
        i_core_clk_en           : in  std_logic;
        i_resetn                : in  std_logic;

        --sample write port
        o_sample_ready          : out std_logic;
        i_sample_valid          : in  std_logic;
        i_sample                : in  ufixed(WHOLE_BITS-1 downto -FRAC_BITS);

        --sample read port
        i_sample_ready          : in  std_logic;
        o_sample_valid          : out std_logic;
        o_sample                : out ufixed(WHOLE_BITS-1 downto -FRAC_BITS);
        o_sample_last           : out std_logic;

        --status signals
        o_buffer_empty          : out std_logic;
        o_buffer_full           : out std_logic;
        o_buffer_count          : out unsigned(BUFF_COUNT_WIDTH-1 downto 0)
    );
end entity circular_decimator;

architecture rtl of circular_decimator is
    -- Memory array declaration
    type ram_type is array (0 to BUFFER_SIZE-1) of ufixed(WHOLE_BITS-1 downto -FRAC_BITS);
    signal ram_block : ram_type;

    signal fifo_empty   : std_logic;
    signal fifo_full    : std_logic;
    signal size_reg     : unsigned(BUFF_COUNT_WIDTH-1 downto 0);
    signal next_size_reg: unsigned(BUFF_COUNT_WIDTH-1 downto 0);
    signal wr_pointer   : unsigned(BUFF_COUNT_WIDTH-1 downto 0);
    signal rd_pointer   : unsigned(BUFF_COUNT_WIDTH-1 downto 0);
    signal base_pointer : unsigned(BUFF_COUNT_WIDTH-1 downto 0);

    signal wr_pointer_next   : unsigned(BUFF_COUNT_WIDTH-1 downto 0);
    signal rd_pointer_next   : unsigned(BUFF_COUNT_WIDTH-1 downto 0);
    signal base_pointer_next : unsigned(BUFF_COUNT_WIDTH-1 downto 0);

    signal read_handshake : std_logic;
    signal write_handshake : std_logic;
begin
    -- Assign ready and full/empty flags
    o_sample_ready <= not fifo_full and i_resetn;
    o_buffer_empty <= fifo_empty;
    o_buffer_full  <= fifo_full;
    o_buffer_count <= size_reg;

    read_handshake  <= o_sample_valid and i_sample_ready;
    write_handshake <= i_sample_valid and o_sample_ready;

    -- FIFO status update
    process(all)
    begin
        fifo_empty <= '1' when (size_reg = 0) else '0';
        fifo_full <= '1' when (size_reg = BUFFER_SIZE) else '0';
    end process;

    -- FIFO read/write control
    rw_ctrl: process(i_core_clk)
    begin
        if rising_edge(i_core_clk) then
            if not(i_resetn) then
                base_pointer <= (others => '0');
                rd_pointer <= (others => '0');
                wr_pointer <= (others => '0');
                o_sample_valid <= '0';
                size_reg <= (others => '0');
            else
                size_reg   <= next_size_reg;
                wr_pointer <= wr_pointer_next;                
                rd_pointer <= rd_pointer_next;   
                base_pointer <= base_pointer_next;

                if write_handshake then
                    -- Write data to FIFO
                    ram_block(to_integer(wr_pointer)) <= i_sample;
                    --wr_pointer <= wr_pointer + 1;
                end if;

                if i_sample_ready or not(o_sample_valid) then
                    -- Read new data from FIFO if client requests more or if there's no valid data on the bus
                    if fifo_empty = '0' and next_size_reg /= 0 then
                        --rd_pointer <= rd_pointer + 1;
                        o_sample_valid <= '1';
                        o_sample <= ram_block(to_integer(rd_pointer));
                    else
                        o_sample_valid <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process rw_ctrl;

    ptr_ctrl: process(all)
    begin
        wr_pointer_next <= wr_pointer;
        rd_pointer_next <= rd_pointer;
        base_pointer_next <= base_pointer;

        if write_handshake then
            wr_pointer_next <= wr_pointer + 1;
            if wr_pointer = BUFFER_SIZE-1 then
                wr_pointer_next <= (others => '0');
            end if;
        end if;

        if i_sample_ready or not(o_sample_valid) then
            if fifo_empty = '0' and next_size_reg /= 0 then
                rd_pointer_next <= rd_pointer + 1;
                if rd_pointer = BUFFER_SIZE-1 then
                    -- skip K samples of x[n] in order to skip values of y[n] (decimation by K)
                    -- if K=1, no decimation, it just allows us to calculate y[n+1]
                    rd_pointer_next   <= base_pointer + DECIMATE_RATIO;
                    base_pointer_next <= base_pointer + DECIMATE_RATIO;
                    if base_pointer + DECIMATE_RATIO > BUFFER_SIZE-1 then
                        --account for overflow when buffer size isn't a power of two
                        --TODO fmax will probably hurt a lot unless i figure out a better way to do this?
                        rd_pointer_next   <= DECIMATE_RATIO - (base_pointer - BUFFER_SIZE);
                        base_pointer_next <= base_pointer + DECIMATE_RATIO;
                    end if;
                end if;
            end if;
        end if;
    end process ptr_ctrl;

    -- Size control logic
    -- TODO use variable here for elaborate size logic (include DECIMATE_RATIO into the mix..)
    size_ctrl: process(all)
    begin
        next_size_reg <= size_reg;
        if write_handshake and not(read_handshake) then
            next_size_reg <= size_reg + 1;
        elsif read_handshake and not(write_handshake) then
            next_size_reg <= size_reg - 1;
        end if;
    end process size_ctrl;
end architecture rtl;