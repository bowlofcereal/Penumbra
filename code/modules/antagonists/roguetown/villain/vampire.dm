#ifdef TESTSERVER
/mob/living/carbon/human/verb/become_vampire()
	set category = "DEBUGTEST"
	set name = "VAMPIRETEST"
	if(mind)
		var/datum/antagonist/vampire/new_antag = new /datum/antagonist/vampire()
		mind.add_antag_datum(new_antag)
#endif

/datum/antagonist/vampire
	name = "Vampire"
	roundend_category = "Vampires"
	antagpanel_category = "Vampire"
	job_rank = ROLE_VAMPIRE
	antag_hud_type = ANTAG_HUD_TRAITOR
	antag_hud_name = "vampire"
	confess_lines = list(
		"I WANT YOUR BLOOD!",
		"DRINK THE BLOOD!",
		"CHILD OF KAIN!",
	)
	rogue_enabled = TRUE
	var/disguised = TRUE //just when the vamps eyes go red
	var/exposed = FALSE //vamp got burnt and revealed
	var/low_vitae = FALSE //vitae too low to disguise self
	var/vitae = 1000
	var/last_transform = 0
	var/is_lesser = FALSE
	var/cache_skin
	var/cache_eye_color
	var/cache_second_color
	var/cache_hair
	var/cache_facial
	var/cache_hair_nat
	var/cache_facial_nat
	var/starved = FALSE
	var/obj/effect/proc_holder/spell/targeted/shapeshift/bat/batform //attached to the datum itself to avoid cloning memes, and other duplicates

/datum/antagonist/vampire/proc/handle_vitae(change)
	var/tempcurrent = vitae
	if(change > 0)
		tempcurrent += change
		if(tempcurrent > 1666)
			tempcurrent = 1666 // to prevent overflow
	if(change < 0)
		tempcurrent += change
		if(tempcurrent < 0)
			tempcurrent = 0 // to prevent excessive negative
	vitae = tempcurrent
	if(vitae <= 20)
		if(!starved)
			to_chat(owner, span_userdanger("I starve, my power dwindles! I am so weak!"))
			starved = TRUE
			for(var/S in MOBSTATS)
				owner.current.change_stat(S, -5)
	else
		if(starved)
			starved = FALSE
			for(var/S in MOBSTATS)
				owner.current.change_stat(S, 5)

/datum/antagonist/vampire/examine_friendorfoe(datum/antagonist/examined_datum,mob/examiner,mob/examined)
	if(istype(examined_datum, /datum/antagonist/vampire/lesser))
		return span_boldnotice("A child of Kain.")
	if(istype(examined_datum, /datum/antagonist/vampire))
		return span_boldnotice("An elder Kin.")
	if(examiner.Adjacent(examined))
		if(istype(examined_datum, /datum/antagonist/werewolf/lesser))
			if(!disguised)
				return span_boldwarning("I sense a lesser Werewolf.")
		if(istype(examined_datum, /datum/antagonist/werewolf))
			if(!disguised)
				return span_boldwarning("THIS IS AN ELDER WEREWOLF! MY ENEMY!")
	if(istype(examined_datum, /datum/antagonist/zombie))
		return span_boldnotice("Another deadite.")
	if(istype(examined_datum, /datum/antagonist/skeleton))
		return span_boldnotice("Another deadite.")

/datum/antagonist/vampire/lesser //le shitcode faec
	name = "Lesser Vampire"
	is_lesser = TRUE
	increase_votepwr = FALSE

/datum/antagonist/vampire/lesser/roundend_report()
	return

