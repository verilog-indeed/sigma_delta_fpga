library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
--math macros to simplyify common functions like clog2
package math_helpers is
  function clog2(n : integer) return integer;
end package math_helpers;

package body math_helpers is
  function clog2(n : integer) return integer is
  begin
    return integer(ceil(log2(real(n))));
  end function clog2;
end package body math_helpers;
