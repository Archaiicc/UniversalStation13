/obj/item/device/depth_scanner
	name = "depth analysis scanner"
	desc = "A device used to check spatial depth and density of rock outcroppings."
	icon = 'icons/obj/pda.dmi'
	icon_state = "crap"
	item_state = "analyzer"
	origin_tech = list(TECH_MAGNET = 2, TECH_ENGINEERING = 2, TECH_BLUESPACE = 2)
	matter = list(MATERIAL_STEEL = 1000, MATERIAL_GLASS = 500, MATERIAL_ALUMINIUM = 150)
	w_class = ITEM_SIZE_SMALL
	slot_flags = SLOT_BELT
	var/list/positive_locations = list()
	var/datum/depth_scan/current

/datum/depth_scan
	var/time = ""
	var/coords = ""
	var/depth = ""
	var/clearance = 0
	var/record_index = 1
	var/dissonance_spread = 1
	var/material = "unknown"

/obj/item/device/depth_scanner/proc/scan_atom(var/mob/user, var/atom/A)
	user.visible_message("<span class='notice'>\The [user] scans \the [A], the air around them humming gently.</span>")

	if(istype(A, /turf/simulated/mineral))
		var/turf/simulated/mineral/M = A
		if((M.finds && M.finds.len) || M.artifact_find)

			//create a new scanlog entry
			var/datum/depth_scan/D = new()
			D.coords = "[M.x]:[M.y]:[M.z]"
			D.time = stationtime2text()
			D.record_index = positive_locations.len + 1
			D.material = M.mineral ? M.mineral.ore_name : "Rock"

			//find the first artifact and store it
			if(M.finds.len)
				var/datum/find/F = M.finds[1]
				D.depth = "[F.excavation_required - F.clearance_range] - [F.excavation_required]"
				D.clearance = F.clearance_range
				D.material = get_responsive_reagent(F.find_type)

			positive_locations.Add(D)

			to_chat(user, "<span class='notice'>[icon2html(src, user)] [src] pings.</span>")

	else if(istype(A, /obj/structure/boulder))
		var/obj/structure/boulder/B = A
		if(B.artifact_find)
			//create a new scanlog entry
			var/datum/depth_scan/D = new()
			D.coords = "[B.x]:[B.y]:[B.z]"
			D.time = stationtime2text()
			D.record_index = positive_locations.len + 1

			//these values are arbitrary
			D.depth = rand(150, 200)
			D.clearance = rand(10, 50)
			D.dissonance_spread = rand(750, 2500) / 100

			positive_locations.Add(D)

			to_chat(user, "<span class='notice'>[icon2html(src, user)] [src] pings [pick("madly","wildly","excitedly","crazily")]!</span>")

	updateSelfDialog()

/obj/item/device/depth_scanner/attack_self(var/mob/living/user)
	interact(user)

/obj/item/device/depth_scanner/interact(var/mob/user as mob)
	user.set_machine(src)
	var/dat = "<b>Coordinates with positive matches</b><br>"

	dat += "<A href='?src=\ref[src];clear=0'>== Clear all ==</a><br>"

	if(current)
		dat += "Time: [current.time]<br>"
		dat += "Coords: [current.coords]<br>"
		dat += "Anomaly depth: [current.depth] cm<br>"
		dat += "Anomaly size: [current.clearance] cm<br>"
		dat += "Dissonance spread: [current.dissonance_spread]<br>"
		var/index = list_find(responsive_carriers, current.material)
		if(index > 0 && index <= finds_as_strings.len)
			dat += "Anomaly material: [finds_as_strings[index]]<br>"
		else
			dat += "Anomaly material: Unknown<br>"
		dat += "<A href='?src=\ref[src];clear=[current.record_index]'>clear entry</a><br>"
	else
		dat += "Select an entry from the list<br>"
		dat += "<br><br><br><br>"
	dat += "<hr>"
	if(positive_locations.len)
		for(var/index = 1 to positive_locations.len)
			var/datum/depth_scan/D = positive_locations[index]
			dat += "<A href='?src=\ref[src];select=[index]'>[D.time], coords: [D.coords]</a><br>"
	else
		dat += "No entries recorded."

	dat += "<hr>"
	dat += "<a href='?src=\ref[src];close=1'>Close</a>"

	var/datum/browser/popup = new(user, "depth_scanner", "Results", 300, 500)
	popup.set_content(dat)
	popup.open()
	onclose(user, "depth_scanner")

/obj/item/device/depth_scanner/OnTopic(user, href_list)
	if(href_list["select"])
		var/index = text2num(href_list["select"])
		if(index && index <= positive_locations.len)
			current = positive_locations[index]
		. = TOPIC_REFRESH
	else if(href_list["clear"])
		var/index = text2num(href_list["clear"])
		if(index)
			if(index <= positive_locations.len)
				var/datum/depth_scan/D = positive_locations[index]
				positive_locations.Remove(D)
				qdel(D)
		else
			//GC will hopefully pick them up before too long
			positive_locations = list()
			QDEL_NULL(current)
		. = TOPIC_REFRESH
	else if(href_list["close"])
		close_browser(user, "window=depth_scanner")
		return TOPIC_HANDLED

	if (. == TOPIC_REFRESH)
		interact(user)
