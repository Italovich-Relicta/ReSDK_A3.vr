// ======================================================
// Copyright (c) 2017-2024 the ReSDK_A3 project
// sdk.relicta.ru
// ======================================================

#include <..\..\host\engine.hpp>
#include <..\Inventory\inventory.hpp>
#include <smd.h>
#include <..\LightEngine\LightEngine.hpp>
#include <..\ClientRpc\clientRpc.hpp>
#include <..\Interactions\interact.hpp>


#include <..\..\host\CombatSystem\CombatSystem.hpp>

#include <..\..\host\GameObjects\Mobs\Mob_combat_attdam_enum.hpp>


/*
Устанавливаются переменные smd_ а onChange... вызываются при изменении

*/

// smd_allInGameMobs - global list of all ingame mobs

//ассоциативный список переменная слежения, метод выполнения при изменении состояния
smd_list_variables = [
	["smd_face","onChangeFace"], //срабатывает при изменении лица
	["smd_faceAnim","onChangeFaceAnim"], //срабатывает при изменеии лицевой анимации
	["smd_bodyParts","onChangeBodyParts"], //срабатывает при изменении наличия частей тела
	["smd_custAnm","onChangeCustomAnim"], //обработчик кастомных анимаций (например связывание)
	["smd_isCombat","onChangeCombat"], //срабатывает при переключении комбат мода
	["smd_attdam","onAttackOrDamage"], //срабатывает при атаке или получении урона
	["smd_isStunned","onStun"], //обработчик стана
	["smd_isGrabbed","onGrabbed"], //обработчик граба
	["smd_pull","onPull"], //таскание предметов
	["smd_visualStates","onVisualStates"], //визуалки (некроз, текущая кровь, горящий чел, марево)
	["smd_visibility","onVisiblility"],
	["smd_interp","onInterpolate"], //поднятие и положение предметов
	["smd_animSpeed","onAnimSpeed"], //изменение скорости анимации персонажа
	["smd_chatMessage","onChatMessage"], //text chat system chatMessage
	["smd_voiceBlob","onVoiceBlobInit"],
	["smd_isPrintingSay","onIsPrintingSay"]
	//["smd_voicePref","onChangeVoicePref"] // > [vol,canspeak,underwatereffect]
	//["smd_radioPref","onChangeRadioPref"] // > []
];
//adding inventory slots
smd_list_allSlots = INV_LIST_ALL apply {["smd_s" + str _x,"onChangeSlotData"]};
smd_list_variables append smd_list_allSlots;

if (!isMultiplayer) then {
	{
		_varName = _x select 0;
		{
			_x setVariable [_varName,nil];
			_x setVariable [smd_local_prefix + _varName,nil];
			if ("smd_s" in _varName) then {
				_x setVariable [smd_local_prefix + _varName + "_obj",nil]
			};
		} foreach allUnits;
	} foreach smd_list_variables;
};

//updater code
smd_handle_update = -1;
smd_isProcessed = {smd_handle_update != -1};
smd_startUpdate = {
	if (smd_handle_update != -1) then {
		call smd_stopUpdate;
	};
	smd_handle_update = startUpdate(smd_onUpdate,smd_update_delay);
	
	{
		[_x,"onVisualStates",true] call smd_syncVar;
	} foreach (smd_allingamemobs-[player]);
	
};

// завершение обновления системы SMD
smd_stopUpdate = {
	if (smd_handle_update == -1) exitWith {};
	stopUpdate(smd_handle_update);
	
	{
		_mob = _x;
		{
			if (smd_local_prefix in _x) then {
				_mob setVariable [_x,null]; // fix legacy 0.7.597 (error: smd_local_prefix + _x -> __local___local_s1)
			};
		} foreach (allVariables _mob);

		//also detach all proxit-objects
		{
			if (_x call smd_isSMDObjectInSlot) then {
				_x call smd_internal_deleteAttachments_rec;
				deleteVehicle _x;
			};
		} foreach (attachedObjects _mob);

	} foreach smd_allInGameMobs;
};
//выгрузка визуальных эффектов с привязкой к старому локальному игроку
smd_unloadVST = {
	params ["_prevPlayer"];
	private __LOCAL_PLAYER__ = _prevPlayer; //external reference
	{
		_mob = _x;
		[_mob,[]] call smd_onVisualStates;
	} foreach smd_allInGameMobs;
};

// Обработчик обновления, вызываемый в каждом кадре
smd_onUpdate = {
	#include "smd_onUpdate.sqf"
};
_smdInitDelay = {
	log("Starting sync mob data service");

};
call _smdInitDelay;
//invokeAfterDelay(_smdInitDelay,5);

//Выполняет принудительную синхрозинацию переменной по её названию или названию функции
smd_syncVar = {
	params ["_mob","_varName",["_findByFunctionName",false]];

	private _indexOfFinder = [0,1] select _findByFunctionName;

	private _idx = smd_list_variables findif {(_x select _indexOfFinder) == _varName};

	if (_idx == -1) exitWith {
		errorformat("smd::syncVar() - Cant sync %1 (as function - %2). Index out of range",_varName arg _findByFunctionName);
	};

	[_mob,smd_list_variables select _idx select 0,smd_list_variables select _idx select 1] call smd_onUpdateSetting;
};

// Обновление настроек SMD
smd_onUpdateSetting = {
	params ["_mob","_varName","_func"];

	traceformat("smd::onUpdateSetting() - Start updating setting %1",_varName);

	private _data = _mob getvariable _varName;
	if isNullVar(_data) exitWith {};
	[_mob,_data] call (missionNamespace getVariable ["smd_" + _func,{}]);

	_mob setVariable [smd_local_prefix + _varName,_data];
};

