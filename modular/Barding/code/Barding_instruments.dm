
/obj/item/rogue/instrument
	name = ""
	desc = ""
	icon = 'modular/Barding/icons/music.dmi'
	icon_state = ""
	lefthand_file = 'modular/Barding/icons/instruments_lefthand.dmi'
	righthand_file = 'modular/Barding/icons/instruments_righthand.dmi'
	experimental_inhand = FALSE
	possible_item_intents = list(/datum/intent/use)
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_BACK_R|ITEM_SLOT_BACK_L
	can_parry = FALSE
	force = 0
	minstr = 0
	wbalance = 0
	wdefense = 0
	throwforce = 0
	throw_range = 4
	blade_dulling = DULLING_BASH
	max_integrity = 100 // Flimsy instruments of wood.
	destroy_message = "falls apart!"
	dropshrink = 0.8
	var/datum/looping_sound/dmusloop/soundloop
	var/list/song_list = list()
	var/playing = FALSE
	var/dynamic_icon
	var/icon_prefix

/obj/item/rogue/instrument/equipped(mob/living/user, slot)
	. = ..()
	if(playing && user.get_active_held_item() != src)
		playing = FALSE
		soundloop.stop()
		user.remove_status_effect(/datum/status_effect/buff/playing_music)
	// Prevents an exploit
	for(var/mob/living/carbon/L in viewers(7))
		var/mob/living/carbon/buffed = L
		if(buffed.mind?.has_antag_datum(/datum/antagonist))
			if(buffed.mind?.isactuallygood())
				for(var/datum/status_effect/bardicbuff/b in L.status_effects)
					buffed.remove_status_effect(b)
			else
				return
		else
			for(var/datum/status_effect/bardicbuff/b in L.status_effects)
				buffed.remove_status_effect(b)

/obj/item/rogue/instrument/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.4,"sx" = 0,"sy" = 2,"sx" = 0,"sy" = 2,"wx" = -1,"wy" = 2,"ex" = 5,"ey" = 1,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 8,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("onbelt")
				return list("shrink" = 0.3,"sx" = -2,"sy" = -5,"nx" = 4,"ny" = -5,"wx" = 0,"wy" = -5,"ex" = 2,"ey" = -5,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0)

/obj/item/rogue/instrument/Initialize()
	soundloop = new(src, FALSE)
	. = ..()

/obj/item/rogue/instrument/dropped(mob/living/user, silent)
	..()
	if(soundloop)
		soundloop.stop()
		user.remove_status_effect(/datum/status_effect/buff/playing_music)
	// Prevents an exploit
	for(var/mob/living/carbon/L in viewers(7))
		var/mob/living/carbon/buffed = L
		if(buffed.mind?.has_antag_datum(/datum/antagonist))
			if(buffed.mind?.isactuallygood())
				for(var/datum/status_effect/bardicbuff/b in L.status_effects)
					buffed.remove_status_effect(b)
			else
				return
		else
			for(var/datum/status_effect/bardicbuff/b in L.status_effects)
				buffed.remove_status_effect(b)

/obj/item/rogue/instrument/attack_self(mob/living/user)
	var/stressevent = /datum/stressevent/music
	var/bardbonus = /datum/stressevent/bardicbuff
	. = ..()
	if(.)
		return
	user.changeNext_move(CLICK_CD_MELEE)
	if(!playing)
		var/note_color = "#7f7f7f" // uses MMO item rarity color grading
		var/curfile = input(user, "Which song do you want to play?", "Pick a song", name) as null|anything in song_list
		if(!user)
			return
		if(user.mind)
			soundloop.stress2give = null
			switch(user.mind.get_skill_level(/datum/skill/misc/music))
				if(1)
					stressevent = /datum/stressevent/music
				if(2)
					stressevent = /datum/stressevent/music/two
					note_color = "#ffffff"
				if(3)
					stressevent = /datum/stressevent/music/three
					note_color = "#1eff00"
				if(4)
					stressevent = /datum/stressevent/music/four
					note_color = "#0070dd"
				if(5)
					stressevent = /datum/stressevent/music/five
					note_color = "#a335ee"
				if(6)
					stressevent = /datum/stressevent/music/six
					note_color = "#ff8000"

		if(playing)
			playing = FALSE
			soundloop.stop()
			user.remove_status_effect(/datum/status_effect/buff/playing_music)
			return

		if(!(src in user.held_items))
			return

		if(user.get_inactive_held_item())
			playing = FALSE
			soundloop.stop()
			user.remove_status_effect(/datum/status_effect/buff/playing_music)
			if(dynamic_icon)
				lower_from_mouth()
				update_icon()
			return

		if(curfile)
			curfile = song_list[curfile]
			playing = TRUE
			soundloop.mid_sounds = list(curfile)
			soundloop.cursound = null
			soundloop.start()
			user.apply_status_effect(/datum/status_effect/buff/playing_music, stressevent, note_color)
			if(dynamic_icon)
				lift_to_mouth()
				update_icon()
				for(var/obj/item/reagent_containers/food/snacks/smallrat/I in view(4, user))
					if(I.loc != user)
						step_towards(I, user)
						sleep(2)
						step_towards(I, user)
						sleep(2)
						step_towards(I, user)
