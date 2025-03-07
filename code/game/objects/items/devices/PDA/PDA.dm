
//The advanced pea-green monochrome lcd of tomorrow.

GLOBAL_LIST_EMPTY(PDAs)

#define PDA_SCANNER_NONE		                  0
#define PDA_SCANNER_MEDICAL		                  1
#define PDA_SCANNER_FORENSICS	                  2 //unused
#define PDA_SCANNER_REAGENT		                  3
#define PDA_SCANNER_HALOGEN		                  4
#define PDA_SCANNER_GAS			                  5
#define PDA_SPAM_DELAY		                      2 MINUTES

//redd's defines, do not touch
#define PDA_PRINTING_GENERAL_REQUEST              "0"
#define PDA_PRINTING_COMPLAINT                    "1"
#define PDA_PRINTING_INCIDENT_REPORT              "2"
#define PDA_PRINTING_SECURITY_INCIDENT_REPORT     "3"
#define PDA_PRINTING_ITEM_REQUEST                 "4"
#define PDA_PRINTING_CYBERIZATION_CONSENT         "5"
#define PDA_PRINTING_HOP_ACCESS_REQUEST           "6"
#define PDA_PRINTING_JOB_CHANGE                   "7"
#define PDA_PRINTING_RESEARCH_REQUEST             "8"
#define PDA_PRINTING_MECH_REQUEST                 "9"
#define PDA_PRINTING_JOB_REASSIGNMENT_CERTIFICATE "10"
#define PDA_PRINTING_LITERACY_TEST                "11"
#define PDA_PRINTING_LITERACY_ANSWERS             "12"


/obj/item/pda
	name = "\improper PDA"
	desc = "A portable microcomputer by Thinktronic Systems, LTD. Functionality determined by a preprogrammed ROM cartridge."
	icon = 'icons/obj/pda.dmi'
	icon_state = "pda"
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	item_flags = NOBLUDGEON
	w_class = WEIGHT_CLASS_TINY
	slot_flags = ITEM_SLOT_ID | ITEM_SLOT_BELT
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 100)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	light_system = MOVABLE_LIGHT
	light_range = 2.3
	light_power = 0.6
	light_color = "#FFCC66"
	light_on = FALSE

	//Main variables
	var/owner = null // String name of owner
	var/default_cartridge = 0 // Typepath of the default cartridge to use
	var/obj/item/cartridge/cartridge = null //current cartridge
	var/mode = 0 //Controls what menu the PDA will display. 0 is hub; the rest are either built in or based on cartridge.
	var/icon_alert = "pda-r" //Icon to be overlayed for message alerts. Taken from the pda icon file.
	var/font_index = 0 //This int tells DM which font is currently selected and lets DM know when the last font has been selected so that it can cycle back to the first font when "toggle font" is pressed again.
	var/font_mode = "font-family:monospace;" //The currently selected font.
	var/background_color = "#808000" //The currently selected background color.

	#define FONT_MONO "font-family:monospace;"
	#define FONT_SHARE "font-family:\"Share Tech Mono\", monospace;letter-spacing:0px;"
	#define FONT_ORBITRON "font-family:\"Orbitron\", monospace;letter-spacing:0px; font-size:15px"
	#define FONT_VT "font-family:\"VT323\", monospace;letter-spacing:1px;"
	#define MODE_MONO 0
	#define MODE_SHARE 1
	#define MODE_ORBITRON 2
	#define MODE_VT 3

	//Secondary variables
	var/scanmode = PDA_SCANNER_NONE
	var/silent = FALSE //To beep or not to beep, that is the question
	var/toff = FALSE //If TRUE, messenger disabled
	var/list/tnote = list() //Current list of received signals, which are transmuted into messages on-the-spot. Can also be just plain strings, y'know, like, who really gives a shit, y'know
	var/last_text //No text spamming
	var/last_everyone //No text for everyone spamming
	var/last_noise //Also no honk spamming that's bad too
	var/ttone = "beep" //The ringtone!
	var/honkamt = 0 //How many honks left when infected with honk.exe
	var/mimeamt = 0 //How many silence left when infected with mime.exe
	var/note = "Congratulations, your station has chosen the Thinktronic 5235 Personal Data Assistant!" //Current note in the notepad function
	var/notehtml = ""
	var/notescanned = FALSE // True if what is in the notekeeper was from a paper.
	var/hidden = FALSE // Is the PDA hidden from the PDA list?
	var/emped = FALSE
	var/equipped = FALSE  //used here to determine if this is the first time its been picked up

	var/obj/item/card/id/id = null //Making it possible to slot an ID card into the PDA so it can function as both.
	var/ownjob = null //related to above

	var/obj/item/paicard/pai = null	// A slot for a personal AI device

	var/datum/picture/picture //Scanned photo

	var/list/contained_item = list(/obj/item/pen, /obj/item/toy/crayon, /obj/item/lipstick, /obj/item/flashlight/pen, /obj/item/clothing/mask/cigarette)
	//This is the typepath to load "into" the pda
	var/obj/item/insert_type = /obj/item/pen
	//This is the currently inserted item
	var/obj/item/inserted_item
	var/overlays_x_offset = 0	//x offset to use for certain overlays

	var/underline_flag = TRUE //flag for underline
	var/beep_cooldown = 0

/obj/item/pda/suicide_act(mob/living/carbon/user)
	var/deathMessage = msg_input(user)
	if (!deathMessage)
		deathMessage = "i ded"
	user.visible_message(span_suicide("[user] is sending a message to the Grim Reaper! It looks like [user.p_theyre()] trying to commit suicide!"))
	tnote += "<i><b>&rarr; To The Grim Reaper:</b></i><br>[deathMessage]<br>"//records a message in their PDA as being sent to the grim reaper
	return BRUTELOSS

/obj/item/pda/examine(mob/user)
	. = ..()
	if(!id && !inserted_item)
		return

	if(id)
		. += span_notice("Alt-click to remove the id.")

	if(inserted_item && (!isturf(loc)))
		. += span_notice("Ctrl-click to remove [inserted_item].")

/obj/item/pda/Initialize(mapload)
	. = ..()

	GLOB.PDAs += src
	if(default_cartridge)
		cartridge = SSwardrobe.provide_type(default_cartridge, src)
		cartridge.host_pda = src
	if(insert_type)
		inserted_item = SSwardrobe.provide_type(insert_type, src)
	update_appearance(UPDATE_ICON)

/obj/item/pda/Destroy()
	GLOB.PDAs -= src
	if(istype(id))
		QDEL_NULL(id)
	if(istype(cartridge))
		QDEL_NULL(cartridge)
	if(istype(pai))
		QDEL_NULL(pai)
	if(istype(inserted_item))
		QDEL_NULL(inserted_item)
	return ..()

/obj/item/pda/equipped(mob/user, slot)
	. = ..()
	if(!equipped)
		if(user.client)
			background_color = user.client.prefs.read_preference(/datum/preference/color/pda_color)
			switch(user.client.prefs.read_preference(/datum/preference/choiced/pda_style))
				if(PDA_FONT_MONO)
					font_index = MODE_MONO
					font_mode = FONT_MONO
				if(PDA_FONT_SHARE)
					font_index = MODE_SHARE
					font_mode = FONT_SHARE
				if(PDA_FONT_ORBITRON)
					font_index = MODE_ORBITRON
					font_mode = FONT_ORBITRON
				if(PDA_FONT_VT)
					font_index = MODE_VT
					font_mode = FONT_VT
				else
					font_index = MODE_MONO
					font_mode = FONT_MONO
			equipped = TRUE