//событие смены лица
smd_onChangeFace = {
	params ["_mob","_ctx"];

	//noface changer
	if (_ctx == "") then {
		_ctx = "persianhead_a3_01_player";
	} else {
		if (equals(_mob,player) && isNullVar(__onChangeHud)) then {
			private _checkedFace = _ctx;
			_ctx = _ctx + "_player";
			if !(isClass (configfile >> "CfgFaces" >> "Man_A3" >>_ctx)) then {
				_ctx = "persianhead_a3_01_player"; //rechange
				errorformat("smd::onChangeFace() - cant find face %1",_checkedFace);
			};
		};
	};



	_mob setFace _ctx;

	// handle error on set face and disable face anim
	[_mob,"onChangeFaceAnim",true] call smd_syncVar;
};

//Лицевая анимация
smd_onChangeFaceAnim = {
	params ["_mob","_ctx"];
	_mob setMimic _ctx;
};

// Изменения наличия частей тела
smd_onChangeBodyParts = {
	params ["_mob","_ctx"];

	if equals(_mob,player) exitWith {
		private _isBodyPartsChanged = true;
		private _flag_check_canwalk_local_player = true;
		[_mob] call anim_syncAnim;
	};

/*	_beforeState = (_mob getVariable [smd_local_prefix + "smd_bodyParts",[true,true,true,true]]);
	_newState = (_mob getVariable ["smd_bodyParts",[true,true,true,true]]);
	private _partnames = ["righthand","lefthand","rightleg","leftleg"];
	{
		_newcurstate = _newState select _forEachIndex;
		if (_x && !_newcurstate) then {

		};
	} forEach _beforeState;*/

};

// Изменение и синхрозинация анимации персонажа
smd_onChangeCustomAnim = {
	params ["_mob","_ctx"];
	//ctx is vec3: _ani,_blen,_prfx
	if equals(_mob,player) exitWith {
		//private _isBodyPartsChanged = true;
		//private _flag_check_canwalk_local_player = true;
		[_mob] call anim_syncAnim;
	};
};

// Изменение статуса боевого режима
smd_onChangeCombat = {
	params ["_mob","_ctx"];

	if equals(player,_mob) then {

		//3rd param - apply camera and sync anim
		[_mob,_ctx,true,([_mob] call smd_isSitting)] call cc_setCombatMode;
		call hud_combStyle_onCombatUpdate;
	} else {

	};
};

//smd_attdam
smd_onAttackOrDamage = {
	params ["_mob","_ctx"];

	if (netTickTime > ((_ctx select 1)+2)) exitWith {};//при позднем синхронизировании -без вызова

	_actType = _ctx select 0;
	//attack
	if equals(_actType,COMBAT_ATTDAM_ATTACK) exitWith {
		// [_slotHandAtt,_enumAtt] for rpc:attanm, _probEff - for particles or throwed items
		_ctx params ["","","_slotHandAtt","_enumAtt","_probEff"];

		//apply attack particles (лязг метала прим.)

		if equals(player,_mob) then {
			//Подавление применения анимации при anim::syncAnim()
			_mob setVariable ["__SMDINT_isSupressedAnimSync",true];
			//play attack anim
			[_mob,_slotHandAtt,_enumAtt] call anim_doAttack;

			_mob setVariable ["__SMDINT_isSupressedAnimSync",false];

			//apply cam shake for attack
			if isNullVar(_probEff) then {
				invokeAfterDelayParams(cam_addCamShake,0.15,vec4(0.1,10,0.05,0.2));
			} else {
				if equalTypes(_probEff,[]) then {
					private _eff = _probEff select 0;
					if (_eff == "th") exitWith {
						invokeAfterDelayParams(cam_addCamShake,0.01,vec4(0.2,20,0.06,0.3));
					};
					if (_eff == "sh") exitWith {
						//vec4(0.15,20,0.05,0.5)
						invokeAfterDelayParams(cam_addCamShake,0.01,vec4(0.05,10,0.25,0.3));//3 параметр отдача
					};
				};
			};
		};

		//apply effect for remote players too
		if (equalTypes(_probEff,[])) then {
			_probEff = array_copy(_probEff);
			private _eff = _probEff deleteAt 0;
			if (_eff == "th") then {
				[_eff,_probEff] call interact_th_addTask;
			};
			if (_eff == "sh") then {
				[_eff,_probEff] call interact_th_addTask;
			};
		};

	};
	if equals(_actType,COMBAT_ATTDAM_DAMAGE) exitWith { //damage

		_ctx params ["","","_woundSize","_damageType","_selection"];

		//apply damage particles (blood drop)
		call {
			if (_damageType == WOUND_TYPE_BRUISE) exitWith {

			};
			if (_damageType == WOUND_TYPE_BLEEDING) exitWith {
				[SHOT_MEATSPLAT,_mob,[_selection]] call le_doshot;
			};
			//specials
			//-100 - destroy or loss limb
			if (_damageType == -100) exitWith {
				[SHOT_DESTROYLIMB,_mob,[_selection]] call le_doshot;
			};
		};

		if equals(player,_mob) then {
			//apply cam shake
			INC(_woundSize); //because wound size start at zero
			[
				(0.1 * (_woundSize/5)),
				0.4*(_woundSize*10),
				0.01 * (7/_woundSize),
				random[0.2,0.6,0.7]
			] call cam_addcamshake;
		}
	};
	if equals(_actType,COMBAT_ATTDAM_DODGE) exitWith {
		_ctx params ["","","_side"];
		[_mob,_side] call anim_doDodge;
	};
	if equals(_actType,COMBAT_ATTDAM_PARRY) exitWith {
		_ctx params ["","","_handIdx","_enum"];
		[_mob,_handIdx,_enum] call anim_doParry;
	};
	if equals(_actType,COMBAT_ATTDAM_POINT) exitWith {
		_ctx params ["","","_obj","_pos","_vec"];
		_timeShow = 5;
		//не показывать указатель на цели если слишком далеко
		if ((getPosATL _mob)distance(_pos)>15) then {
			private _posP = _mob modelToWorldVisual ((_mob selectionPosition "head") vectorAdd [0,1.3,0]);
			_vec = vectorNormalized (_posP vectorDiff _pos);
			_pos = _posP;
			_timeShow = 2;
		};
		_arrw = "Sign_Arrow_F" createVehicleLocal [0,0,0];
		_arrw setObjectTexture [0,"#(rgb,8,8,3)color(0.7,0.15,0.05,0.8)"];
		_obj = if not_equalTypes(_obj,objnull) then {
			noe_client_allPointers getOrDefault [_obj,objNUll];
		};
		_arrw setVariable ["defpos",_pos];
		_arrw setVariable ["defvec",_vec];
		_mob setVariable ["__lastarrow_combat_attdam_point__",_arrw];
		startAsyncInvoke
			{
				params ["_obj","_valmax","_valadd","_valcur","_mob"];
				_pos = _obj getVariable "defpos";
				_vec = _obj getVariable "defvec";
				_obj setPosAtl (_pos vectorAdd ((_vec) vectorMultiply (_valcur)));
				_obj setVectorUp (_vec);
				//some math
				_valcur = _valcur + _valadd;
				_this set [3,_valcur];
				_condreset = false;
				if !inRange(_valcur,0,_valmax)then{
					_this set [2,-_valadd];
				};
				
				not_equals(_mob getVariable vec2("__lastarrow_combat_attdam_point__",objNUll),_obj);
			},
			{
				params ["_obj"];
				deleteVehicle _obj
			},
			[_arrw,0.3,0.01,0	,_mob],//speed add, add per frame
			//[_arrw,dv select 0,dv select 1,dv select 2],
			_timeShow,
			{
				params ["_obj"];
				deleteVehicle _obj
			}
		endAsyncInvoke
	};
};