//			for(var/mob/living/carbon/L in viewers(7)) // Fix: Apply the music buff only if you didn't cancel song selection.
//				if(L.can_hear()) // Only people who can hear music will get buffed
//					L.add_stress(stressevent)

		// BARDIC BUFFS CODE START //

		if(playing && HAS_TRAIT(user, TRAIT_BARDIC_TRAINING)) // Non-bards will never get this prompt. Prompt doesn't show if you cancel song selection either.
			var/list/buffs2pick = list()
			var/musiclevel = user.mind.get_skill_level(/datum/skill/misc/music)
			switch(musiclevel) // There has to be a better way to do this, but so far all I've tried doesn't work as intended.
				if(1) // T1
					buffs2pick += list("Noc's Brilliance (+1 INT)" = /datum/status_effect/bardicbuff/intelligence)
				if(1 to 2) // T2
					buffs2pick += list("Noc's Brilliance (+1 INT)" = /datum/status_effect/bardicbuff/intelligence,
									"Malum's Resilience (+1 END)" = /datum/status_effect/bardicbuff/endurance)
				if(1 to 3) // T3
					buffs2pick += list("Noc's Brilliance (+1 INT)" = /datum/status_effect/bardicbuff/intelligence,
									"Malum's Resilience (+1 END)" = /datum/status_effect/bardicbuff/endurance,
									"Pestra's Blessing (+1 CON)" = /datum/status_effect/bardicbuff/constitution)
				if(1 to 4) // T4
					buffs2pick += list("Noc's Brilliance (+1 INT)" = /datum/status_effect/bardicbuff/intelligence,
									"Malum's Perseverance (+1 END)" = /datum/status_effect/bardicbuff/endurance,
									"Pestra's Blessing (+1 CON)" = /datum/status_effect/bardicbuff/constitution,
									"Xylix's Alacrity (+1 SPD)" = /datum/status_effect/bardicbuff/speed)
				if(1 to 5) // T5
					buffs2pick += list("Noc's Brilliance (+1 INT)" = /datum/status_effect/bardicbuff/intelligence,
									"Malum's Perseverance (+1 END)" = /datum/status_effect/bardicbuff/endurance,
									"Pestra's Blessing (+1 CON)" = /datum/status_effect/bardicbuff/constitution,
									"Xylix's Alacrity (+1 SPD)" = /datum/status_effect/bardicbuff/speed,
									"Ravox's Righteous Fury (+1 STR, +1 PER)" = /datum/status_effect/bardicbuff/ravox)
				if(6 to INFINITY) // Legendary onwards
					buffs2pick += list("Noc's Brilliance (+1 INT)" = /datum/status_effect/bardicbuff/intelligence,
									"Malum's Perseverance (+1 END)" = /datum/status_effect/bardicbuff/endurance,
									"Pestra's Blessing (+1 CON)" = /datum/status_effect/bardicbuff/constitution,
									"Xylix's Alacrity (+1 SPD)" = /datum/status_effect/bardicbuff/speed,
									"Ravox's Righteous Fury (+1 STR, +1 PER)" = /datum/status_effect/bardicbuff/ravox,
									"Astrata's Awakening (Purges sleep, +1 FOR)" = /datum/status_effect/bardicbuff/awaken) // TAKE THE LAND THAT MUST BE TAKEN
				else // debug
					message_admins("<span class='warning'>[key_name(usr)] is a bard with zero music skill and couldn't choose a buff.</span>")
			var/buff2use = input(user, "Which buff to add to your song?", "Bardic Buffs", name) as null|anything in buffs2pick
			if(buff2use) // Prevents runtime
				buff2use = buffs2pick[buff2use] // This is to pick the buff and disregard the name defined at list level.
				for(var/mob/living/carbon/L in viewers(7))
					if(L.can_hear()) // Only good people who can hear music will get buffed
						if(L.mind?.has_antag_datum(/datum/antagonist))
							if(L.mind?.isactuallygood())
								L.add_stress(bardbonus)
								// Apply the buff every second to refresh its duration since it's timed
								while(playing)
									L.apply_status_effect(buff2use)
									var/boon = user?.mind?.get_learning_boon(/datum/skill/misc/music)
									user?.mind?.adjust_experience(/datum/skill/misc/music, ceil((user.STAINT*0.2) * boon)) // And gain exp
									sleep(10 * world.tick_lag) // Sanity to avoid infinite loop
							else
								return
						else
							L.add_stress(bardbonus) // Additional mood increase
							// Apply the buff every second to refresh its duration since it's timed
							while(playing)
								L.apply_status_effect(buff2use)
								var/boon = user?.mind?.get_learning_boon(/datum/skill/misc/music)
								user?.mind?.adjust_experience(/datum/skill/misc/music, ceil((user.STAINT*0.2) * boon)) // and gain exp
								sleep(10 * world.tick_lag) // Sanity to avoid infinite loop
					else
						return
			else
				to_chat(user, "I decided not to bestow any boons to my music.")
				for(var/mob/living/carbon/L in viewers(7))
					L.add_stress(bardbonus) // Give us the extra mood regardless.
				while(playing) // Grant us exp even if we did not apply buffs to anyone.
					var/boon = user?.mind?.get_learning_boon(/datum/skill/misc/music)
					user?.mind?.adjust_experience(/datum/skill/misc/music, ceil((user.STAINT*0.2) * boon))
					sleep(10 * world.tick_lag) // Gain exp every 1 second delay of playing

		// BARDIC BUFFS CODE END //

		while(playing)
			var/boon = user?.mind?.get_learning_boon(/datum/skill/misc/music)
			user?.mind?.adjust_experience(/datum/skill/misc/music, ceil((user.STAINT*0.2) * boon))
			sleep(10 * world.tick_lag) // Gain exp every 1 second delay of playing

	else
		playing = FALSE
		soundloop.stop()
		user.remove_status_effect(/datum/status_effect/buff/playing_music)
		if(dynamic_icon)
			lower_from_mouth()
			update_icon()
		for(var/mob/living/carbon/L in viewers(7))
			var/mob/living/carbon/buffed = L
			if(buffed.mind?.has_antag_datum(/datum/antagonist))
				if(buffed.mind?.isactuallygood())
					for(var/datum/status_effect/bardicbuff/b in L.status_effects)
						buffed.remove_status_effect(b) // All applicable bard buffs stopped
				else
					return
			else
				for(var/datum/status_effect/bardicbuff/b in L.status_effects)
					buffed.remove_status_effect(b) // All applicable bard buffs stopped

