#define FIREALARM_COOLDOWN 67 // Chosen fairly arbitrarily, it is the length of the audio in FireAlarm.ogg. The actual track length is 7 seconds 8ms but but the audio stops at 6s 700ms

/obj/item/electronics/firealarm
	name = "fire alarm electronics"
	custom_price = 5
	desc = "A fire alarm circuit. Can handle heat levels up to 40 degrees celsius."

/obj/item/wallframe/firealarm
	name = "fire alarm frame"
	desc = "Used for building fire alarms."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "fire_bitem"
	result_path = /obj/machinery/firealarm

/obj/machinery/firealarm
	name = "fire alarm"
	desc = "<i>\"Pull this in case of emergency\"</i>. Thus, keep pulling it forever."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "fire0"
	max_integrity = 250
	integrity_failure = 100
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, RAD = 100, FIRE = 90, ACID = 30)
	use_power = IDLE_POWER_USE
	idle_power_usage = 2
	active_power_usage = 6
	power_channel = AREA_USAGE_ENVIRON
	resistance_flags = FIRE_PROOF

	light_power = 0
	light_range = 7
	light_color = "#ff3232"

	var/detecting = 1
	var/buildstage = 2 // 2 = complete, 1 = no wires, 0 = circuit gone
	var/last_alarm = 0
	var/area/myarea = null

/obj/machinery/firealarm/Initialize(mapload, dir, building)
	. = ..()
	if(dir)
		src.setDir(dir)
	if(building)
		buildstage = 0
		panel_open = TRUE
		pixel_x = (dir & 3)? 0 : (dir == 4 ? -24 : 24)
		pixel_y = (dir & 3)? (dir ==1 ? -24 : 24) : 0
	update_appearance(UPDATE_ICON)
	myarea = get_area(src)
	LAZYADD(myarea.firealarms, src)

/obj/machinery/firealarm/Destroy()
	LAZYREMOVE(myarea.firealarms, src)
	return ..()

/obj/machinery/firealarm/update_icon_state()
	. = ..()
	if(panel_open)
		icon_state = "fire_b[buildstage]"
		return
	if(stat & BROKEN)
		icon_state = "firex"
		return
	icon_state = "fire0"

/obj/machinery/firealarm/update_overlays()
	. = ..()
	SSvis_overlays.remove_vis_overlay(src, managed_vis_overlays)
	if(stat & (NOPOWER|BROKEN))
		return

	. += "fire_overlay"

	if(is_station_level(z))
		. += "fire_[GLOB.security_level]"
		SSvis_overlays.add_vis_overlay(src, icon, "fire_[GLOB.security_level]", layer, plane, dir)
		SSvis_overlays.add_vis_overlay(src, icon, "fire_[GLOB.security_level]", layer, EMISSIVE_PLANE, dir)
	else
		. += "fire_[SEC_LEVEL_GREEN]"
		SSvis_overlays.add_vis_overlay(src, icon, "fire_[SEC_LEVEL_GREEN]", layer, plane, dir)
		SSvis_overlays.add_vis_overlay(src, icon, "fire_[SEC_LEVEL_GREEN]", layer, EMISSIVE_PLANE, dir)

	var/area/A = src.loc
	A = A.loc

	if(!detecting || !A.fire)
		. += "fire_off"
		SSvis_overlays.add_vis_overlay(src, icon, "fire_off", layer, plane, dir)
		SSvis_overlays.add_vis_overlay(src, icon, "fire_off", layer, EMISSIVE_PLANE, dir)
	else if(obj_flags & EMAGGED)
		. += "fire_emagged"
		SSvis_overlays.add_vis_overlay(src, icon, "fire_emagged", layer, plane, dir)
		SSvis_overlays.add_vis_overlay(src, icon, "fire_emagged", layer, EMISSIVE_PLANE, dir)
	else
		. += "fire_on"
		SSvis_overlays.add_vis_overlay(src, icon, "fire_on", layer, plane, dir)
		SSvis_overlays.add_vis_overlay(src, icon, "fire_on", layer, EMISSIVE_PLANE, dir)

/obj/machinery/firealarm/emp_act(severity)
	. = ..()

	if (. & EMP_PROTECT_SELF)
		return

	if(prob(50 / severity))
		alarm()