smd_setSlotDataProcessor = {
	params ["_mob","_mode"];
	if (!call smd_isProcessed) exitWith {
		error("smd::setSlotDataProcessor() - smd service disabled");
	};
	private ["_var","_fnc","_srcObj"];

	_mob setVariable [smd_local_prefix+"_isEnabledSMDSlots",_mode];

	{
		_var = _x select 0;
		_fnc = _x select 1;
		if (_mode) then {
			[_mob,_var,_fnc] call smd_onUpdateSetting;
		} else {
			if !isNull(_mob getvariable (smd_local_prefix + _var)) then {

				_srcObj = _mob getvariable (smd_local_prefix + _var + "_obj");
				if !isNullReference(_srcObj) then {
					if (_srcObj call vs_isWorldRadioObject) then {
						[_srcObj] call vs_unloadWorldRadio;
					};
					deleteVehicle _srcObj;
				};
				/*_light = _srcLight getVariable ["__light",objNUll];
				if !isNullReference(_light) then {
					[_srcLight] call le_unloadLight;
				};*/
			};
		};
	} foreach smd_list_allSlots;

};

smd_internal_deleteAttachments_rec = {
	{
		_x call smd_internal_deleteAttachments_rec;
		deleteVehicle _x;
	} foreach (attachedObjects _this);
};

