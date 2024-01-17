library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_Controller is
  port (
    clk : in std_logic;
    reset : in std_logic;
    data_in : in std_logic_vector(7 downto 0);
    tx : out std_logic
  );
end entity UART_Controller;

architecture behavioral of UART_Controller is
  signal uart_data : std_logic_vector(23 downto 0);
  signal tx_counter : integer := 0;
  signal bit_counter : integer := 0;
  signal start_sending : boolean := false;
  signal tx_done : boolean := true;

  constant UART_BIT_PERIOD : time := 10416 ns; -- For 9600 bps, adjust as needed

  procedure send_byte(data_byte : in std_logic_vector) is
    begin
      uart_data <= data_byte;
      start_sending <= true;
      tx_done <= false;
    end procedure;

begin
  process(clk, reset)
  begin
    if reset = '1' then
      tx_counter <= 0;
      bit_counter <= 0;
      start_sending <= false;
      tx_done <= true;
    elsif rising_edge(clk) then
      if start_sending then
        if tx_counter < 3 then
          if bit_counter = 0 then
            tx <= uart_data(7);
          else
            tx <= uart_data(7 - (bit_counter - 1));
          end if;
          bit_counter <= bit_counter + 1;
          if bit_counter = 9 then
            bit_counter <= 0;
            tx_counter <= tx_counter + 1;
          end if;
        else
          start_sending <= false;
          tx_done <= true;
        end if;
      else
        tx <= '1'; -- UART idle state
      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      if tx_done then
        -- Transmit data sequentially
        if not NoTMR_simulation_completed then
          send_byte(NoTMR_CRC24);
        elsif not TMR_simulation_completed then
          send_byte(TMR_CRC24);
        elsif not GTMR_simulation_completed then
          send_byte(GTMR_CRC24);
        elsif tx_counter < 9 then
          case tx_counter is
            when 0 =>
              send_byte(NoTMR_error_count);
            when 1 =>
              send_byte(TMR_CRC24_1_error_count);
            when 2 =>
              send_byte(TMR_CRC24_2_error_count);
            when 3 =>
              send_byte(TMR_CRC24_3_error_count);
            when 4 =>
              send_byte(GTMR_CRC24_1_error_count);
            when 5 =>
              send_byte(GTMR_CRC24_2_error_count);
            when 6 =>
              send_byte(GTMR_CRC24_3_error_count);
            when 7 =>
              send_byte(GTMR_CRC24_4_error_count);
            when 8 =>
              send_byte(GTMR_CRC24_4_tact_enable);
          end case;
        end if;
      end if;
    end if;
  end process;
end architecture behavioral;