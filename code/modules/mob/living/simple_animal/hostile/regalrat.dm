/mob/living/simple_animal/hostile/regalrat
	name = "feral regal rat"
	desc = "An evolved rat, created through some strange science. It leads nearby rats with deadly efficiency to protect its kingdom. Not technically a king."
	icon_state = "regalrat"
	icon_living = "regalrat"
	icon_dead = "regalrat_dead"
	gender = NEUTER
	speak_chance = 0
	turns_per_move = 5
	maxHealth = 70
	health = 70
	see_in_dark = 15
	obj_damage = 10
	butcher_results = list(/obj/item/clothing/head/crown = 1,)
	response_help = "glares at"
	response_disarm = "skoffs at"
	response_harm = "slashes"
	melee_damage_lower = 13
	melee_damage_upper = 15
	attack_sound = 'sound/weapons/bladeslice.ogg'
	attack_vis_effect = ATTACK_EFFECT_CLAW
	attacktext = "slashes"
	attack_sound = 'sound/weapons/punch1.ogg'
	ventcrawler = VENTCRAWLER_ALWAYS
	unique_name = TRUE
	faction = list("rat")
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	var/datum/action/cooldown/riot
	var/datum/action/cooldown/domain
	var/opening_airlock = FALSE
	///Number assigned to rats and mice, checked when determining infighting.

/mob/living/simple_animal/hostile/regalrat/Initialize(mapload)
	. = ..()
	riot = new /datum/action/cooldown/riot
	domain = new /datum/action/cooldown/domain
	riot.Grant(src)
	domain.Grant(src)
	var/kingdom = pick("Plague","Miasma","Maintenance","Trash","Garbage","Rat","Vermin","Cheese")
	var/title = pick("King","Lord","Prince","Emperor","Supreme","Overlord","Master","Shogun","Bojar","Tsar","Hetman")
	name = "[kingdom] [title]"
	language_holder += new /datum/language_holder/mouse(src)

/mob/living/simple_animal/hostile/regalrat/handle_automated_action()
	if(prob(20))
		riot.Trigger()
	return ..()

/mob/living/simple_animal/hostile/regalrat/CanAttack(atom/the_target)
	if(istype(the_target,/mob/living/simple_animal))
		var/mob/living/A = the_target
		if(istype(the_target, /mob/living/simple_animal/hostile/regalrat) && A.stat == CONSCIOUS)
			return TRUE
		if(istype(the_target, /mob/living/simple_animal/hostile/rat) && A.stat == CONSCIOUS)
			var/mob/living/simple_animal/hostile/rat/R = the_target
			if(R.faction_check_mob(src, TRUE))
				return FALSE
			else
				return TRUE
		return ..()

/mob/living/simple_animal/hostile/regalrat/examine(mob/user)
	. = ..()
	if(istype(user,/mob/living/simple_animal/hostile/rat))
		var/mob/living/simple_animal/hostile/rat/ratself = user
		if(ratself.faction_check_mob(src, TRUE))
			. += "<span class='notice'>This is your king. Long live his majesty!</span>"
		else
			. += "<span class='warning'>This is a false king! Strike him down!</span>"
	else if(istype(user,/mob/living/simple_animal/hostile/regalrat) && (user != src))
		. += "<span class='warning'>Who is this foolish false king? This will not stand!</span>"

/mob/living/simple_animal/hostile/regalrat/handle_environment(datum/gas_mixture/environment)
	. = ..()
	if(stat == DEAD || !environment || !environment.get_moles(/datum/gas/miasma))
		return
	var/miasma_percentage = environment.get_moles(/datum/gas/miasma)/environment.total_moles()
	if(miasma_percentage>=0.25)
		heal_bodypart_damage(1)

/**
  *This action checks all nearby mice, and converts them into hostile rats. If no mice are nearby, creates a new one.
  */

/datum/action/cooldown/riot
	name = "Raise Army"
	desc = "Raise an army out of the hordes of mice and pests crawling around the maintenance shafts."
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_INCAPACITATED
	button_icon = 'icons/mob/actions/actions_animal.dmi'
	button_icon_state = "riot"
	background_icon_state = "bg_clock"
	overlay_icon_state = "bg_clock_border"
	cooldown_time = 8 SECONDS
	melee_cooldown_time = 0 SECONDS
	/// How close does something need to be for us to recruit it?
	var/range = 5
	/// Commands you can give to your mouse army
