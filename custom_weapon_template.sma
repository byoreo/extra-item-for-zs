#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieswarm>

/* ~ [ Weapon Resources ] ~ */
new const WEAPON_MODEL_VIEW[] = "models/x.mdl";
new const WEAPON_MODEL_PLAYER[] = "models/x.mdl";
new const WEAPON_MODEL_WORLD[] = "models/x.mdl";

new const WEAPON_REFERENCE[] = "weapon_x";
const WEAPON_SPECIAL_CODE = x;

const WEAPON_BPAMMO = x;
const WEAPON_AMMO = x;

/* ~ [ Weapon Primary Attack ] ~ */
new const WEAPON_SHOOT_SOUND[] = "weapons/x.wav";
const Float: WEAPON_SHOOT_RATE = x.x;
const Float: WEAPON_SHOOT_PUNCHANGLE = x.x;
const Float: WEAPON_SHOOT_DAMAGE = x.x;

/* ~ [ Weapon Muzzleflash ] ~ */
#define CUSTOM_MUZZLEFLASH_ENABLED

#if defined CUSTOM_MUZZLEFLASH_ENABLED
new const ENTITY_MUZZLE_CLASSNAME[] = "x";
new const ENTITY_MUZZLE_SPRITE[] = "sprites/x.spr";

const Float: ENTITY_MUZZLE_NEXTTHINK = x.x;
#endif

/* ~ [ Animations Settings ] ~ */
const Float: WEAPON_ANIM_IDLE_TIME = x.x;
const Float: WEAPON_ANIM_RELOAD_TIME = x.x;
const Float: WEAPON_ANIM_DRAW_TIME = x.x;
const Float: WEAPON_ANIM_SHOOT_TIME = x.x;

enum _: iWeaponAnims
{
	WEAPON_ANIM_IDLE = 0,
	WEAPON_ANIM_RELOAD,
	WEAPON_ANIM_DRAW,
	WEAPON_ANIM_SHOOT
}

/* ~ [ Weapon List ] ~ */
new const WEAPON_WEAPONLIST[] = "weapon_x";
new const iWeaponList[] = { x, x, x, x, x, x, x, x };
// https://wiki.alliedmods.net/CS_WeaponList_Message_Dump
 
/* ~ [ Conditions ] ~ */
#define IsCustomWeapon(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define IsPdataSafe(%0) (pev_valid(%0) == 2)

/* ~ [ Offsets ] ~ */
const m_iClip = 51;
const linux_diff_player = 5;
const linux_diff_weapon = 4;
const m_rpgPlayerItems = 367;
const m_pNext = 42
const m_iId = 43;
const m_iPrimaryAmmoType = 49;
const m_rgAmmo = 376;
const m_flNextAttack = 83;
const m_flTimeWeaponIdle = 48;
const m_maxFrame = 35;
const m_flNextPrimaryAttack = 46;
const m_flNextSecondaryAttack = 47;
const m_pPlayer = 41;
const m_fInReload = 54;
const m_pActiveItem = 373;
const m_rgpPlayerItems_iWeaponBox = 34;

new item_id;

/* ~ [ Global Parameters ] ~ */
new HamHook: gl_HamHook_TraceAttack[4],

    gl_iszAllocString_Entity,
    gl_iszAllocString_ModelView,
    gl_iszAllocString_ModelPlayer,

    #if defined CUSTOM_MUZZLEFLASH_ENABLED
    gl_iszAllocString_MuzzleFlash,
    #endif

    gl_iMsgID_Weaponlist;

