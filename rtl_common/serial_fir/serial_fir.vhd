library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;

entity serial_fir is
    generic (
        SIGNAL_WIDTH       : natural := 16;
        FRAC_BITS          : natural := 8;
        WHOLE_BITS         : natural := SIGNAL_WIDTH - FRAC_BITS;
        DECIMATE_RATIO     : natural := 2;
        FILTER_ORDER       : natural := 8;
        BUFFER_SYN_RAMSTYLE: string  := "registers"
    );
    port (
        i_core_clk              : in  std_logic;
        i_core_clk_en           : in  std_logic;
        i_resetn                : in  std_logic;

        i_raw_signal            : in  ufixed(WHOLE_BITS-1 downto -FRAC_BITS); --TODO maybe it should be sfixed?
        i_raw_signal_valid      : in  std_logic;

        o_filtered_signal       : out ufixed(WHOLE_BITS-1 downto -FRAC_BITS);
        o_filtered_signal_valid : out std_logic;
        i_filtered_signal_ready : in  std_logic
    );
end entity serial_fir;

architecture rtl of serial_fir is
    type filter_state is (IDLE, BUSY, DONE);
    type coeff_arr is array (0 to FILTER_ORDER) of sfixed(WHOLE_BITS-1 downto -FRAC_BITS);
    
begin
    input_buffer: entity work.circular_decimator
    generic map (
        BUFFER_SIZE    => FILTER_ORDER+1,
        SIGNAL_WIDTH   => SIGNAL_WIDTH,
        FRAC_BITS      => FRAC_BITS,
        DECIMATE_RATIO => DECIMATE_RATIO,
        SYN_RAMSTYLE   => BUFFER_SYN_RAMSTYLE
    ) port map (
        i_core_clk     => i_core_clk,
        i_resetn       => i_resetn,

        i_sample_ready =>,
        o_sample_valid =>,
        o_sample       =>,
        o_sample_last =>,
        o_sample_count =>
    );
end architecture;