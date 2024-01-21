---------------------------------------------------------------------------
-- Блок NoTMR модуля FPGAmodule узла FaultTolerantUnit. Резервирование
-- функционального элемента (вычислителя) не применяется. Логика работы
-- функционального элемента заключается в нахождении контрольной суммы
-- входной последовательности, рассчитанной алгоритмом CRC24.
---------------------------------------------------------------------------
-- Порождающий полином (0:23):
-- x^24+x^22+x^20+x^19+x^18+x^16+x^14+x^13+x^11+x^10+x^8+x^7+x^6+x^3+x^1+1
---------------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity NoTMR is
	port (
		-- тактовый сигнал
		clk : in std_logic;
		
		-- ручной запуск и остановка программы
		start_stop : in std_logic;
		
		-- контрольная сумма входной последовательности, рассчитанная алгоритмом CRC24 (24-битное значение)
		CRC24 : out std_logic_vector(23 downto 0);
		
		-- количество внесённых ошибок
		error_count : out std_logic_vector(23 downto 0);
		
		-- флаг, отображающий окончание работы блока NoTMR
		simulation_completed: out std_logic := '0'
	);
end entity NoTMR;

architecture behavioral of NoTMR is
	-- смена состояния программы (запуск и окончание) [внутренний сигнал]
	signal internal_start_stop : std_logic := '0';
	
	-- регистр сдвига с линейной обратной связью (LFSR)
	signal LFSR : std_logic_vector(23 downto 0) := (others => '0');
	
	-- входная последовательность
	signal data : std_logic_vector(23 downto 0);
	
	-- начальное 24-битное значение входной последовательностие (0...01) [внутренний сигнал]
	signal internal_data : std_logic_vector(23 downto 0) := (23 downto 1 => '0', 0 => '1');
	
	signal clock_counter : natural := 0;
	
	signal fault_tact : natural;
	signal fault_tact_generated: std_logic := '0';
	signal error_bit : natural;
	
	constant fault_tact_multiplier : natural := 84596131;
	constant fault_tact_module : natural := 100001;
	signal fault_tact_seed : natural := 1;
	
	constant error_bit_multiplier : natural := 3;
	constant error_bit_module : natural := 25;
	signal error_bit_seed : natural := 1;
	
	signal temp_error_count : natural := 0;
	
	signal temp_simulation_completed : std_logic := '0';