/obj/item/rogue/instrument/dropped(mob/user)
	. = ..()
	playing = FALSE
	soundloop.stop()
	if(dynamic_icon)
		lower_from_mouth()
		update_icon()
	for(var/mob/living/carbon/L in viewers(7))
		var/mob/living/carbon/buffed = L
		if(buffed.mind?.has_antag_datum(/datum/antagonist))
			if(buffed.mind?.isactuallygood())
				for(var/datum/status_effect/bardicbuff/b in L.status_effects)
					buffed.remove_status_effect(b) // All applicable bard buffs stopped
			else
				return
		else
			for(var/datum/status_effect/bardicbuff/b in L.status_effects)
				buffed.remove_status_effect(b) // All applicable bard buffs stopped

// At this point I don't know what other proc should be covered to avoid exploits.
/obj/item/rogue/instrument/obj_destruction(damage_flag)
	. = ..()
	if(playing)
		playing = FALSE
		soundloop.stop()
		for(var/mob/living/carbon/L in viewers(7))
			var/mob/living/carbon/buffed = L
			if(buffed.mind?.has_antag_datum(/datum/antagonist))
				if(buffed.mind?.isactuallygood())
					for(var/datum/status_effect/bardicbuff/b in L.status_effects)
						buffed.remove_status_effect(b) // All applicable bard buffs stopped
				else
					return
			else
				for(var/datum/status_effect/bardicbuff/b in L.status_effects)
					buffed.remove_status_effect(b) // All applicable bard buffs stopped