//событие смены предмета в слоте
smd_onChangeSlotData = {
	params ["_mob","_ctx"];

	//Legacy - 0.7.576 fix: after deleted ghosts his attachments not disposed
	if (_mob getvariable ["__loc_smd_deleteslot_handler",-1] == -1) then {
		_mob setvariable ["__loc_smd_deleteslot_handler",
			_mob objectAddEventHandler ["Deleted",{
				params ["_obj"];
				
				{
					if (_x call smd_isSMDObjectInSlot) then {
						_x call smd_internal_deleteAttachments_rec;
						deleteVehicle _x;
					};
				} foreach (attachedObjects _obj);
			}]
		];
	};

	_outVarName = smd_local_prefix + _varName + "_obj"; //external reference
	//delete previous if exists
	_prevObject = _mob getVariable [_outVarName arg objNULL];
	_isPlayer = equals(_mob,player);

	if !isNullReference(_prevObject) then {
		//Updated at 0.7.690
		// - scripted emitters not contains preframe update: addEventOnDestroySource
		if ([_prevObject] call le_isLoadedLight) then {
			[_prevObject] call le_unloadLight;
		};
		
		if (_prevObject call vs_isWorldRadioObject) then {
			[_prevObject] call vs_unloadWorldRadio;
		};
		
		//fix 0.7.358 - shortsword in left hand after disable two-handed mode
		private _prevIDX_TH = _prevObject getVariable "__loc_smd_istwohanded_real_idx";
		if !isNullVar(_prevIDX_TH) then {
			if equals(_prevIDX_TH,INV_HAND_L) then {
				private _objOthr = [_mob,_prevIDX_TH] call smd_getObjectInSlot;
				if !isNullReference(_objOthr) then {
					[_mob,_objOthr,_prevIDX_TH] call proxIt_updateModel;
				};
			};
		};

		deleteVehicle _prevObject;
	};

	//apply hand anim
	if _isPlayer then {
		[_mob] call anim_syncAnim;
	};


	if (
		equals(_ctx,0) ||
		!(_mob getVariable [smd_local_prefix+"_isEnabledSMDSlots",true])
	) exitWith {}; //non item in slot or disabled sync smd slots

	_ctx params ["_model",["_cfgAnim",[-1,-1]],["_cfgLight",-1],["_cfgRadio",-1]];

	if (_model == 'nan') exitWith {}; //никакой конфигурации не существует

	_slotId = parseNumber (_varName select [5,2]);

	_object = objnull;

	//двуручный режим. нужно переаттачить предмет из правой руки в левую
	if (_model == "#TH#") then {
		//предмет в правой руке. нужно переликновать другой
		if equals(_slotId,INV_HAND_R) then {
			private _objOthr = [_mob,INV_HAND_L] call smd_getObjectInSlot;
			[_mob,_objOthr,INV_HAND_R] call proxIt_updateModel;
		};
		_object = [_mob,null,false] call NGOExt_create;
		_object setVariable ["__loc_smd_istwohanded_real_idx",ifcheck(equals(_slotId,INV_HAND_R),INV_HAND_L,INV_HAND_R)];
		_object attachTo [_mob,[0,0,0],proxIt_list_selections select _slotId,true];
		_object setObjectScale 0.00001;
		_object hideObject true;
	} else {
		_object = [_mob,_model,_slotId] call proxIt_loadConfig;

		if (!isNullReference(_object) && _cfgLight != -1) then {
			private _smd_slotId = _slotId;
			[_cfgLight,_object] call le_loadLight;
		};
	};


	//radio setting
	//[int freq, float volume,float canHearUnits, [prob pos.x,..pos.z], float dist, int type]
	if not_equals(_cfgRadio,-1) then {
		//_cfgRadio params ["_freq","_vol","_hearDist",["_pos",[0,0,0]],"_dist","_raType"];
		if isNull(_cfgRadio select 3) then {
			_cfgRadio set [3,[0,0,0]];
		};

		[_object,_cfgRadio,_mob getvariable "voiceptr",_isPlayer] call vs_loadWorldRadio;
	};


	_mob setvariable [_outVarName,_object];
};

//проверяет является ли объект смд слотом
smd_isSMDObjectInSlot = {
	!isNull(_this getvariable "_pit_lastattachdata")
};

smd_onStun = {
	params ["_mob","_ctx"];
};
//проверяет застанен ли персонаж
smd_isStunned = {player getVariable ["smd_isStunned",false]};


smd_onGrabbed = {
	params ["_mob","_ctx"];
	if (_ctx) then {
		_mob setVariable ["__loc_smd_grb_pool",[]];
		_mob setVariable ["__loc_smd_isgrb",true];
	} else {
		//сначала сброс
		_mob setVariable ["__loc_smd_isgrb",false];

		if ((count (_mob getVariable ["__loc_smd_grb_pool",[]])) > 0) then {
			{
				[_x] call interact_removeOnScreenCapturedObject;
				deleteVehicle _x;
			} foreach (_mob getVariable ["__loc_smd_grb_pool",[]]);
			_mob setVariable ["__loc_smd_grb_pool",[]];
		};

		/*if equals(_mob,player) then {
			warningformat("native ground check %1; osfallcheck %2",isTouchingGround _mob arg os_falling_isOnGround);
			if (!isTouchingGround _mob) then {
				//начал падать
				//if os_falling_isOnGround then {
					[_mob] call os_falling_beginFalling;
				//};
			};
		};*/
	};
};

smd_isPulling = {
	params ["_mob"];
	!isNull(_mob getvariable "__loc_pull_ptr");
};
smd_getPullingObjectPtr = {
	params ["_mob"]; 
	_mob getvariable "__loc_pull_ptr"
};

smd_pullSetTransformValues = {
	params ["_mob","_t","_v"];
	_mob setvariable ["_glob_smd_pull_zpos",_t];
	_mob setvariable ["_glob_smd_pull_rot",_v];
};
smd_pullUpdateTransform = {
	params ["_mob","_mode","_val",["_changeMode",true]];
	if (_mode == "zpos") exitWith {
		private _newval = ((_mob getvariable ["_glob_smd_pull_zpos",0])+(_val));
		private _o = call ND_ObjectPull_getHelper;
		private _maxZOffset = _o getvariable "_maxZOffset";
		_newval = clamp(_newval,-_maxZOffset/2,_maxZOffset);
		_mob setvariable ["_glob_smd_pull_zpos",_newval];
	};
	if (_mode == "rot") exitWith {
		_mob setvariable ["_glob_smd_pull_rot",_val];
	};
	errorformat("smd_pullUpdateTransform() - wrong mode %1",_mode);
};
smd_pullGetTransformInfo = {
	params ["_mob"];
	private _tpRet = [_mob getvariable ["_glob_smd_pull_zpos",0],_mob getvariable ["_glob_smd_pull_rot",[0,0,0]]];
	// _mob setvariable ["_glob_smd_pull_zpos",null];
	// _mob setvariable ["_glob_smd_pull_rot",null];
	_tpRet
};

smd_pullGetHeplerObject = {
	params ["_mob"];
	_mob getvariable "__loc_pull_obj" getvariable ["_vtarg",objNull];
};