/datum/antagonist/vampire/on_gain()
	if(!is_lesser)
		owner.adjust_skillrank(/datum/skill/combat/wrestling, 6, TRUE)
		owner.adjust_skillrank(/datum/skill/combat/unarmed, 6, TRUE)
		ADD_TRAIT(owner.current, TRAIT_NOBLE, TRAIT_GENERIC)
	owner.special_role = name
	ADD_TRAIT(owner.current, TRAIT_STRONGBITE, TRAIT_GENERIC)
	ADD_TRAIT(owner.current, TRAIT_NOHUNGER, TRAIT_GENERIC)
	ADD_TRAIT(owner.current, TRAIT_NOBREATH, TRAIT_GENERIC)
	ADD_TRAIT(owner.current, TRAIT_NOPAIN, TRAIT_GENERIC)
	ADD_TRAIT(owner.current, TRAIT_TOXIMMUNE, TRAIT_GENERIC)
	ADD_TRAIT(owner.current, TRAIT_STEELHEARTED, TRAIT_GENERIC)
	owner.current.cmode_music = 'sound/music/combat_vamp2.ogg'
	
	// Store original appearance before changes
	var/mob/living/carbon/human/H = owner.current
	if(istype(H))
		var/obj/item/organ/eyes/E = H.getorganslot(ORGAN_SLOT_EYES)
		if(E)
			cache_eye_color = E.eye_color
			cache_second_color = E.second_color
			message_admins("DEBUG: Base vampire on_gain() - Caching eye color from eyes organ: [cache_eye_color] [cache_second_color]")
		cache_skin = H.skin_tone
		var/datum/bodypart_feature/hair/head/Hair = H.get_bodypart_feature_of_slot(BODYPART_FEATURE_HAIR)
		if (Hair)
			cache_hair = Hair.accessory_colors
			cache_hair_nat = Hair.natural_color
		var/datum/bodypart_feature/hair/facial/Facial = H.get_bodypart_feature_of_slot(BODYPART_FEATURE_FACIAL_HAIR)
		if (Facial)
			cache_facial = Facial.accessory_colors
			cache_facial_nat = Facial.natural_color
	
	if(increase_votepwr)
		forge_vampire_objectives()
	finalize_vampire()

	// Basic vampire abilities
	owner.current.verbs |= /mob/living/carbon/human/proc/disguise_button
	owner.current.verbs |= /mob/living/carbon/human/proc/vamp_regenerate

	// Only vampire lords get these abilities
	if(owner.has_antag_datum(/datum/antagonist/vampirelord))
		owner.current.verbs |= /mob/living/carbon/human/proc/blood_strength
		owner.current.verbs |= /mob/living/carbon/human/proc/blood_celerity
		owner.current.verbs |= /mob/living/carbon/human/proc/blood_fortitude

	return ..()

/datum/antagonist/vampire/on_removal()
	if(!silent && owner.current)
		to_chat(owner.current,span_danger("I am no longer a [job_rank]!"))
	owner.special_role = null
	if(!isnull(batform))
		owner.current.RemoveSpell(batform)
		QDEL_NULL(batform)
	return ..()

/datum/antagonist/vampire/proc/add_objective(datum/objective/O)
	objectives += O

/datum/antagonist/vampire/proc/remove_objective(datum/objective/O)
	objectives -= O

/datum/antagonist/vampire/proc/forge_vampire_objectives()
	if(!(locate(/datum/objective/escape) in objectives))
		var/datum/objective/vampire/escape_objective = new
		escape_objective.owner = owner
		add_objective(escape_objective)
		return

/datum/antagonist/vampire/greet()
	to_chat(owner.current, span_userdanger("Ever since that bite, I have been a VAMPIRE."))
	owner.announce_objectives()
	..()

/datum/antagonist/vampire/proc/finalize_vampire()
	owner.current.playsound_local(get_turf(owner.current), 'sound/music/vampintro.ogg', 80, FALSE, pressure_affected = FALSE)

/mob/living/carbon/human/proc/set_organ_slot_color(organ_slot, organ_color)
	var/obj/item/organ/Organ = getorganslot(organ_slot)
	if (Organ)
		Organ.accessory_colors = organ_color

/mob/living/carbon/human/proc/set_skin_tone(n_skin_tone, update = TRUE)
	skin_tone = n_skin_tone
	var/san_skin_tone = sanitize_hexcolor(skin_tone, 6, 1) //prepend # to hex
	set_organ_slot_color(ORGAN_SLOT_PENIS, list(san_skin_tone, san_skin_tone))
	set_organ_slot_color(ORGAN_SLOT_BREASTS, san_skin_tone)
	if (update)
		update_body_parts(TRUE)

/datum/bodypart_feature/hair/proc/set_color(n_hair_color, n_natural_color, n_dye_color)
	if (n_hair_color)
		accessory_colors = n_hair_color
	if (n_natural_color)
		natural_color = n_natural_color
	if (n_dye_color)
		hair_dye_color = n_dye_color