/* ~ [ AMX Mod X ] ~ */
public plugin_init()
{
    register_plugin("Custom Weapon Template", "2.1", "Cristian505 \ Batcoh: Code Base");
    // Created & tested in AMX Mod X 1.9.0 on 11/4/2023.

    // Fakemeta
    register_forward(FM_UpdateClientData,    "FM_Hook_UpdateClientData_Post",      true);
    register_forward(FM_SetModel,            "FM_Hook_SetModel_Pre",              false);

    // Hamsandwich
    RegisterHam(Ham_Item_Deploy,            WEAPON_REFERENCE,    "CWeapon__Deploy_Post",           true);
    RegisterHam(Ham_Weapon_PrimaryAttack,   WEAPON_REFERENCE,    "CWeapon__PrimaryAttack_Pre",    false);
    RegisterHam(Ham_Weapon_Reload,          WEAPON_REFERENCE,	 "CWeapon__Reload_Pre",           false);
    RegisterHam(Ham_Item_PostFrame,         WEAPON_REFERENCE,	 "CWeapon__PostFrame_Pre",        false);
    RegisterHam(Ham_Item_Holster,           WEAPON_REFERENCE,	 "CWeapon__Holster_Post",          true);
    RegisterHam(Ham_Item_AddToPlayer,       WEAPON_REFERENCE,    "CWeapon__AddToPlayer_Post",      true);

    // Trace Attack
    gl_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,    "func_breakable",    "CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,	"info_target",	     "CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,	"player",            "CEntity__TraceAttack_Pre",  false);
    gl_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,	"hostage_entity",    "CEntity__TraceAttack_Pre",  false);

    #if defined CUSTOM_MUZZLEFLASH_ENABLED
    RegisterHam(Ham_Think,					"env_sprite",		"CMuzzleFlash__Think_Pre", false);
    #endif

    // Alloc String
    gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
    gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
    gl_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);

    #if defined CUSTOM_MUZZLEFLASH_ENABLED
    gl_iszAllocString_MuzzleFlash = engfunc(EngFunc_AllocString, ENTITY_MUZZLE_CLASSNAME);
    #endif

    // Messages
    gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");

    // Ham Hook
    fm_ham_hook(false);

    // Commands
    item_id = zs_register_item("itemname", 3500); //item name and item cost
}

public plugin_precache()
{
    // Precache Models
    engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
    engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
    engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);

    // Precache Sprites
    #if defined CUSTOM_MUZZLEFLASH_ENABLED
    engfunc(EngFunc_PrecacheModel, ENTITY_MUZZLE_SPRITE);
    #endif

    // Precache Sounds
    engfunc(EngFunc_PrecacheSound, WEAPON_SHOOT_SOUND);

    // Precache generic
    new szWeaponList[128]; formatex(szWeaponList, charsmax(szWeaponList), "sprites/%s.txt", WEAPON_WEAPONLIST);
    engfunc(EngFunc_PrecacheGeneric, szWeaponList);

    // Hook weapon
    register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");
}

/* ~ [ Commands ] ~ */
public Command_HookWeapon(iPlayer)
{
    engclient_cmd(iPlayer, WEAPON_REFERENCE);
    return PLUGIN_HANDLED;
}

public zs_item_selected(id, item){
	if(item_id == item){
		Command_GiveWeapon(id);
	}
}

public Command_GiveWeapon(iPlayer)
{
    static iWeapon; iWeapon = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Entity);
    if(!IsPdataSafe(iWeapon)) return FM_NULLENT;

    set_pev(iWeapon, pev_impulse, WEAPON_SPECIAL_CODE);
    ExecuteHam(Ham_Spawn, iWeapon);
    set_pdata_int(iWeapon, m_iClip, WEAPON_AMMO, linux_diff_weapon);
    UTIL_DropWeapon(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iWeapon));

    if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iWeapon))
    {
	set_pev(iWeapon, pev_flags, pev(iWeapon, pev_flags) | FL_KILLME);
	return 0;
    }

    ExecuteHamB(Ham_Item_AttachToPlayer, iWeapon, iPlayer);
    UTIL_WeaponList(iPlayer, true);

    static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iWeapon, m_iPrimaryAmmoType, linux_diff_weapon);

    set_pdata_int(iPlayer, iAmmoType, WEAPON_BPAMMO, linux_diff_player);

    emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    return 1;
}

/* ~ [ Hamsandwich ] ~ */
public CWeapon__Deploy_Post(iWeapon)
{
    if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return;

    static iPlayer; iPlayer = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);

    set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
    set_pev_string(iPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayer);

    UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW);

    set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
    set_pdata_float(iWeapon, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
}

