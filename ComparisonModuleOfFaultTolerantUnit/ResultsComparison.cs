using System;
using System.IO;

namespace ComparisonModuleOfFaultTolerantUnit
{
    internal class ResultsComparison
    {
        static void Main()
        {
            int NoTMRerrors = 0;
            int TMRerrors = 0;
            int GTMRerrors = 0;

            using (StreamReader ReferenceResultsReader = new StreamReader("ReferenceResults.txt"))
            using (StreamReader NoTMRresultsReader = new StreamReader("NoTMRresults.txt"))
            using (StreamReader TMRresultsReader = new StreamReader("TMRresults.txt"))
            using (StreamReader GTMRresultsReader = new StreamReader("GTMRresults.txt"))
            {
                string referenceWord, file1Word, file2Word, file3Word;

                for (int i = 1; ; i++)
                {
                    referenceWord = ReferenceResultsReader.ReadLine();
                    file1Word = NoTMRresultsReader.ReadLine();
                    file2Word = TMRresultsReader.ReadLine();
                    file3Word = GTMRresultsReader.ReadLine();

                    if (referenceWord == null || file1Word == null || file2Word == null || file3Word == null)
                    {
                        break;
                    }

                    if (referenceWord != file1Word)
                    {
                        NoTMRerrors++;
                    }

                    if (referenceWord != file2Word)
                    {
                        TMRerrors++;
                    }

                    if (referenceWord != file3Word)
                    {
                        GTMRerrors++;
                    }
                }
            }

            Console.WriteLine("МОДУЛЬ СРАВНЕНИЯ");
            Console.WriteLine("--------------");
            Console.WriteLine();

            string noTMRErrorCount = File.ReadAllText("NoTMR_error_count.txt");
            Console.WriteLine("Количество ошибок, внесённых в вычислитель блока NoTMR: " + noTMRErrorCount);
            Console.WriteLine();
            Console.WriteLine("Количество сбоев в блоке NoTMR: " + NoTMRerrors);
            Console.WriteLine();

            double NoTMRfaultTolerancy = (1 - NoTMRerrors / double.Parse(noTMRErrorCount)) * 100;
            Console.WriteLine("Сбоеусточивость блока NoTMR: " + NoTMRfaultTolerancy + " %");
            Console.WriteLine();

            Console.WriteLine("-----");
            Console.WriteLine();

            string[] tmrErrorCounts = File.ReadAllLines("TMR_error_count.txt");
            double TMRErrorCount = 0;
            for (int i = 0; i < tmrErrorCounts.Length; i++)
            {
                Console.WriteLine($"Количество ошибок, внесённых в {i + 1} вычислитель блока TMR: {tmrErrorCounts[i]}");
                TMRErrorCount += double.Parse(tmrErrorCounts[i]);
            }
            Console.WriteLine();
            Console.WriteLine("Количество сбоев в блоке TMR: " + TMRerrors);
            Console.WriteLine();

            double TMRfaultTolerancy = (1 - TMRerrors / TMRErrorCount) * 100;
            Console.WriteLine("Сбоеусточивость блока TMR: " + TMRfaultTolerancy + " %");
            Console.WriteLine();

            Console.WriteLine("-----");
            Console.WriteLine();

            string[] gtmrErrorCounts = File.ReadAllLines("GTMR_error_count.txt");
            double GTMRErrorCount = 0;
            for (int i = 0; i < gtmrErrorCounts.Length; i++)
            {
                Console.WriteLine($"Количество ошибок, внесённых в {i + 1} вычислитель блока GTMR: {gtmrErrorCounts[i]}");
                GTMRErrorCount += double.Parse(gtmrErrorCounts[i]);
            }
            Console.WriteLine();
            Console.WriteLine("Количество сбоев в блоке GTMR: " + GTMRerrors);
            Console.WriteLine();

            double GTMRfaultTolerancy = (1 - GTMRerrors / GTMRErrorCount) * 100;
            Console.WriteLine("Сбоеусточивость блока GTMR: " + GTMRfaultTolerancy + " %");
            Console.WriteLine();

            string GTMR_CRC24_4_tact_enable = File.ReadAllText("GTMR_CRC24_4_tact_enable.txt");
            Console.WriteLine("Номер такта, на котором дополнительный вычислитель в блоке GTMR начал работу: " + GTMR_CRC24_4_tact_enable);
            Console.WriteLine();

            Console.ReadLine();
        }
    }
}