/datum/bodypart_feature/hair/proc/set_gradient(n_natural_gradient, n_dye_gradient)
	if (n_natural_gradient)
		natural_gradient = n_natural_gradient
	if (n_dye_gradient)
		hair_dye_gradient = n_dye_gradient

/mob/living/carbon/human/proc/set_hair_color(n_hair_color, n_natural_color, n_dye_color, update = TRUE)
	var/datum/bodypart_feature/hair/head/Hair = get_bodypart_feature_of_slot(BODYPART_FEATURE_HAIR)
	if (Hair)
		Hair.set_color(n_hair_color, n_natural_color, n_dye_color)
	if (update)
		update_hair()

/mob/living/carbon/human/proc/set_hair_gradient(natural_gradient, dye_gradient, update = TRUE)
	var/datum/bodypart_feature/hair/head/Hair = get_bodypart_feature_of_slot(BODYPART_FEATURE_HAIR)
	if (Hair)
		Hair.set_gradient(natural_gradient, dye_gradient)
	if (update)
		update_hair()

/mob/living/carbon/human/proc/set_facial_hair_color(n_hair_color, n_natural_color, n_dye_color, update = TRUE)
	var/datum/bodypart_feature/hair/facial/Facial = get_bodypart_feature_of_slot(BODYPART_FEATURE_FACIAL_HAIR)
	if (Facial)
		Facial.set_color(n_hair_color, n_natural_color, n_dye_color)
	if (update)
		update_hair()

/mob/living/carbon/human/proc/set_facial_hair_gradient(n_natural_gradient, n_dye_gradient, update = TRUE)
	var/datum/bodypart_feature/hair/facial/Facial = get_bodypart_feature_of_slot(BODYPART_FEATURE_FACIAL_HAIR)
	if (Facial)
		Facial.set_gradient(n_natural_gradient, n_dye_gradient)
	if (update)
		update_hair()

/datum/antagonist/vampire/proc/recover(mob/user)
	var/mob/living/carbon/human/H = user
	if (!H)
		return
	if(H.stat == DEAD)
		return
	to_chat(H, span_warning("I can once more assume a human visage."))
	exposed= FALSE

/datum/antagonist/vampire/on_life(mob/user)
	if(!user)
		return
	var/mob/living/carbon/human/H = user
	if(H.stat == DEAD)
		return
	if(H.advsetup)
		return


	if(H.on_fire)
		if (!exposed)
			to_chat(H, span_warning("I cannot maintain my human visage!"))
			H.vampire_undisguise(src)
			exposed = TRUE
			if(disguised)
				to_chat(H, span_warning("My disguise fails!"))
		addtimer(CALLBACK(src, PROC_REF(recover), user), 30 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE)
		//last_transform = world.time
		H.freak_out()

	if(H.stat)
		if(istype(H.loc, /obj/structure/closet/crate/coffin))
			H.fully_heal()

	vitae = CLAMP(vitae, 0, 1666)

	if(vitae >= 0)
		if (vitae > 0)
			H.blood_volume = BLOOD_VOLUME_NORMAL
		if(vitae < 200)
			if (!low_vitae)
				to_chat(H, span_warning("My vitae reserves are depleted. I cannot maintain my human visage!"))
				low_vitae = TRUE
				if(disguised)
					to_chat(H, span_warning("My disguise fails!"))
				H.vampire_undisguise(src)
		else
			low_vitae = FALSE