public CWeapon__PrimaryAttack_Pre(iWeapon)
{
    if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return HAM_IGNORED;

    static iAmmo; iAmmo = get_pdata_int(iWeapon, m_iClip, linux_diff_weapon);
    if(!iAmmo)
    {
        ExecuteHam(Ham_Weapon_PlayEmptySound, iWeapon);
        set_pdata_float(iWeapon, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

        return HAM_SUPERCEDE;
    }

    static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
    static fw_PlayBackEvent; fw_PlayBackEvent = register_forward(FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false);
    fm_ham_hook(true);		

    ExecuteHam(Ham_Weapon_PrimaryAttack, iWeapon);
		
    unregister_forward(FM_TraceLine, fw_TraceLine, true);
    unregister_forward(FM_PlaybackEvent, fw_PlayBackEvent);
    fm_ham_hook(false);

    static iPlayer; iPlayer = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);

    static Float: vecPunchangle[3];
    pev(iPlayer, pev_punchangle, vecPunchangle);
    vecPunchangle[0] *= WEAPON_SHOOT_PUNCHANGLE
    vecPunchangle[1] *= WEAPON_SHOOT_PUNCHANGLE
    vecPunchangle[2] *= WEAPON_SHOOT_PUNCHANGLE
    set_pev(iPlayer, pev_punchangle, vecPunchangle);

    UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT);

    #if defined CUSTOM_MUZZLEFLASH_ENABLED
    UTIL_CreateMuzzleFlash(iPlayer, ENTITY_MUZZLE_SPRITE, random_float(0.05, 0.06), 150.0, 1);
    #endif

    emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SHOOT_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    set_pdata_float(iPlayer, m_flNextAttack, WEAPON_SHOOT_RATE, linux_diff_player);
    set_pdata_float(iWeapon, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);
    set_pdata_float(iWeapon, m_flNextPrimaryAttack, WEAPON_SHOOT_RATE, linux_diff_weapon);
    set_pdata_float(iWeapon, m_flNextSecondaryAttack, WEAPON_SHOOT_RATE, linux_diff_weapon);

    return HAM_SUPERCEDE;
}

public CWeapon__Reload_Pre(iWeapon)
{
    if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return HAM_IGNORED;

    static iAmmo; iAmmo = get_pdata_int(iWeapon, m_iClip, linux_diff_weapon);
    if(iAmmo >= WEAPON_AMMO) return HAM_SUPERCEDE;

    static iPlayer; iPlayer = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);
    static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iWeapon, m_iPrimaryAmmoType, linux_diff_weapon);

    if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

    set_pdata_int(iWeapon, m_iClip, 0, linux_diff_weapon);
    ExecuteHam(Ham_Weapon_Reload, iWeapon);
    set_pdata_int(iWeapon, m_iClip, iAmmo, linux_diff_weapon);
    set_pdata_int(iWeapon, m_fInReload, 1, linux_diff_weapon);

    UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_RELOAD);

    set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_player);
    set_pdata_float(iWeapon, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
    set_pdata_float(iWeapon, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
    set_pdata_float(iWeapon, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);

    return HAM_SUPERCEDE;
}

public CWeapon__PostFrame_Pre(iWeapon)
{ 
    if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return HAM_IGNORED;

    static iClip; iClip = get_pdata_int(iWeapon, m_iClip, linux_diff_weapon);
    if(get_pdata_int(iWeapon, m_fInReload, linux_diff_weapon) == 1)
    {
        static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iWeapon, m_iPrimaryAmmoType, linux_diff_weapon);
        static iPlayer; iPlayer = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);
        static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
        static j; j = min(WEAPON_AMMO - iClip, iAmmo);
        
        set_pdata_int(iWeapon, m_iClip, iClip + j, linux_diff_weapon);
        set_pdata_int(iPlayer, iAmmoType, iAmmo - j, linux_diff_player);
        set_pdata_int(iWeapon, m_fInReload, 0, linux_diff_weapon);
    }

    return HAM_IGNORED;
}

