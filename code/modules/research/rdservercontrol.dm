/obj/machinery/computer/rdservercontrol
	name = "R&D Server Controller"
	desc = "Used to manage access to research and manufacturing databases."
	icon_screen = "rdcomp"
	icon_keyboard = "rd_key"
	req_access = list(ACCESS_RD)
	circuit = /obj/item/circuitboard/computer/rdservercontrol
	var/datum/techweb/stored_research
	var/obj/item/disk/design_disk/d_disk
	var/obj/item/disk/tech_disk/t_disk

/obj/machinery/computer/rdservercontrol/Initialize()
	. = ..()
	stored_research = SSresearch.science_tech
	stored_research.consoles_accessing[src] = TRUE

/obj/machinery/computer/rdservercontrol/Destroy()
	if(stored_research)
		stored_research.consoles_accessing -= src
	if(t_disk)
		t_disk.forceMove(get_turf(src))
		t_disk = null
	if(d_disk)
		d_disk.forceMove(get_turf(src))
		d_disk = null
	return ..()

/obj/machinery/computer/rdservercontrol/attackby(obj/item/D, mob/user, params)
	// Redeem research points.
	if(istype(D, /obj/item/research_notes))
		var/obj/item/research_notes/R = D
		SSresearch.science_tech.add_point_list(list(TECHWEB_POINT_TYPE_GENERIC = R.value))
		playsound(src, 'sound/machines/copier.ogg', 100, TRUE)
		qdel(R)
		return TRUE
	// Loading tech and design disks.
	if(istype(D, /obj/item/disk))
		if(d_disk || t_disk)
			to_chat(user, "<span class='warning'>A disk is already loaded!</span>")
			return FALSE
		if(!user.transferItemToLoc(D, src))
			to_chat(user, "<span class='warning'>[D] is stuck to your hand!</span>")
			return FALSE
		if(istype(D, /obj/item/disk/tech_disk))
			t_disk = D
		else if (istype(D, /obj/item/disk/design_disk))
			d_disk = D
		else
			to_chat(user, "<span class='warning'>This machine cannot accept disks in that format.</span>")
			return FALSE
		to_chat(user, "<span class='notice'>You insert [D] into \the [src]!</span>")
		return TRUE
	return ..()

/obj/machinery/computer/rdservercontrol/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	add_fingerprint(usr)
	usr.set_machine(src)
	switch(action)
		// Server Interactions
		if("rnd_server_power")
			var/obj/machinery/rnd/server/S = locate(params["rnd_server"]) in GLOB.machines
			if (!S)
				to_chat(usr, "<span class='warning'>RND Server Control: Unable to find RND Server.</span>")
				return FALSE
			S.set_research_disabled(params["research_disabled"] ? TRUE : FALSE)
			return TRUE
		// Disk Interactions
		if("eject_disk")
			return eject_disk()
		// Tech Disk Interactions
		if("clear_tech")
			if(QDELETED(t_disk))
				say("No technology disk found.")
				return FALSE
			qdel(t_disk.stored_research)
			t_disk.stored_research = new
			say("Wiping technology disk.")
			return TRUE
		if("copy_tech")
			if(QDELETED(t_disk))
				say("No technology disk found.")
				return FALSE
			stored_research.copy_research_to(t_disk.stored_research)
			say("Downloading to technology disk.")
			return TRUE
		if("update_tech")
			if(QDELETED(t_disk))
				say("No technology disk found.")
				return FALSE
			say("Uploading technology disk.")
			t_disk.stored_research.copy_research_to(stored_research)
			return TRUE
		// Design Disk Interactions
		if("clear_design")
			if(QDELETED(d_disk))
				say("No design disk found.")
				return FALSE
			var/slot = text2num(params["design_index"])
			if(!slot)
				for(var/i in 1 to d_disk.max_blueprints)
					d_disk.blueprints[i] = null
					say("Wiping design disk.")
			else
				var/datum/design/D = d_disk.blueprints[slot]
				say("Wiping design [D.name] from design disk.")
				d_disk.blueprints[slot] = null
			return TRUE
		if("copy_design")
			if(QDELETED(d_disk))
				say("No design disk found.")
				return FALSE
			var/slot = text2num(params["design_index"])
			var/datum/design/D = SSresearch.techweb_design_by_id(params["design_id"])
			if(D)
				var/autolathe_friendly = TRUE
				if(D.reagents_list.len)
					autolathe_friendly = FALSE
					D.category -= "Imported"
				else
					for(var/x in D.materials)
						if(!(x in list(/datum/material/iron, /datum/material/glass)))
							autolathe_friendly = FALSE
							D.category -= "Imported"

				if(D.build_type & (AUTOLATHE|PROTOLATHE|CRAFTLATHE)) // Specifically excludes circuit imprinter and mechfab
					D.build_type = autolathe_friendly ? (D.build_type | AUTOLATHE) : D.build_type
					D.category |= "Imported"
				d_disk.blueprints[slot] = D
				return TRUE
			return FALSE
		// Uploads a design from disk to the techweb.
		if("update_design")
			if(QDELETED(d_disk))
				say("No design disk found.")
				return FALSE
			var/n = text2num(params["update_design"])
			if(!n)
				for(var/D in d_disk.blueprints)
					if(D)
						stored_research.add_design(D, TRUE)
			else
				stored_research.add_design(d_disk.blueprints[n], TRUE)
			return TRUE

/obj/machinery/computer/rdservercontrol/ui_data(mob/user)
	var/list/data = list()
	// Servers
	data["rnd_servers"] = list()
	for(var/obj/machinery/rnd/server/S in SSresearch.servers)
		data["rnd_servers"] += list(S.ui_data())
	// Logs
	data["research_logs"] = SSresearch.science_tech.research_logs
	// Technology Disks
	data["has_tech_disk"] = t_disk ? TRUE : FALSE
	data["tech_disk"] = list()
	if(t_disk)
		for(var/ti in t_disk.stored_research.researched_nodes)
			var/datum/techweb_node/DN = SSresearch.techweb_node_by_id(ti)
			data["tech_disk"] += list(list(
				"id" = DN.id,
				"name" = DN.display_name
			))
	// Design Disk
	data["has_design_disk"] = d_disk ? TRUE : FALSE
	data["design_disk"] = list()
	data["design_disk_size"] = 0
	if(d_disk)
		data["design_disk_size"] = d_disk.max_blueprints
		for(var/i in 1 to d_disk.max_blueprints)
			if(d_disk.blueprints[i])
				var/datum/design/D = d_disk.blueprints[i]
				data["design_disk"] += list(list(
					"id" = D.id,
					"name" = D.name
				))
			else
				data["design_disk"] += list(null)
	// General Tech
	data["tech_available"] = list()
	for(var/sti in stored_research.researched_nodes)
		var/datum/techweb_node/SN = SSresearch.techweb_node_by_id(sti)
		data["tech_available"] += list(list(
			"id" = SN.id,
			"name" = SN.display_name
		))
	return data

/obj/machinery/computer/rdservercontrol/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RdServerControl", name)
		ui.open()

/obj/machinery/computer/rdservercontrol/proc/eject_disk(type)
	if(d_disk)
		d_disk.forceMove(get_turf(src))
		d_disk = null
	if(t_disk)
		t_disk.forceMove(get_turf(src))
		t_disk = null