begin
	process(start_stop)
		begin
			if (start_stop = '1') then
				internal_start_stop <= not internal_start_stop;
			end if;
	end process;
	
	process(clk)
		begin
			if rising_edge(clk) then
				if internal_start_stop = '1' then
					if (internal_data = "111111111111111111111111") then
						internal_data <= (others => 'U');
						temp_simulation_completed <= '1';
					elsif not(internal_data = "UUUUUUUUUUUUUUUUUUUUUUUU") then
						internal_data <= internal_data + 1;
					end if;
				end if;
			end if;
	end process;
	
	data <= internal_data;
	simulation_completed <= temp_simulation_completed;
	
	process (clk)
	variable temp_fault_tact_generated: std_logic; -- промежуточный флаг определения такта для внесения ошибки
		begin
			if rising_edge(clk) then
				if fault_tact_generated /= '1' then
					-- вычисление псевдослучайного числа для определения такта, на котором будет внесена ошибка
					fault_tact_seed <= (fault_tact_seed * fault_tact_multiplier) mod fault_tact_module;
					temp_fault_tact_generated := '1'; -- установка промежуточного флага, обозначающего, что ошибочный такт определен
				end if;
				
				if clock_counter = fault_tact then
					error_bit_seed <= (error_bit_seed * error_bit_multiplier) mod error_bit_module;
					temp_fault_tact_generated := '0'; -- сброс промежуточного флага
				end if;
				
				fault_tact_generated <= temp_fault_tact_generated; -- установка основого флага определения такта для внесения ошибки в соответствии с промежуточным флагом
			end if;
	end process;
	
	fault_tact <= fault_tact_seed;
	error_bit <= error_bit_seed;
	
	-- вычислитель
	process (clk)
		begin
			if rising_edge(clk) then
				if internal_start_stop = '1' then
					-- вычисление CRC24 с использованием LFSR
					if (error_bit = 1) and (clock_counter = fault_tact) then
						CRC24(0) <= not(LFSR(0) xor LFSR(2) xor LFSR(5) xor LFSR(9) xor LFSR(10) xor LFSR(11) xor LFSR(13) xor LFSR(14) xor LFSR(21) xor LFSR(23) xor data(0) xor data(2) xor data(5) xor data(9) xor data(10) xor data(11) xor data(13) xor data(14) xor data(21) xor data(23));
					else
						CRC24(0) <= LFSR(0) xor LFSR(2) xor LFSR(5) xor LFSR(9) xor LFSR(10) xor LFSR(11) xor LFSR(13) xor LFSR(14) xor LFSR(21) xor LFSR(23) xor data(0) xor data(2) xor data(5) xor data(9) xor data(10) xor data(11) xor data(13) xor data(14) xor data(21) xor data(23);
					end if;
					
					if (error_bit = 2) and (clock_counter = fault_tact) then
						CRC24(1) <= not(LFSR(0) xor LFSR(1) xor LFSR(2) xor LFSR(3) xor LFSR(5) xor LFSR(6) xor LFSR(9) xor LFSR(12) xor LFSR(13) xor LFSR(15) xor LFSR(21) xor LFSR(22) xor LFSR(23) xor data(0) xor data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(9) xor data(12) xor data(13) xor data(15) xor data(21) xor data(22) xor data(23));
					else
						CRC24(1) <= LFSR(0) xor LFSR(1) xor LFSR(2) xor LFSR(3) xor LFSR(5) xor LFSR(6) xor LFSR(9) xor LFSR(12) xor LFSR(13) xor LFSR(15) xor LFSR(21) xor LFSR(22) xor LFSR(23) xor data(0) xor data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(9) xor data(12) xor data(13) xor data(15) xor data(21) xor data(22) xor data(23);
					end if;
					
					if (error_bit = 3) and (clock_counter = fault_tact) then
						CRC24(2) <= not(LFSR(1) xor LFSR(2) xor LFSR(3) xor LFSR(4) xor LFSR(6) xor LFSR(7) xor LFSR(10) xor LFSR(13) xor LFSR(14) xor LFSR(16) xor LFSR(22) xor LFSR(23) xor data(1) xor data(2) xor data(3) xor data(4) xor data(6) xor data(7) xor data(10) xor data(13) xor data(14) xor data(16) xor data(22) xor data(23));
					else
						CRC24(2) <= LFSR(1) xor LFSR(2) xor LFSR(3) xor LFSR(4) xor LFSR(6) xor LFSR(7) xor LFSR(10) xor LFSR(13) xor LFSR(14) xor LFSR(16) xor LFSR(22) xor LFSR(23) xor data(1) xor data(2) xor data(3) xor data(4) xor data(6) xor data(7) xor data(10) xor data(13) xor data(14) xor data(16) xor data(22) xor data(23);
					end if;
					
					if (error_bit = 4) and (clock_counter = fault_tact) then
						CRC24(3) <= not(LFSR(0) xor LFSR(3) xor LFSR(4) xor LFSR(7) xor LFSR(8) xor LFSR(9) xor LFSR(10) xor LFSR(13) xor LFSR(15) xor LFSR(17) xor LFSR(21) xor data(0) xor data(3) xor data(4) xor data(7) xor data(8) xor data(9) xor data(10) xor data(13) xor data(15) xor data(17) xor data(21));
					else
						CRC24(3) <= LFSR(0) xor LFSR(3) xor LFSR(4) xor LFSR(7) xor LFSR(8) xor LFSR(9) xor LFSR(10) xor LFSR(13) xor LFSR(15) xor LFSR(17) xor LFSR(21) xor data(0) xor data(3) xor data(4) xor data(7) xor data(8) xor data(9) xor data(10) xor data(13) xor data(15) xor data(17) xor data(21);
					end if;
					
					if (error_bit = 5) and (clock_counter = fault_tact) then
						CRC24(4) <= not(LFSR(1) xor LFSR(4) xor LFSR(5) xor LFSR(8) xor LFSR(9) xor LFSR(10) xor LFSR(11) xor LFSR(14) xor LFSR(16) xor LFSR(18) xor LFSR(22) xor data(1) xor data(4) xor data(5) xor data(8) xor data(9) xor data(10) xor data(11) xor data(14) xor data(16) xor data(18) xor data(22));
					else
						CRC24(4) <= LFSR(1) xor LFSR(4) xor LFSR(5) xor LFSR(8) xor LFSR(9) xor LFSR(10) xor LFSR(11) xor LFSR(14) xor LFSR(16) xor LFSR(18) xor LFSR(22) xor data(1) xor data(4) xor data(5) xor data(8) xor data(9) xor data(10) xor data(11) xor data(14) xor data(16) xor data(18) xor data(22);
					end if;
					
					if (error_bit = 6) and (clock_counter = fault_tact) then
						CRC24(5) <= not(LFSR(2) xor LFSR(5) xor LFSR(6) xor LFSR(9) xor LFSR(10) xor LFSR(11) xor LFSR(12) xor LFSR(15) xor LFSR(17) xor LFSR(19) xor LFSR(23) xor data(2) xor data(5) xor data(6) xor data(9) xor data(10) xor data(11) xor data(12) xor data(15) xor data(17) xor data(19) xor data(23));
					else
						CRC24(5) <= LFSR(2) xor LFSR(5) xor LFSR(6) xor LFSR(9) xor LFSR(10) xor LFSR(11) xor LFSR(12) xor LFSR(15) xor LFSR(17) xor LFSR(19) xor LFSR(23) xor data(2) xor data(5) xor data(6) xor data(9) xor data(10) xor data(11) xor data(12) xor data(15) xor data(17) xor data(19) xor data(23);
					end if;
					
					if (error_bit = 7) and (clock_counter = fault_tact) then
						CRC24(6) <= not(LFSR(0) xor LFSR(2) xor LFSR(3) xor LFSR(5) xor LFSR(6) xor LFSR(7) xor LFSR(9) xor LFSR(12) xor LFSR(14) xor LFSR(16) xor LFSR(18) xor LFSR(20) xor LFSR(21) xor LFSR(23) xor data(0) xor data(2) xor data(3) xor data(5) xor data(6) xor data(7) xor data(9) xor data(12) xor data(14) xor data(16) xor data(18) xor data(20) xor data(21) xor data(23));
					else
						CRC24(6) <= LFSR(0) xor LFSR(2) xor LFSR(3) xor LFSR(5) xor LFSR(6) xor LFSR(7) xor LFSR(9) xor LFSR(12) xor LFSR(14) xor LFSR(16) xor LFSR(18) xor LFSR(20) xor LFSR(21) xor LFSR(23) xor data(0) xor data(2) xor data(3) xor data(5) xor data(6) xor data(7) xor data(9) xor data(12) xor data(14) xor data(16) xor data(18) xor data(20) xor data(21) xor data(23);
					end if;
					
					if (error_bit = 8) and (clock_counter = fault_tact) then
						CRC24(7) <= not(LFSR(0) xor LFSR(1) xor LFSR(2) xor LFSR(3) xor LFSR(4) xor LFSR(5) xor LFSR(6) xor LFSR(7) xor LFSR(8) xor LFSR(9) xor LFSR(11) xor LFSR(14) xor LFSR(15) xor LFSR(17) xor LFSR(19) xor LFSR(22) xor LFSR(23) xor data(0) xor data(1) xor data(2) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(8) xor data(9) xor data(11) xor data(14) xor data(15) xor data(17) xor data(19) xor data(22) xor data(23));
					else
						CRC24(7) <= LFSR(0) xor LFSR(1) xor LFSR(2) xor LFSR(3) xor LFSR(4) xor LFSR(5) xor LFSR(6) xor LFSR(7) xor LFSR(8) xor LFSR(9) xor LFSR(11) xor LFSR(14) xor LFSR(15) xor LFSR(17) xor LFSR(19) xor LFSR(22) xor LFSR(23) xor data(0) xor data(1) xor data(2) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(8) xor data(9) xor data(11) xor data(14) xor data(15) xor data(17) xor data(19) xor data(22) xor data(23);
					end if;
					
					if (error_bit = 9) and (clock_counter = fault_tact) then
						CRC24(8) <= not(LFSR(0) xor LFSR(1) xor LFSR(3) xor LFSR(4) xor LFSR(6) xor LFSR(7) xor LFSR(8) xor LFSR(11) xor LFSR(12) xor LFSR(13) xor LFSR(14) xor LFSR(15) xor LFSR(16) xor LFSR(18) xor LFSR(20) xor LFSR(21) xor data(0) xor data(1) xor data(3) xor data(4) xor data(6) xor data(7) xor data(8) xor data(11) xor data(12) xor data(13) xor data(14) xor data(15) xor data(16) xor data(18) xor data(20) xor data(21));
					else
						CRC24(8) <= LFSR(0) xor LFSR(1) xor LFSR(3) xor LFSR(4) xor LFSR(6) xor LFSR(7) xor LFSR(8) xor LFSR(11) xor LFSR(12) xor LFSR(13) xor LFSR(14) xor LFSR(15) xor LFSR(16) xor LFSR(18) xor LFSR(20) xor LFSR(21) xor data(0) xor data(1) xor data(3) xor data(4) xor data(6) xor data(7) xor data(8) xor data(11) xor data(12) xor data(13) xor data(14) xor data(15) xor data(16) xor data(18) xor data(20) xor data(21);
					end if;
					
					if (error_bit = 10) and (clock_counter = fault_tact) then
						CRC24(9) <= not(LFSR(1) xor LFSR(2) xor LFSR(4) xor LFSR(5) xor LFSR(7) xor LFSR(8) xor LFSR(9) xor LFSR(12) xor LFSR(13) xor LFSR(14) xor LFSR(15) xor LFSR(16) xor LFSR(17) xor LFSR(19) xor LFSR(21) xor LFSR(22) xor data(1) xor data(2) xor data(4) xor data(5) xor data(7) xor data(8) xor data(9) xor data(12) xor data(13) xor data(14) xor data(15) xor data(16) xor data(17) xor data(19) xor data(21) xor data(22));
					else
						CRC24(9) <= LFSR(1) xor LFSR(2) xor LFSR(4) xor LFSR(5) xor LFSR(7) xor LFSR(8) xor LFSR(9) xor LFSR(12) xor LFSR(13) xor LFSR(14) xor LFSR(15) xor LFSR(16) xor LFSR(17) xor LFSR(19) xor LFSR(21) xor LFSR(22) xor data(1) xor data(2) xor data(4) xor data(5) xor data(7) xor data(8) xor data(9) xor data(12) xor data(13) xor data(14) xor data(15) xor data(16) xor data(17) xor data(19) xor data(21) xor data(22);
					end if;
					
					if (error_bit = 11) and (clock_counter = fault_tact) then
						CRC24(10) <= not(LFSR(0) xor LFSR(3) xor LFSR(6) xor LFSR(8) xor LFSR(11) xor LFSR(15) xor LFSR(16) xor LFSR(17) xor LFSR(18) xor LFSR(20) xor LFSR(21) xor LFSR(22) xor data(0) xor data(3) xor data(6) xor data(8) xor data(11) xor data(15) xor data(16) xor data(17) xor data(18) xor data(20) xor data(21) xor data(22));
					else
						CRC24(10) <= LFSR(0) xor LFSR(3) xor LFSR(6) xor LFSR(8) xor LFSR(11) xor LFSR(15) xor LFSR(16) xor LFSR(17) xor LFSR(18) xor LFSR(20) xor LFSR(21) xor LFSR(22) xor data(0) xor data(3) xor data(6) xor data(8) xor data(11) xor data(15) xor data(16) xor data(17) xor data(18) xor data(20) xor data(21) xor data(22);
					end if;
					
					if (error_bit = 12) and (clock_counter = fault_tact) then
						CRC24(11) <= not(LFSR(0) xor LFSR(1) xor LFSR(2) xor LFSR(4) xor LFSR(5) xor LFSR(7) xor LFSR(10) xor LFSR(11) xor LFSR(12) xor LFSR(13) xor LFSR(14) xor LFSR(16) xor LFSR(17) xor LFSR(18) xor LFSR(19) xor LFSR(22) xor data(0) xor data(1) xor data(2) xor data(4) xor data(5) xor data(7) xor data(10) xor data(11) xor data(12) xor data(13) xor data(14) xor data(16) xor data(17) xor data(18) xor data(19) xor data(22));
					else
						CRC24(11) <= LFSR(0) xor LFSR(1) xor LFSR(2) xor LFSR(4) xor LFSR(5) xor LFSR(7) xor LFSR(10) xor LFSR(11) xor LFSR(12) xor LFSR(13) xor LFSR(14) xor LFSR(16) xor LFSR(17) xor LFSR(18) xor LFSR(19) xor LFSR(22) xor data(0) xor data(1) xor data(2) xor data(4) xor data(5) xor data(7) xor data(10) xor data(11) xor data(12) xor data(13) xor data(14) xor data(16) xor data(17) xor data(18) xor data(19) xor data(22);
					end if;
					
					if (error_bit = 13) and (clock_counter = fault_tact) then
						CRC24(12) <= not(LFSR(1) xor LFSR(2) xor LFSR(3) xor LFSR(5) xor LFSR(6) xor LFSR(8) xor LFSR(11) xor LFSR(12) xor LFSR(13) xor LFSR(14) xor LFSR(15) xor LFSR(17) xor LFSR(18) xor LFSR(19) xor LFSR(20) xor LFSR(23) xor data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(8) xor data(11) xor data(12) xor data(13) xor data(14) xor data(15) xor data(17) xor data(18) xor data(19) xor data(20) xor data(23));
					else
						CRC24(12) <= LFSR(1) xor LFSR(2) xor LFSR(3) xor LFSR(5) xor LFSR(6) xor LFSR(8) xor LFSR(11) xor LFSR(12) xor LFSR(13) xor LFSR(14) xor LFSR(15) xor LFSR(17) xor LFSR(18) xor LFSR(19) xor LFSR(20) xor LFSR(23) xor data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(8) xor data(11) xor data(12) xor data(13) xor data(14) xor data(15) xor data(17) xor data(18) xor data(19) xor data(20) xor data(23);
					end if;
					
					if (error_bit = 14) and (clock_counter = fault_tact) then
						CRC24(13) <= not(LFSR(0) xor LFSR(3) xor LFSR(4) xor LFSR(5) xor LFSR(6) xor LFSR(7) xor LFSR(10) xor LFSR(11) xor LFSR(12) xor LFSR(15) xor LFSR(16) xor LFSR(18) xor LFSR(19) xor LFSR(20) xor LFSR(23) xor data(0) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(10) xor data(11) xor data(12) xor data(15) xor data(16) xor data(18) xor data(19) xor data(20) xor data(23));
					else
						CRC24(13) <= LFSR(0) xor LFSR(3) xor LFSR(4) xor LFSR(5) xor LFSR(6) xor LFSR(7) xor LFSR(10) xor LFSR(11) xor LFSR(12) xor LFSR(15) xor LFSR(16) xor LFSR(18) xor LFSR(19) xor LFSR(20) xor LFSR(23) xor data(0) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(10) xor data(11) xor data(12) xor data(15) xor data(16) xor data(18) xor data(19) xor data(20) xor data(23);
					end if;
					
					if (error_bit = 15) and (clock_counter = fault_tact) then
						CRC24(14) <= not(LFSR(0) xor LFSR(1) xor LFSR(2) xor LFSR(4) xor LFSR(6) xor LFSR(7) xor LFSR(8) xor LFSR(9) xor LFSR(10) xor LFSR(12) xor LFSR(14) xor LFSR(16) xor LFSR(17) xor LFSR(19) xor LFSR(20) xor LFSR(23) xor data(0) xor data(1) xor data(2) xor data(4) xor data(6) xor data(7) xor data(8) xor data(9) xor data(10) xor data(12) xor data(14) xor data(16) xor data(17) xor data(19) xor data(20) xor data(23));
					else
						CRC24(14) <= LFSR(0) xor LFSR(1) xor LFSR(2) xor LFSR(4) xor LFSR(6) xor LFSR(7) xor LFSR(8) xor LFSR(9) xor LFSR(10) xor LFSR(12) xor LFSR(14) xor LFSR(16) xor LFSR(17) xor LFSR(19) xor LFSR(20) xor LFSR(23) xor data(0) xor data(1) xor data(2) xor data(4) xor data(6) xor data(7) xor data(8) xor data(9) xor data(10) xor data(12) xor data(14) xor data(16) xor data(17) xor data(19) xor data(20) xor data(23);
					end if;
					
					if (error_bit = 16) and (clock_counter = fault_tact) then
						CRC24(15) <= not(LFSR(1) xor LFSR(2) xor LFSR(3) xor LFSR(5) xor LFSR(7) xor LFSR(8) xor LFSR(9) xor LFSR(10) xor LFSR(11) xor LFSR(13) xor LFSR(15) xor LFSR(17) xor LFSR(18) xor LFSR(20) xor LFSR(21) xor data(1) xor data(2) xor data(3) xor data(5) xor data(7) xor data(8) xor data(9) xor data(10) xor data(11) xor data(13) xor data(15) xor data(17) xor data(18) xor data(20) xor data(21));
					else
						CRC24(15) <= LFSR(1) xor LFSR(2) xor LFSR(3) xor LFSR(5) xor LFSR(7) xor LFSR(8) xor LFSR(9) xor LFSR(10) xor LFSR(11) xor LFSR(13) xor LFSR(15) xor LFSR(17) xor LFSR(18) xor LFSR(20) xor LFSR(21) xor data(1) xor data(2) xor data(3) xor data(5) xor data(7) xor data(8) xor data(9) xor data(10) xor data(11) xor data(13) xor data(15) xor data(17) xor data(18) xor data(20) xor data(21);
					end if;
					
					if (error_bit = 17) and (clock_counter = fault_tact) then
						CRC24(16) <= not(LFSR(0) xor LFSR(3) xor LFSR(4) xor LFSR(5) xor LFSR(6) xor LFSR(8) xor LFSR(12) xor LFSR(13) xor LFSR(16) xor LFSR(18) xor LFSR(19) xor LFSR(22) xor LFSR(23) xor data(0) xor data(3) xor data(4) xor data(5) xor data(6) xor data(8) xor data(12) xor data(13) xor data(16) xor data(18) xor data(19) xor data(22) xor data(23));
					else
						CRC24(16) <= LFSR(0) xor LFSR(3) xor LFSR(4) xor LFSR(5) xor LFSR(6) xor LFSR(8) xor LFSR(12) xor LFSR(13) xor LFSR(16) xor LFSR(18) xor LFSR(19) xor LFSR(22) xor LFSR(23) xor data(0) xor data(3) xor data(4) xor data(5) xor data(6) xor data(8) xor data(12) xor data(13) xor data(16) xor data(18) xor data(19) xor data(22) xor data(23);
					end if;
					
					if (error_bit = 18) and (clock_counter = fault_tact) then
						CRC24(17) <= not(LFSR(1) xor LFSR(4) xor LFSR(5) xor LFSR(6) xor LFSR(7) xor LFSR(9) xor LFSR(13) xor LFSR(14) xor LFSR(17) xor LFSR(19) xor LFSR(20) xor LFSR(23) xor data(1) xor data(4) xor data(5) xor data(6) xor data(7) xor data(9) xor data(13) xor data(14) xor data(17) xor data(19) xor data(20) xor data(23));
					else
						CRC24(17) <= LFSR(1) xor LFSR(4) xor LFSR(5) xor LFSR(6) xor LFSR(7) xor LFSR(9) xor LFSR(13) xor LFSR(14) xor LFSR(17) xor LFSR(19) xor LFSR(20) xor LFSR(23) xor data(1) xor data(4) xor data(5) xor data(6) xor data(7) xor data(9) xor data(13) xor data(14) xor data(17) xor data(19) xor data(20) xor data(23);
					end if;
					
					if (error_bit = 19) and (clock_counter = fault_tact) then
						CRC24(18) <= not(LFSR(0) xor LFSR(6) xor LFSR(7) xor LFSR(8) xor LFSR(9) xor LFSR(11) xor LFSR(13) xor LFSR(15) xor LFSR(18) xor LFSR(20) xor LFSR(23) xor data(0) xor data(6) xor data(7) xor data(8) xor data(9) xor data(11) xor data(13) xor data(15) xor data(18) xor data(20) xor data(23));
					else
						CRC24(18) <= LFSR(0) xor LFSR(6) xor LFSR(7) xor LFSR(8) xor LFSR(9) xor LFSR(11) xor LFSR(13) xor LFSR(15) xor LFSR(18) xor LFSR(20) xor LFSR(23) xor data(0) xor data(6) xor data(7) xor data(8) xor data(9) xor data(11) xor data(13) xor data(15) xor data(18) xor data(20) xor data(23);
					end if;
					
					if (error_bit = 20) and (clock_counter = fault_tact) then
						CRC24(19) <= not(LFSR(0) xor LFSR(1) xor LFSR(2) xor LFSR(5) xor LFSR(7) xor LFSR(8) xor LFSR(11) xor LFSR(12) xor LFSR(13) xor LFSR(16) xor LFSR(19) xor LFSR(23) xor data(0) xor data(1) xor data(2) xor data(5) xor data(7) xor data(8) xor data(11) xor data(12) xor data(13) xor data(16) xor data(19) xor data(23));
					else
						CRC24(19) <= LFSR(0) xor LFSR(1) xor LFSR(2) xor LFSR(5) xor LFSR(7) xor LFSR(8) xor LFSR(11) xor LFSR(12) xor LFSR(13) xor LFSR(16) xor LFSR(19) xor LFSR(23) xor data(0) xor data(1) xor data(2) xor data(5) xor data(7) xor data(8) xor data(11) xor data(12) xor data(13) xor data(16) xor data(19) xor data(23);
					end if;
					
					if (error_bit = 21) and (clock_counter = fault_tact) then
						CRC24(20) <= not(LFSR(0) xor LFSR(1) xor LFSR(3) xor LFSR(5) xor LFSR(6) xor LFSR(8) xor LFSR(10) xor LFSR(11) xor LFSR(12) xor LFSR(17) xor LFSR(20) xor LFSR(21) xor LFSR(23) xor data(0) xor data(1) xor data(3) xor data(5) xor data(6) xor data(8) xor data(10) xor data(11) xor data(12) xor data(17) xor data(20) xor data(21) xor data(23));
					else
						CRC24(20) <= LFSR(0) xor LFSR(1) xor LFSR(3) xor LFSR(5) xor LFSR(6) xor LFSR(8) xor LFSR(10) xor LFSR(11) xor LFSR(12) xor LFSR(17) xor LFSR(20) xor LFSR(21) xor LFSR(23) xor data(0) xor data(1) xor data(3) xor data(5) xor data(6) xor data(8) xor data(10) xor data(11) xor data(12) xor data(17) xor data(20) xor data(21) xor data(23);
					end if;
					
					if (error_bit = 22) and (clock_counter = fault_tact) then
						CRC24(21) <= not(LFSR(1) xor LFSR(2) xor LFSR(4) xor LFSR(6) xor LFSR(7) xor LFSR(9) xor LFSR(11) xor LFSR(12) xor LFSR(13) xor LFSR(18) xor LFSR(21) xor LFSR(22) xor data(1) xor data(2) xor data(4) xor data(6) xor data(7) xor data(9) xor data(11) xor data(12) xor data(13) xor data(18) xor data(21) xor data(22));
					else
						CRC24(21) <= LFSR(1) xor LFSR(2) xor LFSR(4) xor LFSR(6) xor LFSR(7) xor LFSR(9) xor LFSR(11) xor LFSR(12) xor LFSR(13) xor LFSR(18) xor LFSR(21) xor LFSR(22) xor data(1) xor data(2) xor data(4) xor data(6) xor data(7) xor data(9) xor data(11) xor data(12) xor data(13) xor data(18) xor data(21) xor data(22);
					end if;
					
					if (error_bit = 23) and (clock_counter = fault_tact) then
						CRC24(22) <= not(LFSR(0) xor LFSR(3) xor LFSR(7) xor LFSR(8) xor LFSR(9) xor LFSR(11) xor LFSR(12) xor LFSR(19) xor LFSR(21) xor LFSR(22) xor data(0) xor data(3) xor data(7) xor data(8) xor data(9) xor data(11) xor data(12) xor data(19) xor data(21) xor data(22));
					else
						CRC24(22) <= LFSR(0) xor LFSR(3) xor LFSR(7) xor LFSR(8) xor LFSR(9) xor LFSR(11) xor LFSR(12) xor LFSR(19) xor LFSR(21) xor LFSR(22) xor data(0) xor data(3) xor data(7) xor data(8) xor data(9) xor data(11) xor data(12) xor data(19) xor data(21) xor data(22);
					end if;
					
					if (error_bit = 24) and (clock_counter = fault_tact) then
						CRC24(23) <= not(LFSR(1) xor LFSR(4) xor LFSR(8) xor LFSR(9) xor LFSR(10) xor LFSR(12) xor LFSR(13) xor LFSR(20) xor LFSR(22) xor LFSR(23) xor data(1) xor data(4) xor data(8) xor data(9) xor data(10) xor data(12) xor data(13) xor data(20) xor data(22) xor data(23));
					else
						CRC24(23) <= LFSR(1) xor LFSR(4) xor LFSR(8) xor LFSR(9) xor LFSR(10) xor LFSR(12) xor LFSR(13) xor LFSR(20) xor LFSR(22) xor LFSR(23) xor data(1) xor data(4) xor data(8) xor data(9) xor data(10) xor data(12) xor data(13) xor data(20) xor data(22) xor data(23);
					end if;
					
					if temp_simulation_completed /= '1' then
						if clock_counter = fault_tact then
							temp_error_count <= temp_error_count + 1;
							clock_counter <= 0;
						else
							clock_counter <= clock_counter + 1;
						end if;
					end if;
				end if;
			end if;
	end process;
	
	error_count <= std_logic_vector(to_unsigned(temp_error_count, 24));
end architecture behavioral;