/obj/item/pda/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == cartridge)
		cartridge.host_pda = null
		cartridge = null
	if(gone == inserted_item)
		inserted_item = null

/obj/item/pda/proc/update_label()
	name = "PDA-[owner] ([ownjob])" //Name generalisation

/obj/item/pda/GetAccess()
	if(id)
		return id.GetAccess()
	else
		return ..()

/obj/item/pda/GetID()
	return id

/obj/item/pda/RemoveID()
	return do_remove_id()

/obj/item/pda/InsertID(obj/item/inserting_item)
	var/obj/item/card/inserting_id = inserting_item.RemoveID()
	if(!inserting_id)
		return
	insert_id(inserting_id)
	if(id == inserting_id)
		return TRUE
	return FALSE

/obj/item/pda/update_overlays()
	. = ..()
	var/mutable_appearance/overlay = new()
	overlay.pixel_x = overlays_x_offset
	if(id)
		overlay.icon_state = "id_overlay"
		. += new /mutable_appearance(overlay)
	if(inserted_item)
		overlay.icon_state = "insert_overlay"
		. += new /mutable_appearance(overlay)
	if(light_on)
		overlay.icon_state = "light_overlay"
		. += new /mutable_appearance(overlay)
	if(pai)
		if(pai.pai)
			overlay.icon_state = "pai_overlay"
			. += new /mutable_appearance(overlay)
		else
			overlay.icon_state = "pai_off_overlay"
			. += new /mutable_appearance(overlay)

