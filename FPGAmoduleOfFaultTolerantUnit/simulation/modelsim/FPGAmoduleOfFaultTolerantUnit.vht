-- Copyright (C) 1991-2013 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.

-- ***************************************************************************
-- This file contains a Vhdl test bench template that is freely editable to   
-- suit user's needs .Comments are provided in each section to help the user  
-- fill out necessary details.                                                
-- ***************************************************************************
-- Generated on "01/17/2024 10:54:23"
                                                            
-- Vhdl Test Bench template for design  :  FPGAmoduleOfFaultTolerantUnit
-- 
-- Simulation tool : ModelSim-Altera (VHDL)
-- 

LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;                                

ENTITY FPGAmoduleOfFaultTolerantUnit_vhd_tst IS
END FPGAmoduleOfFaultTolerantUnit_vhd_tst;
ARCHITECTURE FPGAmoduleOfFaultTolerantUnit_arch OF FPGAmoduleOfFaultTolerantUnit_vhd_tst IS
-- constants                                                 
-- signals                                                   
SIGNAL clk : STD_LOGIC;
SIGNAL start_stop : STD_LOGIC;
SIGNAL tx_pin : STD_LOGIC;
COMPONENT FPGAmoduleOfFaultTolerantUnit
	PORT (
	clk : IN STD_LOGIC;
	start_stop : IN STD_LOGIC;
	tx_pin : OUT STD_LOGIC
	);
END COMPONENT;
BEGIN
	i1 : FPGAmoduleOfFaultTolerantUnit
	PORT MAP (
-- list connections between master ports and signals
	clk => clk,
	start_stop => start_stop,
	tx_pin => tx_pin
	);
init : PROCESS                                               
-- variable declarations                                     
BEGIN                                                        
        -- code that executes only once                      
WAIT;                                                       
END PROCESS init;                                           
always : PROCESS                                              
-- optional sensitivity list                                  
-- (        )                                                 
-- variable declarations                                      
BEGIN                                                         
        -- code executes for every event on sensitivity list  
WAIT;                                                        
END PROCESS always;                                          
END FPGAmoduleOfFaultTolerantUnit_arch;