// Fixes an exploit. It shouldn't stack buffs anymore.
/obj/item/rogue/instrument/throw_at(atom/target, range, speed, mob/thrower, spin, diagonals_first, datum/callback/callback)
	. = ..()
	if(playing)
		playing = FALSE
		soundloop.stop()
		if(dynamic_icon)
			lower_from_mouth()
			update_icon()
		for(var/mob/living/carbon/L in viewers(7))
			var/mob/living/carbon/buffed = L
			if(buffed.mind?.has_antag_datum(/datum/antagonist))
				if(buffed.mind?.isactuallygood())
					for(var/datum/status_effect/bardicbuff/b in L.status_effects)
						buffed.remove_status_effect(b) // All applicable bard buffs stopped
				else
					return
			else
				for(var/datum/status_effect/bardicbuff/b in L.status_effects)
					buffed.remove_status_effect(b) // All applicable bard buffs stopped

/obj/item/rogue/instrument/proc/lift_to_mouth()
	icon_state = "[icon_prefix]_play"

/obj/item/rogue/instrument/proc/lower_from_mouth()
	icon_state = "[icon_prefix]"



/obj/item/rogue/instrument/lute
	name = "lute"
	desc = "The favored instrument of Eora, made of wood and simple string."
	possible_item_intents = list(/datum/intent/mace/strike/wood)
	icon_state = "lute"
	song_list = list(
	"Song 1" = 'modular/Barding/sound/instruments/lute (1).ogg',
	"Song 2" = 'modular/Barding/sound/instruments/lute (2).ogg',
	"Song 3" = 'modular/Barding/sound/instruments/lute (3).ogg',
	"Song 4" = 'modular/Barding/sound/instruments/lute (4).ogg',
	"Song 5" = 'modular/Barding/sound/instruments/lute (5).ogg',
	"Song 6" = 'modular/Barding/sound/instruments/lute (6).ogg',
	"Song 7" = 'modular/Barding/sound/instruments/lute (7).ogg',
	"Soilson's Song" = 'modular/Barding/sound/instruments/lute (8).ogg')

/obj/item/rogue/instrument/accord
	name = "accordion"
	desc = "A complex piece of dwarven intuition, composed of metal, wood, hide and ivory. Favored by Abyssorian bards."
	icon_state = "accordion"
	song_list = list(
	"Song 1" = 'modular/Barding/sound/instruments/accord (1).ogg',
	"Song 2" = 'modular/Barding/sound/instruments/accord (2).ogg',
	"Song 3" = 'modular/Barding/sound/instruments/accord (3).ogg',
	"Song 4" = 'modular/Barding/sound/instruments/accord (4).ogg',
	"Song 5" = 'modular/Barding/sound/instruments/accord (5).ogg',
	"Song 6" = 'modular/Barding/sound/instruments/accord (6).ogg',
	"Song of the Falconeer" = 'modular/Barding/sound/instruments/accord (7).ogg',
	"Dwarven Frolick" = 'modular/Barding/sound/instruments/accord (8).ogg'
	)

/obj/item/rogue/instrument/guitar
	name = "guitar"
	desc = "A corrupted lute, a heritage instrument of Tiefling pedigree."
	possible_item_intents = list(/datum/intent/mace/strike/wood)
	icon_state = "guitar"
	song_list = list(
	"Song 1" = 'modular/Barding/sound/instruments/guitar (1).ogg',
	"Song 2" = 'modular/Barding/sound/instruments/guitar (2).ogg',
	"Song 3" = 'modular/Barding/sound/instruments/guitar (3).ogg',
	"Song 4" = 'modular/Barding/sound/instruments/guitar (4).ogg',
	"Song 5" = 'modular/Barding/sound/instruments/guitar (5).ogg',
	"Song 6" = 'modular/Barding/sound/instruments/guitar (6).ogg',
	"Sunset ballad" = 'modular/Barding/sound/instruments/guitar (7).ogg',
	"Romanza" = 'modular/Barding/sound/instruments/guitar (8).ogg',
	"Malaguena" = 'modular/Barding/sound/instruments/guitar (9).ogg',
	"Song of the Archer" = 'modular/Barding/sound/instruments/guitar (10).ogg',
	"The Mask" = 'modular/Barding/sound/instruments/guitar (11).ogg',
	"Evolvado" = 'modular/Barding/sound/instruments/guitar (12).ogg',
	"Asturias" = 'modular/Barding/sound/instruments/guitar (13).ogg',
	"The Fools Journey" = 'modular/Barding/sound/instruments/guitar (14).ogg',
	"Prelude to Sorrow" = 'modular/Barding/sound/instruments/guitar (15).ogg'
	)