/mob/living/carbon/human/proc/disguise_button()
	set name = "Toggle Disguise"
	set category = "VAMPIRE"
	
	var/datum/antagonist/vampire/V = mind.has_antag_datum(/datum/antagonist/vampire)
	if(!V)
		return
	
	if (V.exposed)
		to_chat(src, span_notice("I am still recovering!"))
		return
	
	if(V.disguised)
		to_chat(src, span_notice("I reveal my true form."))
		V.disguised = FALSE
		
		if(dna)
			var/datum/organ_dna/eyes/eyes_dna = dna.organ_dna[ORGAN_SLOT_EYES]
			var/obj/item/organ/eyes/E = getorganslot(ORGAN_SLOT_EYES)
			if(E)
				E.eye_color = "#ff0000"
				E.second_color = "#ff0000"
				if(eyes_dna)
					E.imprint_organ_dna(eyes_dna)
				E.update_accessory_colors()
				E.lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
		
		dna?.species.handle_body(src)
		update_body()
		update_hair()
		update_body_parts(TRUE)
		regenerate_icons()
		update_sight()
	else
		if (V.low_vitae)
			to_chat(src, span_notice("My vitae is too low!"))
			return
		to_chat(src, span_notice("I conceal my vampiric nature."))
		V.disguised = TRUE
		set_skin_tone(V.cache_skin, update = FALSE)
		set_hair_color(V.cache_hair, V.cache_hair_nat, update = FALSE)
		set_facial_hair_color(V.cache_facial, V.cache_facial_nat, update = FALSE)
		
		if(V.cache_eye_color && dna)
			var/datum/organ_dna/eyes/eyes_dna = dna.organ_dna[ORGAN_SLOT_EYES]
			var/obj/item/organ/eyes/E = getorganslot(ORGAN_SLOT_EYES)
			if(E)
				E.eye_color = V.cache_eye_color
				E.second_color = V.cache_second_color
				if(eyes_dna)
					E.imprint_organ_dna(eyes_dna)
				E.update_accessory_colors()
				E.lighting_alpha = null
		
		dna?.species.handle_body(src)
		update_body()
		update_hair()
		update_body_parts(TRUE)
		regenerate_icons()
		update_sight()

/mob/living/carbon/human/proc/vampire_disguise(datum/antagonist/V)
	if(!V)
		return
	
	if(istype(V, /datum/antagonist/vampire))
		var/datum/antagonist/vampire/VD = V
		VD.disguised = TRUE
		set_skin_tone(VD.cache_skin, update = FALSE)
		set_hair_color(VD.cache_hair, VD.cache_hair_nat, update = FALSE)
		set_facial_hair_color(VD.cache_facial, VD.cache_facial_nat, update = FALSE)
		
		if(VD.cache_eye_color && dna)
			var/datum/organ_dna/eyes/eyes_dna = dna.organ_dna[ORGAN_SLOT_EYES]
			var/obj/item/organ/eyes/E = getorganslot(ORGAN_SLOT_EYES)
			if(E)
				E.eye_color = VD.cache_eye_color
				E.second_color = VD.cache_second_color
				if(eyes_dna)
					E.imprint_organ_dna(eyes_dna)
				E.update_accessory_colors()
				E.lighting_alpha = null
		
		dna?.species.handle_body(src)
		update_body()
		update_hair()
		update_body_parts(TRUE)
		regenerate_icons()
		update_sight()

/mob/living/carbon/human/proc/vampire_undisguise(datum/antagonist/V)
	if(!V)
		return
	
	if(istype(V, /datum/antagonist/vampirelord))
		var/datum/antagonist/vampirelord/VD = V
		VD.disguised = FALSE
	else if(istype(V, /datum/antagonist/vampire))
		var/datum/antagonist/vampire/VD = V
		VD.disguised = FALSE
	else
		return
	
	set_skin_tone("c9d3de", update = FALSE)
	set_hair_color("#181a1d", "#181a1d", update = FALSE) //dye not affected
	set_facial_hair_color("#181a1d", "#181a1d", update = FALSE)
	
	if(dna)
		var/datum/organ_dna/eyes/eyes_dna = dna.organ_dna[ORGAN_SLOT_EYES]
		var/obj/item/organ/eyes/E = getorganslot(ORGAN_SLOT_EYES)
		if(E)
			E.eye_color = "#ff0000"
			E.second_color = "#ff0000"
			if(eyes_dna)
				E.imprint_organ_dna(eyes_dna)
			E.update_accessory_colors()
			E.lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
	
	dna?.species.handle_body(src)
	update_body()
	update_hair()
	update_body_parts(TRUE)
	regenerate_icons()
	update_sight()

/mob/living/carbon/human/proc/blood_strength()
	set name = "Night Muscles"
	set category = "VAMPIRE"

	var/datum/antagonist/vampirelord/VD = mind.has_antag_datum(/datum/antagonist/vampirelord)
	if(!VD)
		to_chat(src, span_warning("I am not a vampire lord."))
		return
	if(VD.disguised)
		to_chat(src, span_warning("I cannot use Night Muscles while disguised."))
		return
	if(VD.vitae < 100)
		to_chat(src, span_warning("I need at least 100 vitae to use Night Muscles. (Current: [VD.vitae])"))
		return
	if(has_status_effect(/datum/status_effect/buff/bloodstrength))
		to_chat(src, span_warning("Night Muscles is already active."))
		return
	VD.handle_vitae(-100)
	apply_status_effect(/datum/status_effect/buff/bloodstrength)
	to_chat(src, span_greentext("! NIGHT MUSCLES !"))
	src.playsound_local(get_turf(src), 'sound/misc/vampirespell.ogg', 100, FALSE, pressure_affected = FALSE)