pulling_canPull = false;
smd_onPull = {
	params ["_mob","_ctx"];
	
	private _syncWalk = {
		//in pull mode we can only walking
		if equals(_mob,player) then {
			_mob call cd_fw_syncForceWalk;
		};
	};
	
	private _releaseResources = {
		private _prevObj = _mob getvariable "__loc_pull_obj";
		if !isNullVar(_prevObj) then {
			private _vtarg = _prevObj getvariable ["_vtarg",objnull];
			if !isNullReference(_vtarg) then {
				deleteVehicle _vtarg;	
			};
			deleteVehicle _prevObj;
			_mob setvariable ["__loc_pull_obj",null];
		};
		_mob setvariable ["__loc_pull_ptr",null];
		if equals(_mob,player) then {
			[_mob,null,null] call smd_pullSetTransformValues;
		};
	};

	if equals(_ctx,0) exitWith {
		call _releaseResources;
		call _syncWalk;
	};

	_ctx params ["_ptr","_model","_offset","_pby","_pullSoundList",["_light",-1]];

	call _releaseResources;

	private _obj = createMesh([_model arg [0 arg 0 arg 0] arg true]);
	_obj setPhysicsCollisionFlag false;
	_obj setPosWorld (atltoasl(getposatl _mob vectoradd _offset));
	[_obj,_pby] call model_SetPitchBankYaw;
	
	_obj setvariable ["_soundPlayed",false];
	_mob setvariable ["__loc_pull_obj",_obj];
	_mob setVariable ["__loc_pull_lastupd",tickTime];
	_mob setVariable ["__loc_pull_ptr",_ptr];

	if equals(_mob,player) then {
		private _vtarg = "Land_VR_CoverObject_01_kneel_F" createVehicleLocal [0,0,0];
		_vtarg setObjectTexture [0,""];
		_vtarg setObjectMaterial [0,""];
		_vtarg setObjectTexture [1,"#(argb,8,8,3)color(1,1,0,1,co)"];//edge colors
		_vtarg disableCollisionWith _mob;
		_obj setvariable ["_vtarg",_vtarg];

		private _bbxDat = (core_modelBBX get (tolower _model));
			if isNullVar(_bbxDat) then {_bbxDat = [[0,0,0],[0,0,0],0];};
			(_bbxDat select 0) params ["_x1","_y1","_z1"];
			(_bbxDat select 1) params ["_x2","_y2","_z2"];
			private _bbxDatAll = [
				[0,0,0],
				[_x1,_y1,_z1],
				[_x1,_y1,_z2],
				[_x1,_y2,_z1],
				[_x1,_y2,_z2],
				[_x2,_y1,_z1],
				[_x2,_y1,_z2],
				[_x2,_y2,_z1],
				[_x2,_y2,_z2]
			];
			private _maxZ = ((abs _z1) + (abs _z2))/2;
			_vtarg setVariable ["_maxZOffset",_maxZ];
			_obj setvariable ["_bbxDatAll",_bbxDatAll];
	};
	
	private _lpp = getPosWorld _obj;
	_mob setVariable ["__loc_pull_lastpos",_lpp];
	_mob setVariable ["__loc_pull_newpos",_lpp];
	_mob setVariable ["__loc_pull_lastVDU",_pby];
	_mob setVariable ["__loc_pull_newVDU",_pby];

	[_obj,_ptr] call NGOExt_registerRef;

	if (equals(_mob,player)) then {
		[_mob,"rot",_pby] call smd_pullUpdateTransform;
	};

	startAsyncInvoke
	{
		params ["_mob","_obj","_offset","_pby","_pullSoundList"];
		
		if isNullReference(_obj) exitWith {true};//forward exit

		_lastSavedPos = _mob getVariable ["__loc_pull_lastpos",null];
		_newSavedPos = atltoasl(getposatl _mob vectoradd _offset);//_mob getVariable ["__loc_pull_newpos",_lastSavedPos];
		assert(_lastSavedPos);
		assert(_newSavedPos);
		_isStop = false;
		_isSelf = equals(_mob,player);
		private _vdu = [_obj] call model_getPitchBankYaw;

		if (_isSelf) then {
			([_mob] call smd_pullGetTransformInfo) params ["_modZ","_modPBY"];
			_vdu = _modPBY;
			MODARR(_newSavedPos,2, + _modZ);
		};

		_lastUpd = _mob getVariable "__loc_pull_lastupd";
		_nextUpd = _lastUpd + 1;
		
		//traceformat("pre %1; post %2", _lastSavedPos arg _newSavedPos)

		_newpos = vectorLinearConversion [
			_lastUpd,
			_nextUpd,
			tickTime,
			_lastSavedPos,
			_newSavedPos,
			true//clamp value
		];
		
		_newvdu = vectorLinearConversion [
			_lastUpd,
			_nextUpd,
			tickTime,
			_mob getVariable "__loc_pull_lastVDU",
			_mob getVariable "__loc_pull_newVDU",
			true
		];
		//traceformat("interp pull dist %1; ---> FROM %2 TO %3; NEWPOS %4",(_lastSavedPos select vec2(0,3)) distance ((_pos select vec2(0,3))) arg _lastSavedPos arg _newSavedPos arg _newpos)
		
		if ((_newpos distance _lastSavedPos) > 0.1 && {!(_obj getvariable "_soundPlayed")}) then {
			_pullSnd = pick _pullSoundList;
			_obj setvariable ["_soundPlayed",true];
			if equals(_mob,player) then {
				[_pullSnd,_newpos,1,getRandomPitchInRange(0.5,1.1),15] call soundGlobal_play;
			};
		};

		_canmove = true;
		_bbxDatAll = _obj getvariable "_bbxDatAll";
		_vtarg = _obj getvariable "_vtarg";
		_vtarg setPosWorld (_newpos vectoradd [0,0,_vtarg getvariable ["pull_interp_zpos_delta",0]]);
		[_vtarg,_newvdu] call model_SetPitchBankYaw; 
		_pbdelt = _vtarg getvariable "pull_interp_pby";
		if !isNullVar(_pbdelt) then {
			[_vtarg,_pbdelt] call model_SetPitchBankYaw;
		};
		_vtarg setObjectScale (1.1 * (boundingBoxReal _obj select 2));
		_upos = getCenterMobPos(_mob);
		_uposASL = atltoasl(_upos);
		_itsCount = 0;
		{
			_its = ([
				_vtarg modelToWorld _x,
				_upos,
				_vtarg,
				_obj
			] call interact_getRayCastData) select 0;
			if !isNullReference(_its) then {
				if equals(_its,_mob) exitWith {};
				INC(_itsCount);
			};
		} foreach _bbxDatAll;
		_canmove = _itsCount <= 4;
		_vtarg setObjectTexture [1,
			if (_canmove) then {"#(argb,8,8,3)color(0,1,0,1,co)"} else {"#(argb,8,8,3)color(1,0.0,0,1,co)"}
		];
		_vtarg setvariable ["canmove",_canmove];
		
		_maxDst = ([0,0,0]distance _offset)*2;
		if ((_newSavedPos distance (_lastSavedPos)) > _maxDst) then {
			_isStop = true;			
			["Сорвалась хватка!","error"] call chatPrint;
		};
		private _dir = _mob getRelDir _obj;
		_isOnFront = (_dir > 315 || _dir <= 45);
		if (!_isOnFront) then {
			_isStop = true;
		};

		if (_isStop && _isSelf) exitWith {
			if ([_mob] call smd_isPulling) then {
				rpcSendToServer("ppc_forceStop",[_mob arg _mob getvariable "__loc_pull_ptr"]);
			};
			true
		};

		if (!_canmove) exitWith {
			_mob setVariable ["__loc_pull_lastpos",getposworld _obj];
			_mob setVariable ["__loc_pull_lastupd",tickTime];
			false
		};

		// _localPos = player worldToModelVisual (asltoatl _newpos);
		// _obj attachTo [player,_localPos];
		_obj setPosWorld _newpos;
		[_obj,
			//ifcheck(_isSelf,_vdu,_newvdu)
			_newvdu
		] call model_SetPitchBankYaw;

		if (tickTime >= _nextUpd) then {
			_obj setvariable ["_soundPlayed",false];
			//_this set [2,tickTime + 0.5];
			_mob setVariable ["__loc_pull_lastpos",_newpos];
			_mob setVariable ["__loc_pull_newpos",_newpos];

			_mob setVariable ["__loc_pull_lastVDU",_newvdu];
			_mob setVariable ["__loc_pull_newVDU",_vdu];
			_mob setVariable ["__loc_pull_lastupd",_nextUpd];

			if equals(_mob,player) then {
				_pbyEx = _newvdu;//!error -> [_obj] call model_getPitchBankYaw;
				_nps = if ([_pbyEx] call model_isSafedirTransform) then {getposatl _obj} else {getposworld _obj};
				rpcSendToServer("snc_ppc",[_mob getvariable "__loc_pull_ptr" arg [_nps arg _pbyEx] arg _newvdu]);
			};
		};
		
		isNullReference(_obj)
	},
	{

	},
	[_mob,_obj,_offset,_pby,_pullSoundList]
	endAsyncInvoke

	call _syncWalk;
};

