using System;
using System.IO;
using System.IO.Ports;

namespace COMsniffer
{
    internal class COMsniffer
    {
        static void Main()
        {
            string portName = "COM1";
            int baudRate = 9600;
            Parity parity = Parity.None;
            int dataBits = 8;
            StopBits stopBits = StopBits.One;

            SerialPort serialPort = new SerialPort(portName, baudRate, parity, dataBits, stopBits);

            try
            {
                serialPort.Open();

                using (StreamWriter noTMRWriter = new StreamWriter("NoTMRresults.txt"))
                using (StreamWriter TMRWriter = new StreamWriter("TMRresults.txt"))
                using (StreamWriter GTMRWriter = new StreamWriter("GTMRresults.txt"))
                using (StreamWriter NoTMR_error_count = new StreamWriter("NoTMR_error_count.txt"))
                using (StreamWriter TMR_error_count = new StreamWriter("TMR_error_count.txt"))
                using (StreamWriter GTMR_error_count = new StreamWriter("GTMR_error_count.txt"))
                using (StreamWriter GTMR_CRC24_4_tact_enable = new StreamWriter("GTMR_CRC24_4_tact_enable.txt"))
                {
                    for (int i = 0; i < 3 * 16777215; i++)
                    {
                        byte[] wordBytes = new byte[3];
                        for (int j = 0; j < 3; j++)
                        {
                            int data = serialPort.ReadByte();
                            wordBytes[j] = (byte)data;
                        }

                        int result = (wordBytes[0] << 16) | (wordBytes[1] << 8) | wordBytes[2];

                        if (i < 16777215)
                        {
                            noTMRWriter.WriteLine(result);
                        }
                        else if (i < 2 * 16777215)
                        {
                            TMRWriter.WriteLine(result);
                        }
                        else
                        {
                            GTMRWriter.WriteLine(result);
                        }
                    }

                    for (int numOfLastMessages = 1; numOfLastMessages <= 4; numOfLastMessages++)
                    {
                        for (int j = 0; j < numOfLastMessages; j++)
                        {
                            byte[] wordBytes = new byte[3];
                            for (int k = 0; k < 3; k++)
                            {
                                int data = serialPort.ReadByte();
                                wordBytes[k] = (byte)data;
                            }

                            int result = (wordBytes[0] << 16) | (wordBytes[1] << 8) | wordBytes[2];

                            switch (numOfLastMessages)
                            {
                                case 1:
                                    NoTMR_error_count.WriteLine(result);
                                    break;
                                case 2:
                                    TMR_error_count.WriteLine(result);
                                    break;
                                case 3:
                                    GTMR_error_count.WriteLine(result);
                                    break;
                                case 4:
                                    GTMR_CRC24_4_tact_enable.WriteLine(result);
                                    break;
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка: {ex.Message}");
            }
            finally
            {
                serialPort.Close();
            }
        }
    }
}