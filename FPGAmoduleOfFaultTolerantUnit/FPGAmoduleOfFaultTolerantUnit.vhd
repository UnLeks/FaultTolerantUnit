library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity FPGAmoduleOfFaultTolerantUnit is
    port (
        -- тактовый сигнал
        clk : in std_logic;
        
        -- ручной запуск и остановка программы
        start_stop : in std_logic;
        
        -- выходной пин UART
        tx_pin : out std_logic
    );
end entity FPGAmoduleOfFaultTolerantUnit;

architecture behavioral of FPGAmoduleOfFaultTolerantUnit is
    -- контрольная сумма входной последовательности, рассчитанная алгоритмом CRC24 в блоке NoTMR
    signal NoTMR_CRC24 : std_logic_vector(23 downto 0);
    
    -- контрольная сумма входной последовательности, рассчитанная алгоритмом CRC24 в блоке TMR [с учётом резервирования]
    signal TMR_CRC24 : std_logic_vector(23 downto 0);
    
    -- контрольная сумма входной последовательности, рассчитанная алгоритмом CRC24 в блоке GTMR [с учётом гибридного резервирования]
    signal GTMR_CRC24 : std_logic_vector(23 downto 0);
    
    -- количество ошибок, внесённых в вычислитель блока NoTMR
    signal NoTMR_error_count : std_logic_vector(23 downto 0);
    
    -- количество ошибок, внесённых в вычислители блока TMR
    signal TMR_CRC24_1_error_count : std_logic_vector(23 downto 0);
    signal TMR_CRC24_2_error_count : std_logic_vector(23 downto 0);
    signal TMR_CRC24_3_error_count : std_logic_vector(23 downto 0);
    
    -- количество ошибок, внесённых в вычислители блока GTMR
    signal GTMR_CRC24_1_error_count : std_logic_vector(23 downto 0);
    signal GTMR_CRC24_2_error_count : std_logic_vector(23 downto 0);
    signal GTMR_CRC24_3_error_count : std_logic_vector(23 downto 0);
    signal GTMR_CRC24_4_error_count : std_logic_vector(23 downto 0);
    
    -- номер такта, на котором дополнительный вычислитель в блоке GTMR начал работу
    signal GTMR_CRC24_4_tact_enable : std_logic_vector(23 downto 0);
    
    -- флаг, отображающий окончание работы блока NoTMR
    signal NoTMR_simulation_completed : std_logic := '0';
    
    -- флаг, отображающий окончание работы блока TMR
    signal TMR_simulation_completed : std_logic := '0';
    
    -- флаг, отображающий окончание работы блока GTMR
    signal GTMR_simulation_completed : std_logic := '0';

    -- выходной сигнал UART
    signal tx_out : std_logic;

    -- счетчик для выбора данных для отправки по UART
    signal tx_counter : integer := 0;

    -- данные для отправки по UART
    signal selected_data : std_logic_vector(23 downto 0);
	 
	 component NoTMR
		port (
			clk : in std_logic;
			start_stop : in std_logic;
			CRC24 : out std_logic_vector(23 downto 0);
			error_count : out std_logic_vector(23 downto 0);
			simulation_completed: out std_logic
		);
	end component;
	
	component TMR
		port (
			clk : in std_logic;
			start_stop : in std_logic;
			CRC24 : out std_logic_vector(23 downto 0);
			CRC24_1_error_count : out std_logic_vector(23 downto 0);
			CRC24_2_error_count : out std_logic_vector(23 downto 0);
			CRC24_3_error_count : out std_logic_vector(23 downto 0);
			simulation_completed: out std_logic
		);
	end component;
	
	component GTMR
		port (
			clk : in std_logic;
			start_stop : in std_logic;
			CRC24 : out std_logic_vector(23 downto 0);
			CRC24_1_error_count : out std_logic_vector(23 downto 0);
			CRC24_2_error_count : out std_logic_vector(23 downto 0);
			CRC24_3_error_count : out std_logic_vector(23 downto 0);
			CRC24_4_error_count : out std_logic_vector(23 downto 0);
			CRC24_4_tact_enable : out std_logic_vector(23 downto 0);
			simulation_completed: out std_logic
		);
	end component;

begin
    -- подключение экземпляра блока NoTMR
    NoTMR_instance: NoTMR port map (
        clk => clk,
        start_stop => start_stop,
        CRC24 => NoTMR_CRC24,
        error_count => NoTMR_error_count,
        simulation_completed => NoTMR_simulation_completed
    );
    
    -- подключение экземпляра блока TMR
    TMR_instance: TMR port map (
        clk => clk,
        start_stop => start_stop,
        CRC24 => TMR_CRC24,
        CRC24_1_error_count => TMR_CRC24_1_error_count,
        CRC24_2_error_count => TMR_CRC24_2_error_count,
        CRC24_3_error_count => TMR_CRC24_3_error_count,
        simulation_completed => TMR_simulation_completed
    );
    
    -- подключение экземпляра блока GTMR
    GTMR_instance: GTMR port map (
        clk => clk,
        start_stop => start_stop,
        CRC24 => GTMR_CRC24,
        CRC24_1_error_count => GTMR_CRC24_1_error_count,
        CRC24_2_error_count => GTMR_CRC24_2_error_count,
        CRC24_3_error_count => GTMR_CRC24_3_error_count,
        CRC24_4_error_count => GTMR_CRC24_4_error_count,
        CRC24_4_tact_enable => GTMR_CRC24_4_tact_enable,
        simulation_completed => GTMR_simulation_completed
    );

    -- Логика выбора данных для отправки
    process (NoTMR_simulation_completed, TMR_simulation_completed, GTMR_simulation_completed, selected_data)
    begin
        if NoTMR_simulation_completed = '0' then
            selected_data <= NoTMR_CRC24;
        elsif TMR_simulation_completed = '0' then
            selected_data <= TMR_CRC24;
        elsif GTMR_simulation_completed = '0' then
            selected_data <= GTMR_CRC24;
        else
            selected_data <= (others => '0');
        end if;
    end process;

    -- Логика отправки данных по UART
    process (clk)
    begin
        if rising_edge(clk) then
            if tx_counter < 24 then
                tx_out <= selected_data(tx_counter);
                tx_counter <= tx_counter + 1;
            else
                tx_out <= '0';
                tx_counter <= 0;
            end if;
        end if;
    end process;

    -- Подключение tx_out к tx_pin (вашему выходному пину UART)
    tx_pin <= tx_out;

end architecture behavioral;