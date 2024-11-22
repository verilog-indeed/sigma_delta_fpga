library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
    generic (
        PRESCALE: integer := 128
    );
    port(
        i_xtal, i_reset_n: in  std_logic;
        i_lvds_cmp_p     : in  std_logic;
        i_lvds_cmp_n     : in  std_logic;
        o_dac_feedback   : out std_logic
    );
end top;

architecture rtl of top is
    signal clk_enable: std_logic;
    signal lvds_cmp: std_logic;
    signal clk_div_counter: unsigned(7 downto 0) := (others => '0');
    COMPONENT TLVDS_IBUF
     PORT (
     O:OUT std_logic;
     I:IN std_logic;
     IB:IN std_logic
     );
    END COMPONENT;
    begin
    input_buff: TLVDS_IBUF port map ( 
        O=>lvds_cmp,
        I=>i_lvds_cmp_p,
        IB=>i_lvds_cmp_n
    );

    clk_enable <= '1' when clk_div_counter = 0 else '0';
    clk_div: process (i_xtal, i_reset_n) 
    begin
        if (rising_edge(i_xtal)) then
            clk_div_counter <= clk_div_counter - 1;
            if (clk_div_counter = 0) then
                clk_div_counter <= to_unsigned(PRESCALE, 8);
            end if;
        end if;
        if (not(i_reset_n)) then
            clk_div_counter <= (others => '0');
        end if;
    end process clk_div;

    bit_sample: process (i_xtal, i_reset_n) 
    begin
        if (rising_edge(i_xtal)) then
            if (clk_enable) then
                o_dac_feedback <= lvds_cmp;
            end if;
        end if;
        if (not(i_reset_n)) then
            o_dac_feedback <= '0';
        end if;
    end process bit_sample;
end rtl;