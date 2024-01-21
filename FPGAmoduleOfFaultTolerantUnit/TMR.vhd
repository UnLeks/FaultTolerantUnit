---------------------------------------------------------------------------
-- Блок TMR модуля FPGAmodule узла FaultTolerantUnit. Функциональный
-- элемент (вычислитель) резервирован двумя аналогичными элементами.
-- Логика работы функционального элемента заключается в нахождении
-- контрольной суммы входной последовательности, рассчитанной
-- алгоритмом CRC24.
---------------------------------------------------------------------------
-- Порождающий полином (0:23):
-- x^24+x^22+x^20+x^19+x^18+x^16+x^14+x^13+x^11+x^10+x^8+x^7+x^6+x^3+x^1+1
---------------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity TMR is
	port (
		-- тактовый сигнал
		clk : in std_logic;
		
		-- ручной запуск и остановка программы
		start_stop : in std_logic;
		
		-- контрольная сумма входной последовательности, рассчитанная алгоритмом CRC24 (24-битное значение) [с учётом резервирования]
		CRC24 : out std_logic_vector(23 downto 0);
		
		-- количество внесённых ошибок в вычислитель №1
		CRC24_1_error_count : out std_logic_vector(23 downto 0);
		
		-- количество внесённых ошибок в вычислитель №2
		CRC24_2_error_count : out std_logic_vector(23 downto 0);
		
		-- количество внесённых ошибок в вычислитель №3
		CRC24_3_error_count : out std_logic_vector(23 downto 0);
		
		-- флаг, отображающий окончание работы блока TMR
		simulation_completed: out std_logic := '0'
	);
end entity TMR;