/obj/item/rogue/instrument/harp
	name = "harp"
	desc = "An elven instrument of a great and proud heritage."
	icon_state = "harp"
	song_list = list(
	"Song 1" = 'modular/Barding/sound/instruments/harb (1).ogg',
	"Song 2" = 'modular/Barding/sound/instruments/harb (2).ogg',
	"Song 3" = 'modular/Barding/sound/instruments/harb (3).ogg',
	"Dance of the Mages" = 'modular/Barding/sound/instruments/harp (4).ogg',
	"Trickster Wisps" = 'modular/Barding/sound/instruments/harp (5).ogg')

/obj/item/rogue/instrument/flute // small rats approach a little when begin playing
	name = "flute"
	desc = "A cacophonous wind-instrument, played primarily by humens all around Grimoria."
	icon_state = "flute"
	icon_prefix = "flute" // used for inhands switch
	dynamic_icon = TRUE // used for inhands switch
	song_list = list(
	"Song 1" = 'modular/Barding/sound/instruments/flute (1).ogg',
	"Song 2" = 'modular/Barding/sound/instruments/flute (2).ogg',
	"Song 3" = 'modular/Barding/sound/instruments/flute (3).ogg',
	"Song 4" = 'modular/Barding/sound/instruments/flute (4).ogg',
	"Song 5" = 'modular/Barding/sound/instruments/flute (5).ogg',
	"Song 6" = 'modular/Barding/sound/instruments/flute (6).ogg',
	"Flower Melody" = 'modular/Barding/sound/instruments/flute (7).ogg',
	"Noble Solace" = 'modular/Barding/sound/instruments/flute (8).ogg')

/obj/item/rogue/instrument/drum
	name = "drum"
	desc = "The adopted instrument of Aasimar, used for signaling and rhythmic marches alike."
	icon_state = "drum"
	song_list = list(
	"Song 1" = 'modular/Barding/sound/instruments/drum (1).ogg',
	"Song 2" = 'modular/Barding/sound/instruments/drum (2).ogg',
	"Song 3" = 'modular/Barding/sound/instruments/drum (3).ogg',
	"Snare drum" = 'modular/Barding/sound/instruments/drum (4).ogg',
	"Desert Heat" = 'modular/Barding/sound/instruments/drum (5).ogg')

/obj/item/rogue/instrument/shamisen //I know shamisen should be used while sitting/on knees. butt you think bards really need to be SITTING during battle?
	name = "shamisen"
	desc = "shamisen, or just 'three-stings' is a abyssariad puckled stringed musical instrument, usually played using a Bachi."
	icon = 'icons/roguetown/kaizoku/misc/music.dmi'
	icon_state = "shamisen"
	lefthand_file = 'icons/roguetown/kaizoku/misc/lefthand_music.dmi'
	righthand_file = 'icons/roguetown/kaizoku/misc/righthand_music.dmi'
	song_list = list(
	"Cursed Apple" = 'sound/music/kaizoku/instrument/shamisen1.ogg', //Credit; "Bad Apple by しゃみお - Shamisen player Shamio"
	"Fire Dance" = 'sound/music/kaizoku/instrument/shamisen2.ogg', //Credit; "Fire Dance by しゃみお - Shamisen player Shamio"
	"Lute" = 'sound/music/kaizoku/instrument/shamisen3.ogg', //Credit; "Lute (shamisen) by Museum of Fine Arts, Boston"
	"Tsugaru Ripple" = 'sound/music/kaizoku/instrument/shamisen4.ogg', //Credit; "Tsugaru Shamisen (using Ripple) by Shamisen Komatsuya"
	"Tsugaru" = 'sound/music/kaizoku/instrument/shamisen5.ogg', //Credit; "Tsugaru Shamisen by Roger Walch"
	"Season" = 'sound/music/kaizoku/instrument/shamisen6.ogg', //Credit; "相棒 Season 遊郭編しゃみお - Shamisen player Shamio"
	"Parade" = 'sound/music/kaizoku/instrument/shamisen7.ogg', //Credit; "「雨天PARADE」三味線オリジナル曲 - しゃみお - Shamisen player Shamio"
	"Koshiro" = 'sound/music/kaizoku/instrument/shamisen8.ogg' //Credit; “KOSHIRO” -幸四郎- by SENZO"
	)
