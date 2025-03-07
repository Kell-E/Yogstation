//Largely negative status effects go here, even if they have small benificial effects
//STUN EFFECTS
/datum/status_effect/incapacitating
	tick_interval = 0
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	remove_on_fullheal = TRUE
	//heal_flag_necessary = HEAL_CC_STATUS
	var/needs_update_stat = FALSE

/datum/status_effect/incapacitating/on_creation(mob/living/new_owner, set_duration, updating_canmove)
	if(isnum(set_duration))
		duration = set_duration
	. = ..()
	if(. && updating_canmove)
		owner.update_mobility()
		if(needs_update_stat || issilicon(owner))
			owner.update_stat()


/datum/status_effect/incapacitating/on_remove()
	owner.update_mobility()
	if(needs_update_stat || issilicon(owner)) //silicons need stat updates in addition to normal canmove updates
		owner.update_stat()
	return ..()

//STUN
/datum/status_effect/incapacitating/stun
	id = "stun"

/datum/status_effect/incapacitating/stun/on_apply()
	. = ..()
	if(!.)
		return
	owner.add_traits(list(TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/stun/on_remove()
	owner.remove_traits(list(TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), TRAIT_STATUS_EFFECT(id))
	return ..()


//KNOCKDOWN
/datum/status_effect/incapacitating/knockdown
	id = "knockdown"

/datum/status_effect/incapacitating/knockdown/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_FLOORED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/knockdown/on_remove()
	REMOVE_TRAIT(owner, TRAIT_FLOORED, TRAIT_STATUS_EFFECT(id))
	return ..()


//IMMOBILIZED
/datum/status_effect/incapacitating/immobilized
	id = "immobilized"

/datum/status_effect/incapacitating/immobilized/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/immobilized/on_remove()
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	return ..()


//PARALYZED
/datum/status_effect/incapacitating/paralyzed
	id = "paralyzed"

/datum/status_effect/incapacitating/paralyzed/on_apply()
	. = ..()
	if(!.)
		return
	owner.add_traits(list(TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_FLOORED, TRAIT_HANDS_BLOCKED), TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/paralyzed/on_remove()
	owner.remove_traits(list(TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_FLOORED, TRAIT_HANDS_BLOCKED), TRAIT_STATUS_EFFECT(id))
	return ..()

//INCAPACITATED
/// This status effect represents anything that leaves a character unable to perform basic tasks (interrupting do-afters, for example), but doesn't incapacitate them further than that (no stuns etc..)
/datum/status_effect/incapacitating/incapacitated
	id = "incapacitated"

// What happens when you get the incapacitated status. You get TRAIT_INCAPACITATED added to you for the duration of the status effect.
/datum/status_effect/incapacitating/incapacitated/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))

// When the status effect runs out, your TRAIT_INCAPACITATED is removed.
/datum/status_effect/incapacitating/incapacitated/on_remove()
	REMOVE_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))
	return ..()


//UNCONSCIOUS
/datum/status_effect/incapacitating/unconscious
	id = "unconscious"
	needs_update_stat = TRUE

/datum/status_effect/incapacitating/unconscious/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/unconscious/on_remove()
	REMOVE_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
	return ..()

/datum/status_effect/incapacitating/unconscious/tick()
	if(owner.getStaminaLoss())
		owner.adjustStaminaLoss(-0.3) //reduce stamina loss by 0.3 per tick, 6 per 2 seconds


//SLEEPING
/datum/status_effect/incapacitating/sleeping
	id = "sleeping"
	alert_type = /atom/movable/screen/alert/status_effect/asleep
	needs_update_stat = TRUE
	tick_interval = 2 SECONDS

/datum/status_effect/incapacitating/sleeping/on_apply()
	. = ..()
	if(!.)
		return
	if(!HAS_TRAIT(owner, TRAIT_SLEEPIMMUNE))
		ADD_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
		tick_interval = -1
	RegisterSignal(owner, SIGNAL_ADDTRAIT(TRAIT_SLEEPIMMUNE), PROC_REF(on_owner_insomniac))
	RegisterSignal(owner, SIGNAL_REMOVETRAIT(TRAIT_SLEEPIMMUNE), PROC_REF(on_owner_sleepy))

/datum/status_effect/incapacitating/sleeping/on_remove()
	UnregisterSignal(owner, list(SIGNAL_ADDTRAIT(TRAIT_SLEEPIMMUNE), SIGNAL_REMOVETRAIT(TRAIT_SLEEPIMMUNE)))
	if(!HAS_TRAIT(owner, TRAIT_SLEEPIMMUNE))
		REMOVE_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
		tick_interval = initial(tick_interval)
	return ..()

///If the mob is sleeping and gain the TRAIT_SLEEPIMMUNE we remove the TRAIT_KNOCKEDOUT and stop the tick() from happening
/datum/status_effect/incapacitating/sleeping/proc/on_owner_insomniac(mob/living/source)
	SIGNAL_HANDLER
	REMOVE_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
	tick_interval = -1

///If the mob has the TRAIT_SLEEPIMMUNE but somehow looses it we make him sleep and restart the tick()
/datum/status_effect/incapacitating/sleeping/proc/on_owner_sleepy(mob/living/source)
	SIGNAL_HANDLER
	ADD_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
	tick_interval = initial(tick_interval)

#define HEALING_SLEEP_DEFAULT 0.2

/datum/status_effect/incapacitating/sleeping/tick()
	if(owner.maxHealth)
		var/health_ratio = owner.health / owner.maxHealth
		var/healing = HEALING_SLEEP_DEFAULT

		// having high spirits helps us recover
		var/datum/component/mood/mob_mood = owner.GetComponent(/datum/component/mood)
		if(mob_mood)
			switch(mob_mood.sanity_level)
				if(SANITY_GREAT)
					healing = 0.2
				if(SANITY_NEUTRAL)
					healing = 0.1
				if(SANITY_DISTURBED)
					healing = 0
				if(SANITY_UNSTABLE)
					healing = 0
				if(SANITY_CRAZY)
					healing = -0.1
				if(SANITY_INSANE)
					healing = -0.2

		var/turf/rest_turf = get_turf(owner)
		var/is_sleeping_in_darkness = rest_turf.get_lumcount() <= LIGHTING_TILE_IS_DARK

		// sleeping with a blindfold or in the dark helps us rest
		if(is_blind(owner) || is_sleeping_in_darkness)
			healing += 0.1

		// sleeping in silence is always better
		if(HAS_TRAIT(owner, TRAIT_DEAF))
			healing += 0.1

		// check for beds
		if((locate(/obj/structure/bed) in owner.loc))
			healing += 0.2
		else if((locate(/obj/structure/table) in owner.loc))
			healing += 0.1

		// don't forget the bedsheet
		for(var/obj/item/bedsheet/bedsheet in range(owner.loc,0))
			if(bedsheet.loc != owner.loc) //bedsheets in your backpack/neck don't give you comfort
				continue
			healing += 0.1
			break //Only count the first bedsheet

		if(healing > 0 && health_ratio > 0.8)
			owner.adjustBruteLoss(-1 * healing, required_status = BODYPART_ORGANIC)
			owner.adjustFireLoss(-1 * healing, required_status = BODYPART_ORGANIC)
			owner.adjustToxLoss(-1 * healing * 0.5, TRUE, TRUE)
		owner.adjustStaminaLoss(min(-1 * healing, -1 * HEALING_SLEEP_DEFAULT))
	// Drunkenness gets reduced by 0.3% per tick (6% per 2 seconds)
	owner.set_drunk_effect(owner.get_drunk_amount() * 0.997)

	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.handle_dreams()

	if(prob(2) && owner.health > owner.crit_threshold)
		owner.emote("snore")