/obj/item/pda/MouseDrop(mob/over, src_location, over_location)
	var/mob/M = usr
	if((M == over) && usr.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return attack_self(M)
	return ..()

/obj/item/pda/attack_self_tk(mob/user)
	to_chat(user, span_warning("The PDA's capacitive touch screen doesn't seem to respond!"))
	return

/obj/item/pda/interact(mob/user)
	if(!user.IsAdvancedToolUser())
		to_chat(user, span_warning("You don't have the dexterity to do this!"))
		return

	..()

	var/datum/asset/spritesheet/assets = get_asset_datum(/datum/asset/spritesheet/simple/pda)
	assets.send(user)

	user.set_machine(src)

	var/dat = "<!DOCTYPE html><html><head><meta http-equiv='X-UA-Compatible' content='IE=edge'><meta charset='UTF-8'><title>Personal Data Assistant</title><link href=\"https://fonts.googleapis.com/css?family=Orbitron|Share+Tech+Mono|VT323\" rel=\"stylesheet\"><script type='text/javascript' src='common.js'></script></head><body bgcolor=\"" + background_color + "\"><style>body{" + font_mode + "}ul,ol{list-style-type: none;}a, a:link, a:visited, a:active, a:hover { color: #000000;text-decoration:none; }img {border-style:none;}a img{padding-right: 9px;}</style>"
	dat += assets.css_tag()

	dat += "<a href='byond://?src=[REF(src)];choice=Refresh'>[PDAIMG(refresh)]Refresh</a>"

	if ((!isnull(cartridge)) && (mode == 0))
		dat += " | <a href='byond://?src=[REF(src)];choice=Eject'>[PDAIMG(eject)]Eject [cartridge]</a>"
	if (mode)
		dat += " | <a href='byond://?src=[REF(src)];choice=Return'>[PDAIMG(menu)]Return</a>"

	if (mode == 0)
		dat += "<div align=\"center\">"
		dat += "<br><a href='byond://?src=[REF(src)];choice=Toggle_Font'>Toggle Font</a>"
		dat += " | <a href='byond://?src=[REF(src)];choice=Change_Color'>Change Color</a>"
		dat += " | <a href='byond://?src=[REF(src)];choice=Toggle_Underline'>Toggle Underline</a>" //underline button

		dat += "</div>"

	dat += "<br>"

	if (!owner)
		dat += "Warning: No owner information entered.  Please swipe card.<br><br>"
		dat += "<a href='byond://?src=[REF(src)];choice=Refresh'>[PDAIMG(refresh)]Retry</a>"
	else
		switch (mode)
			if (0)
				dat += "<h2>PERSONAL DATA ASSISTANT v.1.3</h2>"
				dat += "Owner: [owner], [ownjob]<br>"
				dat += text("ID: <a href='?src=[REF(src)];choice=Authenticate'>[id ? "[id.registered_name], [id.assignment]" : "----------"]")
				dat += text("<br><a href='?src=[REF(src)];choice=UpdateInfo'>[id ? "Update PDA Info" : ""]</A><br><br>")

				dat += "[station_time_timestamp()]<br>" //:[world.time / 100 % 6][world.time / 100 % 10]"
				dat += "[time2text(world.realtime, "MMM DD")] [GLOB.year_integer+540]"

				dat += "<br><br>"

				dat += "<h4>General Functions</h4>"
				dat += "<ul>"
				dat += "<li><a href='byond://?src=[REF(src)];choice=1'>[PDAIMG(notes)]Notekeeper</a></li>"
				dat += "<li><a href='byond://?src=[REF(src)];choice=2'>[PDAIMG(mail)]Messenger</a></li>"
				if (cartridge)
					if (cartridge.access & CART_CLOWN)
						dat += "<li><a href='byond://?src=[REF(src)];choice=Honk'>[PDAIMG(honk)]Honk Synthesizer</a></li>"
						dat += "<li><a href='byond://?src=[REF(src)];choice=Trombone'>[PDAIMG(honk)]Sad Trombone</a></li>"
					if (cartridge.access & CART_MANIFEST)
						dat += "<li><a href='byond://?src=[REF(src)];choice=41'>[PDAIMG(notes)]View Crew Manifest</a></li>"
					if(cartridge.access & CART_STATUS_DISPLAY)
						dat += "<li><a href='byond://?src=[REF(src)];choice=42'>[PDAIMG(status)]Set Status Display</a></li>"
					dat += "</ul>"
					if (cartridge.access & CART_ENGINE)
						dat += "<h4>Engineering Functions</h4>"
						dat += "<ul>"
						dat += "<li><a href='byond://?src=[REF(src)];choice=43'>[PDAIMG(power)]Power Monitor</a></li>"
						dat += "</ul>"
					if (cartridge.access & CART_MEDICAL)
						dat += "<h4>Medical Functions</h4>"
						dat += "<ul>"
						dat += "<li><a href='byond://?src=[REF(src)];choice=44'>[PDAIMG(medical)]Medical Records</a></li>"
						dat += "<li><a href='byond://?src=[REF(src)];choice=Medical Scan'>[PDAIMG(scanner)][scanmode == 1 ? "Disable" : "Enable"] Medical Scanner</a></li>"
						dat += "</ul>"
					if (cartridge.access & CART_SECURITY)
						dat += "<h4>Security Functions</h4>"
						dat += "<ul>"
						dat += "<li><a href='byond://?src=[REF(src)];choice=45'>[PDAIMG(cuffs)]Security Records</A></li>"
						dat += "</ul>"
					if(cartridge.access & CART_QUARTERMASTER)
						dat += "<h4>Quartermaster Functions:</h4>"
						dat += "<ul>"
						dat += "<li><a href='byond://?src=[REF(src)];choice=47'>[PDAIMG(crate)]Supply Records</A></li>"
						dat += "<li><a href='byond://?src=[REF(src)];choice=48'>[PDAIMG(crate)]Ore Silo Logs</a></li>"
						dat += "</ul>"
				dat += "</ul>"

				dat += "<h4>Utilities</h4>"
				dat += "<ul>"

				if (cartridge)
					if(ownjob != "Assistant")
						dat += "<li><a href='byond://?src=[REF(src)];choice=Assistant Pager'>[PDAIMG(dronephone)]Assistant Pager</a></li>"
					if(cartridge.bot_access_flags)
						dat += "<li><a href='byond://?src=[REF(src)];choice=54'>[PDAIMG(medbot)]Bots Access</a></li>"
					if (cartridge.access & CART_JANITOR)
						dat += "<li><a href='byond://?src=[REF(src)];choice=49'>[PDAIMG(bucket)]Custodial Locator</a></li>"
					if (istype(cartridge.radio))
						dat += "<li><a href='byond://?src=[REF(src)];choice=40'>[PDAIMG(signaler)]Signaler System</a></li>"
					if (cartridge.access & CART_NEWSCASTER)
						dat += "<li><a href='byond://?src=[REF(src)];choice=53'>[PDAIMG(notes)]Newscaster Access </a></li>"
					if (cartridge.access & CART_REAGENT_SCANNER)
						dat += "<li><a href='byond://?src=[REF(src)];choice=Reagent Scan'>[PDAIMG(reagent)][scanmode == 3 ? "Disable" : "Enable"] Reagent Scanner</a></li>"
					if (cartridge.access & CART_ENGINE)
						dat += "<li><a href='byond://?src=[REF(src)];choice=Halogen Counter'>[PDAIMG(reagent)][scanmode == 4 ? "Disable" : "Enable"] Halogen Counter</a></li>"
					if (cartridge.access & CART_ATMOS)
						dat += "<li><a href='byond://?src=[REF(src)];choice=Gas Scan'>[PDAIMG(reagent)][scanmode == 5 ? "Disable" : "Enable"] Gas Scanner</a></li>"
					if (cartridge.access & CART_REMOTE_DOOR)
						dat += "<li><a href='byond://?src=[REF(src)];choice=Toggle Door'>[PDAIMG(rdoor)]Toggle Remote Door</a></li>"
					if (cartridge.access & CART_DRONEPHONE)
						dat += "<li><a href='byond://?src=[REF(src)];choice=Drone Phone'>[PDAIMG(dronephone)]Drone Phone</a></li>"
					if (cartridge.access & CART_STATUS_DISPLAY)
						dat += "<li><a href='byond://?src=[REF(src)];choice=5'>[PDAIMG(blank)]Bluespace Paperwork Printer</a></li>"
					else if (cartridge.access & CART_SECURITY)
						dat += "<li><a href='byond://?src=[REF(src)];choice=print;paper=[PDA_PRINTING_SECURITY_INCIDENT_REPORT]'>[PDAIMG(notes)]Print Security Incident Report Form</a></li>"
						dat += "<li><a href='byond://?src=[REF(src)];choice=print;paper=[PDA_PRINTING_INCIDENT_REPORT]'>[PDAIMG(notes)]Print Incident Report Form</a></li>"
				if(id && id.registered_account && id.registered_account.account_job.paycheck_department)
					dat += "<li><a href='byond://?src=[REF(src)];choice=6'>[PDAIMG(notes)]Show Department Goals</a></li>"
				dat += "<li><a href='byond://?src=[REF(src)];choice=3'>[PDAIMG(atmos)]Atmospheric Scan</a></li>"
				dat += "<li><a href='byond://?src=[REF(src)];choice=Light'>[PDAIMG(flashlight)][light_on ? "Disable" : "Enable"] Flashlight</a></li>"
				if (pai)
					if(pai.loc != src)
						pai = null
						update_appearance(UPDATE_ICON)
					else
						dat += "<li><a href='byond://?src=[REF(src)];choice=pai;option=1'>pAI Device Configuration</a></li>"
						dat += "<li><a href='byond://?src=[REF(src)];choice=pai;option=2'>Eject pAI Device</a></li>"
				dat += "</ul>"

			if (1)
				dat += "<h4>[PDAIMG(notes)] Notekeeper V2.2</h4>"
				dat += "<a href='byond://?src=[REF(src)];choice=Edit'>Edit</a><br>"
				if(notescanned)
					dat += "(This is a scanned image, editing it may cause some text formatting to change.)<br>"
				dat += "<HR><font face=\"[PEN_FONT]\">[(!notehtml ? note : notehtml)]</font>"

			if (2)
				dat += "<h4>[PDAIMG(mail)] SpaceMessenger V3.9.6</h4>"
				dat += "<a href='byond://?src=[REF(src)];choice=Toggle Ringer'>[PDAIMG(bell)]Ringer: [silent == 1 ? "Off" : "On"]</a> | "
				dat += "<a href='byond://?src=[REF(src)];choice=Toggle Messenger'>[PDAIMG(mail)]Send / Receive: [toff == 1 ? "Off" : "On"]</a> | "
				dat += "<a href='byond://?src=[REF(src)];choice=Ringtone'>[PDAIMG(bell)]Set Ringtone</a> | "
				dat += "<a href='byond://?src=[REF(src)];choice=21'>[PDAIMG(mail)]Messages</a><br>"

				if(cartridge)
					dat += cartridge.message_header()

				dat += "<h4>[PDAIMG(menu)] Detected PDAs</h4>"

				dat += "<ul>"
				var/count = 0

				if (!toff)
					for (var/obj/item/pda/P in sortNames(get_viewable_pdas()))
						if (P == src)
							continue
						dat += "<li><a href='byond://?src=[REF(src)];choice=Message;target=[REF(P)]'>[P]</a>"
						if(cartridge)
							dat += cartridge.message_special(P)
						dat += "</li>"
						count++
				dat += "</ul>"
				if (count == 0)
					dat += "None detected.<br>"
				else if(cartridge && cartridge.spam_enabled)
					dat += "<a href='byond://?src=[REF(src)];choice=MessageAll'>Send To All</a>"

			if(21)
				dat += "<h4>[PDAIMG(mail)] SpaceMessenger V3.9.6</h4>"
				dat += "<a href='byond://?src=[REF(src)];choice=Clear'>[PDAIMG(blank)]Clear Messages</a>"

				dat += "<h4>[PDAIMG(mail)] Messages</h4>"

				//Build the message list
				for(var/x in tnote)
					if(istext(x)) // If it's literally just text
						dat += tnote
					else // It's hopefully a signal
						var/datum/signal/subspace/messaging/pda/sig = x
						dat += "<i><b><a href='byond://?src=[REF(src)];choice=Message;target=[REF(sig.source)]'>[sig.data["name"]]</a> ([sig.data["job"]]):</b></i><br>[sig.format_message(user)]<br>"
				dat += "<br>"

			if (3)
				dat += "<h4>[PDAIMG(atmos)] Atmospheric Readings</h4>"

				var/turf/T = user.loc
				if (isnull(T))
					dat += "Unable to obtain a reading.<br>"
				else
					var/datum/gas_mixture/environment = T.return_air()

					var/pressure = environment.return_pressure()
					var/total_moles = environment.total_moles()

					dat += "Air Pressure: [round(pressure,0.1)] kPa<br>"

					if (total_moles)
						for(var/id in environment.get_gases())
							var/gas_level = environment.get_moles(id)/total_moles
							if(gas_level > 0)
								dat += "[GLOB.meta_gas_info[id][META_GAS_NAME]]: [round(gas_level*100, 0.01)]%<br>"

					dat += "Temperature: [round(environment.return_temperature()-T0C)]&deg;C<br>"
				dat += "<br>"

			if (5)
				dat += "<h4>Bluespace Paperwork Printing</h4><i>Putting the paper in paperwork!</i><ul>"
				dat += "<li><a href='byond://?src=[REF(src)];choice=print;paper=[PDA_PRINTING_GENERAL_REQUEST]'>General Request Form</a></li>"
				dat += "<li><a href='byond://?src=[REF(src)];choice=print;paper=[PDA_PRINTING_COMPLAINT]'>Complaint Form</a></li>"
				dat += "<li><a href='byond://?src=[REF(src)];choice=print;paper=[PDA_PRINTING_INCIDENT_REPORT]'>Incident Report Form</a></li>"
				dat += "<li><a href='byond://?src=[REF(src)];choice=print;paper=[PDA_PRINTING_SECURITY_INCIDENT_REPORT]'>Security Incident Report Form</a></li>"
				dat += "<li><a href='byond://?src=[REF(src)];choice=print;paper=[PDA_PRINTING_ITEM_REQUEST]'>Item Request Form</a></li>"
				dat += "<li><a href='byond://?src=[REF(src)];choice=print;paper=[PDA_PRINTING_CYBERIZATION_CONSENT]'>Cyberization Consent Form</a></li>"
				dat += "<li><a href='byond://?src=[REF(src)];choice=print;paper=[PDA_PRINTING_HOP_ACCESS_REQUEST]'>HoP Access Request Form</a></li>"
				dat += "<li><a href='byond://?src=[REF(src)];choice=print;paper=[PDA_PRINTING_JOB_CHANGE]'>Job Change Request Form</a></li>"
				dat += "<li><a href='byond://?src=[REF(src)];choice=print;paper=[PDA_PRINTING_RESEARCH_REQUEST]'>Research Request Form</a></li>"
				dat += "<li><a href='byond://?src=[REF(src)];choice=print;paper=[PDA_PRINTING_MECH_REQUEST]'>Mech Request Form</a></li>"
				dat += "<li><a href='byond://?src=[REF(src)];choice=print;paper=[PDA_PRINTING_JOB_REASSIGNMENT_CERTIFICATE]'>Job Reassignment Certificate</a></li>"
				dat += "<li><a href='byond://?src=[REF(src)];choice=print;paper=[PDA_PRINTING_LITERACY_TEST]'>Literacy Test</a></li>"
				dat += "<li><a href='byond://?src=[REF(src)];choice=print;paper=[PDA_PRINTING_LITERACY_ANSWERS]'>Literacy Test Answers</a></li>"
				dat += "</ul>"

			// I swear, whoever thought that these magical numbers were a good way to create a menu was a good idea should be fucking shot.
			if(6)
				if(!id || !id.registered_account || !id.registered_account.account_job.paycheck_department)
					mode = 0
					return
				var/dep_account = id.registered_account.account_job.paycheck_department
				dat += "<h4>Department Goals for the [SSYogs.getDepartmentFromAccount(dep_account)] department:</h4><ul>"
				for(var/datum/department_goal/dg in SSYogs.department_goals)
					if(dg.account == dep_account)
						dat += "<li>[dg.name]:</li>"
						dat += "<li>[dg.desc]</li><br>"
				dat += "</ul>"

			else//Else it links to the cart menu proc. Although, it really uses menu hub 4--menu 4 doesn't really exist as it simply redirects to hub.
				dat += cartridge.generate_menu()

	dat += "</body></html>"

	if (underline_flag)
		dat = replacetext(dat, "text-decoration:none", "text-decoration:underline")
	if (!underline_flag)
		dat = replacetext(dat, "text-decoration:underline", "text-decoration:none")

	user << browse(dat, "window=pda;size=400x450;border=1;can_resize=1;can_minimize=0")
	onclose(user, "pda", src)

/obj/item/pda/Topic(href, href_list)
	..()
	var/mob/living/U = usr
	//Looking for master was kind of pointless since PDAs don't appear to have one.

	if(usr.canUseTopic(src, BE_CLOSE, FALSE, NO_TK) && !href_list["close"])
		add_fingerprint(U)
		U.set_machine(src)

		switch(href_list["choice"])

//BASIC FUNCTIONS===================================

			if("Refresh")//Refresh, goes to the end of the proc.

			if ("Toggle_Font")
				//CODE REVISION 2
				font_index = (font_index + 1) % 4

				switch(font_index)
					if (MODE_MONO)
						font_mode = FONT_MONO
					if (MODE_SHARE)
						font_mode = FONT_SHARE
					if (MODE_ORBITRON)
						font_mode = FONT_ORBITRON
					if (MODE_VT)
						font_mode = FONT_VT
			if ("Change_Color")
				var/new_color = input("Please enter a color name or hex value (Default is \'#808000\').",background_color)as color
				background_color = new_color

			if ("Toggle_Underline")
				underline_flag = !underline_flag

			if("Return")//Return
				if(mode<=9)  //this is really shitcode. If there are ever more than 9 regular PDA modes this whole thing has to be rewritten. Note to self
					mode = 0
				else
					mode = round(mode/10)
					if(mode==4 || mode == 5)//Fix for cartridges. Redirects to hub.
						mode = 0
			if ("Authenticate")//Checks for ID
				id_check(U)
			if("UpdateInfo")
				ownjob = id.assignment
				if(istype(id, /obj/item/card/id/syndicate))
					owner = id.registered_name
				update_label()
			if("Eject")//Ejects the cart, only done from hub.
				if (!isnull(cartridge))
					U.put_in_hands(cartridge)
					to_chat(U, span_notice("You remove [cartridge] from [src]."))
					scanmode = PDA_SCANNER_NONE
					cartridge.host_pda = null
					cartridge = null
					update_appearance(UPDATE_ICON)

//MENU FUNCTIONS===================================

			if("0")//Hub
				mode = 0
			if("1")//Notes
				mode = 1
			if("2")//Messenger
				mode = 2
			if("21")//Read messeges
				mode = 21
			if("3")//Atmos scan
				mode = 3
			if("4")//Redirects to hub
				mode = 0
			if("5") //Paperwork Printer
				mode = 5
			if("6") // Department goals
				if(!id || !id.registered_account || !id.registered_account.account_job.paycheck_department)
					mode = 0
					return
				mode = 6


//MAIN FUNCTIONS===================================

			if("Light")
				toggle_light()
			if("Medical Scan")
				if(scanmode == PDA_SCANNER_MEDICAL)
					scanmode = PDA_SCANNER_NONE
				else if((!isnull(cartridge)) && (cartridge.access & CART_MEDICAL))
					scanmode = PDA_SCANNER_MEDICAL
			if("Reagent Scan")
				if(scanmode == PDA_SCANNER_REAGENT)
					scanmode = PDA_SCANNER_NONE
				else if((!isnull(cartridge)) && (cartridge.access & CART_REAGENT_SCANNER))
					scanmode = PDA_SCANNER_REAGENT
			if("Halogen Counter")
				if(scanmode == PDA_SCANNER_HALOGEN)
					scanmode = PDA_SCANNER_NONE
				else if((!isnull(cartridge)) && (cartridge.access & CART_ENGINE))
					scanmode = PDA_SCANNER_HALOGEN
			if("Honk")
				if ( !(last_noise && world.time < last_noise + 20) )
					playsound(src, 'sound/items/bikehorn.ogg', 50, 1)
					last_noise = world.time
			if("Trombone")
				if ( !(last_noise && world.time < last_noise + 20) )
					playsound(src, 'sound/misc/sadtrombone.ogg', 50, 1)
					last_noise = world.time
			if("Gas Scan")
				if(scanmode == PDA_SCANNER_GAS)
					scanmode = PDA_SCANNER_NONE
				else if((!isnull(cartridge)) && (cartridge.access & CART_ATMOS))
					scanmode = PDA_SCANNER_GAS
			if("Drone Phone")
				var/alert_s = input(U,"Alert severity level","Ping Drones",null) as null|anything in list("Low","Medium","High","Critical")
				var/area/A = get_area(U)
				if(A && alert_s && !QDELETED(U))
					var/msg = span_boldnotice("NON-DRONE PING: [U.name]: [alert_s] priority alert in [A.name]!")
					_alert_drones(msg, TRUE, U)
					to_chat(U, msg)
			if("Assistant Pager")
				ping_assistants(U)



//NOTEKEEPER FUNCTIONS===================================

			if ("Edit")
				var/n = stripped_multiline_input(U, "Please enter message", name, note)
				if (in_range(src, U) && loc == U)
					if (mode == 1 && n)
						note = n
						notehtml = parsemarkdown(n, U)
						notescanned = FALSE
				else
					U << browse(null, "window=pda")
					return

//MESSENGER FUNCTIONS===================================

			if("Toggle Messenger")
				toff = !toff
			if("Toggle Ringer")//If viewing texts then erase them, if not then toggle silent status
				silent = !silent
			if("Clear")//Clears messages
				tnote = list()
			if("Ringtone")
				var/t = stripped_input(U, "Please enter new ringtone", name, ttone, 20)
				if(in_range(src, U) && loc == U && t)
					if(SEND_SIGNAL(src, COMSIG_TABLET_CHANGE_ID, U, t) & COMPONENT_STOP_RINGTONE_CHANGE)
						U << browse(null, "window=pda")
						return
					else
						ttone = t
				else
					U << browse(null, "window=pda")
					return
			if("Message")
				create_message(U, locate(href_list["target"]) in GLOB.PDAs)

			if("MessageAll")
				send_to_all(U)

			if("cart")
				if(cartridge)
					cartridge.special(U, href_list)
				else
					U << browse(null, "window=pda")
					return

//SYNDICATE FUNCTIONS===================================

			if("Toggle Door")
				if(cartridge && cartridge.access & CART_REMOTE_DOOR)
					for(var/obj/machinery/door/poddoor/M in GLOB.machines)
						if(M.id == cartridge.remote_door_id)
							if(M.density)
								M.open()
							else
								M.close()

//pAI FUNCTIONS===================================
			if("pai")
				switch(href_list["option"])
					if("1")		// Configure pAI device
						pai.attack_self(U)
					if("2")		// Eject pAI device
						usr.put_in_hands(pai)
						to_chat(usr, span_notice("You remove the pAI from the [name]."))
//Redd's Shitty Paperwork Printing Functions=======

			if("print")
				//check if it's a head cartridge or a sec cartridge
				var/turf/user_turf = get_turf(usr)
				if (cartridge.access & CART_STATUS_DISPLAY)
					to_chat(usr, span_warning("The PDA whirrs as a paper materializes!"))
					playsound(src,"sound/items/polaroid1.ogg",30,1)
					//figure out which one we're trying to print
					switch(href_list["paper"])
						if (PDA_PRINTING_GENERAL_REQUEST) //obj/item/paper/paperwork/general_request_form(src)
							usr.put_in_hands(new /obj/item/paper/paperwork/general_request_form(user_turf))
						if (PDA_PRINTING_COMPLAINT)//obj/item/paper/paperwork/complaint_form
							usr.put_in_hands(new /obj/item/paper/paperwork/complaint_form(user_turf))
						if (PDA_PRINTING_INCIDENT_REPORT)
							usr.put_in_hands(new /obj/item/paper/paperwork/incident_report(user_turf))
						if (PDA_PRINTING_SECURITY_INCIDENT_REPORT)
							usr.put_in_hands(new /obj/item/paper/paperwork/sec_incident_report(user_turf))
						if (PDA_PRINTING_ITEM_REQUEST)
							usr.put_in_hands(new /obj/item/paper/paperwork/item_form(user_turf))
						if (PDA_PRINTING_CYBERIZATION_CONSENT)
							usr.put_in_hands(new /obj/item/paper/paperwork/cyborg_request_form(user_turf))
						if (PDA_PRINTING_HOP_ACCESS_REQUEST)
							usr.put_in_hands(new /obj/item/paper/paperwork/hopaccessrequestform(user_turf))
						if (PDA_PRINTING_JOB_CHANGE)
							usr.put_in_hands(new /obj/item/paper/paperwork/hop_job_change_form(user_turf))
						if (PDA_PRINTING_RESEARCH_REQUEST)
							usr.put_in_hands(new /obj/item/paper/paperwork/rd_form(user_turf))
						if (PDA_PRINTING_MECH_REQUEST)
							usr.put_in_hands(new /obj/item/paper/paperwork/mech_form(user_turf))
						if (PDA_PRINTING_JOB_REASSIGNMENT_CERTIFICATE)
							usr.put_in_hands(new /obj/item/paper/paperwork/jobchangecert(user_turf))
						if (PDA_PRINTING_LITERACY_TEST)
							usr.put_in_hands(new /obj/item/paper/paperwork/literacytest(user_turf))
						if (PDA_PRINTING_LITERACY_ANSWERS)
							usr.put_in_hands(new /obj/item/paper/paperwork/literacytest/answers(user_turf))
				else if (cartridge.access & CART_SECURITY)
					to_chat(usr, span_warning("The PDA whirrs as a paper materializes!"))
					playsound(src,"sound/items/polaroid1.ogg",30,1)
					switch(href_list["paper"])
						if (PDA_PRINTING_INCIDENT_REPORT)
							usr.put_in_hands(new /obj/item/paper/paperwork/incident_report(user_turf))
						if (PDA_PRINTING_SECURITY_INCIDENT_REPORT)
							usr.put_in_hands(new /obj/item/paper/paperwork/sec_incident_report(user_turf))



//LINK FUNCTIONS===================================

			else//Cartridge menu linking
				mode = max(text2num(href_list["choice"]), 0)

	else//If not in range, can't interact or not using the pda.
		U.unset_machine()
		U << browse(null, "window=pda")
		return

//EXTRA FUNCTIONS===================================

	if (mode == 2 || mode == 21)//To clear message overlays.
		update_appearance(UPDATE_ICON)

	if ((honkamt > 0) && (prob(60)))//For clown virus.
		honkamt--
		playsound(src, 'sound/items/bikehorn.ogg', 30, 1)

	if(U.machine == src && href_list["skiprefresh"]!="1")//Final safety.
		attack_self(U)//It auto-closes the menu prior if the user is not in range and so on.
	else
		U.unset_machine()
		U << browse(null, "window=pda")
	return

/obj/item/pda/proc/remove_id()

	if(issilicon(usr) || !usr.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	do_remove_id(usr)


/obj/item/pda/proc/do_remove_id(mob/user)
	if(!id)
		return
	if(user)
		user.put_in_hands(id)
		to_chat(user, "<span class='notice'>You remove the ID from the [name].</span>")
	else
		id.forceMove(get_turf(src))

	. = id
	id = null
	update_appearance(UPDATE_ICON)

	if(ishuman(loc))
		var/mob/living/carbon/human/H = loc
		if(H.wear_id == src)
			H.sec_hud_set_ID()


/obj/item/pda/proc/msg_input(mob/living/U = usr)
	var/t = stripped_input(U, "Please enter message", name)
	if (!t || toff)
		return
	if(!U.canUseTopic(src, BE_CLOSE))
		return
	if(emped)
		t = Gibberish(t, 100)
	return t

/obj/item/pda/proc/send_message(mob/living/user, list/obj/item/pda/targets, everyone)
	var/message = msg_input(user)
	if(!message || !targets.len)
		return
	if((last_text && world.time < last_text + 10) || (everyone && last_everyone && world.time < last_everyone + PDA_SPAM_DELAY))
		return
	if(prob(1))
		message += "\nSent from my PDA"
	// Send the signal
	var/list/string_targets = list()
	for (var/obj/item/pda/P in targets)
		if (P.owner && P.ownjob)  // != src is checked by the UI
			string_targets += "[P.owner] ([P.ownjob])"
	for (var/obj/machinery/computer/message_monitor/M in targets)
		// In case of "Reply" to a message from a console, this will make the
		// message be logged successfully. If the console is impersonating
		// someone by matching their name and job, the reply will reach the
		// impersonated PDA.
		string_targets += "[M.customsender] ([M.customjob])"
	if (!string_targets.len)
		return

	var/datum/signal/subspace/messaging/pda/signal = new(src, list(
		"name" = "[owner]",
		"job" = "[ownjob]",
		"message" = message,
		"language" = user.get_selected_language(),
		"targets" = string_targets
	))
	if (picture)
		signal.data["photo"] = picture
	signal.send_to_receivers()

	// If it didn't reach, note that fact
	if (!signal.data["done"])
		to_chat(user, span_notice("ERROR: Server isn't responding."))
		return

	var/target_text = signal.format_target()
	// Log it in our logs
	tnote += signal
	// Show it to ghosts
	var/ghost_message = "[span_name("[owner] ")]<span class='game say'>PDA Message</span> --> [span_name("[target_text]")]: [span_message("[signal.format_message()]")]"
	for(var/mob/M in GLOB.player_list)
		if(isobserver(M) && M.client && (M.client.prefs.chat_toggles & CHAT_GHOSTPDA))
			to_chat(M, "[FOLLOW_LINK(M, user)] [ghost_message]")
	// Log in the talk log
	user.log_talk(message, LOG_PDA, tag="PDA: [initial(name)] to [target_text]")
	to_chat(user, span_info("Message sent to [target_text]: \"[message]\""))
	// Reset the photo
	picture = null
	last_text = world.time
	if (everyone)
		last_everyone = world.time

/obj/item/pda/proc/receive_message(datum/signal/subspace/messaging/pda/signal)
	tnote += signal

	if (!silent)
		if(HAS_TRAIT(SSstation, STATION_TRAIT_PDA_GLITCHED))
			playsound(src, pick('sound/machines/twobeep_voice1.ogg', 'sound/machines/twobeep_voice2.ogg'), 50, TRUE)
		else
			playsound(src, 'sound/machines/twobeep_high.ogg', 50, TRUE)
		audible_message("[icon2html(src, hearers(src))] *[ttone]*", null, 3)
	//Search for holder of the PDA.
	var/mob/living/L = null
	if(loc && isliving(loc))
		L = loc
	//Maybe they are a pAI!
	else
		L = get(src, /mob/living/silicon)

	if(L && L.stat != UNCONSCIOUS)
		var/reply = "(<a href='byond://?src=[REF(src)];choice=Message;skiprefresh=1;target=[REF(signal.source)]'>Reply</a>)"
		var/hrefstart
		var/hrefend
		if (isAI(L))
			hrefstart = "<a href='?src=[REF(L)];track=[html_encode(signal.data["name"])]'>"
			hrefend = "</a>"

		if(signal.data["automated"])
			reply = "\[Automated Message\]"

		to_chat(L, "[icon2html(src)] <b>Message from [hrefstart][signal.data["name"]] ([signal.data["job"]])[hrefend], </b>[signal.format_message(L)] [reply]")

	update_appearance(UPDATE_ICON)
	add_overlay(icon_alert)

/obj/item/pda/proc/receive_ping(message)
	if (!silent)
		if(HAS_TRAIT(SSstation, STATION_TRAIT_PDA_GLITCHED))
			playsound(src, pick('sound/machines/twobeep_voice1.ogg', 'sound/machines/twobeep_voice2.ogg'), 50, TRUE)
		else
			playsound(src, 'sound/machines/twobeep_high.ogg', 50, TRUE)
		audible_message("[icon2html(src, hearers(src))] *[ttone]*", null, 3)

	var/mob/living/L = null
	if(loc && isliving(loc))
		L = loc
	//Maybe they are a pAI!
	else
		L = get(src, /mob/living/silicon)

	if(L && L.stat != UNCONSCIOUS)
		to_chat(L, message)

/obj/item/pda/proc/send_to_all(mob/living/U)
	if (last_everyone && world.time < last_everyone + PDA_SPAM_DELAY)
		to_chat(U,span_warning("Send To All function is still on cooldown."))
		return
	send_message(U,get_viewable_pdas(), TRUE)

/obj/item/pda/proc/ping_assistants(mob/living/U)
	if (last_everyone && world.time < last_everyone + PDA_SPAM_DELAY)
		to_chat(U,span_warning("Function is still on cooldown."))
		return

	var/area/A = get_area(U)
	var/toSend = stripped_input(U, "Please enter your issue.")

	if(!toSend)
		return

	toSend = "Assistant requested by [owner] at [A]! Reason: [toSend]"

	last_everyone = world.time
	for(var/obj/item/pda/P in get_viewable_assistant_pdas())
		P.receive_ping(toSend)

/obj/item/pda/proc/create_message(mob/living/U, obj/item/pda/P)
	send_message(U,list(P))

/obj/item/pda/AltClick()
	..()

	if(id)
		remove_id()
	else
		remove_pen()

/obj/item/pda/CtrlClick()
	..()

	if(isturf(loc)) //stops the user from dragging the PDA by ctrl-clicking it.
		return

	remove_pen()

/obj/item/pda/verb/verb_toggle_light()
	set category = "Object"
	set name = "Toggle Flashlight"

	toggle_light()

/obj/item/pda/verb/verb_remove_id()
	set category = "Object"
	set name = "Eject ID"
	set src in usr

	if(id)
		remove_id()
	else
		to_chat(usr, span_warning("This PDA does not have an ID in it!"))

/obj/item/pda/verb/verb_remove_pen()
	set category = "Object"
	set name = "Remove Pen"
	set src in usr

	remove_pen()

/obj/item/pda/proc/toggle_light()
	if(issilicon(usr) || !usr.canUseTopic(src, BE_CLOSE))
		return
	if(light_on)
		set_light_on(FALSE)
	else if(light_range)
		set_light_on(TRUE)
	update_appearance(UPDATE_ICON)
	for(var/X in actions)
		var/datum/action/A = X
		A.build_all_button_icons()

/obj/item/pda/proc/remove_pen()

	if(issilicon(usr) || !usr.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return

	if(inserted_item)
		to_chat(usr, span_notice("You remove [inserted_item] from [src]."))
		usr.put_in_hands(inserted_item) //Don't need to manage the pen ref, handled on Exited()
		update_appearance(UPDATE_ICON)
	else
		to_chat(usr, span_warning("This PDA does not have a pen in it!"))

//trying to insert or remove an id
/obj/item/pda/proc/id_check(mob/user, obj/item/card/id/I)
	if(!I)
		if(id && (src in user.contents))
			remove_id()
			return TRUE
		else
			var/obj/item/card/id/C = user.get_active_held_item()
			if(istype(C))
				I = C

	if(I && I?.registered_name)
		if(!user.transferItemToLoc(I, src))
			return FALSE
		insert_id(I, user)
		update_appearance(UPDATE_ICON)
	return TRUE


/obj/item/pda/proc/insert_id(obj/item/card/id/inserting_id, mob/user)
	var/obj/old_id = id
	id = inserting_id
	if(ishuman(loc))
		var/mob/living/carbon/human/human_wearer = loc
		if(human_wearer.wear_id == src)
			human_wearer.sec_hud_set_ID()
	if(old_id)
		if(user)
			user.put_in_hands(old_id)
		else
			old_id.forceMove(get_turf(src))


// access to status display signals
/obj/item/pda/attackby(obj/item/C, mob/user, params)
	if(istype(C, /obj/item/cartridge) && !cartridge)
		if(!user.transferItemToLoc(C, src))
			return
		cartridge = C
		cartridge.host_pda = src
		to_chat(user, span_notice("You insert [cartridge] into [src]."))
		update_appearance(UPDATE_ICON)

	else if(istype(C, /obj/item/card/id))
		var/obj/item/card/id/idcard = C
		if(!idcard.registered_name)
			to_chat(user, span_warning("\The [src] rejects the ID!"))
			return
		if(!owner)
			owner = idcard.registered_name
			ownjob = idcard.assignment
			update_label()
			to_chat(user, span_notice("Card scanned."))
		else
			//Basic safety check. If either both objects are held by user or PDA is on ground and card is in hand.
			if(((src in user.contents) || (isturf(loc) && in_range(src, user))) && (C in user.contents))
				if(!id_check(user, idcard))
					return
				to_chat(user, span_notice("You put the ID into \the [src]'s slot."))
				updateSelfDialog()//Update self dialog on success.
			return	//Return in case of failed check or when successful.
		updateSelfDialog()//For the non-input related code.
	else if(istype(C, /obj/item/paicard) && !pai)
		if(!user.transferItemToLoc(C, src))
			return
		pai = C
		to_chat(user, span_notice("You slot \the [C] into [src]."))
		update_appearance(UPDATE_ICON)
		updateUsrDialog()
	else if(is_type_in_list(C, contained_item)) //Checks if there is a pen
		if(inserted_item)
			to_chat(user, span_warning("There is already \a [inserted_item] in \the [src]!"))
		else
			if(!user.transferItemToLoc(C, src))
				return
			to_chat(user, span_notice("You slide \the [C] into \the [src]."))
			inserted_item = C
			update_appearance(UPDATE_ICON)
	else if(istype(C, /obj/item/photo))
		var/obj/item/photo/P = C
		picture = P.picture
		to_chat(user, span_notice("You scan \the [C]."))
	else
		return ..()

/obj/item/pda/attack(mob/living/carbon/C, mob/living/user)
	if(istype(C))
		switch(scanmode)

			if(PDA_SCANNER_MEDICAL)
				if(beep_cooldown < world.time)
					playsound(src, 'sound/effects/fastbeep.ogg', 20)
					beep_cooldown = world.time + 40
				C.visible_message(span_alert("[user] has analyzed [C]'s vitals!"))
				healthscan(user, C, 1)
				add_fingerprint(user)

			if(PDA_SCANNER_HALOGEN)
				C.visible_message(span_warning("[user] has analyzed [C]'s radiation levels!"))

				user.show_message(span_notice("Analyzing Results for [C]:"))
				if(C.radiation)
					user.show_message("\green Radiation Level: \black [C.radiation]")
				else
					user.show_message(span_notice("No radiation detected."))

/obj/item/pda/afterattack(atom/A as mob|obj|turf|area, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	switch(scanmode)
		if(PDA_SCANNER_REAGENT)
			if(!isnull(A.reagents))
				if(A.reagents.reagent_list.len > 0)
					var/reagents_length = A.reagents.reagent_list.len
					to_chat(user, span_notice("[reagents_length] chemical agent[reagents_length > 1 ? "s" : ""] found."))
					for (var/re in A.reagents.reagent_list)
						to_chat(user, span_notice("\t [re]"))
				else
					to_chat(user, span_notice("No active chemical agents found in [A]."))
			else
				to_chat(user, span_notice("No significant chemical agents found in [A]."))

		if(PDA_SCANNER_GAS)
			A.analyzer_act(user, src)

	if (!scanmode && istype(A, /obj/item/paper) && owner)
		var/obj/item/paper/PP = A
		if (!PP.info)
			to_chat(user, span_warning("Unable to scan! Paper is blank."))
			return
		notehtml = PP.info
		note = replacetext(notehtml, "<BR>", "\[br\]")
		note = replacetext(note, "<li>", "\[*\]")
		note = replacetext(note, "<ul>", "\[list\]")
		note = replacetext(note, "</ul>", "\[/list\]")
		note = html_encode(note)
		notescanned = TRUE
		to_chat(user, span_notice("Paper scanned. Saved to PDA's notekeeper.") )


/obj/item/pda/proc/explode() //This needs tuning.
	var/turf/T = get_turf(src)

	if (ismob(loc))
		var/mob/M = loc
		M.show_message(span_userdanger("Your [src] explodes!"), MSG_VISUAL, span_warning("You hear a loud *pop*!"), MSG_AUDIBLE)
	else
		visible_message(span_danger("[src] explodes!"), span_warning("You hear a loud *pop*!"))

	if(T)
		T.hotspot_expose(700,125)
		if(istype(cartridge, /obj/item/cartridge/virus/syndicate))
			explosion(T, -1, 1, 3, 4)
		else
			explosion(T, -1, -1, 2, 3)
	qdel(src)
	return

//pAI verb and proc for sending PDA messages.
/mob/living/silicon/proc/cmd_send_pdamesg(mob/user)
	var/list/plist = list()
	var/list/namecounts = list()

	if(aiPDA.toff)
		to_chat(user, "Turn on your receiver in order to send messages.")
		return

	for (var/obj/item/pda/P in get_viewable_pdas())
		if (P == src)
			continue
		else if (P == aiPDA)
			continue

		plist[avoid_assoc_duplicate_keys(P.owner, namecounts)] = P

	var/c = input(user, "Please select a PDA") as null|anything in sortList(plist)

	if (!c)
		return

	var/selected = plist[c]

	if(aicamera.stored.len)
		var/add_photo = input(user,"Do you want to attach a photo?","Photo","No") as null|anything in list("Yes","No")
		if(add_photo=="Yes")
			var/datum/picture/Pic = aicamera.selectpicture(user)
			aiPDA.picture = Pic

	if(incapacitated())
		return

	aiPDA.create_message(src, selected)

/mob/living/silicon/ai/proc/cmd_show_message_log(mob/user)
	if(incapacitated())
		return
	if(!isnull(aiPDA))
		//Build the message list
		var/dat
		for(var/x in aiPDA.tnote)
			if(istext(x)) // If it's literally just text
				dat += aiPDA.tnote
			else // It's hopefully a signal
				var/datum/signal/subspace/messaging/pda/sig = x
				dat += "<b>[sig.data["name"]]([sig.data["job"]])<i> (<a href='byond://?src=[REF(src.aiPDA)];choice=Message;target=[REF(sig.source)]'>Reply</a>) (<a href='?src=[REF(usr)];track=[html_encode(sig.data["name"])]'>Track</a>):</b></i><br>[sig.format_message(user)]<br>"
				dat += "<br>"
		var/HTML = "<html><head><meta charset='UTF-8'><title>AI PDA Message Log</title></head><body>[dat]</body></html>"
		user << browse(HTML, "window=log;size=400x444;border=1;can_resize=1;can_close=1;can_minimize=0")
	else
		to_chat(user, "You do not have a PDA. You should make an issue report about this.")

/mob/living/silicon/pai/verb/cmd_toggle_pda_receiver()
	set category = "AI Commands"
	set name = "PDA - Toggle Sender/Receiver"
	if(usr.stat == DEAD)
		return //won't work if dead
	if(!isnull(aiPDA))
		aiPDA.toff = !aiPDA.toff
		to_chat(usr, span_notice("PDA sender/receiver toggled [(aiPDA.toff ? "Off" : "On")]!"))
	else
		to_chat(usr, "You do not have a PDA. You should make an issue report about this.")

/mob/living/silicon/pai/verb/cmd_toggle_pda_silent()
	set category = "AI Commands"
	set name = "PDA - Toggle Ringer"
	if(usr.stat == DEAD)
		return //won't work if dead
	if(!isnull(aiPDA))
		//0
		aiPDA.silent = !aiPDA.silent
		to_chat(usr, span_notice("PDA ringer toggled [(aiPDA.silent ? "Off" : "On")]!"))
	else
		to_chat(usr, "You do not have a PDA. You should make an issue report about this.")

/mob/living/silicon/pai/proc/cmd_show_message_log(mob/user)
	if(incapacitated())
		return
	if(!isnull(aiPDA))
		//Build the message list
		var/dat
		for(var/x in aiPDA.tnote)
			if(istext(x)) // If it's literally just text
				dat += aiPDA.tnote
			else // It's hopefully a signal
				var/datum/signal/subspace/messaging/pda/sig = x
				dat += "<b>[sig.data["name"]]([sig.data["job"]])<i> (<a href='byond://?src=[REF(src.aiPDA)];choice=Message;target=[REF(sig.source)]'>Reply</a>):</b></i><br>[sig.format_message(user)]<br>"
				dat += "<br>"
		var/HTML = "<html><head><meta charset='UTF-8'><title>AI PDA Message Log</title></head><body>[dat]</body></html>"
		user << browse(HTML, "window=log;size=400x444;border=1;can_resize=1;can_close=1;can_minimize=0")
	else
		to_chat(user, "You do not have a PDA. You should make an issue report about this.")

// Pass along the pulse to atoms in contents, largely added so pAIs are vulnerable to EMP
/obj/item/pda/emp_act(severity)
	. = ..()
	if (!(. & EMP_PROTECT_CONTENTS))
		for(var/atom/A in src)
			A.emp_act(severity)
	if (!(. & EMP_PROTECT_SELF))
		emped += 1
		spawn(200 * severity)
			emped -= 1

/proc/get_viewable_pdas()
	. = list()
	// Returns a list of PDAs which can be viewed from another PDA/message monitor.
	for(var/obj/item/pda/P in GLOB.PDAs)
		if(!P.owner || P.toff || P.hidden)
			continue
		. += P

/proc/get_viewable_assistant_pdas()
	. = list()
	// Same as above except returns only assistant PDAs
	for(var/obj/item/pda/P in GLOB.PDAs)
		if(P.ownjob == "Assistant")
			if(!P.owner|| P.toff || P.hidden)
				continue
			. += P

/obj/item/pda/proc/pda_no_detonate()
	return COMPONENT_TABLET_NO_DETONATE

/// Return a list of types you want to pregenerate and use later
/// Do not pass in things that care about their init location, or expect extra input
/// Also as a curtiousy to me, don't pass in any bombs
/obj/item/pda/proc/get_types_to_preload()
	var/list/preload = list()
	preload += default_cartridge
	preload += insert_type
	return preload

/// Callbacks for preloading pdas
/obj/item/pda/proc/display_pda()
	GLOB.PDAs += src

/// See above, we don't want jerry from accounting to try and message nullspace his new bike
/obj/item/pda/proc/cloak_pda()
	GLOB.PDAs -= src

#undef PDA_SCANNER_NONE
#undef PDA_SCANNER_MEDICAL
#undef PDA_SCANNER_FORENSICS
#undef PDA_SCANNER_REAGENT
#undef PDA_SCANNER_HALOGEN
#undef PDA_SCANNER_GAS
#undef PDA_SPAM_DELAY
#undef PDA_PRINTING_GENERAL_REQUEST
#undef PDA_PRINTING_COMPLAINT
#undef PDA_PRINTING_INCIDENT_REPORT
#undef PDA_PRINTING_SECURITY_INCIDENT_REPORT
#undef PDA_PRINTING_ITEM_REQUEST
#undef PDA_PRINTING_CYBERIZATION_CONSENT
#undef PDA_PRINTING_HOP_ACCESS_REQUEST
#undef PDA_PRINTING_JOB_CHANGE
#undef PDA_PRINTING_RESEARCH_REQUEST
#undef PDA_PRINTING_MECH_REQUEST
#undef PDA_PRINTING_JOB_REASSIGNMENT_CERTIFICATE
#undef PDA_PRINTING_LITERACY_TEST
#undef PDA_PRINTING_LITERACY_ANSWERS

