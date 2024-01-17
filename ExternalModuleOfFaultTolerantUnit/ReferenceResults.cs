using System;
using System.IO;

namespace ExternalModuleOfFaultTolerantUnit
{
    internal class ReferenceResults
    {
        static void Main()
        {
            string firstStringValueOfInputSequence = new string('0', 24);
            string dataInString = firstStringValueOfInputSequence;
            uint dataInDecimal;

            string lastStringValueOfInputSequence = new string('1', 24);
            uint lastValueOfInputSequence = Convert.ToUInt32(lastStringValueOfInputSequence, 2);

            sbyte[] dataIn = new sbyte[dataInString.Length];
            sbyte[] LFSR = new sbyte[dataIn.Length];
            sbyte[] CRC24 = new sbyte[dataIn.Length];

            string CRC24String;

            // путь к внешнему текстовому файлу
            string filePath = "ReferenceResults.txt";

            // проверка наличия файла и его удаление при существовании
            if (File.Exists(filePath))
            {
                File.Delete(filePath);
            }

            for (uint i = 0; i < lastValueOfInputSequence; i++)
            {
                // увеличение входной последовательности на 1
                dataInDecimal = Convert.ToUInt32(dataInString, 2) + 1;
                dataInString = Convert.ToString(dataInDecimal, 2).PadLeft(24, '0');

                for (int j = 0; j < dataInString.Length; j++)
                {
                    if (dataInString[(dataInString.Length - 1) - j] == '0')
                    {
                        dataIn[j] = 0;
                    }
                    else if (dataInString[(dataInString.Length - 1) - j] == '1')
                    {
                        dataIn[j] = 1;
                    }
                }

                // вычисление CRC24 с использованием LFSR
                CRC24[0] = (sbyte)(LFSR[0] ^ LFSR[2] ^ LFSR[5] ^ LFSR[9] ^ LFSR[10] ^ LFSR[11] ^ LFSR[13] ^ LFSR[14] ^ LFSR[21] ^ LFSR[23] ^ dataIn[0] ^ dataIn[2] ^ dataIn[5] ^ dataIn[9] ^ dataIn[10] ^ dataIn[11] ^ dataIn[13] ^ dataIn[14] ^ dataIn[21] ^ dataIn[23]);
                CRC24[1] = (sbyte)(LFSR[0] ^ LFSR[1] ^ LFSR[2] ^ LFSR[3] ^ LFSR[5] ^ LFSR[6] ^ LFSR[9] ^ LFSR[12] ^ LFSR[13] ^ LFSR[15] ^ LFSR[21] ^ LFSR[22] ^ LFSR[23] ^ dataIn[0] ^ dataIn[1] ^ dataIn[2] ^ dataIn[3] ^ dataIn[5] ^ dataIn[6] ^ dataIn[9] ^ dataIn[12] ^ dataIn[13] ^ dataIn[15] ^ dataIn[21] ^ dataIn[22] ^ dataIn[23]);
                CRC24[2] = (sbyte)(LFSR[1] ^ LFSR[2] ^ LFSR[3] ^ LFSR[4] ^ LFSR[6] ^ LFSR[7] ^ LFSR[10] ^ LFSR[13] ^ LFSR[14] ^ LFSR[16] ^ LFSR[22] ^ LFSR[23] ^ dataIn[1] ^ dataIn[2] ^ dataIn[3] ^ dataIn[4] ^ dataIn[6] ^ dataIn[7] ^ dataIn[10] ^ dataIn[13] ^ dataIn[14] ^ dataIn[16] ^ dataIn[22] ^ dataIn[23]);
                CRC24[3] = (sbyte)(LFSR[0] ^ LFSR[3] ^ LFSR[4] ^ LFSR[7] ^ LFSR[8] ^ LFSR[9] ^ LFSR[10] ^ LFSR[13] ^ LFSR[15] ^ LFSR[17] ^ LFSR[21] ^ dataIn[0] ^ dataIn[3] ^ dataIn[4] ^ dataIn[7] ^ dataIn[8] ^ dataIn[9] ^ dataIn[10] ^ dataIn[13] ^ dataIn[15] ^ dataIn[17] ^ dataIn[21]);
                CRC24[4] = (sbyte)(LFSR[1] ^ LFSR[4] ^ LFSR[5] ^ LFSR[8] ^ LFSR[9] ^ LFSR[10] ^ LFSR[11] ^ LFSR[14] ^ LFSR[16] ^ LFSR[18] ^ LFSR[22] ^ dataIn[1] ^ dataIn[4] ^ dataIn[5] ^ dataIn[8] ^ dataIn[9] ^ dataIn[10] ^ dataIn[11] ^ dataIn[14] ^ dataIn[16] ^ dataIn[18] ^ dataIn[22]);
                CRC24[5] = (sbyte)(LFSR[2] ^ LFSR[5] ^ LFSR[6] ^ LFSR[9] ^ LFSR[10] ^ LFSR[11] ^ LFSR[12] ^ LFSR[15] ^ LFSR[17] ^ LFSR[19] ^ LFSR[23] ^ dataIn[2] ^ dataIn[5] ^ dataIn[6] ^ dataIn[9] ^ dataIn[10] ^ dataIn[11] ^ dataIn[12] ^ dataIn[15] ^ dataIn[17] ^ dataIn[19] ^ dataIn[23]);
                CRC24[6] = (sbyte)(LFSR[0] ^ LFSR[2] ^ LFSR[3] ^ LFSR[5] ^ LFSR[6] ^ LFSR[7] ^ LFSR[9] ^ LFSR[12] ^ LFSR[14] ^ LFSR[16] ^ LFSR[18] ^ LFSR[20] ^ LFSR[21] ^ LFSR[23] ^ dataIn[0] ^ dataIn[2] ^ dataIn[3] ^ dataIn[5] ^ dataIn[6] ^ dataIn[7] ^ dataIn[9] ^ dataIn[12] ^ dataIn[14] ^ dataIn[16] ^ dataIn[18] ^ dataIn[20] ^ dataIn[21] ^ dataIn[23]);
                CRC24[7] = (sbyte)(LFSR[0] ^ LFSR[1] ^ LFSR[2] ^ LFSR[3] ^ LFSR[4] ^ LFSR[5] ^ LFSR[6] ^ LFSR[7] ^ LFSR[8] ^ LFSR[9] ^ LFSR[11] ^ LFSR[14] ^ LFSR[15] ^ LFSR[17] ^ LFSR[19] ^ LFSR[22] ^ LFSR[23] ^ dataIn[0] ^ dataIn[1] ^ dataIn[2] ^ dataIn[3] ^ dataIn[4] ^ dataIn[5] ^ dataIn[6] ^ dataIn[7] ^ dataIn[8] ^ dataIn[9] ^ dataIn[11] ^ dataIn[14] ^ dataIn[15] ^ dataIn[17] ^ dataIn[19] ^ dataIn[22] ^ dataIn[23]);
                CRC24[8] = (sbyte)(LFSR[0] ^ LFSR[1] ^ LFSR[3] ^ LFSR[4] ^ LFSR[6] ^ LFSR[7] ^ LFSR[8] ^ LFSR[11] ^ LFSR[12] ^ LFSR[13] ^ LFSR[14] ^ LFSR[15] ^ LFSR[16] ^ LFSR[18] ^ LFSR[20] ^ LFSR[21] ^ dataIn[0] ^ dataIn[1] ^ dataIn[3] ^ dataIn[4] ^ dataIn[6] ^ dataIn[7] ^ dataIn[8] ^ dataIn[11] ^ dataIn[12] ^ dataIn[13] ^ dataIn[14] ^ dataIn[15] ^ dataIn[16] ^ dataIn[18] ^ dataIn[20] ^ dataIn[21]);
                CRC24[9] = (sbyte)(LFSR[1] ^ LFSR[2] ^ LFSR[4] ^ LFSR[5] ^ LFSR[7] ^ LFSR[8] ^ LFSR[9] ^ LFSR[12] ^ LFSR[13] ^ LFSR[14] ^ LFSR[15] ^ LFSR[16] ^ LFSR[17] ^ LFSR[19] ^ LFSR[21] ^ LFSR[22] ^ dataIn[1] ^ dataIn[2] ^ dataIn[4] ^ dataIn[5] ^ dataIn[7] ^ dataIn[8] ^ dataIn[9] ^ dataIn[12] ^ dataIn[13] ^ dataIn[14] ^ dataIn[15] ^ dataIn[16] ^ dataIn[17] ^ dataIn[19] ^ dataIn[21] ^ dataIn[22]);
                CRC24[10] = (sbyte)(LFSR[0] ^ LFSR[3] ^ LFSR[6] ^ LFSR[8] ^ LFSR[11] ^ LFSR[15] ^ LFSR[16] ^ LFSR[17] ^ LFSR[18] ^ LFSR[20] ^ LFSR[21] ^ LFSR[22] ^ dataIn[0] ^ dataIn[3] ^ dataIn[6] ^ dataIn[8] ^ dataIn[11] ^ dataIn[15] ^ dataIn[16] ^ dataIn[17] ^ dataIn[18] ^ dataIn[20] ^ dataIn[21] ^ dataIn[22]);
                CRC24[11] = (sbyte)(LFSR[0] ^ LFSR[1] ^ LFSR[2] ^ LFSR[4] ^ LFSR[5] ^ LFSR[7] ^ LFSR[10] ^ LFSR[11] ^ LFSR[12] ^ LFSR[13] ^ LFSR[14] ^ LFSR[16] ^ LFSR[17] ^ LFSR[18] ^ LFSR[19] ^ LFSR[22] ^ dataIn[0] ^ dataIn[1] ^ dataIn[2] ^ dataIn[4] ^ dataIn[5] ^ dataIn[7] ^ dataIn[10] ^ dataIn[11] ^ dataIn[12] ^ dataIn[13] ^ dataIn[14] ^ dataIn[16] ^ dataIn[17] ^ dataIn[18] ^ dataIn[19] ^ dataIn[22]);
                CRC24[12] = (sbyte)(LFSR[1] ^ LFSR[2] ^ LFSR[3] ^ LFSR[5] ^ LFSR[6] ^ LFSR[8] ^ LFSR[11] ^ LFSR[12] ^ LFSR[13] ^ LFSR[14] ^ LFSR[15] ^ LFSR[17] ^ LFSR[18] ^ LFSR[19] ^ LFSR[20] ^ LFSR[23] ^ dataIn[1] ^ dataIn[2] ^ dataIn[3] ^ dataIn[5] ^ dataIn[6] ^ dataIn[8] ^ dataIn[11] ^ dataIn[12] ^ dataIn[13] ^ dataIn[14] ^ dataIn[15] ^ dataIn[17] ^ dataIn[18] ^ dataIn[19] ^ dataIn[20] ^ dataIn[23]);
                CRC24[13] = (sbyte)(LFSR[0] ^ LFSR[3] ^ LFSR[4] ^ LFSR[5] ^ LFSR[6] ^ LFSR[7] ^ LFSR[10] ^ LFSR[11] ^ LFSR[12] ^ LFSR[15] ^ LFSR[16] ^ LFSR[18] ^ LFSR[19] ^ LFSR[20] ^ LFSR[23] ^ dataIn[0] ^ dataIn[3] ^ dataIn[4] ^ dataIn[5] ^ dataIn[6] ^ dataIn[7] ^ dataIn[10] ^ dataIn[11] ^ dataIn[12] ^ dataIn[15] ^ dataIn[16] ^ dataIn[18] ^ dataIn[19] ^ dataIn[20] ^ dataIn[23]);
                CRC24[14] = (sbyte)(LFSR[0] ^ LFSR[1] ^ LFSR[2] ^ LFSR[4] ^ LFSR[6] ^ LFSR[7] ^ LFSR[8] ^ LFSR[9] ^ LFSR[10] ^ LFSR[12] ^ LFSR[14] ^ LFSR[16] ^ LFSR[17] ^ LFSR[19] ^ LFSR[20] ^ LFSR[23] ^ dataIn[0] ^ dataIn[1] ^ dataIn[2] ^ dataIn[4] ^ dataIn[6] ^ dataIn[7] ^ dataIn[8] ^ dataIn[9] ^ dataIn[10] ^ dataIn[12] ^ dataIn[14] ^ dataIn[16] ^ dataIn[17] ^ dataIn[19] ^ dataIn[20] ^ dataIn[23]);
                CRC24[15] = (sbyte)(LFSR[1] ^ LFSR[2] ^ LFSR[3] ^ LFSR[5] ^ LFSR[7] ^ LFSR[8] ^ LFSR[9] ^ LFSR[10] ^ LFSR[11] ^ LFSR[13] ^ LFSR[15] ^ LFSR[17] ^ LFSR[18] ^ LFSR[20] ^ LFSR[21] ^ dataIn[1] ^ dataIn[2] ^ dataIn[3] ^ dataIn[5] ^ dataIn[7] ^ dataIn[8] ^ dataIn[9] ^ dataIn[10] ^ dataIn[11] ^ dataIn[13] ^ dataIn[15] ^ dataIn[17] ^ dataIn[18] ^ dataIn[20] ^ dataIn[21]);
                CRC24[16] = (sbyte)(LFSR[0] ^ LFSR[3] ^ LFSR[4] ^ LFSR[5] ^ LFSR[6] ^ LFSR[8] ^ LFSR[12] ^ LFSR[13] ^ LFSR[16] ^ LFSR[18] ^ LFSR[19] ^ LFSR[22] ^ LFSR[23] ^ dataIn[0] ^ dataIn[3] ^ dataIn[4] ^ dataIn[5] ^ dataIn[6] ^ dataIn[8] ^ dataIn[12] ^ dataIn[13] ^ dataIn[16] ^ dataIn[18] ^ dataIn[19] ^ dataIn[22] ^ dataIn[23]);
                CRC24[17] = (sbyte)(LFSR[1] ^ LFSR[4] ^ LFSR[5] ^ LFSR[6] ^ LFSR[7] ^ LFSR[9] ^ LFSR[13] ^ LFSR[14] ^ LFSR[17] ^ LFSR[19] ^ LFSR[20] ^ LFSR[23] ^ dataIn[1] ^ dataIn[4] ^ dataIn[5] ^ dataIn[6] ^ dataIn[7] ^ dataIn[9] ^ dataIn[13] ^ dataIn[14] ^ dataIn[17] ^ dataIn[19] ^ dataIn[20] ^ dataIn[23]);
                CRC24[18] = (sbyte)(LFSR[0] ^ LFSR[6] ^ LFSR[7] ^ LFSR[8] ^ LFSR[9] ^ LFSR[11] ^ LFSR[13] ^ LFSR[15] ^ LFSR[18] ^ LFSR[20] ^ LFSR[23] ^ dataIn[0] ^ dataIn[6] ^ dataIn[7] ^ dataIn[8] ^ dataIn[9] ^ dataIn[11] ^ dataIn[13] ^ dataIn[15] ^ dataIn[18] ^ dataIn[20] ^ dataIn[23]);
                CRC24[19] = (sbyte)(LFSR[0] ^ LFSR[1] ^ LFSR[2] ^ LFSR[5] ^ LFSR[7] ^ LFSR[8] ^ LFSR[11] ^ LFSR[12] ^ LFSR[13] ^ LFSR[16] ^ LFSR[19] ^ LFSR[23] ^ dataIn[0] ^ dataIn[1] ^ dataIn[2] ^ dataIn[5] ^ dataIn[7] ^ dataIn[8] ^ dataIn[11] ^ dataIn[12] ^ dataIn[13] ^ dataIn[16] ^ dataIn[19] ^ dataIn[23]);
                CRC24[20] = (sbyte)(LFSR[0] ^ LFSR[1] ^ LFSR[3] ^ LFSR[5] ^ LFSR[6] ^ LFSR[8] ^ LFSR[10] ^ LFSR[11] ^ LFSR[12] ^ LFSR[17] ^ LFSR[20] ^ LFSR[21] ^ LFSR[23] ^ dataIn[0] ^ dataIn[1] ^ dataIn[3] ^ dataIn[5] ^ dataIn[6] ^ dataIn[8] ^ dataIn[10] ^ dataIn[11] ^ dataIn[12] ^ dataIn[17] ^ dataIn[20] ^ dataIn[21] ^ dataIn[23]);
                CRC24[21] = (sbyte)(LFSR[1] ^ LFSR[2] ^ LFSR[4] ^ LFSR[6] ^ LFSR[7] ^ LFSR[9] ^ LFSR[11] ^ LFSR[12] ^ LFSR[13] ^ LFSR[18] ^ LFSR[21] ^ LFSR[22] ^ dataIn[1] ^ dataIn[2] ^ dataIn[4] ^ dataIn[6] ^ dataIn[7] ^ dataIn[9] ^ dataIn[11] ^ dataIn[12] ^ dataIn[13] ^ dataIn[18] ^ dataIn[21] ^ dataIn[22]);
                CRC24[22] = (sbyte)(LFSR[0] ^ LFSR[3] ^ LFSR[7] ^ LFSR[8] ^ LFSR[9] ^ LFSR[11] ^ LFSR[12] ^ LFSR[19] ^ LFSR[21] ^ LFSR[22] ^ dataIn[0] ^ dataIn[3] ^ dataIn[7] ^ dataIn[8] ^ dataIn[9] ^ dataIn[11] ^ dataIn[12] ^ dataIn[19] ^ dataIn[21] ^ dataIn[22]);
                CRC24[23] = (sbyte)(LFSR[1] ^ LFSR[4] ^ LFSR[8] ^ LFSR[9] ^ LFSR[10] ^ LFSR[12] ^ LFSR[13] ^ LFSR[20] ^ LFSR[22] ^ LFSR[23] ^ dataIn[1] ^ dataIn[4] ^ dataIn[8] ^ dataIn[9] ^ dataIn[10] ^ dataIn[12] ^ dataIn[13] ^ dataIn[20] ^ dataIn[22] ^ dataIn[23]);

                Array.Reverse(CRC24);

                // конвертация массива CRC24 в строку
                CRC24String = string.Concat(CRC24);

                // запись значения массива CRC24 в файл
                if (dataInString == lastStringValueOfInputSequence)
                {
                    File.AppendAllText(filePath, CRC24String);
                }
                else
                {
                    File.AppendAllText(filePath, CRC24String + Environment.NewLine);
                }

                // отображение прогресса расчётов
                if (dataInString == "000000000000000000000000")
                {
                    Console.WriteLine("Вычисление 1 степени...");
                }
                else if (dataInString == "000000000000000000000001")
                {
                    Console.WriteLine("Вычисление 2 степени...");
                }
                else if (dataInString == "000000000000000000000011")
                {
                    Console.WriteLine("Вычисление 3 степени...");
                }
                else if (dataInString == "000000000000000000000111")
                {
                    Console.WriteLine("Вычисление 4 степени...");
                }
                else if (dataInString == "000000000000000000001111")
                {
                    Console.WriteLine("Вычисление 5 степени...");
                }
                else if (dataInString == "000000000000000000011111")
                {
                    Console.WriteLine("Вычисление 6 степени...");
                }
                else if (dataInString == "000000000000000000111111")
                {
                    Console.WriteLine("Вычисление 7 степени...");
                }
                else if (dataInString == "000000000000000001111111")
                {
                    Console.WriteLine("Вычисление 8 степени...");
                }
                else if (dataInString == "000000000000000011111111")
                {
                    Console.WriteLine("Вычисление 9 степени...");
                }
                else if (dataInString == "000000000000000111111111")
                {
                    Console.WriteLine("Вычисление 10 степени...");
                }
                else if (dataInString == "000000000000001111111111")
                {
                    Console.WriteLine("Вычисление 11 степени...");
                }
                else if (dataInString == "000000000000011111111111")
                {
                    Console.WriteLine("Вычисление 12 степени...");
                }
                else if (dataInString == "000000000000111111111111")
                {
                    Console.WriteLine("Вычисление 13 степени...");
                }
                else if (dataInString == "000000000001111111111111")
                {
                    Console.WriteLine("Вычисление 14 степени...");
                }
                else if (dataInString == "000000000011111111111111")
                {
                    Console.WriteLine("Вычисление 15 степени...");
                }
                else if (dataInString == "000000000111111111111111")
                {
                    Console.WriteLine("Вычисление 16 степени...");
                }
                else if (dataInString == "000000001111111111111111")
                {
                    Console.WriteLine("Вычисление 17 степени...");
                }
                else if (dataInString == "000000011111111111111111")
                {
                    Console.WriteLine("Вычисление 18 степени...");
                }
                else if (dataInString == "000000111111111111111111")
                {
                    Console.WriteLine("Вычисление 19 степени...");
                }
                else if (dataInString == "000001111111111111111111")
                {
                    Console.WriteLine("Вычисление 20 степени...");
                }
                else if (dataInString == "000011111111111111111111")
                {
                    Console.WriteLine("Вычисление 21 степени...");
                }
                else if (dataInString == "000111111111111111111111")
                {
                    Console.WriteLine("Вычисление 22 степени...");
                }
                else if (dataInString == "001111111111111111111111")
                {
                    Console.WriteLine("Вычисление 23 степени...");
                }
                else if (dataInString == "011111111111111111111111")
                {
                    Console.WriteLine("Вычисление 24 степени...");
                }
            }
        }
    }
}