#undef HEALING_SLEEP_DEFAULT

/atom/movable/screen/alert/status_effect/asleep
	name = "Asleep"
	desc = "You've fallen asleep. Wait a bit and you should wake up. Unless you don't, considering how helpless you are."
	icon_state = "asleep"


//STASIS
/datum/status_effect/incapacitating/stasis
	id = "stasis"
	duration = -1
	tick_interval = 1 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/stasis
	var/last_dead_time
	/// What is added to the *life_tickrate*, -1 to freeze the ticks
	var/stasis_mod = -1

/datum/status_effect/incapacitating/stasis/proc/update_time_of_death()
	if(last_dead_time)
		var/delta = world.time - last_dead_time
		var/new_timeofdeath = owner.timeofdeath + delta
		owner.timeofdeath = new_timeofdeath
		owner.tod = station_time_timestamp(wtime=new_timeofdeath)
		last_dead_time = null
	if(owner.stat == DEAD)
		last_dead_time = world.time

/datum/status_effect/incapacitating/stasis/on_creation(mob/living/new_owner, set_duration, updating_canmove, new_stasis_mod)
	. = ..()
	if(.)
		update_time_of_death()
		stasis_mod = new_stasis_mod
		new_owner.life_tickrate += stasis_mod
		owner.reagents?.end_metabolization(owner, FALSE)

/datum/status_effect/incapacitating/stasis/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/stasis/tick()
	update_time_of_death()

/datum/status_effect/incapacitating/stasis/on_remove()
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))
	update_time_of_death()
	owner.life_tickrate -= stasis_mod
	return ..()

/datum/status_effect/incapacitating/stasis/be_replaced()
	update_time_of_death()
	owner.life_tickrate -= stasis_mod
	return ..()

/atom/movable/screen/alert/status_effect/stasis
	name = "Stasis"
	desc = "Your biological functions have halted. You could live forever this way, but it's pretty boring."
	icon_state = "stasis"

//GOLEM GANG

//OTHER DEBUFFS
/datum/status_effect/strandling //get it, strand as in durathread strand + strangling = strandling hahahahahahahahahahhahahaha i want to die
	id = "strandling"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/strandling

/datum/status_effect/strandling/on_apply()
	ADD_TRAIT(owner, TRAIT_MAGIC_CHOKE, "dumbmoron")
	return ..()

/datum/status_effect/strandling/on_remove()
	REMOVE_TRAIT(owner, TRAIT_MAGIC_CHOKE, "dumbmoron")
	return ..()

/atom/movable/screen/alert/status_effect/strandling
	name = "Choking strand"
	desc = "A magical strand of Durathread is wrapped around your neck, preventing you from breathing! Click this icon to remove the strand."
	icon_state = "his_grace"
	alerttooltipstyle = "hisgrace"

/atom/movable/screen/alert/status_effect/strandling/Click(location, control, params)
	. = ..()
	to_chat(mob_viewer, span_notice("You attempt to remove the durathread strand from around your neck."))
	if(do_after(mob_viewer, 3.5 SECONDS, mob_viewer, FALSE))
		if(isliving(mob_viewer))
			var/mob/living/L = mob_viewer
			to_chat(mob_viewer, span_notice("You succesfuly remove the durathread strand."))
			L.remove_status_effect(STATUS_EFFECT_CHOKINGSTRAND)

//OTHER DEBUFFS
/datum/status_effect/pacify
	id = "pacify"
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 1
	duration = 100
	alert_type = null

/datum/status_effect/pacify/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	. = ..()

/datum/status_effect/pacify/on_apply()
	ADD_TRAIT(owner, TRAIT_PACIFISM, "status_effect")
	return ..()

/datum/status_effect/pacify/on_remove()
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, "status_effect")

/datum/status_effect/his_wrath //does minor damage over time unless holding His Grace
	id = "his_wrath"
	duration = -1
	tick_interval = 4
	alert_type = /atom/movable/screen/alert/status_effect/his_wrath

/atom/movable/screen/alert/status_effect/his_wrath
	name = "His Wrath"
	desc = "You fled from His Grace instead of feeding Him, and now you suffer."
	icon_state = "his_grace"
	alerttooltipstyle = "hisgrace"

/datum/status_effect/his_wrath/tick()
	for(var/obj/item/his_grace/HG in owner.held_items)
		qdel(src)
		return
	owner.adjustBruteLoss(0.1)
	owner.adjustFireLoss(0.1)
	owner.adjustToxLoss(0.2, TRUE, TRUE)

/datum/status_effect/belligerent
	id = "belligerent"
	duration = 70
	tick_interval = 0 //tick as fast as possible
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/belligerent
	var/leg_damage_on_toggle = 2 //damage on initial application and when the owner tries to toggle to run
	var/cultist_damage_on_toggle = 10 //damage on initial application and when the owner tries to toggle to run, but to cultists

/atom/movable/screen/alert/status_effect/belligerent
	name = "Belligerent"
	desc = "<b><font color=#880020>Kneel, her-eti'c.</font></b>"
	icon_state = "belligerent"
	alerttooltipstyle = "clockcult"

/datum/status_effect/belligerent/on_apply()
	return do_movement_toggle(TRUE)

/datum/status_effect/belligerent/tick()
	if(!do_movement_toggle())
		qdel(src)

/datum/status_effect/belligerent/proc/do_movement_toggle(force_damage)
	var/number_legs = owner.get_num_legs(FALSE)
	if(iscarbon(owner) && !is_servant_of_ratvar(owner) && !owner.can_block_magic(charge_cost = 0) && number_legs)
		if(force_damage || owner.m_intent != MOVE_INTENT_WALK)
			if(GLOB.ratvar_awakens)
				owner.Paralyze(20)
			if(iscultist(owner))
				owner.apply_damage(cultist_damage_on_toggle * 0.5, BURN, BODY_ZONE_L_LEG)
				owner.apply_damage(cultist_damage_on_toggle * 0.5, BURN, BODY_ZONE_R_LEG)
			else
				owner.apply_damage(leg_damage_on_toggle * 0.5, BURN, BODY_ZONE_L_LEG)
				owner.apply_damage(leg_damage_on_toggle * 0.5, BURN, BODY_ZONE_R_LEG)
		if(owner.m_intent != MOVE_INTENT_WALK)
			if(!iscultist(owner))
				to_chat(owner, span_warning("Your leg[number_legs > 1 ? "s shiver":" shivers"] with pain!"))
			else //Cultists take extra burn damage
				to_chat(owner, span_warning("Your leg[number_legs > 1 ? "s burn":" burns"] with pain!"))
			owner.toggle_move_intent()
		return TRUE
	return FALSE

