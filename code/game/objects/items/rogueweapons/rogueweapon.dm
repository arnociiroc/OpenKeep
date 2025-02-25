// ===== WEAPON DAMAGE DEFINES =======
#define DAMAGE_AXE 20
#define DAMAGE_AXE_WIELD 25
#define DAMAGE_HEAVYAXE_WIELD 30
#define DAMAGE_BAD_AXE 13
#define DAMAGE_BAD_AXE_WIELD 18

#define DAMAGE_WEAK_FLAIL 17
#define DAMAGE_NORMAL_FLAIL 23
#define DAMAGE_GOOD_FLAIL 28

#define DAMAGE_CLUB 15
#define DAMAGE_CLUB_WIELD 20
#define DAMAGE_MACE 20
#define DAMAGE_MACE_WIELD 25
#define DAMAGE_HEAVYCLUB_WIELD 30

#define DAMAGE_WEAK_KNIFE 8
#define DAMAGE_KNIFE 10
#define DAMAGE_DAGGER 12
#define DAMAGE_GOOD_DAGGER 14

#define DAMAGE_STAFF 12
#define DAMAGE_STAFF_WIELD 23 //Even a wooden quarterstaff is a devastating weapon.
#define DAMAGE_SPEAR 15
#define DAMAGE_SPEARPLUS 18
#define DAMAGE_SPEAR_WIELD 25
#define DAMAGE_HALBERD_WIELD 35

#define DAMAGE_SHORTSWORD 16
#define DAMAGE_SWORD 20
#define DAMAGE_SWORD_WIELD 25
#define DAMAGE_LONGSWORD_WIELD 28
#define DAMAGE_GREATSWORD_WIELD 35

#define DAMAGE_WHIP 20

// ===== AP DEFINES =======
#define AP_AXE_CUT 10
#define AP_AXE_CHOP 15
#define AP_HEAVYAXE_CHOP 25
#define AP_HEAVYAXE_STAB 35

#define AP_FLAIL_STRIKE 5
#define AP_FLAIL_SMASH 60
#define AP_CLUB_STRIKE 25
#define AP_CLUB_SMASH 35
#define AP_HEAVY_SMASH 45

#define AP_SPEAR_POKE 20
#define AP_POLEARM_THRUST 45
#define AP_POLEARM_BASH 5
#define AP_POLEARM_CHOP 30 //Slightly less AP than a heavy axe's chop, still represents the ease with which a halberd or similar chop could get through earlier maille.

#define AP_SWORD_THRUST 20
#define AP_SWORD_CHOP 5
#define AP_SABRE_CUT 18
#define AP_SABRE_CHOP 13
#define AP_RAPIER_THRUST 30

#define AP_DAGGER_STAB 30
#define AP_DAGGER_PICK 40
#define AP_PICK 45

//wdefense defines
#define TERRIBLE_PARRY -1
#define BAD_PARRY 0
#define MEDIOCRE_PARRY 1
#define AVERAGE_PARRY 2
#define GOOD_PARRY 2.5
#define GREAT_PARRY 3
#define ULTMATE_PARRY 4

//wbalance defines
#define VERY_EASY_TO_DODGE -2
#define EASY_TO_DODGE -1
#define DODGE_CHANCE_NORMAL 0
#define HARD_TO_DODGE 1
#define VERY_HARD_TO_DODGE 2

/obj/item/rogueweapon
	name = ""
	desc = ""
	icon_state = "sabre"
	icon = 'icons/roguetown/weapons/32.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/rogue_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/rogue_righthand.dmi'
	force = 15
	throwforce = 10
	w_class = WEIGHT_CLASS_NORMAL
	block_chance = 0
	armor_penetration = 5
	sharpness = IS_SHARP
	custom_materials = null
	possible_item_intents = list(SWORD_CUT, SWORD_THRUST)
	can_parry = TRUE
	wlength = 45
	sellprice = 1
	has_inspect_verb = TRUE
	pickup_sound = "rustle" // Sound list define strings are in code/game/sound.dm
	parrysound = list('sound/combat/parry/parrygen.ogg')
	drop_sound = 'sound/foley/dropsound/mace_drop.ogg'
	anvilrepair = /datum/skill/craft/weaponsmithing
	obj_flags = CAN_BE_HIT
	blade_dulling = DULLING_BASH
	resistance_flags = FIRE_PROOF
	max_integrity = 200
	wdefense = 3
	experimental_onhip = TRUE
	experimental_onback = TRUE
	embedding = list(
		"embed_chance" = 0, //Leave this at 0 until embed code is given an overhaul. Ideally each weapon should have a different value. Doesn't affect ranged or things like mantraps.
		"embedded_pain_multiplier" = 1,
		"embedded_fall_chance" = 0,
	)
	var/initial_sl
	var/list/possible_enhancements
	var/renamed_name
	var/axe_cut = 0
	istrainable = TRUE // You can train weapon skills on a dummy with these.

/obj/item/rogueweapon/Initialize()
	. = ..()
	if(!destroy_message)
		var/yea = pick("[src] is broken!", "[src] is useless!", "[src] is destroyed!")
		destroy_message = "<span class='warning'>[yea]</span>"

/obj/item/rogueweapon/get_dismemberment_chance(obj/item/bodypart/affecting, mob/user)
	if(!get_sharpness() || !affecting.can_dismember(src))
		return 0

	var/total_dam = affecting.get_damage()
	var/nuforce = get_complex_damage(src, user)
	var/pristine_blade = TRUE
	if(max_blade_int && dismember_blade_int)
		var/blade_int_modifier = (blade_int / dismember_blade_int)
		//blade is about as sharp as a brick it won't dismember shit
		if(blade_int_modifier <= 0.15)
			return 0
		nuforce *= blade_int_modifier
		pristine_blade = (blade_int >= (dismember_blade_int * 0.95))

	if(user)
		if(istype(user.rmb_intent, /datum/rmb_intent/weak))
			nuforce = 0
		else if(istype(user.rmb_intent, /datum/rmb_intent/strong))
			nuforce *= 1.1

		if(user.used_intent.blade_class == BCLASS_CHOP) //chopping attacks always attempt dismembering
			nuforce *= 1.1
		else if(user.used_intent.blade_class == BCLASS_CUT)
			if(!pristine_blade && (total_dam < affecting.max_damage * 0.8))
				return 0
		else
			return 0

	if(nuforce < 20) //End force needs to be at least this high, after accounting for strong intent and chop. An iron messer should be able to do it, but not a dagger.
		return 0

	var/probability = (nuforce * (total_dam / affecting.max_damage) - 5) //More weight given to total damage accumulated on the limb
	if(affecting.body_zone == BODY_ZONE_HEAD) //Decapitations are harder to pull off in general
		probability *= 0.5
	var/hard_dismember = HAS_TRAIT(affecting, TRAIT_HARDDISMEMBER)
	var/easy_dismember = affecting.rotted || affecting.skeletonized || HAS_TRAIT(affecting, TRAIT_EASYDISMEMBER)
	if(affecting.owner)
		if(!hard_dismember)
			hard_dismember = HAS_TRAIT(affecting.owner, TRAIT_HARDDISMEMBER)
		if(!easy_dismember)
			easy_dismember = HAS_TRAIT(affecting.owner, TRAIT_EASYDISMEMBER)
	if(hard_dismember)
		return min(probability, 5)
	else if(easy_dismember)
		return probability * 2.0
	return probability
