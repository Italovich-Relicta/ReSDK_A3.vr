node_system_group("objects")

nodeModule_setPath("Объекты")
nodeModule_setIcon("data\\icons\\icon_Blueprint_Node_16x")
nodeModule_setColorStyle("Function")
nodeModule_setExecType("all")

"
    node:null_check
    name:Объект существует
    namelib:Объект существует (не null)
    desc:Проверяет существование (валидность) объекта. Если ссылка на объект пригоден для использования (не удален и существует) - возвращает ИСТИНУ.
    icon:data\\icons\\icon_BluePrintEditor_Function_16px
    color:PureFunction
    exec:pure
    code:(!ISNULL(@in.1))
    in:object^:Объект:Ссылка на проверяемый объект.
    out:bool:Результат:Возвращает ИСТИНУ, если объект существует. Если ссылка на объект не существует или объект был удален - возвращает ЛОЖЬ.
" node_system

["getChildTypes","Унаследованные классы","[@in.1,@in.2] call oop_getinhlist","classname:Тип","bool:Глобально:Выполняет глобальный поиск не только прямых наследников, а вообщех всех объектов прямо или косвенно унаследовавших свойства проверяемого типа"
    opt "def=false", "array[classname]:Массив типов"
"Данный узел предназначен для получения массива типов, унаследованных от указанного типа."
] reg_binary

//TODO fix bug - stackgen error
["createObject","Создать объект",'private @genvar.out.2 = new(@in.1); @out.1',"classname:Имя класса","object^:Объект:Созданный объект","Выполняет базовое создание объекта. Если вам нужно создать игровой объект используйте узел для создания игровых объектов"] reg_unary
["deleteObject","Удалить объект",'delete(@in.1); @out.1',"object^:Объект:Ссылка на объект","","Выполняет базовое удаление объекта. Обратите внимание, что для удаления игровых объектов необходимо использовать узел для удаления игровых объектов."] reg_unary

nodeModule_setColorStyle("PureFunction")
nodeModule_setExecType("pure")

["thisObject","Этот объект:Объект этого графа (этот объект)",'this',"self:Объект","Возвращает ссылку на экземпляр текущего графа."] reg_nular

["isTypeOf","Унаследован от",'isTypeOf(@in.1,@in.2)',"object^:Объект","classname:Имя класса","bool:Результат","Проверяет, является ли проверяемый объект дочерним типом от указанного класса."] reg_binary

//istypeof

//TODO reflection category (e.g. reflection, injection, member info, attributes, etc.)
//["createObjectByString","Создать объект",'instantiate(@in.1)']