/datum/status_effect/belligerent/on_remove()
	if(owner.m_intent == MOVE_INTENT_WALK)
		owner.toggle_move_intent()

/datum/status_effect/maniamotor
	id = "maniamotor"
	duration = -1
	tick_interval = 10
	status_type = STATUS_EFFECT_MULTIPLE
	alert_type = null
	var/obj/structure/destructible/clockwork/powered/mania_motor/motor
	var/severity = 0 //goes up to a maximum of MAX_MANIA_SEVERITY
	var/warned_turnoff = FALSE //if we've warned that the motor is off
	var/warned_outofsight = FALSE //if we've warned that the target is out of sight of the motor
	var/static/list/mania_messages = list("Go nuts.", "Take a crack at crazy.", "Make a bid for insanity.", "Get kooky.", "Move towards mania.", "Become bewildered.", "Wax wild.", \
	"Go round the bend.", "Land in lunacy.", "Try dementia.", "Strive to get a screw loose.", "Advance forward.", "Approach the transmitter.", "Touch the antennae.", \
	"Move towards the mania motor.", "Come closer.", "Get over here already!", "Keep your eyes on the motor.")
	var/static/list/flee_messages = list("Oh, NOW you flee.", "Get back here!", "If you were smarter, you'd come back.", "Only fools run.", "You'll be back.")
	var/static/list/turnoff_messages = list("Why would they turn it-", "What are these idi-", "Fools, fools, all of-", "Are they trying to c-", "All this effort just f-")
	var/static/list/powerloss_messages = list("\"Oh, the id**ts di***t s***e en**** pow**...\"" = TRUE, "\"D*dn't **ey mak* an **te***c*i*n le**?\"" = TRUE, "\"The** f**ls for**t t* make a ***** *f-\"" = TRUE, \
	"\"No, *O, you **re so cl***-\"" = TRUE, "You hear a yell of frustration, cut off by static." = FALSE)

/datum/status_effect/maniamotor/on_creation(mob/living/new_owner, obj/structure/destructible/clockwork/powered/mania_motor/new_motor)
	. = ..()
	if(.)
		motor = new_motor

/datum/status_effect/maniamotor/Destroy()
	motor = null
	return ..()

/datum/status_effect/maniamotor/tick()
	var/is_servant = is_servant_of_ratvar(owner)
	var/span_part = severity > 50 ? "" : "_small" //let's save like one check
	if(QDELETED(motor))
		if(!is_servant)
			to_chat(owner, "<span class='sevtug[span_part]'>You feel a frustrated voice quietly fade from your mind...</span>")
		qdel(src)
		return
	if(!motor.active) //it being off makes it fall off much faster
		if(!is_servant && !warned_turnoff)
			if(can_access_clockwork_power(motor, motor.mania_cost))
				to_chat(owner, "<span class='sevtug[span_part]'>\"[text2ratvar(pick(turnoff_messages))]\"</span>")
			else
				var/pickedmessage = pick(powerloss_messages)
				to_chat(owner, "<span class='sevtug[span_part]'>[powerloss_messages[pickedmessage] ? "[text2ratvar(pickedmessage)]" : pickedmessage]</span>")
			warned_turnoff = TRUE
		severity = max(severity - 2, 0)
		if(!severity)
			qdel(src)
			return
	else
		if(prob(severity * 2))
			warned_turnoff = FALSE
		if(!(owner in viewers(7, motor))) //not being in range makes it fall off slightly faster
			if(!is_servant && !warned_outofsight)
				to_chat(owner, "<span class='sevtug[span_part]'>\"[text2ratvar(pick(flee_messages))]\"</span>")
				warned_outofsight = TRUE
			severity = max(severity - 1, 0)
			if(!severity)
				qdel(src)
				return
		else if(prob(severity * 2))
			warned_outofsight = FALSE
	if(is_servant) //heals servants of braindamage, hallucination, druggy, dizziness, and confusion
		owner.remove_status_effect(/datum/status_effect/hallucination)
		owner.remove_status_effect(/datum/status_effect/drugginess)
		owner.remove_status_effect(/datum/status_effect/drowsiness)
		owner.remove_status_effect(/datum/status_effect/confusion)
		severity = 0
	else if(!owner.can_block_magic(charge_cost = 0) && owner.stat != DEAD && severity)
		var/static/hum = get_sfx('sound/effects/screech.ogg') //same sound for every proc call
		if(owner.getToxLoss() > MANIA_DAMAGE_TO_CONVERT)
			if(is_eligible_servant(owner))
				to_chat(owner, "<span class='sevtug[span_part]'>\"[text2ratvar("You are mine and his, now.")]\"</span>")
				if(add_servant_of_ratvar(owner))
					owner.log_message("conversion was done with a Mania Motor", LOG_ATTACK, color="#BE8700")
			owner.Unconscious(100)
		else
			if(prob(severity * 0.15))
				to_chat(owner, "<span class='sevtug[span_part]'>\"[text2ratvar(pick(mania_messages))]\"</span>")
			owner.playsound_local(get_turf(motor), hum, severity, 1)
			owner.adjust_drugginess(clamp(max(severity * 0.075, 1), 0, max(0, 50 SECONDS))) //7.5% of severity per second, minimum 1
			owner.adjust_hallucinations_up_to(max(severity * 0.075, 1) SECONDS, 50 SECONDS) //7.5% of severity per second, minimum 1
			owner.adjust_dizzy_up_to(round(severity * 0.05, 1) SECONDS, 50 SECONDS) //5% of severity per second above 10 severity
			owner.adjust_confusion_up_to(round(severity * 0.025, 1) SECONDS, 25 SECONDS) //2.5% of severity per second above 20 severity
			owner.adjustToxLoss(severity * 0.02, TRUE, TRUE) //2% of severity per second
		severity--

/datum/status_effect/cultghost //is a cult ghost and can't use manifest runes
	id = "cult_ghost"
	duration = -1
	alert_type = null

/datum/status_effect/cultghost/on_apply()
	owner.see_invisible = SEE_INVISIBLE_OBSERVER
	owner.see_in_dark = 2

/datum/status_effect/cultghost/tick()
	if(owner.reagents)
		owner.reagents.del_reagent(/datum/reagent/water/holywater) //can't be deconverted

/datum/status_effect/the_shadow
	id = "the_shadow"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	duration = -1
	var/mutable_appearance/shadow

/datum/status_effect/the_shadow/on_apply()
	if(ishuman(owner))
		shadow = mutable_appearance('icons/effects/effects.dmi', "curse")
		shadow.pixel_x = -owner.pixel_x
		shadow.pixel_y = -owner.pixel_y
		owner.add_overlay(shadow)
		to_chat(owner, span_boldwarning("The shadows invade your mind, MUST. GET. THEM. OUT"))
		return TRUE
	return FALSE