/datum/status_effect/buff/bloodstrength
	id = "bloodstrength"
	alert_type = /atom/movable/screen/alert/status_effect/buff/bloodstrength
	effectedstats = list("strength" = 6)
	duration = 1 MINUTES

/atom/movable/screen/alert/status_effect/buff/bloodstrength
	name = "Night Muscles"
	desc = ""
	icon_state = "bleed1"

/mob/living/carbon/human/proc/blood_celerity()
	set name = "Quickening"
	set category = "VAMPIRE"

	var/datum/antagonist/vampirelord/VD = mind.has_antag_datum(/datum/antagonist/vampirelord)
	if(!VD)
		to_chat(src, span_warning("I am not a vampire lord."))
		return
	if(VD.disguised)
		to_chat(src, span_warning("I cannot use Quickening while disguised."))
		return
	if(VD.vitae < 100)
		to_chat(src, span_warning("I need at least 100 vitae to use Quickening. (Current: [VD.vitae])"))
		return
	if(has_status_effect(/datum/status_effect/buff/celerity))
		to_chat(src, span_warning("Quickening is already active."))
		return
	VD.handle_vitae(-100)
	rogstam_add(2000)
	apply_status_effect(/datum/status_effect/buff/celerity)
	to_chat(src, span_greentext("! QUICKENING !"))
	src.playsound_local(get_turf(src), 'sound/misc/vampirespell.ogg', 100, FALSE, pressure_affected = FALSE)

/datum/status_effect/buff/celerity
	id = "celerity"
	alert_type = /atom/movable/screen/alert/status_effect/buff/celerity
	effectedstats = list("speed" = 15,"perception" = 10)
	duration = 30 SECONDS

/datum/status_effect/buff/celerity/nextmove_modifier()
	return 0.60

/atom/movable/screen/alert/status_effect/buff/celerity
	name = "Quickening"
	desc = ""
	icon_state = "bleed1"

/mob/living/carbon/human/proc/blood_fortitude()
	set name = "Armor of Darkness"
	set category = "VAMPIRE"

	var/datum/antagonist/vampire/VD = mind.has_antag_datum(/datum/antagonist/vampire)
	if(!VD)
		to_chat(src, span_warning("I am not a vampire lord."))
		return
	if(VD.disguised)
		to_chat(src, span_warning("I cannot use Armor of Darkness while disguised."))
		return
	if(VD.vitae < 100)
		to_chat(src, span_warning("I need at least 100 vitae to use Armor of Darkness. (Current: [VD.vitae])"))
		return
	if(has_status_effect(/datum/status_effect/buff/fortitude))
		to_chat(src, span_warning("Armor of Darkness is already active."))
		return
	VD.vitae -= 100
	rogstam_add(2000)
	apply_status_effect(/datum/status_effect/buff/fortitude)
	to_chat(src, span_greentext("! ARMOR OF DARKNESS !"))
	src.playsound_local(get_turf(src), 'sound/misc/vampirespell.ogg', 100, FALSE, pressure_affected = FALSE)

/datum/status_effect/buff/fortitude
	id = "fortitude"
	alert_type = /atom/movable/screen/alert/status_effect/buff/fortitude
	effectedstats = list("endurance" = 20,"constitution" = 20)
	duration = 30 SECONDS

/atom/movable/screen/alert/status_effect/buff/fortitude
	name = "Armor of Darkness"
	desc = ""
	icon_state = "bleed1"

/datum/status_effect/buff/fortitude/on_apply()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		QDEL_NULL(H.skin_armor)
		H.skin_armor = new /obj/item/clothing/suit/roguetown/armor/skin_armor/vampire_fortitude(H)
	owner.add_stress(/datum/stressevent/weed)

/datum/status_effect/buff/fortitude/on_remove()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(istype(H.skin_armor, /obj/item/clothing/suit/roguetown/armor/skin_armor/vampire_fortitude))
			QDEL_NULL(H.skin_armor)
	. = ..()

