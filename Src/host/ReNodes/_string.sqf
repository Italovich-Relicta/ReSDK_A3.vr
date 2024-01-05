// ======================================================
// Copyright (c) 2017-2024 the ReSDK_A3 project
// sdk.relicta.ru
// ======================================================


node_system_group("string")

"
    node:stringMake
    path:Строки
    name:Создать строку
    desc:Создает строку 
    icon:data\\icons\\pill_16x.png
    runtimeports:1
    exec:pure
    code:[ @genport.in.1(,) ] joinString """"
    in:string:Строка 1
    option:""makeport_in""\: {""type""\: ""makeport_in"",""src""\:""Строка 1"",""text_format""\:""Строка {value}""}
" node_system

"
    node:makeLiteralString
    name:Создать буквальную строку
    icon:data\\icons\\icon_BluePrintEditor_Function_16px
    color:PureFunction
    exec:pure
    code:@in.1
    in:string:Строка
    out:string:Строка
" node_system

//splitstring
"
    node:splitString
    name:Разбить строку
    desc:Разбивает строку на массив строк с указанным разделителем.
    icon:data\\icons\\icon_BluePrintEditor_Function_16px
    color:PureFunction
    exec:pure
    code:(@in.1) splitString (@in.2)
    in:string:Строка
    in:string:Разделитель
    out:array[string]:Массив строк
" node_system

//joinstring
"
    node:joinString
    name:Объединить строки
    desc:Объединяет массив строк с указанным разделителем.
    icon:data\\icons\\icon_BluePrintEditor_Function_16px
    color:PureFunction
    exec:pure
    code:(@in.1) joinString (@in.2)
    in:array[string]:Массив строк
    in:string:Разделитель:Строка, которая будет объединять соседние элементы массива строк.
    out:string:Строка:Результат объединения
" node_system

//count
"
    node:stringCount
    name:Количество символов
    desc:Возвращает количество символов в строке.
    icon:data\\icons\\icon_BluePrintEditor_Function_16px
    color:PureFunction
    exec:pure
    code: [@in.1,@in.2] call stringLength
    in:string:Строка
    in:bool:Как количество:При флаге false символы кириллицы (русские буквы) считаются как 2 символа, так как занимают 2 байта. Иными словами, с флагом true считается количество символов в строке, а с false считается количество байт в строке.
        opt:def=true
    out:int:Размер:Количество символов в строке, либо количество байт в строке (в зависимости от флага ""Как количество"")
" node_system

//toArray
"
    node:stringToCharArray
    name:Строка в массив
    desc:Преобразует строку в массив чисел. Каждый элемент массива является номером символа в [ru.wikipedia.org/wiki/Юникод Юникоде].
    icon:data\\icons\\icon_BluePrintEditor_Function_16px
    color:PureFunction
    exec:pure
    code:toArray(@in.1)
    in:string:Строка
    out:array[int]:Массив 
" node_system

//toString
"
    node:charArrayToString
    name:Массив в строку
    desc:Преобразует массив чисел в строку. Каждое число будет преобразоввано по [symbl.cc/ru/unicode/table/#cyrillic таблице символов Юникода]. Например, русская заглавная буква ""А"" имеет код 1040 (0x0410 в x16).
    icon:data\\icons\\icon_BluePrintEditor_Function_16px
    color:PureFunction
    exec:pure
    code:toString(@in.1)
    in:array[int]:Массив
    out:string:Строка
" node_system

//select
"
    node:selectString
    name:Выбрать подстроку
    desc:Выбирает подстроку из строки
    icon:data\\icons\\icon_BluePrintEditor_Function_16px
    color:PureFunction
    exec:pure
    code:[@in.1,@in.2,@in.3] call stringSelect
    in:string:Строка
    in:int:Старт:Стартовый индекс, с которого начинается подстрока
    in:int:Длина:Длина подстроки
    out:string:Подстрока
" node_system

//toUpper
"
    node:stringToUpper
    name:Верхний регистр
    desc:Преобразует строку в верхний регистр
    icon:data\\icons\\icon_BluePrintEditor_Function_16px
    color:PureFunction
    exec:pure
    code:toUpper(@in.1)
    in:string:Строка
    out:string:Строка
" node_system

//toLower
"
    node:stringToLower
    name:Нижний регистр
    desc:Преобразует строку в нижний регистр
    icon:data\\icons\\icon_BluePrintEditor_Function_16px
    color:PureFunction
    exec:pure
    code:toLower(@in.1)
    in:string:Строка
    out:string:Строка
" node_system

//endl
"
    node:stringEndl
    name:Новая строка
    namelib:Новая строка (перенос строки)
    desc:Возвращает символ новой строки.
    icon:data\\icons\\icon_BluePrintEditor_Function_16px
    color:PureFunction
    exec:pure
    code:endl
    out:string:Новая строка
" node_system

//format
//TODO rewrite unsafe and slower node
"
    node:stringFormat
    name:Форматировать строку
    desc:Форматирует строку. Указанные элементы внутри строки можно получить с помощью %1, %2 и т.д.
    icon:data\\icons\\icon_BluePrintEditor_Function_16px
    color:PureFunction
    exec:pure
    code:format([@in.1]+ (@in.2)call{if(_this isequaltype[])then {_this}else{[_this]}})
    in:string:Строка
    in:auto:Элемент:Если элемент массив, то каждый из его элементов доступен с помощью %1, %2 и т.д. В ином случае элемент доступен только с помощью %1.
" node_system