/datum/status_effect/the_shadow/tick()
	var/turf/T = get_turf(owner)
	var/light_amount = T.get_lumcount()
	if(light_amount > LIGHTING_TILE_IS_DARK)
		to_chat(owner, span_notice("As the light reaches the shadows, they dissipate!"))
		qdel(src)
	if(owner.stat == DEAD)
		qdel(src)
	owner.adjust_hallucinations(2 SECONDS)
	owner.adjust_confusion(2 SECONDS)
	owner.adjustEarDamage(0, 5)

/datum/status_effect/the_shadow/Destroy()
	if(owner)
		owner.overlays -= shadow
	QDEL_NULL(shadow)
	return ..()

/datum/status_effect/crusher_mark
	id = "crusher_mark"
	duration = 300 //if you leave for 30 seconds you lose the mark, deal with it
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	var/mutable_appearance/marked_underlay
	var/obj/item/kinetic_crusher/hammer_synced

/datum/status_effect/crusher_mark/on_creation(mob/living/new_owner, obj/item/kinetic_crusher/new_hammer_synced)
	. = ..()
	if(.)
		hammer_synced = new_hammer_synced

/datum/status_effect/crusher_mark/on_apply()
	if(owner.mob_size >= MOB_SIZE_LARGE)
		marked_underlay = mutable_appearance('icons/effects/effects.dmi', "shield2")
		marked_underlay.pixel_x = -owner.pixel_x
		marked_underlay.pixel_y = -owner.pixel_y
		owner.underlays += marked_underlay
		return TRUE
	return FALSE

/datum/status_effect/crusher_mark/Destroy()
	hammer_synced = null
	if(owner)
		owner.underlays -= marked_underlay
	QDEL_NULL(marked_underlay)
	return ..()

/datum/status_effect/crusher_mark/be_replaced()
	owner.underlays -= marked_underlay //if this is being called, we should have an owner at this point.
	..()

/datum/status_effect/saw_bleed
	id = "saw_bleed"
	duration = -1 //removed under specific conditions
	tick_interval = 6
	alert_type = null
	var/mutable_appearance/bleed_overlay
	var/mutable_appearance/bleed_underlay
	var/bleed_amount = 3
	var/bleed_buildup = 3
	var/bleed_crit = 10
	var/delay_before_decay = 5
	var/bleed_damage = 200
	var/needs_to_bleed = FALSE

/datum/status_effect/saw_bleed/Destroy()
	if(owner)
		owner.cut_overlay(bleed_overlay)
		owner.underlays -= bleed_underlay
	QDEL_NULL(bleed_overlay)
	return ..()

/datum/status_effect/saw_bleed/on_apply()
	if(owner.stat == DEAD)
		return FALSE
	bleed_overlay = mutable_appearance('icons/effects/bleed.dmi', "bleed[bleed_amount]")
	bleed_underlay = mutable_appearance('icons/effects/bleed.dmi', "bleed[bleed_amount]")
	var/icon/I = icon(owner.icon, owner.icon_state, owner.dir)
	var/icon_height = I.Height()
	bleed_overlay.pixel_x = -owner.pixel_x
	bleed_overlay.pixel_y = FLOOR(icon_height * 0.25, 1)
	bleed_overlay.transform = matrix() * (icon_height/world.icon_size) //scale the bleed overlay's size based on the target's icon size
	bleed_underlay.pixel_x = -owner.pixel_x
	bleed_underlay.transform = matrix() * (icon_height/world.icon_size) * 3
	bleed_underlay.alpha = 40
	owner.add_overlay(bleed_overlay)
	owner.underlays += bleed_underlay
	return ..()

/datum/status_effect/saw_bleed/tick()
	if(owner.stat == DEAD)
		qdel(src)
	else
		if(faction_check(owner.faction, list("mining", "boss")))
			owner.apply_damage(10)
		else //This is so that it doesn't murder humans drastically as there are none in either faction.
			owner.apply_damage(2)
		add_bleed(-1)

/datum/status_effect/saw_bleed/proc/add_bleed(amount)
	owner.cut_overlay(bleed_overlay)
	owner.underlays -= bleed_underlay
	bleed_amount += amount
	if(bleed_amount)
		if(bleed_amount >= bleed_crit)
			needs_to_bleed = TRUE
			qdel(src)
		else
			if(amount > 0)
				tick_interval += delay_before_decay
			bleed_overlay.icon_state = "bleed[bleed_amount]"
			bleed_underlay.icon_state = "bleed[bleed_amount]"
			owner.add_overlay(bleed_overlay)
			owner.underlays += bleed_underlay
	else
		qdel(src)

/datum/status_effect/saw_bleed/on_remove()
	if(needs_to_bleed)
		var/turf/T = get_turf(owner)
		new /obj/effect/temp_visual/bleed/explode(T)
		for(var/d in GLOB.alldirs)
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, d)
		playsound(T, "desceration", 200, 1, -1)
		owner.adjustBruteLoss(bleed_damage)
	else
		new /obj/effect/temp_visual/bleed(get_turf(owner))

/datum/status_effect/saw_bleed/bloodletting
	id = "bloodletting"
	bleed_crit = 7
	bleed_damage = 20

/mob/living/proc/apply_necropolis_curse(set_curse)
	var/datum/status_effect/necropolis_curse/C = has_status_effect(STATUS_EFFECT_NECROPOLIS_CURSE)
	if(!set_curse)
		set_curse = pick(CURSE_BLINDING, CURSE_SPAWNING, CURSE_WASTING, CURSE_GRASPING)
	if(QDELETED(C))
		apply_status_effect(STATUS_EFFECT_NECROPOLIS_CURSE, set_curse)
	else
		C.apply_curse(set_curse)
		C.duration += 3000 //time added by additional curses

/datum/status_effect/necropolis_curse
	id = "necrocurse"
	duration = 6000 //you're cursed for 10 minutes have fun
	tick_interval = 50
	alert_type = null
	var/curse_flags = NONE
	var/effect_last_activation = 0
	var/effect_cooldown = 100
	var/obj/effect/temp_visual/curse/wasting_effect = new

/datum/status_effect/necropolis_curse/hivemind
	id = "hivecurse"
	duration = 600

/datum/status_effect/necropolis_curse/on_creation(mob/living/new_owner, set_curse)
	. = ..()
	if(.)
		apply_curse(set_curse)

/datum/status_effect/necropolis_curse/Destroy()
	if(!QDELETED(wasting_effect))
		qdel(wasting_effect)
		wasting_effect = null
	return ..()

/datum/status_effect/necropolis_curse/on_remove()
	remove_curse(curse_flags)

/datum/status_effect/necropolis_curse/proc/apply_curse(set_curse)
	curse_flags |= set_curse
	if(curse_flags & CURSE_BLINDING)
		owner.overlay_fullscreen("curse", /atom/movable/screen/fullscreen/curse, 1)

/datum/status_effect/necropolis_curse/proc/remove_curse(remove_curse)
	if(remove_curse & CURSE_BLINDING)
		owner.clear_fullscreen("curse", 50)
	curse_flags &= ~remove_curse