public CWeapon__Holster_Post(iWeapon)
{
    if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return;

    static iPlayer; iPlayer = get_pdata_cbase(iWeapon, m_pPlayer, linux_diff_weapon);

    set_pdata_float(iWeapon, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
    set_pdata_float(iWeapon, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
    set_pdata_float(iWeapon, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
    set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);

    #if defined CUSTOM_MUZZLEFLASH_ENABLED
    new pMuzzleFlash = FM_NULLENT;

    while((pMuzzleFlash = fm_find_ent_by_owner(pMuzzleFlash, ENTITY_MUZZLE_CLASSNAME, iPlayer)) > 0)
    if(IsPdataSafe(pMuzzleFlash)) set_pev(pMuzzleFlash, pev_flags, FL_KILLME);
    #endif
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float: flDamage)
{
    if(!is_user_connected(iAttacker)) return;
	
    static iWeapon; iWeapon = get_pdata_cbase(iAttacker, 373, 5);
    if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return;

    flDamage *= WEAPON_SHOOT_DAMAGE
    SetHamParamFloat(3, flDamage);
}

public CWeapon__AddToPlayer_Post(iWeapon, iPlayer)
{
    if(IsPdataSafe(iWeapon) && IsCustomWeapon(iWeapon)) UTIL_WeaponList(iPlayer, true);
    else if(!pev(iWeapon, pev_impulse)) UTIL_WeaponList(iPlayer, false);
}

public fm_ham_hook(bool: bEnabled)
{
    if(bEnabled)
    {
	EnableHamForward(gl_HamHook_TraceAttack[0]);
	EnableHamForward(gl_HamHook_TraceAttack[1]);
	EnableHamForward(gl_HamHook_TraceAttack[2]);
	EnableHamForward(gl_HamHook_TraceAttack[3]);
    }
    else 
    {
	DisableHamForward(gl_HamHook_TraceAttack[0]);
	DisableHamForward(gl_HamHook_TraceAttack[1]);
	DisableHamForward(gl_HamHook_TraceAttack[2]);
	DisableHamForward(gl_HamHook_TraceAttack[3]);
    }
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
    if(!is_user_alive(iPlayer)) return;

    static iWeapon; iWeapon = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
    if(!IsPdataSafe(iWeapon) || !IsCustomWeapon(iWeapon)) return;

    set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(iEntity)
{
    static i, szClassName[32], iWeapon;
    pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

    if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

    for(i = 0; i < 6; i++)
    {
        iWeapon = get_pdata_cbase(iEntity, m_rgpPlayerItems_iWeaponBox + i, linux_diff_weapon);
		
        if(IsPdataSafe(iWeapon) && IsCustomWeapon(iWeapon))
        {
            engfunc(EngFunc_SetModel, iEntity, WEAPON_MODEL_WORLD);
            return FMRES_SUPERCEDE;
        }
    }

    return FMRES_IGNORED;
}

public FM_Hook_PlaybackEvent_Pre() return FMRES_SUPERCEDE;
public FM_Hook_TraceLine_Post(const Float: vecOrigin1[3], const Float: vecOrigin2[3], iFlags, iAttacker, iTrace)
{
    if(iFlags & IGNORE_MONSTERS) return FMRES_IGNORED;
    if(!is_user_alive(iAttacker)) return FMRES_IGNORED;

    static pHit; pHit = get_tr2(iTrace, TR_pHit);
    static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);

    if(pHit > 0) if(pev(pHit, pev_solid) != SOLID_BSP) return FMRES_IGNORED;

    engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEndPos, 0);
    write_byte(TE_WORLDDECAL);
    engfunc(EngFunc_WriteCoord, vecEndPos[0]);
    engfunc(EngFunc_WriteCoord, vecEndPos[1]);
    engfunc(EngFunc_WriteCoord, vecEndPos[2]);
    write_byte(random_num(41, 45));
    message_end();
	
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_STREAK_SPLASH);
    engfunc(EngFunc_WriteCoord, vecEndPos[0]);
    engfunc(EngFunc_WriteCoord, vecEndPos[1]);
    engfunc(EngFunc_WriteCoord, vecEndPos[2]);
    write_coord(random_num(-20, 20));
    write_coord(random_num(-20, 20));
    write_coord(random_num(-20, 20)); 
    write_byte(5);
    write_short(70);
    write_short(3);
    write_short(75);
    message_end();

    return FMRES_IGNORED;
}