//	var/static/list/mouse_commands = list(
//		/datum/pet_command/idle,
//		/datum/pet_command/free,
//		/datum/pet_command/follow,
//		/datum/pet_command/point_targetting/attack/mouse
//	)
	/// Commands you can give to glockroaches
//	var/static/list/glockroach_commands = list(
//		/datum/pet_command/idle,
//		/datum/pet_command/free,
//		/datum/pet_command/follow,
//		/datum/pet_command/point_targetting/attack/glockroach
//	)

/datum/action/cooldown/riot/Activate()
	if(!isopenturf(owner.loc))
		to_chat(owner, span_warning("You can't use raise soldiers while in an object!"))
		return
	var/cap = CONFIG_GET(number/ratcap)
	var/something_from_nothing = FALSE
	for(var/mob/living/simple_animal/mouse/M in oview(owner, 5))
		var/mob/living/simple_animal/hostile/rat/new_rat = new(get_turf(M))
		var/bodycolor = M.body_color
		new_rat.body_color = bodycolor
		if(new_rat.body_color) //Coloring rats!
			new_rat.icon_state = "mouse_[new_rat.body_color]"
			new_rat.icon_living = "mouse_[new_rat.body_color]"
			new_rat.icon_dead = "mouse_[new_rat.body_color]_dead"
		something_from_nothing = TRUE
		if(M.mind && M.stat == CONSCIOUS)
			M.mind.transfer_to(new_rat)
		if(istype(owner,/mob/living/simple_animal/hostile/regalrat))
			var/mob/living/simple_animal/hostile/regalrat/giantrat = owner
			new_rat.faction = giantrat.faction
		qdel(M)
	if(!something_from_nothing)
		if(LAZYLEN(SSmobs.cheeserats) >= cap)
			to_chat(owner,"<span class='warning'>There's too many mice on this station to beckon a new one! Find them first!</span>")
			return
		new /mob/living/simple_animal/mouse(owner.loc)
		owner.visible_message("<span class='warning'>[owner] commands a mouse to its side!</span>")
	else
		owner.visible_message("<span class='warning'>[owner] commands its army to action, mutating them into rats!</span>")
	StartCooldown()

/**
 *Increase the rat king's domain
 */
/datum/action/cooldown/domain
	name = "Rat King's Domain"
	desc = "Corrupts this area to be more suitable for your rat army."
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_INCAPACITATED
	cooldown_time = 6 SECONDS
	melee_cooldown_time = 0 SECONDS
	button_icon = 'icons/mob/actions/actions_animal.dmi'
	background_icon_state = "bg_clock"
	overlay_icon_state = "bg_clock_border"
	button_icon_state = "coffer"

/datum/action/cooldown/domain/proc/domain()
	var/turf/T = get_turf(owner)
	T.atmos_spawn_air("miasma=4;TEMP=[T20C]")
	switch (rand(1,10))
		if (8)
			new /obj/effect/decal/cleanable/vomit(T)
		if (9)
			new /obj/effect/decal/cleanable/vomit/old(T)
		if (10)
			new /obj/effect/decal/cleanable/oil/slippery(T)
		else
			new /obj/effect/decal/cleanable/dirt(T)
	StartCooldown()

/datum/action/cooldown/domain/Activate()
	StartCooldown(10 SECONDS)
	domain()
	StartCooldown()

#define REGALRAT_INTERACTION "regalrat"
/mob/living/simple_animal/hostile/regalrat/AttackingTarget()
	if (DOING_INTERACTION(src, REGALRAT_INTERACTION))
		return
	if (QDELETED(target))
		return
	if(istype(target, /obj/machinery/door/airlock))
		pry_door(target)
		return

	if (target.reagents && target.is_injectable(src, allowmobs = TRUE) && !istype(target, /obj/item/reagent_containers/food/snacks/cheesewedge))
		src.visible_message(span_warning("[src] starts licking [target] passionately!"), span_notice("You start licking [target]..."))
		if(do_after(src, 2 SECONDS, target))
			target.reagents.add_reagent(/datum/reagent/rat_spit, rand(1,3), no_react = TRUE)
			to_chat(src, span_notice("You finish licking [target]."))
	else if(istype(target, /obj/item/reagent_containers/food/snacks/cheesewedge))
		to_chat(src, span_green("You eat [target], restoring some health."))
		heal_bodypart_damage(30)
		qdel(target)

	if (DOING_INTERACTION(src, REGALRAT_INTERACTION)) // check again in case we started interacting
		return
	return ..()