/datum/status_effect/necropolis_curse/tick()
	if(owner.stat == DEAD)
		return
	if(curse_flags & CURSE_WASTING)
		wasting_effect.forceMove(owner.loc)
		wasting_effect.setDir(owner.dir)
		wasting_effect.transform = owner.transform //if the owner has been stunned the overlay should inherit that position
		wasting_effect.alpha = 255
		animate(wasting_effect, alpha = 0, time = 3.2 SECONDS)
		playsound(owner, 'sound/effects/curse5.ogg', 20, 1, -1)
		owner.adjustFireLoss(0.75)
	if(effect_last_activation <= world.time)
		effect_last_activation = world.time + effect_cooldown
		if(curse_flags & CURSE_SPAWNING)
			var/turf/spawn_turf
			var/sanity = 10
			while(!spawn_turf && sanity)
				spawn_turf = locate(owner.x + pick(rand(10, 15), rand(-10, -15)), owner.y + pick(rand(10, 15), rand(-10, -15)), owner.z)
				sanity--
			if(spawn_turf)
				var/mob/living/simple_animal/hostile/asteroid/curseblob/C = new (spawn_turf)
				C.set_target = owner
				C.GiveTarget()
		if(curse_flags & CURSE_GRASPING)
			var/grab_dir = turn(owner.dir, pick(-90, 90, 180, 180)) //grab them from a random direction other than the one faced, favoring grabbing from behind
			var/turf/spawn_turf = get_ranged_target_turf(owner, grab_dir, 5)
			if(spawn_turf)
				grasp(spawn_turf)

/datum/status_effect/necropolis_curse/proc/grasp(turf/spawn_turf)
	set waitfor = FALSE
	new/obj/effect/temp_visual/dir_setting/curse/grasp_portal(spawn_turf, owner.dir)
	playsound(spawn_turf, 'sound/effects/curse2.ogg', 80, 1, -1)
	var/obj/projectile/curse_hand/C = new (spawn_turf)
	C.preparePixelProjectile(owner, spawn_turf)
	C.fire()

/obj/effect/temp_visual/curse
	icon_state = "curse"

/obj/effect/temp_visual/curse/Initialize(mapload)
	. = ..()
	deltimer(timerid)

/datum/status_effect/progenitor_curse
	duration = 200
	tick_interval = 5

/datum/status_effect/progenitor_curse/tick()
	if(owner.stat == DEAD)
		return
	var/grab_dir = turn(owner.dir, rand(-180, 180)) //grab them from a random direction
	var/turf/spawn_turf = get_ranged_target_turf(owner, grab_dir, 5)
	if(spawn_turf)
		grasp(spawn_turf)

/datum/status_effect/progenitor_curse/proc/grasp(turf/spawn_turf)
	set waitfor = FALSE
	new/obj/effect/temp_visual/dir_setting/curse/grasp_portal(spawn_turf, owner.dir)
	playsound(spawn_turf, 'sound/effects/curse2.ogg', 80, 1, -1)
	var/obj/projectile/curse_hand/progenitor/C = new (spawn_turf)
	C.preparePixelProjectile(owner, spawn_turf)
	C.fire()

//Kindle: Used by servants of Ratvar. 10-second knockdown, reduced by 1 second per 5 damage taken while the effect is active.
/datum/status_effect/kindle
	id = "kindle"
	status_type = STATUS_EFFECT_UNIQUE
	tick_interval = 5
	duration = 10 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/kindle
	var/old_health

/datum/status_effect/kindle/tick()
	owner.Paralyze(1.5 SECONDS)
	if(iscarbon(owner))
		var/mob/living/carbon/C = owner
		C.silent += 2
		C.adjust_stutter(5 SECONDS)
	if(!old_health)
		old_health = owner.health
	var/health_difference = old_health - owner.health
	if(!health_difference)
		return
	owner.visible_message(span_warning("The light in [owner]'s eyes dims as [owner.p_theyre()] harmed!"), \
	span_boldannounce("The dazzling lights dim as you're harmed!"))
	health_difference *= 2 //so 10 health difference translates to 20 deciseconds of stun reduction
	duration -= health_difference
	old_health = owner.health

/datum/status_effect/kindle/on_remove()
	owner.visible_message(span_warning("The light in [owner]'s eyes fades!"), \
	span_boldannounce("You snap out of your daze!"))

/atom/movable/screen/alert/status_effect/kindle
	name = "Dazzling Lights"
	desc = "Blinding light dances in your vision, stunning and silencing you. <i>Any damage taken will shorten the light's effects!</i>"
	icon_state = "kindle"
	alerttooltipstyle = "clockcult"


//Ichorial Stain: Applied to servants revived by a vitality matrix. Prevents them from being revived by one again until the effect fades.
/datum/status_effect/ichorial_stain
	id = "ichorial_stain"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 600
	examine_text = span_warning("SUBJECTPRONOUN is drenched in thick, blue ichor!")
	alert_type = /atom/movable/screen/alert/status_effect/ichorial_stain

/datum/status_effect/ichorial_stain/on_apply()
	owner.visible_message(span_danger("[owner] gets back up, [owner.p_their()] body dripping blue ichor!"), \
	span_userdanger("Thick blue ichor covers your body; you can't be revived like this again until it dries!"))
	return TRUE

/datum/status_effect/ichorial_stain/on_remove()
	owner.visible_message(span_danger("The blue ichor on [owner]'s body dries out!"), \
	span_boldnotice("The ichor on your body is dry - you can now be revived by vitality matrices again!"))

/atom/movable/screen/alert/status_effect/ichorial_stain
	name = "Ichorial Stain"
	desc = "Your body is covered in blue ichor! You can't be revived by vitality matrices."
	icon_state = "ichorial_stain"
	alerttooltipstyle = "clockcult"

/datum/status_effect/gonbolaPacify
	id = "gonbolaPacify"
	status_type = STATUS_EFFECT_MULTIPLE
	tick_interval = -1
	alert_type = null

/datum/status_effect/gonbolaPacify/on_apply()
	ADD_TRAIT(owner, TRAIT_PACIFISM, "gonbolaPacify")
	ADD_TRAIT(owner, TRAIT_MUTE, "gonbolaMute")
	ADD_TRAIT(owner, TRAIT_JOLLY, "gonbolaJolly")
	to_chat(owner, span_notice("You suddenly feel at peace and feel no need to make any sudden or rash actions..."))
	return ..()

/datum/status_effect/gonbolaPacify/on_remove()
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, "gonbolaPacify")
	REMOVE_TRAIT(owner, TRAIT_MUTE, "gonbolaMute")
	REMOVE_TRAIT(owner, TRAIT_JOLLY, "gonbolaJolly")

/datum/status_effect/trance
	id = "trance"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 300
	tick_interval = 10
	examine_text = span_warning("SUBJECTPRONOUN seems slow and unfocused.")
	var/stun = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/trance

/atom/movable/screen/alert/status_effect/trance
	name = "Trance"
	desc = "Everything feels so distant, and you can feel your thoughts forming loops inside your head..."
	icon_state = "high"

/datum/status_effect/trance/tick()
	if(stun)
		owner.Stun(6 SECONDS, TRUE, TRUE)
	owner.adjust_dizzy(20 SECONDS)