smd_onPull_old = {
	params ["_mob","_ctx"];
	
	private _syncWalk = {
		//in pull mode we can only walking
		if equals(_mob,player) then {
			_mob call cd_fw_syncForceWalk;
		};
	};

	if equals(_ctx,0) exitWith {
		//stop grab
		private _ptr = _mob getVariable "__loc_pull_ptr";
		if isNullVar(_ptr) exitWith {};
		noe_client_set_lockedPropUpdates deleteAt _ptr;
		
		[_ptr] call noe_client_resetObjectTransform;
		_mob setVariable ["__loc_pull_ptr",null];
		
		private _obj = noe_client_allPointers get _ptr;
		if !isNullReference(_obj) then {
			_obj enableCollisionWith _mob;
		};

		call _syncWalk;
	};
	if (equalTypes(_ctx,"") && {[_ctx,"helper+"] call stringStartWith}) exitWith {
		_mob setVariable ["__loc_pull_ptr",_ctx];
		call _syncWalk;
	};

	_ctx params ["_ptr"];

	private _isSelf = equals(_mob,player); //true if mob is local client
	noe_client_set_lockedPropUpdates set [_ptr,true];

	//"Land_VR_CoverObject_01_kneel_F" - target
	private _vtarg = "Land_VR_CoverObject_01_kneel_F" createVehicleLocal [0,0,0];
	_vtarg setObjectTexture [0,""];
	_vtarg setObjectMaterial [0,""];
	_vtarg setObjectTexture [1,"#(argb,8,8,3)color(1,1,0,1,co)"];//edge colors
	_vtarg disableCollisionWith _mob;

	_mob setVariable ["__loc_pull_vtarg",_vtarg];
	private _pars = [_mob,_ptr,_vtarg,_isSelf];
	_mob setVariable ["__loc_pull_ptr",_ptr];
	call _syncWalk;
	private _obj = noe_client_allPointers get _ptr;
	if isNullVar(_obj) exitWith {
		setLastError("Object not found: " + _ptr);
	};
	
	_vtarg setvariable ["_lastobj",_obj];
	[_obj,_vtarg] call NGOExt_createSoftlink;
	private _lpp = getPosWorld _obj;
	
	_mob setVariable ["__loc_pull_lastpos",_lpp];
	_mob setVariable ["__loc_pull_newpos",_lpp];
	
	_mob setVariable ["__loc_pull_lastVDU",[_obj] call model_getPitchBankYaw];
	_mob setVariable ["__loc_pull_newVDU",[_obj] call model_getPitchBankYaw];

	_mob setVariable ["__loc_pull_lastupd",tickTime];
	startAsyncInvoke
		{
			params ["_pars","_tick"];
			_pars params ["_mob","_ptr","_vtarg","_isSelf"];
			if !([_mob] call smd_isPulling) exitWith {true};

			private _obj = noe_client_allPointers get _ptr;
			if isNullReference(_obj) exitWith {false};
			private _pdat = [_ptr,true] call noe_client_getOrignalObjectData;
			if isNullVar(_pdat) exitWith {false};
			
			_lastobj = _vtarg getvariable ["_lastobj",objnull];
			_needUpdate = not_equals(_lastobj,_obj);
			if (_needUpdate) then {
				_vtarg setvariable ["_lastobj",_obj];
				[_ptr] call noe_client_resetObjectTransform;
			};

			//if (true) exitWith {false}; //todo remove on ready
			//pos, dir,vec
			private _pos = _pdat get "pos";
			//asltoatl
			if (count _pos == 4) then {
				_pos = _pos select [0,3];
			};
			
			_obj disableCollisionWith _mob;

			private _vdu = [_obj] call model_getPitchBankYaw;

			//sync color
			if (_isSelf) then {
				_vtarg setObjectTexture [1,
					if (pulling_canPull) then {"#(argb,8,8,3)color(0,1,0,1,co)"} else {"#(argb,8,8,3)color(1,0.0,0,1,co)"}
				];//edge colors
			};

			/*
				принцип работы:
				1. берется последняя применённая позиция (по умолчанию - исходная)
				2. интерполируется по времени от стартовой до новой. время интерполяции 0.5 (const)
				3. при достижении лимита времени - позиция обновляется
			*/
			_lastSavedPos = _mob getVariable ["__loc_pull_lastpos",_pos];
			_newSavedPos = _mob getVariable ["__loc_pull_newpos",_lastSavedPos];
			assert(_lastSavedPos);
			assert(_newSavedPos);

			_lastUpd = _mob getVariable "__loc_pull_lastupd";
			_nextUpd = _lastUpd + 0.5;
			//traceformat("pre %1; post %2",_lastSavedPos arg _pos)
			_newpos = vectorLinearConversion [
				_lastUpd,
				_nextUpd,
				tickTime,
				_lastSavedPos select [0,3],
				_newSavedPos select [0,3],
				true//clamp value
			];
			_newvdu = vectorLinearConversion [
				_lastUpd,
				_nextUpd,
				tickTime,
				_mob getVariable "__loc_pull_lastVDU",
				_mob getVariable "__loc_pull_newVDU",
				true];
			//traceformat("interp pull dist %1; ---> FROM %2 TO %3; NEWPOS %4",(_lastSavedPos select vec2(0,3)) distance ((_pos select vec2(0,3))) arg _lastSavedPos arg _newSavedPos arg _newpos)
			
			if (tickTime >= _nextUpd) then {
				//_this set [2,tickTime + 0.5];
				_mob setVariable ["__loc_pull_lastpos",_newpos];
				_mob setVariable ["__loc_pull_newpos",_pos];

				_mob setVariable ["__loc_pull_lastVDU",_newvdu];
				_mob setVariable ["__loc_pull_newVDU",_vdu];
				_mob setVariable ["__loc_pull_lastupd",_nextUpd];
			};
			_zdelta = _obj getvariable ["pull_interp_zpos_delta",0];
			_newpos = _newpos vectorAdd [0,0,_zdelta];
			_obj setPosWorld (_newpos);
			
			//[_obj,_newvdu] call model_SetPitchBankYaw;
			//_vtarg setposatl (getposatl _obj);
			if (_isSelf) then {
				//_vtarg setVectorDirAndUp [vectorDirVisual _obj,vectorUpVisual _obj];
				_vtarg attachTo [_obj,[0,0,0]];
				//_vtarg setVectorDirAndUp [vectorDirVisual _obj,vectorUpVisual _obj];
				
				_vtarg setObjectScale (1.1 * (boundingBoxReal _obj select 2));
				detach _vtarg;
			};
			
			isNull(_mob getVariable "__loc_pull_ptr");
		},
		{
			params ["_pars","_tick"];
			_pars params ["_mob","_ptr","_vtarg"];
			traceformat("TERMINATED PULLING %1",_pars)
			deleteVehicle _vtarg;
		},
		[_pars,tickTime]
	endAsyncInvoke
};

