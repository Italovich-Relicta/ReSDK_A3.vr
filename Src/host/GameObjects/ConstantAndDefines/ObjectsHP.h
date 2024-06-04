// ======================================================
// Copyright (c) 2017-2024 the ReSDK_A3 project
// sdk.relicta.ru
// ======================================================

//комплексные объекты состоят из нескольких частей. в основном это механизмы и устройства. их гораздо легче разрушить
#define OBJECT_TYPE_COMPLEX "complex"
//простые (однородные) объекты обычно состоят из одного материала. большинство объектов типа постройки - простые
#define OBJECT_TYPE_SIMPLE "simple"

//!рассеянные типы не использовать. В них нет смысла на данном этапе
#define OBJECT_TYPE_SPREADED "spreaded"

/*
Деревянные и пластиковые инструменты, устройства, мебель и т.д. обычно имеют СП 2.
Маленькие металлические, деревянно-металлические или композитные объекты, например топоры и пистолеты, обычно имеют СП 4.
Цельнометаллическое оружие ближнего боя имеет СП 6
*/
#define DR_SP_1 2
#define DR_SP_2 4
#define DR_SP_3 6
