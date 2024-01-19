# FaultTolerantUnit (Сбоеустойчивый узел)

Целостность хранимой и обрабатываемой информации является важнейшим условием успешности космической миссии. К числу актуальных угроз целостности относится действие космической радиации, приводящее к сбоям в работе бортового оборудования.

Данный проект представляет собой минимальный инструментарий для проведения лабораторного исследования эффективности метода тройного модульного резервирования (далее - троирования, TMR) для регистровых цифровых функциональных узлов бортовой аппаратуры космических аппаратов (далее - КА), реализованных в программируемых логических интегральных схемах (далее - ПЛИС). В проекте воссоздано возникновение одиночных сбоев (далее - SEU) вследствие воздействия элементарных частиц в составе радиационного фона околоземного пространства на аппаратуру КА, приводящих к инвертированию состояния ячеек памяти (0 на 1 или наоборот).

В качестве функционального узла выбран вычислитель хэш-функции, выполняющий алгоритм расчёта контрольной суммы CRC-24.

Моделирование возникновения SEU реализовано путём работы генераторов псевдослучайных чисел двух типов:
1) первый отвечает за определение порядкового номера такта в общем цикле вычислений контрольных сумм, на котором нужно внести ошибку;
2) второй отвечает за определение порядкового номера бита в сообщении, значение которого нужно инвертировать, тем самым сымитировав возникновение SEU из-за космической радиации.

Проект состоит из следующих компонентов:

1) FPGAmoduleOfFaultTolerantUnit (язык описания аппаратуры VHDL) − компонент для ПЛИС. В данном модуле реализованы 3 схемы троирования: NoTMR, TMR и GTMR. NoTMR состоит из одного вычислителя CRC-24, резервирование не предусмотрено. TMR состоит из трёх вычислителей и мажоритарного (голосующего) элемента на выходе вычислительного узла, работающего по принципу «большинства» и позволяющего «маскировать» одну ошибку. Схема GTMR схожа по логике с TMR, за исключением наличия в схеме ещё одного дополнительного вычислителя и устройства контроля и управления. По умолчанию при старте программы дополнительный вычислитель не производит расчёт контрольных сумм. В устройстве контроля и управления задано условие, при котором дополнительный вычислитель должен вступить в работу. Устройство на каждом такте работы программы проверяет, выполнилось ли условие в одном из вычислителей: если не выполнилось, то дополнительный вычислитель остаётся отключённым и вычисление контрольных сумм производится в трёх основных вычислителях; если выполнилось, то устройство контроля и управления отключает один из основных вычислителей, для которого сработало условие, и одновременно с этим включает дополнительный вычислитель, который начинает рассчитывать контрольные суммы вместо отключённого вычислителя. Помимо этого, в модуле реализована передача рассчитанных контрольных сумм каждого вычислительного узла на ЭВМ для их сохранения и последующего анализа;
2) ExternalModuleOfFaultTolerantUnit (язык C#) - компонент для пользовательской ЭВМ под управлением ОС семейства Windows. В данном модуле реализован расчёт эталонных контрольных сумм (без внесения ошибок в сообщения);
3) COMsniffer (язык C#) - компонент для ЭВМ, предназначенный для прослушивания COM-порта, по которому ПЛИС соединяется с ЭВМ, и сохранения входящих последовательностей (контрольных сумм);
4) ComparisonModuleOfFaultTolerantUnit (язык C#) - компонент для ЭВМ, выполняющий построчное сравнение контрольных сумм вычислительных узлов на ПЛИС с соответствующей эталонной контрольной суммой. Если какая-либо из выходных контрольных сумм не совпадает с эталонным значением, то счётчик ошибок этого блока увеличивается на единицу. По окончанию работы программы в консоль выводится информация со значениями количества внесённых ошибок для каждого вычислителя в каждом блоке на ПЛИС и количества несовпадающих с эталоном контрольным сумм для каждого блока.