#undef REGALRAT_INTERACTION

/**
 * Allows rat king to pry open an airlock if it isn't locked.
 *
 * A proc used for letting the rat king pry open airlocks instead of just attacking them.
 * This allows the rat king to traverse the station when there is a lack of vents or
 * accessible doors, something which is common in certain rat king spawn points.
 */
/mob/living/simple_animal/hostile/regalrat/proc/pry_door(target)
	if(opening_airlock)
		return FALSE
	var/obj/machinery/door/airlock/prying_door = target
	if(!prying_door.density || prying_door.locked || prying_door.welded)
		return FALSE
	opening_airlock = TRUE
	visible_message(
		span_warning("[src] begins prying open the airlock..."),
		span_notice("You begin digging your claws into the airlock..."),
		span_warning("You hear groaning metal..."),
	)
	var/time_to_open = 0.5 SECONDS
	if(prying_door.hasPower())
		time_to_open = 5 SECONDS
		playsound(src, 'sound/machines/airlock_alien_prying.ogg', 100, vary = TRUE)
	if(do_after(src, time_to_open, prying_door))
		opening_airlock = FALSE
		if(prying_door.density && !prying_door.open(2))
			to_chat(src, span_warning("Despite your efforts, the airlock managed to resist your attempts to open it!"))
			return FALSE
		prying_door.open()
		return FALSE
	opening_airlock = FALSE

/**
 *Spittle; harmless reagent that is added by rat king, and makes you disgusted.
 */

/datum/reagent/rat_spit
	name = "Rat Spit"
	description = "Something coming from a rat. Dear god! Who knows where it's been!"
	reagent_state = LIQUID
	color = "#C8C8C8"
	metabolization_rate = 0.03 * REAGENTS_METABOLISM
	taste_description = "something funny"
	overdose_threshold = 20

/datum/reagent/rat_spit/on_mob_metabolize(mob/living/L)
	..()
	if(HAS_TRAIT(L, TRAIT_AGEUSIA))
		return
	to_chat(L, span_notice("This food has a funny taste!"))

/datum/reagent/rat_spit/overdose_start(mob/living/M)
	..()
	var/mob/living/carbon/victim = M
	if (istype(victim) && !("rat" in victim.faction))
		to_chat(victim, span_userdanger("With this last sip, you feel your body convulsing horribly from the contents you've ingested. As you contemplate your actions, you sense an awakened kinship with rat-kind and their newly risen leader!"))
		victim.faction |= "rat"
		victim.vomit()
	metabolization_rate = 10 * REAGENTS_METABOLISM

/datum/reagent/rat_spit/on_mob_life(mob/living/carbon/C)
	if(prob(15))
		to_chat(C, span_notice("You feel queasy!"))
		C.adjust_disgust(3)
	else if(prob(10))
		to_chat(C, span_warning("That food does not sit up well!"))
		C.adjust_disgust(5)
	else if(prob(5))
		C.vomit()
	..()

/mob/living/simple_animal/hostile/regalrat/controlled
	name = "regal rat"

/mob/living/simple_animal/hostile/regalrat/controlled/Initialize(mapload)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(get_player))

/mob/living/simple_animal/hostile/regalrat/controlled/proc/get_player()
	var/list/mob/dead/observer/candidates = pollGhostCandidates("Do you want to play as the Royal Rat, cheesey be their crown?", ROLE_MOUSE, null, FALSE, 100, POLL_IGNORE_SENTIENCE_POTION)
	if(LAZYLEN(candidates) && !mind)
		var/mob/dead/observer/C = pick(candidates)
		key = C.key
		notify_ghosts("All rise for the rat king, ascendant to the throne in \the [get_area(src)].", source = src, action = NOTIFY_ORBIT, flashwindow = FALSE, header = "Sentient Rat Created")
	to_chat(src, span_notice("You are an independent, invasive force on the station! Horde coins, trash, cheese, and the like from the safety of darkness!"))