/datum/status_effect/trance/on_apply()
	if(!iscarbon(owner))
		return FALSE
	RegisterSignal(owner, COMSIG_MOVABLE_HEAR, PROC_REF(hypnotize))
	ADD_TRAIT(owner, TRAIT_MUTE, "trance")
	if(!owner.has_quirk(/datum/quirk/monochromatic))
		owner.add_client_colour(/datum/client_colour/monochrome)
	owner.visible_message("[stun ? span_warning("[owner] stands still as [owner.p_their()] eyes seem to focus on a distant point.") : ""]", \
	span_warning("[pick("You feel your thoughts slow down...", "You suddenly feel extremely dizzy...", "You feel like you're in the middle of a dream...","You feel incredibly relaxed...")]"))
	return TRUE

/datum/status_effect/trance/on_creation(mob/living/new_owner, _duration, _stun = TRUE)
	duration = _duration
	stun = _stun
	return ..()

/datum/status_effect/trance/on_remove()
	UnregisterSignal(owner, COMSIG_MOVABLE_HEAR)
	REMOVE_TRAIT(owner, TRAIT_MUTE, "trance")
	owner.remove_status_effect(/datum/status_effect/dizziness)
	if(!owner.has_quirk(/datum/quirk/monochromatic))
		owner.remove_client_colour(/datum/client_colour/monochrome)
	to_chat(owner, span_warning("You snap out of your trance!"))

/datum/status_effect/trance/proc/hypnotize(datum/source, list/hearing_args)
	if(!owner.can_hear())
		return
	if(hearing_args[HEARING_SPEAKER] == owner)
		return
	var/mob/living/carbon/C = owner
	C.cure_trauma_type(/datum/brain_trauma/hypnosis, TRAUMA_RESILIENCE_SURGERY) //clear previous hypnosis
	addtimer(CALLBACK(C, TYPE_PROC_REF(/mob/living/carbon, gain_trauma), /datum/brain_trauma/hypnosis, TRAUMA_RESILIENCE_SURGERY, hearing_args[HEARING_RAW_MESSAGE]), 10)
	addtimer(CALLBACK(C, TYPE_PROC_REF(/mob/living, Stun), 60, TRUE, TRUE), 15) //Take some time to think about it
	qdel(src)

/datum/status_effect/spasms
	id = "spasms"
	status_type = STATUS_EFFECT_MULTIPLE
	alert_type = null

/datum/status_effect/spasms/tick()
	if(prob(15))
		switch(rand(1,5))
			if(1)
				if((owner.mobility_flags & MOBILITY_MOVE) && isturf(owner.loc))
					to_chat(owner, span_warning("Your leg spasms!"))
					step(owner, pick(GLOB.cardinals))
			if(2)
				if(owner.incapacitated())
					return
				var/obj/item/I = owner.get_active_held_item()
				if(I)
					to_chat(owner, span_warning("Your fingers spasm!"))
					owner.log_message("used [I] due to a Muscle Spasm", LOG_ATTACK)
					I.attack_self(owner)
			if(3)
				var/prev_intent = owner.a_intent
				owner.a_intent = INTENT_HARM

				var/range = 1
				if(istype(owner.get_active_held_item(), /obj/item/gun)) //get targets to shoot at
					range = 7

				var/list/mob/living/targets = list()
				for(var/mob/M in oview(owner, range))
					if(isliving(M))
						targets += M
				if(LAZYLEN(targets))
					to_chat(owner, span_warning("Your arm spasms!"))
					owner.log_message(" attacked someone due to a Muscle Spasm", LOG_ATTACK) //the following attack will log itself
					owner.ClickOn(pick(targets))
				owner.a_intent = prev_intent
			if(4)
				var/prev_intent = owner.a_intent
				owner.a_intent = INTENT_HARM
				to_chat(owner, span_warning("Your arm spasms!"))
				owner.log_message("attacked [owner.p_them()]self to a Muscle Spasm", LOG_ATTACK)
				owner.ClickOn(owner)
				owner.a_intent = prev_intent
			if(5)
				if(owner.incapacitated())
					return
				var/obj/item/I = owner.get_active_held_item()
				var/list/turf/targets = list()
				for(var/turf/T in oview(owner, 3))
					targets += T
				if(LAZYLEN(targets) && I)
					to_chat(owner, span_warning("Your arm spasms!"))
					owner.log_message("threw [I] due to a Muscle Spasm", LOG_ATTACK)
					owner.throw_item(pick(targets))

/datum/status_effect/dna_melt
	id = "dna_melt"
	duration = 600
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/dna_melt
	var/kill_either_way = FALSE //no amount of removing mutations is gonna save you now

/datum/status_effect/dna_melt/on_creation(mob/living/new_owner, set_duration, updating_canmove)
	. = ..()
	to_chat(new_owner, span_boldwarning("My body can't handle the mutations! I need to get my mutations removed fast!"))

/datum/status_effect/dna_melt/on_remove()
	if(!ishuman(owner))
		owner.gib() //fuck you in particular
		return
	var/mob/living/carbon/human/H = owner
	H.something_horrible(kill_either_way)

/atom/movable/screen/alert/status_effect/dna_melt
	name = "Genetic Breakdown"
	desc = "I don't feel so good. Your body can't handle the mutations! You have one minute to remove your mutations, or you will be met with a horrible fate."
	icon_state = "dna_melt"

/datum/status_effect/go_away
	id = "go_away"
	duration = 100
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 1
	alert_type = /atom/movable/screen/alert/status_effect/go_away
	var/direction

/datum/status_effect/go_away/on_creation(mob/living/new_owner, set_duration, updating_canmove)
	. = ..()
	direction = pick(NORTH, SOUTH, EAST, WEST)
	new_owner.setDir(direction)

/datum/status_effect/go_away/tick()
	owner.AdjustStun(1, ignore_canstun = TRUE)
	var/turf/T = get_step(owner, direction)
	owner.forceMove(T)

/atom/movable/screen/alert/status_effect/go_away
	name = "TO THE STARS AND BEYOND!"
	desc = "I must go, my people need me!"
	icon_state = "high"

/datum/status_effect/fake_virus
	id = "fake_virus"
	duration = 3 MINUTES
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 1
	alert_type = null
	var/msg_stage = 0//so you dont get the most intense messages immediately

/datum/status_effect/fake_virus/tick()
	var/fake_msg = ""
	var/fake_emote = ""
	switch(msg_stage)
		if(0 to 300)
			if(prob(1))
				fake_msg = pick(
					span_warning(pick("Your head hurts.", "Your head pounds.")),
					span_warning(pick("You're having difficulty breathing.", "Your breathing becomes heavy.")),
					span_warning(pick("You feel dizzy.", "Your head spins.")),
					span_warning(pick("You swallow excess mucus.", "You lightly cough.")),
					span_warning(pick("Your head hurts.", "Your mind blanks for a moment.")),
					span_warning(pick("Your throat hurts.", "You clear your throat.")))
		if(301 to 600)
			if(prob(2))
				fake_msg = pick(
					span_warning(pick("Your head hurts a lot.", "Your head pounds incessantly.")),
					span_warning(pick("Your windpipe feels like a straw.", "Your breathing becomes tremendously difficult.")),
					span_warning("You feel very [pick("dizzy","woozy","faint")]."),
					span_warning(pick("You hear a ringing in your ear.", "Your ears pop.")),
					span_warning("You nod off for a moment."))
		else
			if(prob(3))
				if(prob(50))// coin flip to throw a message or an emote
					fake_msg = pick(
					span_userdanger(pick("Your head hurts!", "You feel a burning knife inside your brain!", "A wave of pain fills your head!")),
					span_userdanger(pick("Your lungs hurt!", "It hurts to breathe!")),
					span_warning(pick("You feel nauseated.", "You feel like you're going to throw up!")))
				else
					fake_emote = pick("cough", "sniff", "sneeze")

	if(fake_emote)
		owner.emote(fake_emote)
	else if(fake_msg)
		to_chat(owner, fake_msg)

	msg_stage++

//Broken Will: Applied by Devour Will, and functions similarly to Kindle. Induces sleep for 30 seconds, going down by 1 second for every point of damage the target takes. //yogs start: darkspawn
/datum/status_effect/broken_will
	id = "broken_will"
	status_type = STATUS_EFFECT_UNIQUE
	tick_interval = 5
	duration = 300
	examine_text = span_deadsay("SUBJECTPRONOUN is in a deep, deathlike sleep, with no signs of awareness to anything around them.")
	alert_type = /atom/movable/screen/alert/status_effect/broken_will
	var/old_health

/datum/status_effect/broken_will/tick()
	owner.Unconscious(15)
	if(!old_health)
		old_health = owner.health
	var/health_difference = old_health - owner.health
	if(!health_difference)
		return
	owner.visible_message(span_warning("[owner] jerks in their sleep as they're harmed!"))
	to_chat(owner, span_boldannounce("Something hits you, pulling you towards wakefulness!"))
	health_difference *= 10 //1 point of damage = 1 second = 10 deciseconds
	duration -= health_difference
	old_health = owner.health

/atom/movable/screen/alert/status_effect/broken_will
	name = "Broken Will"
	desc = "..."
	icon_state = "broken_will"
	alerttooltipstyle = "alien" //yogs end

/datum/status_effect/eldritch
	duration = 15 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	on_remove_on_mob_delete = TRUE
	///underlay used to indicate that someone is marked
	var/mutable_appearance/marked_underlay
	///path for the underlay
	var/effect_sprite = ""

/datum/status_effect/eldritch/on_creation(mob/living/new_owner, ...)
	marked_underlay = mutable_appearance('icons/effects/effects.dmi', effect_sprite,BELOW_MOB_LAYER)
	return ..()

/datum/status_effect/eldritch/on_apply()
	if(owner.mob_size >= MOB_SIZE_HUMAN)
		owner.underlays |= marked_underlay
		//owner.update_appearance(UPDATE_ICON)
		return TRUE
	return FALSE

/datum/status_effect/eldritch/Destroy()
	owner.underlays &= marked_underlay
	QDEL_NULL(marked_underlay)
	return ..()

/**
  * What happens when this mark gets poppedd
  *
  * Adds actual functionality to each mark
  */
/datum/status_effect/eldritch/proc/on_effect()
	playsound(owner, 'sound/magic/repulse.ogg', 75, TRUE)
	qdel(src) //what happens when this is procced.

//Each mark has diffrent effects when it is destroyed that combine with the mansus grasp effect.
/datum/status_effect/eldritch/flesh
	id = "flesh_mark"
	effect_sprite = "emark1"

/datum/status_effect/eldritch/flesh/on_effect()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		var/obj/item/bodypart/bodypart = pick(H.bodyparts)
		var/datum/wound/slash/severe/crit_wound = new
		crit_wound.apply_wound(bodypart)
	return ..()

/datum/status_effect/eldritch/ash
	id = "ash_mark"
	effect_sprite = "emark2"
	///Dictates how much damage and stamina loss this mark will cause.
	var/repetitions = 1

/datum/status_effect/eldritch/ash/on_creation(mob/living/new_owner, _repetition = 5)
	. = ..()
	repetitions = max(1,_repetition)

/datum/status_effect/eldritch/ash/on_effect()
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.adjustFireLoss(5 * repetitions)
		carbon_owner.adjust_fire_stacks(2)
		carbon_owner.ignite_mob()
		for(var/mob/living/carbon/victim in range(1,carbon_owner))
			if(IS_HERETIC(victim) || victim == carbon_owner)
				continue
			victim.apply_status_effect(type,repetitions-1)
			break
	return ..()

/datum/status_effect/eldritch/rust
	id = "rust_mark"
	effect_sprite = "emark3"

/datum/status_effect/eldritch/rust/on_effect()
	if(!iscarbon(owner))
		return
	var/mob/living/carbon/carbon_owner = owner
	for(var/obj/item/I in carbon_owner.get_all_gear())
		//Affects roughly 75% of items
		if(!QDELETED(I) && prob(75)) //Just in case
			I.take_damage(100)
	return ..()

/datum/status_effect/corrosion_curse
	id = "corrosion_curse"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	tick_interval = 1 SECONDS

/datum/status_effect/corrosion_curse/on_creation(mob/living/new_owner, ...)
	. = ..()
	to_chat(owner, span_danger("Your feel your body starting to break apart..."))

/datum/status_effect/corrosion_curse/tick()
	. = ..()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	var/chance = rand(0,100)
	switch(chance)
		if(0 to 19)
			H.vomit()
		if(20 to 29)
			H.adjust_dizzy(10)
		if(30 to 39)
			H.adjustOrganLoss(ORGAN_SLOT_LIVER,5)
		if(40 to 49)
			H.adjustOrganLoss(ORGAN_SLOT_HEART,5)
		if(50 to 59)
			H.adjustOrganLoss(ORGAN_SLOT_STOMACH,5)
		if(60 to 69)
			H.adjustOrganLoss(ORGAN_SLOT_EYES,10)
		if(70 to 79)
			H.adjustOrganLoss(ORGAN_SLOT_EARS,10)
		if(80 to 89)
			H.adjustOrganLoss(ORGAN_SLOT_LUNGS,10)
		if(90 to 99)
			H.adjustOrganLoss(ORGAN_SLOT_TONGUE,10)
		if(100)
			H.adjustOrganLoss(ORGAN_SLOT_BRAIN,20)
	
/datum/status_effect/eldritch/void
	id = "void mark"
	effect_sprite = "emark4"

/datum/status_effect/eldritch/void/on_effect()
	owner.apply_status_effect(/datum/status_effect/void_chill/major)
	owner.adjust_silence(10 SECONDS)
	return ..()

/datum/status_effect/amok
	id = "amok"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	duration = 10 SECONDS
	tick_interval = 1 SECONDS

/datum/status_effect/amok/on_apply(mob/living/afflicted)
	. = ..()
	to_chat(owner, span_boldwarning("Your feel filled with a rage that is not your own!"))

/datum/status_effect/amok/tick()
	. = ..()
	var/prev_intent = owner.a_intent
	owner.a_intent = INTENT_HARM

	var/list/mob/living/targets = list()
	for(var/mob/living/potential_target in oview(owner, 1))
		if(IS_HERETIC(potential_target) || potential_target.mind?.has_antag_datum(/datum/antagonist/heretic_monster))
			continue
		targets += potential_target
	if(LAZYLEN(targets))
		owner.log_message(" attacked someone due to the amok debuff.", LOG_ATTACK) //the following attack will log itself
		owner.ClickOn(pick(targets))
	owner.a_intent = prev_intent

/datum/status_effect/cloudstruck
	id = "cloudstruck"
	status_type = STATUS_EFFECT_REPLACE
	duration = 3 SECONDS
	on_remove_on_mob_delete = TRUE
	///This overlay is applied to the owner for the duration of the effect.
	var/mutable_appearance/mob_overlay

/datum/status_effect/cloudstruck/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	. = ..()

/datum/status_effect/cloudstruck/on_apply()
	mob_overlay = mutable_appearance('icons/effects/eldritch.dmi', "cloud_swirl", ABOVE_MOB_LAYER)
	owner.overlays += mob_overlay
	//owner.update_appearance(UPDATE_ICON)
	ADD_TRAIT(owner, TRAIT_BLIND, "cloudstruck")
	return TRUE

/datum/status_effect/cloudstruck/on_remove()
	. = ..()
	if(QDELETED(owner))
		return
	REMOVE_TRAIT(owner, TRAIT_BLIND, "cloudstruck")
	if(owner)
		owner.overlays -= mob_overlay
		//owner.update_appearance(UPDATE_ICON)

/datum/status_effect/cloudstruck/Destroy()
	. = ..()
	QDEL_NULL(mob_overlay)

/datum/status_effect/exposed
	id = "exposed"
	duration = 10 SECONDS
	///damage multiplier
	var/power = 1.15

/datum/status_effect/exposed/on_apply()
	. = ..()
	if(.)
		owner.add_filter("exposed", 2, list("type" = "outline", "color" = COLOR_YELLOW, "size" = 1))
		if(ismegafauna(owner))
			power = 1.30
			duration *= 4
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.physiology.brute_mod *= power
			H.physiology.burn_mod *= power
			H.physiology.tox_mod *= power
			H.physiology.oxy_mod *= power
			H.physiology.clone_mod *= power
			H.physiology.stamina_mod *= power
		else if(isanimal(owner))
			var/mob/living/simple_animal/S = owner
			for(var/i in S.damage_coeff)
				S.damage_coeff[i] *= power

/datum/status_effect/exposed/on_remove()
	owner.remove_filter("exposed")
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.physiology.brute_mod /= power
		H.physiology.burn_mod /= power
		H.physiology.tox_mod /= power
		H.physiology.oxy_mod /= power
		H.physiology.clone_mod /= power
		H.physiology.stamina_mod /= power
	else if(isanimal(owner))
		var/mob/living/simple_animal/S = owner
		for(var/i in S.damage_coeff)
			S.damage_coeff[i] /= power

/datum/status_effect/knuckled
    id = "knuckle_wound"
    duration = 10 SECONDS
    status_type = STATUS_EFFECT_REPLACE
    alert_type = null
    var/mutable_appearance/bruise
    var/obj/item/melee/knuckles

/datum/status_effect/knuckled/on_apply()
    bruise = mutable_appearance('icons/effects/effects.dmi', "rshield")
    bruise.pixel_x = -owner.pixel_x
    bruise.pixel_y = -owner.pixel_y
    owner.underlays += bruise
    return TRUE

/datum/status_effect/knuckled/Destroy()
    if(owner)
        owner.underlays -= bruise
    QDEL_NULL(bruise)
    return ..()

/datum/status_effect/knuckled/be_replaced()
    owner.underlays -= bruise
    ..()

/datum/status_effect/taming
	id = "taming"
	duration = -1
	tick_interval = 6
	alert_type = null
	var/tame_amount = 1
	var/tame_buildup = 1
	var/tame_crit = 35
	var/needs_to_tame = FALSE
	var/mob/living/tamer

/datum/status_effect/taming/on_creation(mob/living/owner, mob/living/user)
	. = ..()
	if(!.)
		return
	tamer = user

/datum/status_effect/taming/on_apply()
	if(owner.stat == DEAD)
		return FALSE
	return ..()

/datum/status_effect/taming/tick()
	if(owner.stat == DEAD)
		qdel(src)

/datum/status_effect/taming/proc/add_tame(amount)
	tame_amount += amount
	if(tame_amount)
		if(tame_amount >= tame_crit)
			needs_to_tame = TRUE
			qdel(src)
	else
		qdel(src)

/datum/status_effect/taming/on_remove()
	var/mob/living/simple_animal/hostile/M = owner
	if(needs_to_tame)
		var/turf/T = get_turf(M)
		new /obj/effect/temp_visual/love_heart(T)
		M.drop_loot()
		M.loot = null
		M.add_atom_colour("#11c42f", FIXED_COLOUR_PRIORITY)
		M.faction = tamer.faction
		to_chat(tamer, span_notice("[M] is now friendly after exposure to the flowers!"))
		. = ..()

/datum/status_effect/exhumed
	id = "exhume"
	tick_interval = -1
	alert_type = null

/datum/status_effect/catchup
	id = "catchup"
	duration = 1 SECONDS
	var/newcolor = list(rgb(77,77,77), rgb(150,150,150), rgb(28,28,28), rgb(0,0,0))

/datum/status_effect/catchup/on_apply()
	. = ..()
	if(.)
		owner.add_movespeed_modifier("catchup", update=TRUE, priority=100, multiplicative_slowdown=1.5)
		owner.add_atom_colour(newcolor, FIXED_COLOUR_PRIORITY)

/datum/status_effect/catchup/on_remove()
	owner.remove_movespeed_modifier("catchup")
	owner.remove_atom_colour(FIXED_COLOUR_PRIORITY)

/datum/status_effect/void_chill
	id = "void_chill"
	alert_type = /atom/movable/screen/alert/status_effect/void_chill
	duration = 8 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 0.5 SECONDS
	/// The amount the victim's body temperature changes each tick() in kelvin. Multiplied by TEMPERATURE_DAMAGE_COEFFICIENT.
	var/cooling_per_tick = -14

/atom/movable/screen/alert/status_effect/void_chill
	name = "Void Chill"
	desc = "There's something freezing you from within and without. You've never felt cold this oppressive before..."
	icon_state = "void_chill"

/datum/status_effect/void_chill/on_apply()
	owner.add_atom_colour(COLOR_BLUE_LIGHT, TEMPORARY_COLOUR_PRIORITY)
	return TRUE

/datum/status_effect/void_chill/on_remove()
	owner.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, COLOR_BLUE_LIGHT)

/datum/status_effect/void_chill/tick(seconds_between_ticks)
	owner.adjust_bodytemperature(cooling_per_tick * TEMPERATURE_DAMAGE_COEFFICIENT)

/datum/status_effect/void_chill/major
	duration = 10 SECONDS
	cooling_per_tick = -20

/datum/status_effect/void_chill/lasting
	id = "lasting_void_chill"
	duration = -1