/obj/machinery/firealarm/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(obj_flags & EMAGGED)
		return FALSE
	obj_flags |= EMAGGED
	update_appearance(UPDATE_ICON)
	if(user)
		user.visible_message(span_warning("Sparks fly out of [src]!"),
							span_notice("You emag [src], disabling its thermal sensors."))
	playsound(src, "sparks", 50, 1)
	return TRUE

/obj/machinery/firealarm/temperature_expose(datum/gas_mixture/air, temperature, volume)
	var/turf/open/T = get_turf(src)
	if((temperature >= FIRE_MINIMUM_TEMPERATURE_TO_EXIST || temperature < BODYTEMP_COLD_DAMAGE_LIMIT || (istype(T) && T.turf_fire)) && (last_alarm+FIREALARM_COOLDOWN < world.time) && !(obj_flags & EMAGGED) && detecting && !stat)
		alarm()
	..()

/obj/machinery/firealarm/proc/alarm(mob/user)
	if(!is_operational() || (last_alarm+FIREALARM_COOLDOWN > world.time))
		return
	last_alarm = world.time
	var/area/A = get_area(src)
	A.firealert(src)
	playsound(loc, 'goon/sound/machinery/FireAlarm.ogg', 75)
	if(user)
		log_game("[user] triggered a fire alarm at [COORD(src)]")

/obj/machinery/firealarm/proc/reset(mob/user)
	if(!is_operational())
		return
	var/area/A = get_area(src)
	A.firereset(src)
	if(user)
		log_game("[user] reset a fire alarm at [COORD(src)]")

/obj/machinery/firealarm/attack_hand(mob/user)
	if(buildstage != 2)
		return ..()
	add_fingerprint(user)
	play_click_sound("button")
	var/area/A = get_area(src)
	if(A.fire || A.party)
		reset(user)
	else
		alarm(user)

/obj/machinery/firealarm/attack_ai(mob/user)
	return attack_hand(user)

/obj/machinery/firealarm/attack_robot(mob/user)
	return attack_hand(user)

/obj/machinery/firealarm/attackby(obj/item/W, mob/user, params)
	add_fingerprint(user)

	if(W.tool_behaviour == TOOL_SCREWDRIVER && buildstage == 2)
		W.play_tool_sound(src)
		panel_open = !panel_open
		to_chat(user, span_notice("The wires have been [panel_open ? "exposed" : "unexposed"]."))
		update_appearance(UPDATE_ICON)
		return

	if(panel_open)

		if(W.tool_behaviour == TOOL_WELDER && user.a_intent == INTENT_HELP)
			if(obj_integrity < max_integrity)
				if(!W.tool_start_check(user, amount=0))
					return

				to_chat(user, span_notice("You begin repairing [src]..."))
				if(W.use_tool(src, user, 40, volume=50))
					obj_integrity = max_integrity
					to_chat(user, span_notice("You repair [src]."))
			else
				to_chat(user, span_warning("[src] is already in good condition!"))
			return

		switch(buildstage)
			if(2)
				if(W.tool_behaviour == TOOL_MULTITOOL)
					detecting = !detecting
					if (src.detecting)
						user.visible_message("[user] has reconnected [src]'s detecting unit!", span_notice("You reconnect [src]'s detecting unit."))
					else
						user.visible_message("[user] has disconnected [src]'s detecting unit!", span_notice("You disconnect [src]'s detecting unit."))
					return

				else if(W.tool_behaviour == TOOL_WIRECUTTER)
					buildstage = 1
					W.play_tool_sound(src)
					new /obj/item/stack/cable_coil(user.loc, 5)
					to_chat(user, span_notice("You cut the wires from \the [src]."))
					update_appearance(UPDATE_ICON)
					return

				else if(W.force) //hit and turn it on
					..()
					var/area/A = get_area(src)
					if(!A.fire)
						alarm()
					return

			if(1)
				if(istype(W, /obj/item/stack/cable_coil))
					var/obj/item/stack/cable_coil/coil = W
					if(coil.get_amount() < 5)
						to_chat(user, span_warning("You need more cable for this!"))
					else
						coil.use(5)
						buildstage = 2
						to_chat(user, span_notice("You wire \the [src]."))
						update_appearance(UPDATE_ICON)
					return

				else if(W.tool_behaviour == TOOL_CROWBAR)
					user.visible_message("[user.name] removes the electronics from [src.name].", \
										span_notice("You start prying out the circuit..."))
					if(W.use_tool(src, user, 20, volume=50))
						if(buildstage == 1)
							if(stat & BROKEN)
								to_chat(user, span_notice("You remove the destroyed circuit."))
								stat &= ~BROKEN
							else
								to_chat(user, span_notice("You pry out the circuit."))
								new /obj/item/electronics/firealarm(user.loc)
							buildstage = 0
							update_appearance(UPDATE_ICON)
					return
			if(0)
				if(istype(W, /obj/item/electronics/firealarm))
					to_chat(user, span_notice("You insert the circuit."))
					qdel(W)
					buildstage = 1
					update_appearance(UPDATE_ICON)
					return

				else if(istype(W, /obj/item/electroadaptive_pseudocircuit))
					var/obj/item/electroadaptive_pseudocircuit/P = W
					if(!P.adapt_circuit(user, 15))
						return
					user.visible_message(span_notice("[user] fabricates a circuit and places it into [src]."), \
					span_notice("You adapt a fire alarm circuit and slot it into the assembly."))
					buildstage = 1
					update_appearance(UPDATE_ICON)
					return

				else if(W.tool_behaviour == TOOL_WRENCH)
					user.visible_message("[user] removes the fire alarm assembly from the wall.", \
										 span_notice("You remove the fire alarm assembly from the wall."))
					var/obj/item/wallframe/firealarm/frame = new /obj/item/wallframe/firealarm()
					frame.forceMove(user.drop_location())
					W.play_tool_sound(src)
					qdel(src)
					return

	return ..()


