// ======================================================
// Copyright (c) 2017-2024 the ReSDK_A3 project
// sdk.relicta.ru
// ======================================================


ND_INIT(MobInventory)
	//getWidthByHeightToSquare
	//_ctg = [(40),(40)] call nd_stdLoad;
	_ctg = if (isFirstLoad) then {
		_sx = 40;
		_sy = 70;
		private _ctg = [thisDisplay,WIDGETGROUP,[50 - _sx/2,50-_sy/2,_sx,_sy]] call createWidget;
		addSavedWdiget(_ctg);

		_back = [thisDisplay,BACKGROUND,[0,0,100,100],_ctg] call createWidget;
		_back setBackgroundColor [0.3,0.3,0.3,0.5];

		_closer = [thisDisplay,[0,90,100,10],_ctg] call nd_addClosingButton;
		_closer ctrlSetText "Закрыть";

		_ctgLeft = [thisDisplay,WIDGETGROUPSCROLLS,[0,0,100,90],_ctg] call createWidget;
		addSavedWdiget(_ctgLeft);
		
		_ctgLeft
	} else {
		getSavedWidgets select 1
	};
	
	call nd_cleanupData;
	
	__allocTxt = {
		if equals(_this,[]) then {
			_ptr = "";
			inventory_slotnames_default select _i;
		} else {
			_this params ["_name","_icn","_ptrex"];
			_ptr = _ptrex;
			if (!(".paa" in _icn)) then { //realoc if not fullpath
				_icn = PATH_PICTURE_INV(_icn);
			};
			format["(%1) <img size='1.3' image='%2'/> %3",inventory_slotnames_default select _i,_icn,_name];
		};	
	};
	_lall = INV_LIST_ALL;
	_sizeH = 100 / (count _lall);
	_ptr = ""; //outside reference
	for "_i" from 0 to (count _lall) - 1 do {
		regNDWidget(TEXT,vec4(0,_sizeH * _i,100,_sizeH),_ctg,null);
		[lastNDWidget,format["<t align='center'>%1</t>",(ctxParams deleteAt 0) call __allocTxt]] call widgetSetText;
		lastNDWidget setVariable ["ref",_ptr];
		lastNDWidget setVariable ["slotid",_lall select _i];
		lastNDWidget ctrlAddEventHandler ["MouseButtonUp",{
			params ["_ct","_bt"];
			_id = _ct getVariable ["slotid",null];
			if !isNullVar(_id) then {
				[_id] call nd_onPressButton;
			};
		}]
	};	
	
	/*#define SIZE_INVSLOT 7
	#define SLOT_BIASH 0.3
	
	[0,0,getWidthByHeightToSquare(SIZE_INVSLOT),SIZE_INVSLOT] params ["_xp","_yp","_wp","_hp"];

	_xp = 50 - transformSizeByAR(SIZE_INVSLOT) / 2;
	_yp = 50 - SIZE_INVSLOT;

	private _biasW = transformSizeByAR(SLOT_BIASH);

	#define allocpos__(xpos,ypos) [_xp + ((_wp + _biasW) * xpos),_yp + ((_hp + SLOT_BIASH) * ypos),_wp,_hp]
	
	{
		(inventory_slotpos_map select _x) params ["_xMap","_yMap"];
		regNDWidget(PICTURE,allocpos__(_xMap,_yMap),null,null);
		lastNDWidget ctrlSetText (inventory_sloticons_default select _x);
	} foreach inventory_openModeSlotsId;*/
	
	
ND_END

ND_ObjectPull_getVtarget = {
	player getvariable ["__loc_pull_vtarg",objNUll]
};
ND_ObjectPull_getPtrObj = {
	private _ptr = player getvariable ["__loc_pull_ptr",null];
	if isNullVar(_ptr) exitWith {objNUll};
	noe_client_allPointers getOrDefault [_ptr,objNull]
};

ND_INIT(ObjectPull)
	_ctg = if (isFirstLoad) then {
		
		private _offsH = 10;
		private _header = [thisDisplay,TEXT,vec4(0,0,90,_offsH)] call createWidget;
		[_header,"<t align='center'>Зажмите ЛКМ для вращения, скролл для подъема, опускания</t>"] call widgetSetText;
		addSavedWdiget(_header);

		_closer = [thisDisplay,[90,0,100-90,_offsH]] call nd_addClosingButton;
		_closer ctrlSetText "Закрыть";

		//full-sized
		private _back = [thisDisplay,BACKGROUND,vec4(0,_offsH,100,100-_offsH)] call createWidget;
		_back ctrlEnable true;
		_back ctrlShow true;
		_back setBackgroundColor [0.1,0.1,0.1,0.2];
		addSavedWdiget(_back);

		//initialize variables
		_back setVariable ["_tranform_vec",[0,0,0]];
		_back setVariable ["_ch_vec",[0,0,0]];
		_back setVariable ["_transform_zpos",0];
		_back setVariable ["_ch_zpos",0];
		_back setVariable ["_isPressed",false];
		_back setVariable ["_pressedPos",[50,50]];
		
		_back ctrlAddEventHandler ["MouseButtonDown",{
			params ["_w","_b"];
			_w setVariable ["_isPressed",true];
			_w setVariable ["_pressedPos",call mouseGetPosition];
			private _o = call ND_ObjectPull_getPtrObj;
			if !isNullReference(_o) then {
				_w setVariable ["_transform_vec",[_o] call model_getPitchBankYaw];
			};

		}];
		_back ctrlAddEventHandler ["MouseButtonUp",{
			params ["_w","_b"];
			_w setVariable ["_isPressed",false];
			//save transform
			private _transform = _w getVariable ["_ch_vec",vec3(0,0,0)];
			_w setvariable ["_tranform_vec",_transform];
			
			//send new transform
			[["vupd",_transform]]call nd_onPressButton;
		}];
		_back ctrlAddEventHandler ["MouseMoving",{
			params ["_w","_xabs","_yabs"];
			if (_w getVariable ["_isPressed",false]) then {
				(call mouseGetPosition) params ["_x","_y"];
				(_w getVariable "_pressedPos") params ["_ofX","_ofY"];
				
				//x - 2
				//y - 0
				_dX = _ofX - _x;
				_dY = _ofY - _y;
				_xnorm = (linearConversion [0,100,_ofX - _x,-180,180,true]) ;
				_ynorm = (linearConversion [0,100,_ofY - _y,-90,90,true]) ;
				_oldVec = _w getVariable ["_tranform_vec",vec3(0,0,0)];
				_newvec = [(_oldVec select 0) + (_dY),(_oldVec select 1),(_oldVec select 2) + (_dX)];
				_newvec set [0,[_newvec select 0,-180,180] call clampInRange];
				_newvec set [2,clampangle(_newvec select 2,0,359)];
				traceformat("NEWVEC %1",_newvec)

				_w setvariable ["_ch_vec",_newvec];
				private _o = call ND_ObjectPull_getPtrObj;
				if !isNullReference(_o) then {
					[_o,_newvec] call model_SetPitchBankYaw;
				};
			};
		}];
		_back ctrlAddEventHandler ["MouseZChanged",{
			params ["_w","_val"];
			[["zupd",_val / 12]]call nd_onPressButton;
		}];

		_back
	} else {
		getSavedWidgets select 1
	};
	
	call nd_cleanupData;	
	
ND_END