architecture behavioral of TMR is
	-- смена состояния программы (запуск и окончание) [внутренний сигнал]
	signal internal_start_stop : std_logic := '0';
	
	-- регистры сдвига с линейной обратной связью (LFSR)
	signal LFSR_1, LFSR_2, LFSR_3 : std_logic_vector(23 downto 0) := (others => '0');
	
	-- входная последовательность
	signal data : std_logic_vector(23 downto 0);
	
	-- начальное 24-битное значение входной последовательностие (0...01) [внутренний сигнал]
	signal internal_data : std_logic_vector(23 downto 0) := (23 downto 1 => '0', 0 => '1');
	
	-- контрольные суммы входной последовательности, рассчитанные алгоритмом CRC24 [внутренние сигналы]
	signal CRC24_1, CRC24_2, CRC24_3 : std_logic_vector(23 downto 0);
	
	signal CRC24_1_clock_counter : natural := 0;
	signal CRC24_2_clock_counter : natural := 0;
	signal CRC24_3_clock_counter : natural := 0;
	
	signal CRC24_1_fault_tact : natural;
	signal CRC24_2_fault_tact : natural;
	signal CRC24_3_fault_tact : natural;
	
	signal CRC24_1_fault_tact_generated: std_logic := '0';
	signal CRC24_2_fault_tact_generated: std_logic := '0';
	signal CRC24_3_fault_tact_generated: std_logic := '0';
	
	signal CRC24_1_error_bit : natural;
	signal CRC24_2_error_bit : natural;
	signal CRC24_3_error_bit : natural;
	
	constant CRC24_1_fault_tact_multiplier : natural := 563798441;
	constant CRC24_1_fault_tact_module : natural := 100001;
	signal CRC24_1_fault_tact_seed : natural := 1;
	
	constant CRC24_2_fault_tact_multiplier : natural := 574182389;
	constant CRC24_2_fault_tact_module : natural := 100001;
	signal CRC24_2_fault_tact_seed : natural := 1;
	
	constant CRC24_3_fault_tact_multiplier : natural := 245791633;
	constant CRC24_3_fault_tact_module : natural := 100001;
	signal CRC24_3_fault_tact_seed : natural := 1;
	
	constant CRC24_1_error_bit_multiplier : natural := 23;
	constant CRC24_1_error_bit_module : natural := 25;
	signal CRC24_1_error_bit_seed : natural := 1;
	
	constant CRC24_2_error_bit_multiplier : natural := 13;
	constant CRC24_2_error_bit_module : natural := 25;
	signal CRC24_2_error_bit_seed : natural := 1;
	
	constant CRC24_3_error_bit_multiplier : natural := 17;
	constant CRC24_3_error_bit_module : natural := 25;
	signal CRC24_3_error_bit_seed : natural := 1;
	
	signal temp_CRC24_1_error_count : natural := 0;
	signal temp_CRC24_2_error_count : natural := 0;
	signal temp_CRC24_3_error_count : natural := 0;
	
	-- выходное значение голосующего элемента
	signal voting_element_out : std_logic_vector(23 downto 0);
	
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
	variable temp_CRC24_1_fault_tact_generated: std_logic; -- промежуточный флаг определения такта для внесения ошибки
		begin
			if rising_edge(clk) then
				if CRC24_1_fault_tact_generated /= '1' then
					-- вычисление псевдослучайного числа для определения такта, на котором будет внесена ошибка
					CRC24_1_fault_tact_seed <= (CRC24_1_fault_tact_seed * CRC24_1_fault_tact_multiplier) mod CRC24_1_fault_tact_module;
					temp_CRC24_1_fault_tact_generated := '1'; -- установка промежуточного флага, обозначающего, что ошибочный такт определен
				end if;
				
				if CRC24_1_clock_counter = CRC24_1_fault_tact then
					CRC24_1_error_bit_seed <= (CRC24_1_error_bit_seed * CRC24_1_error_bit_multiplier) mod CRC24_1_error_bit_module;
					temp_CRC24_1_fault_tact_generated := '0'; -- сброс промежуточного флага
				end if;
				
				CRC24_1_fault_tact_generated <= temp_CRC24_1_fault_tact_generated; -- установка основого флага определения такта для внесения ошибки в соответствии с промежуточным флагом
			end if;
	end process;
	
	CRC24_1_fault_tact <= CRC24_1_fault_tact_seed;
	CRC24_1_error_bit <= CRC24_1_error_bit_seed;
	
	process (clk)
	variable temp_CRC24_2_fault_tact_generated: std_logic; -- промежуточный флаг определения такта для внесения ошибки
		begin
			if rising_edge(clk) then
				if CRC24_2_fault_tact_generated /= '1' then
					-- вычисление псевдослучайного числа для определения такта, на котором будет внесена ошибка
					CRC24_2_fault_tact_seed <= (CRC24_2_fault_tact_seed * CRC24_2_fault_tact_multiplier) mod CRC24_2_fault_tact_module;
					temp_CRC24_2_fault_tact_generated := '1'; -- установка промежуточного флага, обозначающего, что ошибочный такт определен
				end if;
				
				if CRC24_2_clock_counter = CRC24_2_fault_tact then
					CRC24_2_error_bit_seed <= (CRC24_2_error_bit_seed * CRC24_2_error_bit_multiplier) mod CRC24_2_error_bit_module;
					temp_CRC24_2_fault_tact_generated := '0'; -- сброс промежуточного флага
				end if;
				
				CRC24_2_fault_tact_generated <= temp_CRC24_2_fault_tact_generated; -- установка основого флага определения такта для внесения ошибки в соответствии с промежуточным флагом
			end if;
	end process;
	
	CRC24_2_fault_tact <= CRC24_2_fault_tact_seed;
	CRC24_2_error_bit <= CRC24_2_error_bit_seed;
	
	process (clk)
	variable temp_CRC24_3_fault_tact_generated: std_logic; -- промежуточный флаг определения такта для внесения ошибки
		begin
			if rising_edge(clk) then
				if CRC24_3_fault_tact_generated /= '1' then
					-- вычисление псевдослучайного числа для определения такта, на котором будет внесена ошибка
					CRC24_3_fault_tact_seed <= (CRC24_3_fault_tact_seed * CRC24_3_fault_tact_multiplier) mod CRC24_3_fault_tact_module;
					temp_CRC24_3_fault_tact_generated := '1'; -- установка промежуточного флага, обозначающего, что ошибочный такт определен
				end if;
				
				if CRC24_3_clock_counter = CRC24_3_fault_tact then
					CRC24_3_error_bit_seed <= (CRC24_3_error_bit_seed * CRC24_3_error_bit_multiplier) mod CRC24_3_error_bit_module;
					temp_CRC24_3_fault_tact_generated := '0'; -- сброс промежуточного флага
				end if;
				
				CRC24_3_fault_tact_generated <= temp_CRC24_3_fault_tact_generated; -- установка основого флага определения такта для внесения ошибки в соответствии с промежуточным флагом
			end if;
	end process;
	
	CRC24_3_fault_tact <= CRC24_3_fault_tact_seed;
	CRC24_3_error_bit <= CRC24_3_error_bit_seed;
	
	-- вычислитель №1
	process (clk)
		begin
			if rising_edge(clk) then
				if internal_start_stop = '1' then
					-- вычисление CRC24_1 с использованием LFSR_1
					if (CRC24_1_error_bit = 1) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(0) <= not(LFSR_1(0) xor LFSR_1(2) xor LFSR_1(5) xor LFSR_1(9) xor LFSR_1(10) xor LFSR_1(11) xor LFSR_1(13) xor LFSR_1(14) xor LFSR_1(21) xor LFSR_1(23) xor data(0) xor data(2) xor data(5) xor data(9) xor data(10) xor data(11) xor data(13) xor data(14) xor data(21) xor data(23));
					else
						CRC24_1(0) <= LFSR_1(0) xor LFSR_1(2) xor LFSR_1(5) xor LFSR_1(9) xor LFSR_1(10) xor LFSR_1(11) xor LFSR_1(13) xor LFSR_1(14) xor LFSR_1(21) xor LFSR_1(23) xor data(0) xor data(2) xor data(5) xor data(9) xor data(10) xor data(11) xor data(13) xor data(14) xor data(21) xor data(23);
					end if;
					
					if (CRC24_1_error_bit = 2) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(1) <= not(LFSR_1(0) xor LFSR_1(1) xor LFSR_1(2) xor LFSR_1(3) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(9) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(15) xor LFSR_1(21) xor LFSR_1(22) xor LFSR_1(23) xor data(0) xor data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(9) xor data(12) xor data(13) xor data(15) xor data(21) xor data(22) xor data(23));
					else
						CRC24_1(1) <= LFSR_1(0) xor LFSR_1(1) xor LFSR_1(2) xor LFSR_1(3) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(9) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(15) xor LFSR_1(21) xor LFSR_1(22) xor LFSR_1(23) xor data(0) xor data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(9) xor data(12) xor data(13) xor data(15) xor data(21) xor data(22) xor data(23);
					end if;
					
					if (CRC24_1_error_bit = 3) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(2) <= not(LFSR_1(1) xor LFSR_1(2) xor LFSR_1(3) xor LFSR_1(4) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(10) xor LFSR_1(13) xor LFSR_1(14) xor LFSR_1(16) xor LFSR_1(22) xor LFSR_1(23) xor data(1) xor data(2) xor data(3) xor data(4) xor data(6) xor data(7) xor data(10) xor data(13) xor data(14) xor data(16) xor data(22) xor data(23));
					else
						CRC24_1(2) <= LFSR_1(1) xor LFSR_1(2) xor LFSR_1(3) xor LFSR_1(4) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(10) xor LFSR_1(13) xor LFSR_1(14) xor LFSR_1(16) xor LFSR_1(22) xor LFSR_1(23) xor data(1) xor data(2) xor data(3) xor data(4) xor data(6) xor data(7) xor data(10) xor data(13) xor data(14) xor data(16) xor data(22) xor data(23);
					end if;
					
					if (CRC24_1_error_bit = 4) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(3) <= not(LFSR_1(0) xor LFSR_1(3) xor LFSR_1(4) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(10) xor LFSR_1(13) xor LFSR_1(15) xor LFSR_1(17) xor LFSR_1(21) xor data(0) xor data(3) xor data(4) xor data(7) xor data(8) xor data(9) xor data(10) xor data(13) xor data(15) xor data(17) xor data(21));
					else
						CRC24_1(3) <= LFSR_1(0) xor LFSR_1(3) xor LFSR_1(4) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(10) xor LFSR_1(13) xor LFSR_1(15) xor LFSR_1(17) xor LFSR_1(21) xor data(0) xor data(3) xor data(4) xor data(7) xor data(8) xor data(9) xor data(10) xor data(13) xor data(15) xor data(17) xor data(21);
					end if;
					
					if (CRC24_1_error_bit = 5) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(4) <= not(LFSR_1(1) xor LFSR_1(4) xor LFSR_1(5) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(10) xor LFSR_1(11) xor LFSR_1(14) xor LFSR_1(16) xor LFSR_1(18) xor LFSR_1(22) xor data(1) xor data(4) xor data(5) xor data(8) xor data(9) xor data(10) xor data(11) xor data(14) xor data(16) xor data(18) xor data(22));
					else
						CRC24_1(4) <= LFSR_1(1) xor LFSR_1(4) xor LFSR_1(5) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(10) xor LFSR_1(11) xor LFSR_1(14) xor LFSR_1(16) xor LFSR_1(18) xor LFSR_1(22) xor data(1) xor data(4) xor data(5) xor data(8) xor data(9) xor data(10) xor data(11) xor data(14) xor data(16) xor data(18) xor data(22);
					end if;
					
					if (CRC24_1_error_bit = 6) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(5) <= not(LFSR_1(2) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(9) xor LFSR_1(10) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(15) xor LFSR_1(17) xor LFSR_1(19) xor LFSR_1(23) xor data(2) xor data(5) xor data(6) xor data(9) xor data(10) xor data(11) xor data(12) xor data(15) xor data(17) xor data(19) xor data(23));
					else
						CRC24_1(5) <= LFSR_1(2) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(9) xor LFSR_1(10) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(15) xor LFSR_1(17) xor LFSR_1(19) xor LFSR_1(23) xor data(2) xor data(5) xor data(6) xor data(9) xor data(10) xor data(11) xor data(12) xor data(15) xor data(17) xor data(19) xor data(23);
					end if;
					
					if (CRC24_1_error_bit = 7) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(6) <= not(LFSR_1(0) xor LFSR_1(2) xor LFSR_1(3) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(9) xor LFSR_1(12) xor LFSR_1(14) xor LFSR_1(16) xor LFSR_1(18) xor LFSR_1(20) xor LFSR_1(21) xor LFSR_1(23) xor data(0) xor data(2) xor data(3) xor data(5) xor data(6) xor data(7) xor data(9) xor data(12) xor data(14) xor data(16) xor data(18) xor data(20) xor data(21) xor data(23));
					else
						CRC24_1(6) <= LFSR_1(0) xor LFSR_1(2) xor LFSR_1(3) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(9) xor LFSR_1(12) xor LFSR_1(14) xor LFSR_1(16) xor LFSR_1(18) xor LFSR_1(20) xor LFSR_1(21) xor LFSR_1(23) xor data(0) xor data(2) xor data(3) xor data(5) xor data(6) xor data(7) xor data(9) xor data(12) xor data(14) xor data(16) xor data(18) xor data(20) xor data(21) xor data(23);
					end if;
					
					if (CRC24_1_error_bit = 8) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(7) <= not(LFSR_1(0) xor LFSR_1(1) xor LFSR_1(2) xor LFSR_1(3) xor LFSR_1(4) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(11) xor LFSR_1(14) xor LFSR_1(15) xor LFSR_1(17) xor LFSR_1(19) xor LFSR_1(22) xor LFSR_1(23) xor data(0) xor data(1) xor data(2) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(8) xor data(9) xor data(11) xor data(14) xor data(15) xor data(17) xor data(19) xor data(22) xor data(23));
					else
						CRC24_1(7) <= LFSR_1(0) xor LFSR_1(1) xor LFSR_1(2) xor LFSR_1(3) xor LFSR_1(4) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(11) xor LFSR_1(14) xor LFSR_1(15) xor LFSR_1(17) xor LFSR_1(19) xor LFSR_1(22) xor LFSR_1(23) xor data(0) xor data(1) xor data(2) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(8) xor data(9) xor data(11) xor data(14) xor data(15) xor data(17) xor data(19) xor data(22) xor data(23);
					end if;
					
					if (CRC24_1_error_bit = 9) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(8) <= not(LFSR_1(0) xor LFSR_1(1) xor LFSR_1(3) xor LFSR_1(4) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(14) xor LFSR_1(15) xor LFSR_1(16) xor LFSR_1(18) xor LFSR_1(20) xor LFSR_1(21) xor data(0) xor data(1) xor data(3) xor data(4) xor data(6) xor data(7) xor data(8) xor data(11) xor data(12) xor data(13) xor data(14) xor data(15) xor data(16) xor data(18) xor data(20) xor data(21));
					else
						CRC24_1(8) <= LFSR_1(0) xor LFSR_1(1) xor LFSR_1(3) xor LFSR_1(4) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(14) xor LFSR_1(15) xor LFSR_1(16) xor LFSR_1(18) xor LFSR_1(20) xor LFSR_1(21) xor data(0) xor data(1) xor data(3) xor data(4) xor data(6) xor data(7) xor data(8) xor data(11) xor data(12) xor data(13) xor data(14) xor data(15) xor data(16) xor data(18) xor data(20) xor data(21);
					end if;
					
					if (CRC24_1_error_bit = 10) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(9) <= not(LFSR_1(1) xor LFSR_1(2) xor LFSR_1(4) xor LFSR_1(5) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(14) xor LFSR_1(15) xor LFSR_1(16) xor LFSR_1(17) xor LFSR_1(19) xor LFSR_1(21) xor LFSR_1(22) xor data(1) xor data(2) xor data(4) xor data(5) xor data(7) xor data(8) xor data(9) xor data(12) xor data(13) xor data(14) xor data(15) xor data(16) xor data(17) xor data(19) xor data(21) xor data(22));
					else
						CRC24_1(9) <= LFSR_1(1) xor LFSR_1(2) xor LFSR_1(4) xor LFSR_1(5) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(14) xor LFSR_1(15) xor LFSR_1(16) xor LFSR_1(17) xor LFSR_1(19) xor LFSR_1(21) xor LFSR_1(22) xor data(1) xor data(2) xor data(4) xor data(5) xor data(7) xor data(8) xor data(9) xor data(12) xor data(13) xor data(14) xor data(15) xor data(16) xor data(17) xor data(19) xor data(21) xor data(22);
					end if;
					
					if (CRC24_1_error_bit = 11) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(10) <= not(LFSR_1(0) xor LFSR_1(3) xor LFSR_1(6) xor LFSR_1(8) xor LFSR_1(11) xor LFSR_1(15) xor LFSR_1(16) xor LFSR_1(17) xor LFSR_1(18) xor LFSR_1(20) xor LFSR_1(21) xor LFSR_1(22) xor data(0) xor data(3) xor data(6) xor data(8) xor data(11) xor data(15) xor data(16) xor data(17) xor data(18) xor data(20) xor data(21) xor data(22));
					else
						CRC24_1(10) <= LFSR_1(0) xor LFSR_1(3) xor LFSR_1(6) xor LFSR_1(8) xor LFSR_1(11) xor LFSR_1(15) xor LFSR_1(16) xor LFSR_1(17) xor LFSR_1(18) xor LFSR_1(20) xor LFSR_1(21) xor LFSR_1(22) xor data(0) xor data(3) xor data(6) xor data(8) xor data(11) xor data(15) xor data(16) xor data(17) xor data(18) xor data(20) xor data(21) xor data(22);
					end if;
					
					if (CRC24_1_error_bit = 12) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(11) <= not(LFSR_1(0) xor LFSR_1(1) xor LFSR_1(2) xor LFSR_1(4) xor LFSR_1(5) xor LFSR_1(7) xor LFSR_1(10) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(14) xor LFSR_1(16) xor LFSR_1(17) xor LFSR_1(18) xor LFSR_1(19) xor LFSR_1(22) xor data(0) xor data(1) xor data(2) xor data(4) xor data(5) xor data(7) xor data(10) xor data(11) xor data(12) xor data(13) xor data(14) xor data(16) xor data(17) xor data(18) xor data(19) xor data(22));
					else
						CRC24_1(11) <= LFSR_1(0) xor LFSR_1(1) xor LFSR_1(2) xor LFSR_1(4) xor LFSR_1(5) xor LFSR_1(7) xor LFSR_1(10) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(14) xor LFSR_1(16) xor LFSR_1(17) xor LFSR_1(18) xor LFSR_1(19) xor LFSR_1(22) xor data(0) xor data(1) xor data(2) xor data(4) xor data(5) xor data(7) xor data(10) xor data(11) xor data(12) xor data(13) xor data(14) xor data(16) xor data(17) xor data(18) xor data(19) xor data(22);
					end if;
					
					if (CRC24_1_error_bit = 13) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(12) <= not(LFSR_1(1) xor LFSR_1(2) xor LFSR_1(3) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(8) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(14) xor LFSR_1(15) xor LFSR_1(17) xor LFSR_1(18) xor LFSR_1(19) xor LFSR_1(20) xor LFSR_1(23) xor data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(8) xor data(11) xor data(12) xor data(13) xor data(14) xor data(15) xor data(17) xor data(18) xor data(19) xor data(20) xor data(23));
					else
						CRC24_1(12) <= LFSR_1(1) xor LFSR_1(2) xor LFSR_1(3) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(8) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(14) xor LFSR_1(15) xor LFSR_1(17) xor LFSR_1(18) xor LFSR_1(19) xor LFSR_1(20) xor LFSR_1(23) xor data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(8) xor data(11) xor data(12) xor data(13) xor data(14) xor data(15) xor data(17) xor data(18) xor data(19) xor data(20) xor data(23);
					end if;
					
					if (CRC24_1_error_bit = 14) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(13) <= not(LFSR_1(0) xor LFSR_1(3) xor LFSR_1(4) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(10) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(15) xor LFSR_1(16) xor LFSR_1(18) xor LFSR_1(19) xor LFSR_1(20) xor LFSR_1(23) xor data(0) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(10) xor data(11) xor data(12) xor data(15) xor data(16) xor data(18) xor data(19) xor data(20) xor data(23));
					else
						CRC24_1(13) <= LFSR_1(0) xor LFSR_1(3) xor LFSR_1(4) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(10) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(15) xor LFSR_1(16) xor LFSR_1(18) xor LFSR_1(19) xor LFSR_1(20) xor LFSR_1(23) xor data(0) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(10) xor data(11) xor data(12) xor data(15) xor data(16) xor data(18) xor data(19) xor data(20) xor data(23);
					end if;
					
					if (CRC24_1_error_bit = 15) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(14) <= not(LFSR_1(0) xor LFSR_1(1) xor LFSR_1(2) xor LFSR_1(4) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(10) xor LFSR_1(12) xor LFSR_1(14) xor LFSR_1(16) xor LFSR_1(17) xor LFSR_1(19) xor LFSR_1(20) xor LFSR_1(23) xor data(0) xor data(1) xor data(2) xor data(4) xor data(6) xor data(7) xor data(8) xor data(9) xor data(10) xor data(12) xor data(14) xor data(16) xor data(17) xor data(19) xor data(20) xor data(23));
					else
						CRC24_1(14) <= LFSR_1(0) xor LFSR_1(1) xor LFSR_1(2) xor LFSR_1(4) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(10) xor LFSR_1(12) xor LFSR_1(14) xor LFSR_1(16) xor LFSR_1(17) xor LFSR_1(19) xor LFSR_1(20) xor LFSR_1(23) xor data(0) xor data(1) xor data(2) xor data(4) xor data(6) xor data(7) xor data(8) xor data(9) xor data(10) xor data(12) xor data(14) xor data(16) xor data(17) xor data(19) xor data(20) xor data(23);
					end if;
					
					if (CRC24_1_error_bit = 16) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(15) <= not(LFSR_1(1) xor LFSR_1(2) xor LFSR_1(3) xor LFSR_1(5) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(10) xor LFSR_1(11) xor LFSR_1(13) xor LFSR_1(15) xor LFSR_1(17) xor LFSR_1(18) xor LFSR_1(20) xor LFSR_1(21) xor data(1) xor data(2) xor data(3) xor data(5) xor data(7) xor data(8) xor data(9) xor data(10) xor data(11) xor data(13) xor data(15) xor data(17) xor data(18) xor data(20) xor data(21));
					else
						CRC24_1(15) <= LFSR_1(1) xor LFSR_1(2) xor LFSR_1(3) xor LFSR_1(5) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(10) xor LFSR_1(11) xor LFSR_1(13) xor LFSR_1(15) xor LFSR_1(17) xor LFSR_1(18) xor LFSR_1(20) xor LFSR_1(21) xor data(1) xor data(2) xor data(3) xor data(5) xor data(7) xor data(8) xor data(9) xor data(10) xor data(11) xor data(13) xor data(15) xor data(17) xor data(18) xor data(20) xor data(21);
					end if;
					
					if (CRC24_1_error_bit = 17) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(16) <= not(LFSR_1(0) xor LFSR_1(3) xor LFSR_1(4) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(8) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(16) xor LFSR_1(18) xor LFSR_1(19) xor LFSR_1(22) xor LFSR_1(23) xor data(0) xor data(3) xor data(4) xor data(5) xor data(6) xor data(8) xor data(12) xor data(13) xor data(16) xor data(18) xor data(19) xor data(22) xor data(23));
					else
						CRC24_1(16) <= LFSR_1(0) xor LFSR_1(3) xor LFSR_1(4) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(8) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(16) xor LFSR_1(18) xor LFSR_1(19) xor LFSR_1(22) xor LFSR_1(23) xor data(0) xor data(3) xor data(4) xor data(5) xor data(6) xor data(8) xor data(12) xor data(13) xor data(16) xor data(18) xor data(19) xor data(22) xor data(23);
					end if;
					
					if (CRC24_1_error_bit = 18) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(17) <= not(LFSR_1(1) xor LFSR_1(4) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(9) xor LFSR_1(13) xor LFSR_1(14) xor LFSR_1(17) xor LFSR_1(19) xor LFSR_1(20) xor LFSR_1(23) xor data(1) xor data(4) xor data(5) xor data(6) xor data(7) xor data(9) xor data(13) xor data(14) xor data(17) xor data(19) xor data(20) xor data(23));
					else
						CRC24_1(17) <= LFSR_1(1) xor LFSR_1(4) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(9) xor LFSR_1(13) xor LFSR_1(14) xor LFSR_1(17) xor LFSR_1(19) xor LFSR_1(20) xor LFSR_1(23) xor data(1) xor data(4) xor data(5) xor data(6) xor data(7) xor data(9) xor data(13) xor data(14) xor data(17) xor data(19) xor data(20) xor data(23);
					end if;
					
					if (CRC24_1_error_bit = 19) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(18) <= not(LFSR_1(0) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(11) xor LFSR_1(13) xor LFSR_1(15) xor LFSR_1(18) xor LFSR_1(20) xor LFSR_1(23) xor data(0) xor data(6) xor data(7) xor data(8) xor data(9) xor data(11) xor data(13) xor data(15) xor data(18) xor data(20) xor data(23));
					else
						CRC24_1(18) <= LFSR_1(0) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(11) xor LFSR_1(13) xor LFSR_1(15) xor LFSR_1(18) xor LFSR_1(20) xor LFSR_1(23) xor data(0) xor data(6) xor data(7) xor data(8) xor data(9) xor data(11) xor data(13) xor data(15) xor data(18) xor data(20) xor data(23);
					end if;
					
					if (CRC24_1_error_bit = 20) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(19) <= not(LFSR_1(0) xor LFSR_1(1) xor LFSR_1(2) xor LFSR_1(5) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(16) xor LFSR_1(19) xor LFSR_1(23) xor data(0) xor data(1) xor data(2) xor data(5) xor data(7) xor data(8) xor data(11) xor data(12) xor data(13) xor data(16) xor data(19) xor data(23));
					else
						CRC24_1(19) <= LFSR_1(0) xor LFSR_1(1) xor LFSR_1(2) xor LFSR_1(5) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(16) xor LFSR_1(19) xor LFSR_1(23) xor data(0) xor data(1) xor data(2) xor data(5) xor data(7) xor data(8) xor data(11) xor data(12) xor data(13) xor data(16) xor data(19) xor data(23);
					end if;
					
					if (CRC24_1_error_bit = 21) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(20) <= not(LFSR_1(0) xor LFSR_1(1) xor LFSR_1(3) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(8) xor LFSR_1(10) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(17) xor LFSR_1(20) xor LFSR_1(21) xor LFSR_1(23) xor data(0) xor data(1) xor data(3) xor data(5) xor data(6) xor data(8) xor data(10) xor data(11) xor data(12) xor data(17) xor data(20) xor data(21) xor data(23));
					else
						CRC24_1(20) <= LFSR_1(0) xor LFSR_1(1) xor LFSR_1(3) xor LFSR_1(5) xor LFSR_1(6) xor LFSR_1(8) xor LFSR_1(10) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(17) xor LFSR_1(20) xor LFSR_1(21) xor LFSR_1(23) xor data(0) xor data(1) xor data(3) xor data(5) xor data(6) xor data(8) xor data(10) xor data(11) xor data(12) xor data(17) xor data(20) xor data(21) xor data(23);
					end if;
					
					if (CRC24_1_error_bit = 22) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(21) <= not(LFSR_1(1) xor LFSR_1(2) xor LFSR_1(4) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(9) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(18) xor LFSR_1(21) xor LFSR_1(22) xor data(1) xor data(2) xor data(4) xor data(6) xor data(7) xor data(9) xor data(11) xor data(12) xor data(13) xor data(18) xor data(21) xor data(22));
					else
						CRC24_1(21) <= LFSR_1(1) xor LFSR_1(2) xor LFSR_1(4) xor LFSR_1(6) xor LFSR_1(7) xor LFSR_1(9) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(18) xor LFSR_1(21) xor LFSR_1(22) xor data(1) xor data(2) xor data(4) xor data(6) xor data(7) xor data(9) xor data(11) xor data(12) xor data(13) xor data(18) xor data(21) xor data(22);
					end if;
					
					if (CRC24_1_error_bit = 23) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(22) <= not(LFSR_1(0) xor LFSR_1(3) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(19) xor LFSR_1(21) xor LFSR_1(22) xor data(0) xor data(3) xor data(7) xor data(8) xor data(9) xor data(11) xor data(12) xor data(19) xor data(21) xor data(22));
					else
						CRC24_1(22) <= LFSR_1(0) xor LFSR_1(3) xor LFSR_1(7) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(11) xor LFSR_1(12) xor LFSR_1(19) xor LFSR_1(21) xor LFSR_1(22) xor data(0) xor data(3) xor data(7) xor data(8) xor data(9) xor data(11) xor data(12) xor data(19) xor data(21) xor data(22);
					end if;
					
					if (CRC24_1_error_bit = 24) and (CRC24_1_clock_counter = CRC24_1_fault_tact) then
						CRC24_1(23) <= not(LFSR_1(1) xor LFSR_1(4) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(10) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(20) xor LFSR_1(22) xor LFSR_1(23) xor data(1) xor data(4) xor data(8) xor data(9) xor data(10) xor data(12) xor data(13) xor data(20) xor data(22) xor data(23));
					else
						CRC24_1(23) <= LFSR_1(1) xor LFSR_1(4) xor LFSR_1(8) xor LFSR_1(9) xor LFSR_1(10) xor LFSR_1(12) xor LFSR_1(13) xor LFSR_1(20) xor LFSR_1(22) xor LFSR_1(23) xor data(1) xor data(4) xor data(8) xor data(9) xor data(10) xor data(12) xor data(13) xor data(20) xor data(22) xor data(23);
					end if;
					
					if temp_simulation_completed /= '1' then
						if CRC24_1_clock_counter = CRC24_1_fault_tact then
							temp_CRC24_1_error_count <= temp_CRC24_1_error_count + 1;
							CRC24_1_clock_counter <= 0;
						else
							CRC24_1_clock_counter <= CRC24_1_clock_counter + 1;
						end if;
					end if;
				end if;
			end if;
	end process;
	
	CRC24_1_error_count <= std_logic_vector(to_unsigned(temp_CRC24_1_error_count, 24));
	
	-- вычислитель №2
	process (clk)
		begin
			if rising_edge(clk) then
				if internal_start_stop = '1' then
					-- вычисление CRC24_2 с использованием LFSR_2
					if (CRC24_2_error_bit = 1) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(0) <= not(LFSR_2(0) xor LFSR_2(2) xor LFSR_2(5) xor LFSR_2(9) xor LFSR_2(10) xor LFSR_2(11) xor LFSR_2(13) xor LFSR_2(14) xor LFSR_2(21) xor LFSR_2(23) xor data(0) xor data(2) xor data(5) xor data(9) xor data(10) xor data(11) xor data(13) xor data(14) xor data(21) xor data(23));
					else
						CRC24_2(0) <= LFSR_2(0) xor LFSR_2(2) xor LFSR_2(5) xor LFSR_2(9) xor LFSR_2(10) xor LFSR_2(11) xor LFSR_2(13) xor LFSR_2(14) xor LFSR_2(21) xor LFSR_2(23) xor data(0) xor data(2) xor data(5) xor data(9) xor data(10) xor data(11) xor data(13) xor data(14) xor data(21) xor data(23);
					end if;
					
					if (CRC24_2_error_bit = 2) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(1) <= not(LFSR_2(0) xor LFSR_2(1) xor LFSR_2(2) xor LFSR_2(3) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(9) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(15) xor LFSR_2(21) xor LFSR_2(22) xor LFSR_2(23) xor data(0) xor data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(9) xor data(12) xor data(13) xor data(15) xor data(21) xor data(22) xor data(23));
					else
						CRC24_2(1) <= LFSR_2(0) xor LFSR_2(1) xor LFSR_2(2) xor LFSR_2(3) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(9) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(15) xor LFSR_2(21) xor LFSR_2(22) xor LFSR_2(23) xor data(0) xor data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(9) xor data(12) xor data(13) xor data(15) xor data(21) xor data(22) xor data(23);
					end if;
					
					if (CRC24_2_error_bit = 3) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(2) <= not(LFSR_2(1) xor LFSR_2(2) xor LFSR_2(3) xor LFSR_2(4) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(10) xor LFSR_2(13) xor LFSR_2(14) xor LFSR_2(16) xor LFSR_2(22) xor LFSR_2(23) xor data(1) xor data(2) xor data(3) xor data(4) xor data(6) xor data(7) xor data(10) xor data(13) xor data(14) xor data(16) xor data(22) xor data(23));
					else
						CRC24_2(2) <= LFSR_2(1) xor LFSR_2(2) xor LFSR_2(3) xor LFSR_2(4) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(10) xor LFSR_2(13) xor LFSR_2(14) xor LFSR_2(16) xor LFSR_2(22) xor LFSR_2(23) xor data(1) xor data(2) xor data(3) xor data(4) xor data(6) xor data(7) xor data(10) xor data(13) xor data(14) xor data(16) xor data(22) xor data(23);
					end if;
					
					if (CRC24_2_error_bit = 4) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(3) <= not(LFSR_2(0) xor LFSR_2(3) xor LFSR_2(4) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(10) xor LFSR_2(13) xor LFSR_2(15) xor LFSR_2(17) xor LFSR_2(21) xor data(0) xor data(3) xor data(4) xor data(7) xor data(8) xor data(9) xor data(10) xor data(13) xor data(15) xor data(17) xor data(21));
					else
						CRC24_2(3) <= LFSR_2(0) xor LFSR_2(3) xor LFSR_2(4) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(10) xor LFSR_2(13) xor LFSR_2(15) xor LFSR_2(17) xor LFSR_2(21) xor data(0) xor data(3) xor data(4) xor data(7) xor data(8) xor data(9) xor data(10) xor data(13) xor data(15) xor data(17) xor data(21);
					end if;
					
					if (CRC24_2_error_bit = 5) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(4) <= not(LFSR_2(1) xor LFSR_2(4) xor LFSR_2(5) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(10) xor LFSR_2(11) xor LFSR_2(14) xor LFSR_2(16) xor LFSR_2(18) xor LFSR_2(22) xor data(1) xor data(4) xor data(5) xor data(8) xor data(9) xor data(10) xor data(11) xor data(14) xor data(16) xor data(18) xor data(22));
					else
						CRC24_2(4) <= LFSR_2(1) xor LFSR_2(4) xor LFSR_2(5) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(10) xor LFSR_2(11) xor LFSR_2(14) xor LFSR_2(16) xor LFSR_2(18) xor LFSR_2(22) xor data(1) xor data(4) xor data(5) xor data(8) xor data(9) xor data(10) xor data(11) xor data(14) xor data(16) xor data(18) xor data(22);
					end if;
					
					if (CRC24_2_error_bit = 6) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(5) <= not(LFSR_2(2) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(9) xor LFSR_2(10) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(15) xor LFSR_2(17) xor LFSR_2(19) xor LFSR_2(23) xor data(2) xor data(5) xor data(6) xor data(9) xor data(10) xor data(11) xor data(12) xor data(15) xor data(17) xor data(19) xor data(23));
					else
						CRC24_2(5) <= LFSR_2(2) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(9) xor LFSR_2(10) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(15) xor LFSR_2(17) xor LFSR_2(19) xor LFSR_2(23) xor data(2) xor data(5) xor data(6) xor data(9) xor data(10) xor data(11) xor data(12) xor data(15) xor data(17) xor data(19) xor data(23);
					end if;
					
					if (CRC24_2_error_bit = 7) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(6) <= not(LFSR_2(0) xor LFSR_2(2) xor LFSR_2(3) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(9) xor LFSR_2(12) xor LFSR_2(14) xor LFSR_2(16) xor LFSR_2(18) xor LFSR_2(20) xor LFSR_2(21) xor LFSR_2(23) xor data(0) xor data(2) xor data(3) xor data(5) xor data(6) xor data(7) xor data(9) xor data(12) xor data(14) xor data(16) xor data(18) xor data(20) xor data(21) xor data(23));
					else
						CRC24_2(6) <= LFSR_2(0) xor LFSR_2(2) xor LFSR_2(3) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(9) xor LFSR_2(12) xor LFSR_2(14) xor LFSR_2(16) xor LFSR_2(18) xor LFSR_2(20) xor LFSR_2(21) xor LFSR_2(23) xor data(0) xor data(2) xor data(3) xor data(5) xor data(6) xor data(7) xor data(9) xor data(12) xor data(14) xor data(16) xor data(18) xor data(20) xor data(21) xor data(23);
					end if;
					
					if (CRC24_2_error_bit = 8) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(7) <= not(LFSR_2(0) xor LFSR_2(1) xor LFSR_2(2) xor LFSR_2(3) xor LFSR_2(4) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(11) xor LFSR_2(14) xor LFSR_2(15) xor LFSR_2(17) xor LFSR_2(19) xor LFSR_2(22) xor LFSR_2(23) xor data(0) xor data(1) xor data(2) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(8) xor data(9) xor data(11) xor data(14) xor data(15) xor data(17) xor data(19) xor data(22) xor data(23));
					else
						CRC24_2(7) <= LFSR_2(0) xor LFSR_2(1) xor LFSR_2(2) xor LFSR_2(3) xor LFSR_2(4) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(11) xor LFSR_2(14) xor LFSR_2(15) xor LFSR_2(17) xor LFSR_2(19) xor LFSR_2(22) xor LFSR_2(23) xor data(0) xor data(1) xor data(2) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(8) xor data(9) xor data(11) xor data(14) xor data(15) xor data(17) xor data(19) xor data(22) xor data(23);
					end if;
					
					if (CRC24_2_error_bit = 9) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(8) <= not(LFSR_2(0) xor LFSR_2(1) xor LFSR_2(3) xor LFSR_2(4) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(14) xor LFSR_2(15) xor LFSR_2(16) xor LFSR_2(18) xor LFSR_2(20) xor LFSR_2(21) xor data(0) xor data(1) xor data(3) xor data(4) xor data(6) xor data(7) xor data(8) xor data(11) xor data(12) xor data(13) xor data(14) xor data(15) xor data(16) xor data(18) xor data(20) xor data(21));
					else
						CRC24_2(8) <= LFSR_2(0) xor LFSR_2(1) xor LFSR_2(3) xor LFSR_2(4) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(14) xor LFSR_2(15) xor LFSR_2(16) xor LFSR_2(18) xor LFSR_2(20) xor LFSR_2(21) xor data(0) xor data(1) xor data(3) xor data(4) xor data(6) xor data(7) xor data(8) xor data(11) xor data(12) xor data(13) xor data(14) xor data(15) xor data(16) xor data(18) xor data(20) xor data(21);
					end if;
					
					if (CRC24_2_error_bit = 10) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(9) <= not(LFSR_2(1) xor LFSR_2(2) xor LFSR_2(4) xor LFSR_2(5) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(14) xor LFSR_2(15) xor LFSR_2(16) xor LFSR_2(17) xor LFSR_2(19) xor LFSR_2(21) xor LFSR_2(22) xor data(1) xor data(2) xor data(4) xor data(5) xor data(7) xor data(8) xor data(9) xor data(12) xor data(13) xor data(14) xor data(15) xor data(16) xor data(17) xor data(19) xor data(21) xor data(22));
					else
						CRC24_2(9) <= LFSR_2(1) xor LFSR_2(2) xor LFSR_2(4) xor LFSR_2(5) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(14) xor LFSR_2(15) xor LFSR_2(16) xor LFSR_2(17) xor LFSR_2(19) xor LFSR_2(21) xor LFSR_2(22) xor data(1) xor data(2) xor data(4) xor data(5) xor data(7) xor data(8) xor data(9) xor data(12) xor data(13) xor data(14) xor data(15) xor data(16) xor data(17) xor data(19) xor data(21) xor data(22);
					end if;
					
					if (CRC24_2_error_bit = 11) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(10) <= not(LFSR_2(0) xor LFSR_2(3) xor LFSR_2(6) xor LFSR_2(8) xor LFSR_2(11) xor LFSR_2(15) xor LFSR_2(16) xor LFSR_2(17) xor LFSR_2(18) xor LFSR_2(20) xor LFSR_2(21) xor LFSR_2(22) xor data(0) xor data(3) xor data(6) xor data(8) xor data(11) xor data(15) xor data(16) xor data(17) xor data(18) xor data(20) xor data(21) xor data(22));
					else
						CRC24_2(10) <= LFSR_2(0) xor LFSR_2(3) xor LFSR_2(6) xor LFSR_2(8) xor LFSR_2(11) xor LFSR_2(15) xor LFSR_2(16) xor LFSR_2(17) xor LFSR_2(18) xor LFSR_2(20) xor LFSR_2(21) xor LFSR_2(22) xor data(0) xor data(3) xor data(6) xor data(8) xor data(11) xor data(15) xor data(16) xor data(17) xor data(18) xor data(20) xor data(21) xor data(22);
					end if;
					
					if (CRC24_2_error_bit = 12) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(11) <= not(LFSR_2(0) xor LFSR_2(1) xor LFSR_2(2) xor LFSR_2(4) xor LFSR_2(5) xor LFSR_2(7) xor LFSR_2(10) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(14) xor LFSR_2(16) xor LFSR_2(17) xor LFSR_2(18) xor LFSR_2(19) xor LFSR_2(22) xor data(0) xor data(1) xor data(2) xor data(4) xor data(5) xor data(7) xor data(10) xor data(11) xor data(12) xor data(13) xor data(14) xor data(16) xor data(17) xor data(18) xor data(19) xor data(22));
					else
						CRC24_2(11) <= LFSR_2(0) xor LFSR_2(1) xor LFSR_2(2) xor LFSR_2(4) xor LFSR_2(5) xor LFSR_2(7) xor LFSR_2(10) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(14) xor LFSR_2(16) xor LFSR_2(17) xor LFSR_2(18) xor LFSR_2(19) xor LFSR_2(22) xor data(0) xor data(1) xor data(2) xor data(4) xor data(5) xor data(7) xor data(10) xor data(11) xor data(12) xor data(13) xor data(14) xor data(16) xor data(17) xor data(18) xor data(19) xor data(22);
					end if;
					
					if (CRC24_2_error_bit = 13) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(12) <= not(LFSR_2(1) xor LFSR_2(2) xor LFSR_2(3) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(8) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(14) xor LFSR_2(15) xor LFSR_2(17) xor LFSR_2(18) xor LFSR_2(19) xor LFSR_2(20) xor LFSR_2(23) xor data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(8) xor data(11) xor data(12) xor data(13) xor data(14) xor data(15) xor data(17) xor data(18) xor data(19) xor data(20) xor data(23));
					else
						CRC24_2(12) <= LFSR_2(1) xor LFSR_2(2) xor LFSR_2(3) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(8) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(14) xor LFSR_2(15) xor LFSR_2(17) xor LFSR_2(18) xor LFSR_2(19) xor LFSR_2(20) xor LFSR_2(23) xor data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(8) xor data(11) xor data(12) xor data(13) xor data(14) xor data(15) xor data(17) xor data(18) xor data(19) xor data(20) xor data(23);
					end if;
					
					if (CRC24_2_error_bit = 14) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(13) <= not(LFSR_2(0) xor LFSR_2(3) xor LFSR_2(4) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(10) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(15) xor LFSR_2(16) xor LFSR_2(18) xor LFSR_2(19) xor LFSR_2(20) xor LFSR_2(23) xor data(0) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(10) xor data(11) xor data(12) xor data(15) xor data(16) xor data(18) xor data(19) xor data(20) xor data(23));
					else
						CRC24_2(13) <= LFSR_2(0) xor LFSR_2(3) xor LFSR_2(4) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(10) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(15) xor LFSR_2(16) xor LFSR_2(18) xor LFSR_2(19) xor LFSR_2(20) xor LFSR_2(23) xor data(0) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(10) xor data(11) xor data(12) xor data(15) xor data(16) xor data(18) xor data(19) xor data(20) xor data(23);
					end if;
					
					if (CRC24_2_error_bit = 15) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(14) <= not(LFSR_2(0) xor LFSR_2(1) xor LFSR_2(2) xor LFSR_2(4) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(10) xor LFSR_2(12) xor LFSR_2(14) xor LFSR_2(16) xor LFSR_2(17) xor LFSR_2(19) xor LFSR_2(20) xor LFSR_2(23) xor data(0) xor data(1) xor data(2) xor data(4) xor data(6) xor data(7) xor data(8) xor data(9) xor data(10) xor data(12) xor data(14) xor data(16) xor data(17) xor data(19) xor data(20) xor data(23));
					else
						CRC24_2(14) <= LFSR_2(0) xor LFSR_2(1) xor LFSR_2(2) xor LFSR_2(4) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(10) xor LFSR_2(12) xor LFSR_2(14) xor LFSR_2(16) xor LFSR_2(17) xor LFSR_2(19) xor LFSR_2(20) xor LFSR_2(23) xor data(0) xor data(1) xor data(2) xor data(4) xor data(6) xor data(7) xor data(8) xor data(9) xor data(10) xor data(12) xor data(14) xor data(16) xor data(17) xor data(19) xor data(20) xor data(23);
					end if;
					
					if (CRC24_2_error_bit = 16) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(15) <= not(LFSR_2(1) xor LFSR_2(2) xor LFSR_2(3) xor LFSR_2(5) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(10) xor LFSR_2(11) xor LFSR_2(13) xor LFSR_2(15) xor LFSR_2(17) xor LFSR_2(18) xor LFSR_2(20) xor LFSR_2(21) xor data(1) xor data(2) xor data(3) xor data(5) xor data(7) xor data(8) xor data(9) xor data(10) xor data(11) xor data(13) xor data(15) xor data(17) xor data(18) xor data(20) xor data(21));
					else
						CRC24_2(15) <= LFSR_2(1) xor LFSR_2(2) xor LFSR_2(3) xor LFSR_2(5) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(10) xor LFSR_2(11) xor LFSR_2(13) xor LFSR_2(15) xor LFSR_2(17) xor LFSR_2(18) xor LFSR_2(20) xor LFSR_2(21) xor data(1) xor data(2) xor data(3) xor data(5) xor data(7) xor data(8) xor data(9) xor data(10) xor data(11) xor data(13) xor data(15) xor data(17) xor data(18) xor data(20) xor data(21);
					end if;
					
					if (CRC24_2_error_bit = 17) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(16) <= not(LFSR_2(0) xor LFSR_2(3) xor LFSR_2(4) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(8) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(16) xor LFSR_2(18) xor LFSR_2(19) xor LFSR_2(22) xor LFSR_2(23) xor data(0) xor data(3) xor data(4) xor data(5) xor data(6) xor data(8) xor data(12) xor data(13) xor data(16) xor data(18) xor data(19) xor data(22) xor data(23));
					else
						CRC24_2(16) <= LFSR_2(0) xor LFSR_2(3) xor LFSR_2(4) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(8) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(16) xor LFSR_2(18) xor LFSR_2(19) xor LFSR_2(22) xor LFSR_2(23) xor data(0) xor data(3) xor data(4) xor data(5) xor data(6) xor data(8) xor data(12) xor data(13) xor data(16) xor data(18) xor data(19) xor data(22) xor data(23);
					end if;
					
					if (CRC24_2_error_bit = 18) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(17) <= not(LFSR_2(1) xor LFSR_2(4) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(9) xor LFSR_2(13) xor LFSR_2(14) xor LFSR_2(17) xor LFSR_2(19) xor LFSR_2(20) xor LFSR_2(23) xor data(1) xor data(4) xor data(5) xor data(6) xor data(7) xor data(9) xor data(13) xor data(14) xor data(17) xor data(19) xor data(20) xor data(23));
					else
						CRC24_2(17) <= LFSR_2(1) xor LFSR_2(4) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(9) xor LFSR_2(13) xor LFSR_2(14) xor LFSR_2(17) xor LFSR_2(19) xor LFSR_2(20) xor LFSR_2(23) xor data(1) xor data(4) xor data(5) xor data(6) xor data(7) xor data(9) xor data(13) xor data(14) xor data(17) xor data(19) xor data(20) xor data(23);
					end if;
					
					if (CRC24_2_error_bit = 19) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(18) <= not(LFSR_2(0) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(11) xor LFSR_2(13) xor LFSR_2(15) xor LFSR_2(18) xor LFSR_2(20) xor LFSR_2(23) xor data(0) xor data(6) xor data(7) xor data(8) xor data(9) xor data(11) xor data(13) xor data(15) xor data(18) xor data(20) xor data(23));
					else
						CRC24_2(18) <= LFSR_2(0) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(11) xor LFSR_2(13) xor LFSR_2(15) xor LFSR_2(18) xor LFSR_2(20) xor LFSR_2(23) xor data(0) xor data(6) xor data(7) xor data(8) xor data(9) xor data(11) xor data(13) xor data(15) xor data(18) xor data(20) xor data(23);
					end if;
					
					if (CRC24_2_error_bit = 20) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(19) <= not(LFSR_2(0) xor LFSR_2(1) xor LFSR_2(2) xor LFSR_2(5) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(16) xor LFSR_2(19) xor LFSR_2(23) xor data(0) xor data(1) xor data(2) xor data(5) xor data(7) xor data(8) xor data(11) xor data(12) xor data(13) xor data(16) xor data(19) xor data(23));
					else
						CRC24_2(19) <= LFSR_2(0) xor LFSR_2(1) xor LFSR_2(2) xor LFSR_2(5) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(16) xor LFSR_2(19) xor LFSR_2(23) xor data(0) xor data(1) xor data(2) xor data(5) xor data(7) xor data(8) xor data(11) xor data(12) xor data(13) xor data(16) xor data(19) xor data(23);
					end if;
					
					if (CRC24_2_error_bit = 21) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(20) <= not(LFSR_2(0) xor LFSR_2(1) xor LFSR_2(3) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(8) xor LFSR_2(10) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(17) xor LFSR_2(20) xor LFSR_2(21) xor LFSR_2(23) xor data(0) xor data(1) xor data(3) xor data(5) xor data(6) xor data(8) xor data(10) xor data(11) xor data(12) xor data(17) xor data(20) xor data(21) xor data(23));
					else
						CRC24_2(20) <= LFSR_2(0) xor LFSR_2(1) xor LFSR_2(3) xor LFSR_2(5) xor LFSR_2(6) xor LFSR_2(8) xor LFSR_2(10) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(17) xor LFSR_2(20) xor LFSR_2(21) xor LFSR_2(23) xor data(0) xor data(1) xor data(3) xor data(5) xor data(6) xor data(8) xor data(10) xor data(11) xor data(12) xor data(17) xor data(20) xor data(21) xor data(23);
					end if;
					
					if (CRC24_2_error_bit = 22) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(21) <= not(LFSR_2(1) xor LFSR_2(2) xor LFSR_2(4) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(9) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(18) xor LFSR_2(21) xor LFSR_2(22) xor data(1) xor data(2) xor data(4) xor data(6) xor data(7) xor data(9) xor data(11) xor data(12) xor data(13) xor data(18) xor data(21) xor data(22));
					else
						CRC24_2(21) <= LFSR_2(1) xor LFSR_2(2) xor LFSR_2(4) xor LFSR_2(6) xor LFSR_2(7) xor LFSR_2(9) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(18) xor LFSR_2(21) xor LFSR_2(22) xor data(1) xor data(2) xor data(4) xor data(6) xor data(7) xor data(9) xor data(11) xor data(12) xor data(13) xor data(18) xor data(21) xor data(22);
					end if;
					
					if (CRC24_2_error_bit = 23) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(22) <= not(LFSR_2(0) xor LFSR_2(3) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(19) xor LFSR_2(21) xor LFSR_2(22) xor data(0) xor data(3) xor data(7) xor data(8) xor data(9) xor data(11) xor data(12) xor data(19) xor data(21) xor data(22));
					else
						CRC24_2(22) <= LFSR_2(0) xor LFSR_2(3) xor LFSR_2(7) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(11) xor LFSR_2(12) xor LFSR_2(19) xor LFSR_2(21) xor LFSR_2(22) xor data(0) xor data(3) xor data(7) xor data(8) xor data(9) xor data(11) xor data(12) xor data(19) xor data(21) xor data(22);
					end if;
					
					if (CRC24_2_error_bit = 24) and (CRC24_2_clock_counter = CRC24_2_fault_tact) then
						CRC24_2(23) <= not(LFSR_2(1) xor LFSR_2(4) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(10) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(20) xor LFSR_2(22) xor LFSR_2(23) xor data(1) xor data(4) xor data(8) xor data(9) xor data(10) xor data(12) xor data(13) xor data(20) xor data(22) xor data(23));
					else
						CRC24_2(23) <= LFSR_2(1) xor LFSR_2(4) xor LFSR_2(8) xor LFSR_2(9) xor LFSR_2(10) xor LFSR_2(12) xor LFSR_2(13) xor LFSR_2(20) xor LFSR_2(22) xor LFSR_2(23) xor data(1) xor data(4) xor data(8) xor data(9) xor data(10) xor data(12) xor data(13) xor data(20) xor data(22) xor data(23);
					end if;
					
					if temp_simulation_completed /= '1' then
						if CRC24_2_clock_counter = CRC24_2_fault_tact then
							temp_CRC24_2_error_count <= temp_CRC24_2_error_count + 1;
							CRC24_2_clock_counter <= 0;
						else
							CRC24_2_clock_counter <= CRC24_2_clock_counter + 1;
						end if;
					end if;
				end if;
			end if;
	end process;
	
	CRC24_2_error_count <= std_logic_vector(to_unsigned(temp_CRC24_2_error_count, 24));
	
	-- вычислитель №3
	process (clk)
		begin
			if rising_edge(clk) then
				if internal_start_stop = '1' then
					-- вычисление CRC24_3 с использованием LFSR_3
					if (CRC24_3_error_bit = 1) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(0) <= not(LFSR_3(0) xor LFSR_3(2) xor LFSR_3(5) xor LFSR_3(9) xor LFSR_3(10) xor LFSR_3(11) xor LFSR_3(13) xor LFSR_3(14) xor LFSR_3(21) xor LFSR_3(23) xor data(0) xor data(2) xor data(5) xor data(9) xor data(10) xor data(11) xor data(13) xor data(14) xor data(21) xor data(23));
					else
						CRC24_3(0) <= LFSR_3(0) xor LFSR_3(2) xor LFSR_3(5) xor LFSR_3(9) xor LFSR_3(10) xor LFSR_3(11) xor LFSR_3(13) xor LFSR_3(14) xor LFSR_3(21) xor LFSR_3(23) xor data(0) xor data(2) xor data(5) xor data(9) xor data(10) xor data(11) xor data(13) xor data(14) xor data(21) xor data(23);
					end if;
					
					if (CRC24_3_error_bit = 2) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(1) <= not(LFSR_3(0) xor LFSR_3(1) xor LFSR_3(2) xor LFSR_3(3) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(9) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(15) xor LFSR_3(21) xor LFSR_3(22) xor LFSR_3(23) xor data(0) xor data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(9) xor data(12) xor data(13) xor data(15) xor data(21) xor data(22) xor data(23));
					else
						CRC24_3(1) <= LFSR_3(0) xor LFSR_3(1) xor LFSR_3(2) xor LFSR_3(3) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(9) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(15) xor LFSR_3(21) xor LFSR_3(22) xor LFSR_3(23) xor data(0) xor data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(9) xor data(12) xor data(13) xor data(15) xor data(21) xor data(22) xor data(23);
					end if;
					
					if (CRC24_3_error_bit = 3) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(2) <= not(LFSR_3(1) xor LFSR_3(2) xor LFSR_3(3) xor LFSR_3(4) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(10) xor LFSR_3(13) xor LFSR_3(14) xor LFSR_3(16) xor LFSR_3(22) xor LFSR_3(23) xor data(1) xor data(2) xor data(3) xor data(4) xor data(6) xor data(7) xor data(10) xor data(13) xor data(14) xor data(16) xor data(22) xor data(23));
					else
						CRC24_3(2) <= LFSR_3(1) xor LFSR_3(2) xor LFSR_3(3) xor LFSR_3(4) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(10) xor LFSR_3(13) xor LFSR_3(14) xor LFSR_3(16) xor LFSR_3(22) xor LFSR_3(23) xor data(1) xor data(2) xor data(3) xor data(4) xor data(6) xor data(7) xor data(10) xor data(13) xor data(14) xor data(16) xor data(22) xor data(23);
					end if;
					
					if (CRC24_3_error_bit = 4) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(3) <= not(LFSR_3(0) xor LFSR_3(3) xor LFSR_3(4) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(10) xor LFSR_3(13) xor LFSR_3(15) xor LFSR_3(17) xor LFSR_3(21) xor data(0) xor data(3) xor data(4) xor data(7) xor data(8) xor data(9) xor data(10) xor data(13) xor data(15) xor data(17) xor data(21));
					else
						CRC24_3(3) <= LFSR_3(0) xor LFSR_3(3) xor LFSR_3(4) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(10) xor LFSR_3(13) xor LFSR_3(15) xor LFSR_3(17) xor LFSR_3(21) xor data(0) xor data(3) xor data(4) xor data(7) xor data(8) xor data(9) xor data(10) xor data(13) xor data(15) xor data(17) xor data(21);
					end if;
					
					if (CRC24_3_error_bit = 5) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(4) <= not(LFSR_3(1) xor LFSR_3(4) xor LFSR_3(5) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(10) xor LFSR_3(11) xor LFSR_3(14) xor LFSR_3(16) xor LFSR_3(18) xor LFSR_3(22) xor data(1) xor data(4) xor data(5) xor data(8) xor data(9) xor data(10) xor data(11) xor data(14) xor data(16) xor data(18) xor data(22));
					else
						CRC24_3(4) <= LFSR_3(1) xor LFSR_3(4) xor LFSR_3(5) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(10) xor LFSR_3(11) xor LFSR_3(14) xor LFSR_3(16) xor LFSR_3(18) xor LFSR_3(22) xor data(1) xor data(4) xor data(5) xor data(8) xor data(9) xor data(10) xor data(11) xor data(14) xor data(16) xor data(18) xor data(22);
					end if;
					
					if (CRC24_3_error_bit = 6) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(5) <= not(LFSR_3(2) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(9) xor LFSR_3(10) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(15) xor LFSR_3(17) xor LFSR_3(19) xor LFSR_3(23) xor data(2) xor data(5) xor data(6) xor data(9) xor data(10) xor data(11) xor data(12) xor data(15) xor data(17) xor data(19) xor data(23));
					else
						CRC24_3(5) <= LFSR_3(2) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(9) xor LFSR_3(10) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(15) xor LFSR_3(17) xor LFSR_3(19) xor LFSR_3(23) xor data(2) xor data(5) xor data(6) xor data(9) xor data(10) xor data(11) xor data(12) xor data(15) xor data(17) xor data(19) xor data(23);
					end if;
					
					if (CRC24_3_error_bit = 7) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(6) <= not(LFSR_3(0) xor LFSR_3(2) xor LFSR_3(3) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(9) xor LFSR_3(12) xor LFSR_3(14) xor LFSR_3(16) xor LFSR_3(18) xor LFSR_3(20) xor LFSR_3(21) xor LFSR_3(23) xor data(0) xor data(2) xor data(3) xor data(5) xor data(6) xor data(7) xor data(9) xor data(12) xor data(14) xor data(16) xor data(18) xor data(20) xor data(21) xor data(23));
					else
						CRC24_3(6) <= LFSR_3(0) xor LFSR_3(2) xor LFSR_3(3) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(9) xor LFSR_3(12) xor LFSR_3(14) xor LFSR_3(16) xor LFSR_3(18) xor LFSR_3(20) xor LFSR_3(21) xor LFSR_3(23) xor data(0) xor data(2) xor data(3) xor data(5) xor data(6) xor data(7) xor data(9) xor data(12) xor data(14) xor data(16) xor data(18) xor data(20) xor data(21) xor data(23);
					end if;
					
					if (CRC24_3_error_bit = 8) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(7) <= not(LFSR_3(0) xor LFSR_3(1) xor LFSR_3(2) xor LFSR_3(3) xor LFSR_3(4) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(11) xor LFSR_3(14) xor LFSR_3(15) xor LFSR_3(17) xor LFSR_3(19) xor LFSR_3(22) xor LFSR_3(23) xor data(0) xor data(1) xor data(2) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(8) xor data(9) xor data(11) xor data(14) xor data(15) xor data(17) xor data(19) xor data(22) xor data(23));
					else
						CRC24_3(7) <= LFSR_3(0) xor LFSR_3(1) xor LFSR_3(2) xor LFSR_3(3) xor LFSR_3(4) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(11) xor LFSR_3(14) xor LFSR_3(15) xor LFSR_3(17) xor LFSR_3(19) xor LFSR_3(22) xor LFSR_3(23) xor data(0) xor data(1) xor data(2) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(8) xor data(9) xor data(11) xor data(14) xor data(15) xor data(17) xor data(19) xor data(22) xor data(23);
					end if;
					
					if (CRC24_3_error_bit = 9) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(8) <= not(LFSR_3(0) xor LFSR_3(1) xor LFSR_3(3) xor LFSR_3(4) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(14) xor LFSR_3(15) xor LFSR_3(16) xor LFSR_3(18) xor LFSR_3(20) xor LFSR_3(21) xor data(0) xor data(1) xor data(3) xor data(4) xor data(6) xor data(7) xor data(8) xor data(11) xor data(12) xor data(13) xor data(14) xor data(15) xor data(16) xor data(18) xor data(20) xor data(21));
					else
						CRC24_3(8) <= LFSR_3(0) xor LFSR_3(1) xor LFSR_3(3) xor LFSR_3(4) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(14) xor LFSR_3(15) xor LFSR_3(16) xor LFSR_3(18) xor LFSR_3(20) xor LFSR_3(21) xor data(0) xor data(1) xor data(3) xor data(4) xor data(6) xor data(7) xor data(8) xor data(11) xor data(12) xor data(13) xor data(14) xor data(15) xor data(16) xor data(18) xor data(20) xor data(21);
					end if;
					
					if (CRC24_3_error_bit = 10) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(9) <= not(LFSR_3(1) xor LFSR_3(2) xor LFSR_3(4) xor LFSR_3(5) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(14) xor LFSR_3(15) xor LFSR_3(16) xor LFSR_3(17) xor LFSR_3(19) xor LFSR_3(21) xor LFSR_3(22) xor data(1) xor data(2) xor data(4) xor data(5) xor data(7) xor data(8) xor data(9) xor data(12) xor data(13) xor data(14) xor data(15) xor data(16) xor data(17) xor data(19) xor data(21) xor data(22));
					else
						CRC24_3(9) <= LFSR_3(1) xor LFSR_3(2) xor LFSR_3(4) xor LFSR_3(5) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(14) xor LFSR_3(15) xor LFSR_3(16) xor LFSR_3(17) xor LFSR_3(19) xor LFSR_3(21) xor LFSR_3(22) xor data(1) xor data(2) xor data(4) xor data(5) xor data(7) xor data(8) xor data(9) xor data(12) xor data(13) xor data(14) xor data(15) xor data(16) xor data(17) xor data(19) xor data(21) xor data(22);
					end if;
					
					if (CRC24_3_error_bit = 11) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(10) <= not(LFSR_3(0) xor LFSR_3(3) xor LFSR_3(6) xor LFSR_3(8) xor LFSR_3(11) xor LFSR_3(15) xor LFSR_3(16) xor LFSR_3(17) xor LFSR_3(18) xor LFSR_3(20) xor LFSR_3(21) xor LFSR_3(22) xor data(0) xor data(3) xor data(6) xor data(8) xor data(11) xor data(15) xor data(16) xor data(17) xor data(18) xor data(20) xor data(21) xor data(22));
					else
						CRC24_3(10) <= LFSR_3(0) xor LFSR_3(3) xor LFSR_3(6) xor LFSR_3(8) xor LFSR_3(11) xor LFSR_3(15) xor LFSR_3(16) xor LFSR_3(17) xor LFSR_3(18) xor LFSR_3(20) xor LFSR_3(21) xor LFSR_3(22) xor data(0) xor data(3) xor data(6) xor data(8) xor data(11) xor data(15) xor data(16) xor data(17) xor data(18) xor data(20) xor data(21) xor data(22);
					end if;
					
					if (CRC24_3_error_bit = 12) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(11) <= not(LFSR_3(0) xor LFSR_3(1) xor LFSR_3(2) xor LFSR_3(4) xor LFSR_3(5) xor LFSR_3(7) xor LFSR_3(10) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(14) xor LFSR_3(16) xor LFSR_3(17) xor LFSR_3(18) xor LFSR_3(19) xor LFSR_3(22) xor data(0) xor data(1) xor data(2) xor data(4) xor data(5) xor data(7) xor data(10) xor data(11) xor data(12) xor data(13) xor data(14) xor data(16) xor data(17) xor data(18) xor data(19) xor data(22));
					else
						CRC24_3(11) <= LFSR_3(0) xor LFSR_3(1) xor LFSR_3(2) xor LFSR_3(4) xor LFSR_3(5) xor LFSR_3(7) xor LFSR_3(10) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(14) xor LFSR_3(16) xor LFSR_3(17) xor LFSR_3(18) xor LFSR_3(19) xor LFSR_3(22) xor data(0) xor data(1) xor data(2) xor data(4) xor data(5) xor data(7) xor data(10) xor data(11) xor data(12) xor data(13) xor data(14) xor data(16) xor data(17) xor data(18) xor data(19) xor data(22);
					end if;
					
					if (CRC24_3_error_bit = 13) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(12) <= not(LFSR_3(1) xor LFSR_3(2) xor LFSR_3(3) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(8) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(14) xor LFSR_3(15) xor LFSR_3(17) xor LFSR_3(18) xor LFSR_3(19) xor LFSR_3(20) xor LFSR_3(23) xor data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(8) xor data(11) xor data(12) xor data(13) xor data(14) xor data(15) xor data(17) xor data(18) xor data(19) xor data(20) xor data(23));
					else
						CRC24_3(12) <= LFSR_3(1) xor LFSR_3(2) xor LFSR_3(3) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(8) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(14) xor LFSR_3(15) xor LFSR_3(17) xor LFSR_3(18) xor LFSR_3(19) xor LFSR_3(20) xor LFSR_3(23) xor data(1) xor data(2) xor data(3) xor data(5) xor data(6) xor data(8) xor data(11) xor data(12) xor data(13) xor data(14) xor data(15) xor data(17) xor data(18) xor data(19) xor data(20) xor data(23);
					end if;
					
					if (CRC24_3_error_bit = 14) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(13) <= not(LFSR_3(0) xor LFSR_3(3) xor LFSR_3(4) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(10) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(15) xor LFSR_3(16) xor LFSR_3(18) xor LFSR_3(19) xor LFSR_3(20) xor LFSR_3(23) xor data(0) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(10) xor data(11) xor data(12) xor data(15) xor data(16) xor data(18) xor data(19) xor data(20) xor data(23));
					else
						CRC24_3(13) <= LFSR_3(0) xor LFSR_3(3) xor LFSR_3(4) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(10) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(15) xor LFSR_3(16) xor LFSR_3(18) xor LFSR_3(19) xor LFSR_3(20) xor LFSR_3(23) xor data(0) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7) xor data(10) xor data(11) xor data(12) xor data(15) xor data(16) xor data(18) xor data(19) xor data(20) xor data(23);
					end if;
					
					if (CRC24_3_error_bit = 15) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(14) <= not(LFSR_3(0) xor LFSR_3(1) xor LFSR_3(2) xor LFSR_3(4) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(10) xor LFSR_3(12) xor LFSR_3(14) xor LFSR_3(16) xor LFSR_3(17) xor LFSR_3(19) xor LFSR_3(20) xor LFSR_3(23) xor data(0) xor data(1) xor data(2) xor data(4) xor data(6) xor data(7) xor data(8) xor data(9) xor data(10) xor data(12) xor data(14) xor data(16) xor data(17) xor data(19) xor data(20) xor data(23));
					else
						CRC24_3(14) <= LFSR_3(0) xor LFSR_3(1) xor LFSR_3(2) xor LFSR_3(4) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(10) xor LFSR_3(12) xor LFSR_3(14) xor LFSR_3(16) xor LFSR_3(17) xor LFSR_3(19) xor LFSR_3(20) xor LFSR_3(23) xor data(0) xor data(1) xor data(2) xor data(4) xor data(6) xor data(7) xor data(8) xor data(9) xor data(10) xor data(12) xor data(14) xor data(16) xor data(17) xor data(19) xor data(20) xor data(23);
					end if;
					
					if (CRC24_3_error_bit = 16) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(15) <= not(LFSR_3(1) xor LFSR_3(2) xor LFSR_3(3) xor LFSR_3(5) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(10) xor LFSR_3(11) xor LFSR_3(13) xor LFSR_3(15) xor LFSR_3(17) xor LFSR_3(18) xor LFSR_3(20) xor LFSR_3(21) xor data(1) xor data(2) xor data(3) xor data(5) xor data(7) xor data(8) xor data(9) xor data(10) xor data(11) xor data(13) xor data(15) xor data(17) xor data(18) xor data(20) xor data(21));
					else
						CRC24_3(15) <= LFSR_3(1) xor LFSR_3(2) xor LFSR_3(3) xor LFSR_3(5) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(10) xor LFSR_3(11) xor LFSR_3(13) xor LFSR_3(15) xor LFSR_3(17) xor LFSR_3(18) xor LFSR_3(20) xor LFSR_3(21) xor data(1) xor data(2) xor data(3) xor data(5) xor data(7) xor data(8) xor data(9) xor data(10) xor data(11) xor data(13) xor data(15) xor data(17) xor data(18) xor data(20) xor data(21);
					end if;
					
					if (CRC24_3_error_bit = 17) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(16) <= not(LFSR_3(0) xor LFSR_3(3) xor LFSR_3(4) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(8) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(16) xor LFSR_3(18) xor LFSR_3(19) xor LFSR_3(22) xor LFSR_3(23) xor data(0) xor data(3) xor data(4) xor data(5) xor data(6) xor data(8) xor data(12) xor data(13) xor data(16) xor data(18) xor data(19) xor data(22) xor data(23));
					else
						CRC24_3(16) <= LFSR_3(0) xor LFSR_3(3) xor LFSR_3(4) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(8) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(16) xor LFSR_3(18) xor LFSR_3(19) xor LFSR_3(22) xor LFSR_3(23) xor data(0) xor data(3) xor data(4) xor data(5) xor data(6) xor data(8) xor data(12) xor data(13) xor data(16) xor data(18) xor data(19) xor data(22) xor data(23);
					end if;
					
					if (CRC24_3_error_bit = 18) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(17) <= not(LFSR_3(1) xor LFSR_3(4) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(9) xor LFSR_3(13) xor LFSR_3(14) xor LFSR_3(17) xor LFSR_3(19) xor LFSR_3(20) xor LFSR_3(23) xor data(1) xor data(4) xor data(5) xor data(6) xor data(7) xor data(9) xor data(13) xor data(14) xor data(17) xor data(19) xor data(20) xor data(23));
					else
						CRC24_3(17) <= LFSR_3(1) xor LFSR_3(4) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(9) xor LFSR_3(13) xor LFSR_3(14) xor LFSR_3(17) xor LFSR_3(19) xor LFSR_3(20) xor LFSR_3(23) xor data(1) xor data(4) xor data(5) xor data(6) xor data(7) xor data(9) xor data(13) xor data(14) xor data(17) xor data(19) xor data(20) xor data(23);
					end if;
					
					if (CRC24_3_error_bit = 19) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(18) <= not(LFSR_3(0) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(11) xor LFSR_3(13) xor LFSR_3(15) xor LFSR_3(18) xor LFSR_3(20) xor LFSR_3(23) xor data(0) xor data(6) xor data(7) xor data(8) xor data(9) xor data(11) xor data(13) xor data(15) xor data(18) xor data(20) xor data(23));
					else
						CRC24_3(18) <= LFSR_3(0) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(11) xor LFSR_3(13) xor LFSR_3(15) xor LFSR_3(18) xor LFSR_3(20) xor LFSR_3(23) xor data(0) xor data(6) xor data(7) xor data(8) xor data(9) xor data(11) xor data(13) xor data(15) xor data(18) xor data(20) xor data(23);
					end if;
					
					if (CRC24_3_error_bit = 20) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(19) <= not(LFSR_3(0) xor LFSR_3(1) xor LFSR_3(2) xor LFSR_3(5) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(16) xor LFSR_3(19) xor LFSR_3(23) xor data(0) xor data(1) xor data(2) xor data(5) xor data(7) xor data(8) xor data(11) xor data(12) xor data(13) xor data(16) xor data(19) xor data(23));
					else
						CRC24_3(19) <= LFSR_3(0) xor LFSR_3(1) xor LFSR_3(2) xor LFSR_3(5) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(16) xor LFSR_3(19) xor LFSR_3(23) xor data(0) xor data(1) xor data(2) xor data(5) xor data(7) xor data(8) xor data(11) xor data(12) xor data(13) xor data(16) xor data(19) xor data(23);
					end if;
					
					if (CRC24_3_error_bit = 21) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(20) <= not(LFSR_3(0) xor LFSR_3(1) xor LFSR_3(3) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(8) xor LFSR_3(10) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(17) xor LFSR_3(20) xor LFSR_3(21) xor LFSR_3(23) xor data(0) xor data(1) xor data(3) xor data(5) xor data(6) xor data(8) xor data(10) xor data(11) xor data(12) xor data(17) xor data(20) xor data(21) xor data(23));
					else
						CRC24_3(20) <= LFSR_3(0) xor LFSR_3(1) xor LFSR_3(3) xor LFSR_3(5) xor LFSR_3(6) xor LFSR_3(8) xor LFSR_3(10) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(17) xor LFSR_3(20) xor LFSR_3(21) xor LFSR_3(23) xor data(0) xor data(1) xor data(3) xor data(5) xor data(6) xor data(8) xor data(10) xor data(11) xor data(12) xor data(17) xor data(20) xor data(21) xor data(23);
					end if;
					
					if (CRC24_3_error_bit = 22) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(21) <= not(LFSR_3(1) xor LFSR_3(2) xor LFSR_3(4) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(9) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(18) xor LFSR_3(21) xor LFSR_3(22) xor data(1) xor data(2) xor data(4) xor data(6) xor data(7) xor data(9) xor data(11) xor data(12) xor data(13) xor data(18) xor data(21) xor data(22));
					else
						CRC24_3(21) <= LFSR_3(1) xor LFSR_3(2) xor LFSR_3(4) xor LFSR_3(6) xor LFSR_3(7) xor LFSR_3(9) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(18) xor LFSR_3(21) xor LFSR_3(22) xor data(1) xor data(2) xor data(4) xor data(6) xor data(7) xor data(9) xor data(11) xor data(12) xor data(13) xor data(18) xor data(21) xor data(22);
					end if;
					
					if (CRC24_3_error_bit = 23) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(22) <= not(LFSR_3(0) xor LFSR_3(3) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(19) xor LFSR_3(21) xor LFSR_3(22) xor data(0) xor data(3) xor data(7) xor data(8) xor data(9) xor data(11) xor data(12) xor data(19) xor data(21) xor data(22));
					else
						CRC24_3(22) <= LFSR_3(0) xor LFSR_3(3) xor LFSR_3(7) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(11) xor LFSR_3(12) xor LFSR_3(19) xor LFSR_3(21) xor LFSR_3(22) xor data(0) xor data(3) xor data(7) xor data(8) xor data(9) xor data(11) xor data(12) xor data(19) xor data(21) xor data(22);
					end if;
					
					if (CRC24_3_error_bit = 24) and (CRC24_3_clock_counter = CRC24_3_fault_tact) then
						CRC24_3(23) <= not(LFSR_3(1) xor LFSR_3(4) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(10) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(20) xor LFSR_3(22) xor LFSR_3(23) xor data(1) xor data(4) xor data(8) xor data(9) xor data(10) xor data(12) xor data(13) xor data(20) xor data(22) xor data(23));
					else
						CRC24_3(23) <= LFSR_3(1) xor LFSR_3(4) xor LFSR_3(8) xor LFSR_3(9) xor LFSR_3(10) xor LFSR_3(12) xor LFSR_3(13) xor LFSR_3(20) xor LFSR_3(22) xor LFSR_3(23) xor data(1) xor data(4) xor data(8) xor data(9) xor data(10) xor data(12) xor data(13) xor data(20) xor data(22) xor data(23);
					end if;
					
					if temp_simulation_completed /= '1' then
						if CRC24_3_clock_counter = CRC24_3_fault_tact then
							temp_CRC24_3_error_count <= temp_CRC24_3_error_count + 1;
							CRC24_3_clock_counter <= 0;
						else
							CRC24_3_clock_counter <= CRC24_3_clock_counter + 1;
						end if;
					end if;
				end if;
			end if;
	end process;
	
	CRC24_3_error_count <= std_logic_vector(to_unsigned(temp_CRC24_3_error_count, 24));
	
	-- голосующий элемент
	process (clk)
		begin
			if rising_edge(clk) then
				if (CRC24_1 = CRC24_2) or (CRC24_1 = CRC24_3) then
					voting_element_out <= CRC24_1;
				elsif CRC24_2 = CRC24_3 then
					voting_element_out <= CRC24_2;
				else
					voting_element_out <= (others => '0');
				end if;
			end if;
	end process;
	
	CRC24 <= voting_element_out;
end architecture behavioral;