/obj/machinery/firealarm/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if((buildstage == 0) && (the_rcd.upgrade & RCD_UPGRADE_SIMPLE_CIRCUITS))
		return list("mode" = RCD_UPGRADE_SIMPLE_CIRCUITS, "delay" = 20, "cost" = 1)	
	return FALSE

/obj/machinery/firealarm/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	switch(passed_mode)
		if(RCD_UPGRADE_SIMPLE_CIRCUITS)
			user.visible_message(span_notice("[user] fabricates a circuit and places it into [src]."), \
			span_notice("You adapt a fire alarm circuit and slot it into the assembly."))
			buildstage = 1
			update_appearance(UPDATE_ICON)
			return TRUE
	return FALSE

/obj/machinery/firealarm/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = TRUE, attack_dir, armour_penetration = 0)
	. = ..()
	if(.) //damage received
		if(obj_integrity > 0 && !(stat & BROKEN) && buildstage != 0)
			if(prob(33))
				alarm()

/obj/machinery/firealarm/singularity_pull(S, current_size)
	if (current_size >= STAGE_FIVE) // If the singulo is strong enough to pull anchored objects, the fire alarm experiences integrity failure
		deconstruct()
	..()

/obj/machinery/firealarm/obj_break(damage_flag)
	if(buildstage == 0) //can't break the electronics if there isn't any inside.
		return

	. = ..()
	if(.)
		LAZYREMOVE(myarea.firealarms, src)

/obj/machinery/firealarm/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/sheet/metal(loc, 1)
		if(!(stat & BROKEN))
			var/obj/item/I = new /obj/item/electronics/firealarm(loc)
			if(!disassembled)
				I.obj_integrity = I.max_integrity * 0.5
		new /obj/item/stack/cable_coil(loc, 3)
	qdel(src)

/obj/machinery/firealarm/proc/update_fire_light(fire)
	if(fire == !!light_power)
		return  // do nothing if we're already active
	if(fire)
		set_light(l_power = 0.8)
		update_appearance(UPDATE_ICON)
	else
		set_light(l_power = 0)
		update_appearance(UPDATE_ICON)

/*
 * Return of the Return of the Party button
 */

/area
	var/party = FALSE

/obj/machinery/firealarm/partyalarm
	name = "\improper PARTY BUTTON"
	desc = "Cuban Pete is in the house!"
	var/static/party_overlay

/obj/machinery/firealarm/partyalarm/reset()
	if (stat & (NOPOWER|BROKEN))
		return
	var/area/A = get_area(src)
	if (!A || !A.party)
		return
	A.party = FALSE
	A.cut_overlay(party_overlay)

/obj/machinery/firealarm/partyalarm/alarm()
	if (stat & (NOPOWER|BROKEN))
		return
	var/area/A = get_area(src)
	if (!A || A.party || A.name == "Space")
		return
	A.party = TRUE
	if (!party_overlay)
		party_overlay = iconstate2appearance('icons/turf/areas.dmi', "party")
	A.add_overlay(party_overlay)