//TODO replace to header
#define VISIBILITY_MODE_DEFAULT 0
#define VISIBILITY_MODE_GHOST 1
#define VISIBILITY_MODE_STEALTH 2
#define VISIBILITY_MODE_ADMIN 3
#define VISIBILITY_MODE_CUSTOM 4
//todo change to bitflags
smd_internal_map_vis = createHashMapFromArray [
	[VISIBILITY_MODE_DEFAULT,[VISIBILITY_MODE_DEFAULT]],
	[VISIBILITY_MODE_GHOST,[VISIBILITY_MODE_DEFAULT,VISIBILITY_MODE_GHOST]],
	[VISIBILITY_MODE_ADMIN,[VISIBILITY_MODE_DEFAULT,VISIBILITY_MODE_GHOST,VISIBILITY_MODE_STEALTH,VISIBILITY_MODE_ADMIN]]
];

smd_onVisiblility = {
	params ["_mob","_ctx"];
	_ctx params ["_visLevel",["_customMobs",[]]];
	//_customMobs - ?
	//_visLevel <=: 0 full, 1 ghost, 2 stealth, 3 admin, etc...
	// 

	if equals(_mob,player) then {
		//no act
	} else {
		//hide player, sync smd_allingamemobs-[player]
	};
};

smd_onVisualStates = {
	params ["_mob","_ctx"];

	/*
		Содержит ссылки и типы данных
		1. Выгрузить все
		2. загрузить новые
	*/
	private __LOCAL_PLAYER__ = player;

	private _prevlv = _mob getVariable ["__lv_visstates",[]];
	{
		ifcheck(equalTypes(_x,[]),vec3(_x select 0,_mob,_x select 1),vec2(_x,_mob)) call le_vst_remove;
	} foreach _prevlv;

	{
		ifcheck(equalTypes(_x,[]),vec3(_x select 0,_mob,_x select 1),vec2(_x,_mob)) call le_vst_create;
	} foreach _ctx;
	//do sync data
	_mob setVariable ["__lv_visstates",array_copy(_ctx)];
};