/* ~ [ Entity ] ~ */
#if defined CUSTOM_MUZZLEFLASH_ENABLED
public CMuzzleFlash__Think_Pre(iSprite)
{
    if(!IsPdataSafe(iSprite)) return HAM_IGNORED;
    if(pev(iSprite, pev_classname) == gl_iszAllocString_MuzzleFlash)
    {
        static Float: flFrame;
        if(pev(iSprite, pev_frame, flFrame) && ++flFrame - 1.0 < get_pdata_float(iSprite, m_maxFrame, linux_diff_weapon))
        {
            set_pev(iSprite, pev_frame, flFrame);
            set_pev(iSprite, pev_nextthink, get_gametime() + ENTITY_MUZZLE_NEXTTHINK);
				
            return HAM_SUPERCEDE;
        }

        set_pev(iSprite, pev_flags, FL_KILLME);
        return HAM_SUPERCEDE;
    }

    return HAM_IGNORED;
}
#endif

/* ~ [ Stocks ] ~ */
stock UTIL_SendWeaponAnim(const iPlayer, const iAnim)
{
    set_pev(iPlayer, pev_weaponanim, iAnim);

    message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
    write_byte(iAnim);
    write_byte(0);
    message_end();
}

stock UTIL_DropWeapon(const iPlayer, const iSlot)
{
    static iEntity, iNext, szWeaponName[32];
    iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot, linux_diff_player);

    if(iEntity > 0)
    {       
        do 
        {
            iNext = get_pdata_cbase(iEntity, m_pNext, linux_diff_weapon);
            if(get_weaponname(get_pdata_int(iEntity, m_iId, linux_diff_weapon), szWeaponName, charsmax(szWeaponName)))
            engclient_cmd(iPlayer, "drop", szWeaponName);
        } 
		
        while((iEntity = iNext) > 0);
    }
}

#if defined CUSTOM_MUZZLEFLASH_ENABLED
stock UTIL_SetTransparency(iSprite, iRendermode, Float: flAmt, iFx = kRenderFxNone)
{
    set_pev(iSprite, pev_rendermode, iRendermode);
    set_pev(iSprite, pev_renderamt, flAmt);
    set_pev(iSprite, pev_renderfx, iFx);
}

stock UTIL_CreateMuzzleFlash(iPlayer, const szMuzzleSprite[], Float: flScale, Float: flBrightness, iAttachment)
{
    #define ENTITY_SPRITES_INTOLERANCE 100
    if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < ENTITY_SPRITES_INTOLERANCE) return FM_NULLENT;
		
    static iSprite, iszAllocStringCached;
    if(iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "env_sprite")))
    iSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
		
    if(!IsPdataSafe(iSprite)) return FM_NULLENT;
		
    set_pev(iSprite, pev_model, szMuzzleSprite);
    set_pev(iSprite, pev_spawnflags, SF_SPRITE_ONCE);
		
    set_pev_string(iSprite, pev_classname, gl_iszAllocString_MuzzleFlash);
    set_pev(iSprite, pev_owner, iPlayer);
    set_pev(iSprite, pev_aiment, iPlayer);
    set_pev(iSprite, pev_body, iAttachment);
		
    UTIL_SetTransparency(iSprite, kRenderTransAdd, flBrightness);
    set_pev(iSprite, pev_scale, flScale);
		
    dllfunc(DLLFunc_Spawn, iSprite);

    return iSprite;
}
#endif

stock UTIL_WeaponList(const iPlayer, bool: bEnabled)
{
    message_begin(MSG_ONE, gl_iMsgID_Weaponlist, _, iPlayer);
    write_string(bEnabled ? WEAPON_WEAPONLIST : WEAPON_REFERENCE);
    write_byte(iWeaponList[0]);
    write_byte(bEnabled ? WEAPON_AMMO : iWeaponList[1]);
    write_byte(iWeaponList[2]);
    write_byte(iWeaponList[3]);
    write_byte(iWeaponList[4]);
    write_byte(iWeaponList[5]);
    write_byte(iWeaponList[6]);
    write_byte(iWeaponList[7]);
    message_end();
}