/obj/item/clothing/suit/roguetown/armor/skin_armor/vampire_fortitude
	slot_flags = null
	name = "vampire's skin"
	desc = ""
	icon_state = null
	body_parts_covered = FULL_BODY
	armor = list("blunt" = 100, "slash" = 100, "stab" = 90, "bullet" = 0, "laser" = 0,"energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 0, "acid" = 0)
	prevent_crits = list(BCLASS_CUT, BCLASS_STAB, BCLASS_BLUNT, BCLASS_TWIST)
	blocksound = SOFTHIT
	blade_dulling = DULLING_BASHCHOP
	sewrepair = TRUE
	max_integrity = 0

/mob/living/carbon/human/proc/vamp_regenerate()
	set name = "Regenerate"
	set category = "VAMPIRE"
	
	var/silver_curse_status = FALSE
	for(var/datum/status_effect/debuff/silver_curse/silver_curse in status_effects)
		silver_curse_status = TRUE
		break
	
	var/datum/antagonist/vampire/VD = mind.has_antag_datum(/datum/antagonist/vampire)
	var/datum/antagonist/vampirelord/VL = mind.has_antag_datum(/datum/antagonist/vampirelord)
	if(!VD && !VL)
		to_chat(src, span_warning("I am not a vampire."))
		return
	
	var/vitae_check = 0
	var/is_disguised = FALSE
	if(VD)
		vitae_check = VD.vitae
		is_disguised = VD.disguised
	else if(VL)
		vitae_check = VL.vitae
		is_disguised = VL.disguised
	
	if(is_disguised)
		to_chat(src, span_warning("I cannot regenerate while disguised."))
		return
	if(silver_curse_status)
		to_chat(src, span_warning("The silver curse prevents regeneration!"))
		return
	if(vitae_check < 500)
		to_chat(src, span_warning("I need at least 500 vitae to regenerate. (Current: [vitae_check])"))
		return
	
	to_chat(src, span_greentext("! REGENERATE !"))
	src.playsound_local(get_turf(src), 'sound/misc/vampirespell.ogg', 100, FALSE, pressure_affected = FALSE)
	if(VD)
		VD.handle_vitae(-500)
	else if(VL)
		VL.handle_vitae(-500)
	fully_heal()
	regenerate_limbs()

/mob/living/carbon/human/proc/vampire_infect()
	if(!mind)
		return
	if(mind.has_antag_datum(/datum/antagonist/vampire))
		return
	if(mind.has_antag_datum(/datum/antagonist/werewolf))
		return
	if(mind.has_antag_datum(/datum/antagonist/zombie))
		return
	if(mob_timers["becoming_vampire"])
		return
	mob_timers["becoming_vampire"] = world.time
	addtimer(CALLBACK(src, TYPE_PROC_REF(/mob/living/carbon/human, vampire_finalize)), 2 MINUTES)
	to_chat(src, span_danger("I feel sick..."))
	src.playsound_local(get_turf(src), 'sound/music/horror.ogg', 80, FALSE, pressure_affected = FALSE)
	flash_fullscreen("redflash3")

/mob/living/carbon/human/proc/vampire_finalize()
	if(!mind)
		mob_timers["becoming_vampire"] = null
		return
	if(mind.has_antag_datum(/datum/antagonist/vampire))
		mob_timers["becoming_vampire"] = null
		return
	if(mind.has_antag_datum(/datum/antagonist/werewolf))
		mob_timers["becoming_vampire"] = null
		return
	if(mind.has_antag_datum(/datum/antagonist/zombie))
		mob_timers["becoming_vampire"] = null
		return
	var/datum/antagonist/vampire/new_antag = new /datum/antagonist/vampire/lesser()
	mind.add_antag_datum(new_antag)
	Sleeping(100)
//	stop_all_loops()
	src.playsound_local(src, 'sound/misc/deth.ogg', 100)
	if(client)
		SSdroning.kill_rain(client)
		SSdroning.kill_loop(client)
		SSdroning.kill_droning(client)
		client.move_delay = initial(client.move_delay)
		var/atom/movable/screen/gameover/hog/H = new()
		H.layer = SPLASHSCREEN_LAYER+0.1
		client.screen += H
		H.Fade()
		addtimer(CALLBACK(H, TYPE_PROC_REF(/atom/movable/screen/gameover, Fade), TRUE), 100)