//check if unit have visual state [player,VST_HUMAN_STEALTH] call smd_hasVisualState;
smd_hasVisualState = {
	params ["_mob","_state"];

	((_mob getVariable ["__lv_visstates",[]]) findIf {
		ifcheck(equalTypes(_x,[]),equals(_x select 0,_state),equals(_x,_state))
	}) != 1;
};

smd_onInterpolate = {
	params ["_mob","_data"];
	_data = array_copy(_data);
	private _tick = _data deleteAt 0;
	if ((netTickTime -_tick)>3) exitWith {};
	[_mob,_data] call noe_client_interp_start;
};

smd_onAnimSpeed = {
	params ["_mob","_val"];
	_mob setAnimSpeedCoef _val;
};

smd_getObjectInSlot = {
	params ["_mob","_slot"];

	private _src = _mob getvariable (smd_local_prefix + "smd_s" + str _slot + "_obj");
	if isNull(_src) exitWith {objnull};
	_src
};

smd_getRedirectOnTwoHanded = {
	params ["_mob","_slot"];
	private _obj = _mob getVariable (smd_local_prefix + "smd_s" + str _slot + "_obj");
	if isNull(_obj) exitWith {_slot};
	_obj getVariable ["__loc_smd_istwohanded_real_idx",_slot]
};

smd_reloadMobsLighting = {
	{
		_mob = _x;

		{

			_var = _x select 0;
			if !isNull(_mob getvariable (smd_local_prefix + _var)) then {
				_fnc = _x select 1;
				_srcLight = _mob getvariable (smd_local_prefix + _var + "_obj");
				_light = _srcLight getVariable ["__light",objNUll];
				if !isNullReference(_light) then {
					[_srcLight] call le_unloadLight;
				};
				[_mob,_var,_fnc] call smd_onUpdateSetting;
			};

		} foreach smd_list_allSlots;


	} foreach smd_allInGameMobs;
};

smd_createOffGeom = {
	params ["_user","_srcObj","_oGeom"];
	startAsyncInvoke
	{
		params ["_user","_srcObj","_oGeom"];
		
		if isNullReference(_user) exitWith {true};
		if isNullReference(_srcObj) exitWith {true};
		if isNullReference(_oGeom) exitWith {true};

		//get relative position
		_srcPos = asltoatl getPosWorld _srcObj;
		_srcTransf = [vectorDirVisual _srcObj,vectorUpVisual _srcObj];
		_srcScale = getObjectScale _srcObj;
		_localPos = _user worldToModelVisual _srcPos;
		
		//hack for disabling roadway lod
		_oGeom attachTo [_user,_localPos];
		_oGeom setVectorDirAndUp _srcTransf;
		_oGeom setObjectScale _srcScale;
		
		false
	},
	{},
	[_user,_srcObj,_oGeom]
	endAsyncInvoke
};

smd_onChatMessage = {
	params ["_mob","_ctx"];
	
	//CTX:vec3: message(string),distance(int),addedNetTime(floag)

	//no local player processing
	//if equals(_mob,player) exitwith {
		(_mob getvariable ["__local_mob_voiceblobParams",[
			"undeclared",1,0.5,1
		]]) params ["_voiceType","_basePitch","_baseSpeed","_pertick"];
	//};
	private _v3data = vec3(_ctx select 0,_ctx select 1,tickTime); //data is vec3 mes,distance,adddate
	private _addedNetTime = _ctx select 2;
	private _doNotPlayBlob = false;
	//time too long
	if (netTickTime >= (
		([_mob,_v3data select 0] call chatos_getTimeText)
		+ _addedNetTime + chatos_postMessageVisibleDelay //!!Время видимости дополнительное
	)) then {
		_v3data set [2,0];
		_doNotPlayBlob = true;
	};

	if (_voiceType != "undeclared") then {
		if (_doNotPlayBlob) exitWith {};

		[_mob,_ctx select 0,_ctx select 1,
			_voiceType,_basePitch,_baseSpeed,_pertick
		] call chatos_actBlob;
	};

	_mob setVariable ["__local_mob_onchatmessage",_v3data];
};

//["_voiceType","_basePitch","_baseSpeed"]
smd_onVoiceBlobInit = {
	params ["_mob","_ctx"];
	_mob setvariable ["__local_mob_voiceblobParams",_ctx];
};

smd_onIsPrintingSay = {
	params ["_mob","_ctx"];
	
	//событие вызывается когда персонаж открывает окно печати текста
	_mob setvariable ["__local_mob_isprinting",_ctx];
};