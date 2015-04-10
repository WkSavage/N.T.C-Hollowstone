/obj/item/device/taperecorder/duty_officer
	desc = "A device that can record up to an hour of dialogue and play it back. It automatically translates the content in playback."
	name = "universal recorder"
	icon_state = "taperecorderidle"
	item_state = "analyzer"
	w_class = 1.0
	recording = 0
	timestamp = list()	//This actually turns timestamp into a string later on

	flags = FPRINT | TABLEPASS| CONDUCT
	throwforce = 2
	throw_speed = 4
	throw_range = 20

	//Redundent
	matter = list()
	playing = 0
	emagged = 0
	timerecorded = 0
	playsleepseconds = 0
	storedinfo = list()
	canprint = 1

	//Specific for Duty Officers
	var/paused = 0
	var/assignedUsers = list()
	var/sessionLog = list()
	var/interviewLog = list()
	var/sLogFile = null
	var/iLogFile = null

/obj/item/device/taperecorder/duty_officer/hear_talk(mob/living/M as mob, msg, var/verb="says")
	if(recording && !paused)
		timestamp = "[get_time()]"
		var/fmsg = "\[[timestamp]\] [M.name] [verb], \"[msg]\""
		sLogFile << fmsg
	return

/obj/item/device/taperecorder/duty_officer/proc/get_time()
	return "[round(world.time / 36000)+12]:[(world.time / 600 % 60) < 10 ? add_zero(world.time / 600 % 60, 1) : world.time / 600 % 60]:[(world.time / 60 % 60) < 10 ? add_zero(world.time / 60 % 60, 1) : world.time / 60 % 60]"


/obj/item/device/taperecorder/duty_officer/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W, /obj/item/weapon/card/id))
		var/obj/item/weapon/card/id/ID = W
		if(ID.GetAccess(access_cent_captain))
			if(!user in assignedUsers)
				assignedUsers += user
			else
				user << "<span class='notice'>The device beeps and flashes \"Already Registered\".</span>"
			return
		else
			user << "<span class='notice'>The device beeps and appears to shutdown.</span>"
			return
	if(istype(W, /obj/item/weapon/paper))
		var/obj/item/weapon/paper/P = W
		logPaper(user, P)
	..()

/obj/item/device/taperecorder/duty_officer/proc/logPaper(var/mob/M, var/obj/item/weapon/paper/P)
	if(!P)
		return
	var/case = input(usr, "Enter case name","Case Name") as null|text
	if(!case || case == "")
		usr  << "<span class='notice'>The device beeps and flashes \"No data entered, Aborting\".</span>"
		return
	var/reference = input(usr, "Enter reference","Reference") as null|text
	if(!reference || reference == "")
		usr  << "<span class='notice'>The device beeps and flashes \"No data entered, Aborting\".</span>"
		return

	var/date_string = time2text(world.realtime, "YYYY_MM_DD")
	var/fileLoc = "data/dutylogs/[M.ckey]/[date_string]-[case].log"
	var/fileName = "[date_string]-[case].log"
	if(fexists(fileLoc))
		var/safe = 0
		var/i = 1
		while(!safe)
			fileLoc = "data/dutylogs/[M.ckey]/[date_string]-[case][i].log"
			if(!fexists(fileLoc))
				fileName = "[date_string]-[case][i].log"
				safe = 1
				break
			i++

	iLogFile = file(fileLoc)
	iLogFile << "[P.name]-[reference]"
	iLogFile << "Case file: [case]"
	iLogFile << "Reference: [reference]"
	iLogFile << "Date: [date_string]"
	iLogFile << "Filed by: [M]"
	iLogFile << "--------------------------------"
	iLogFile << "[P.info]"
	iLogFile << "[P.stamps]"
	iLogFile = null
	usr  << "<span class='notice'>The device beeps and flashes \"Writing to [fileName]\".</span>"
	return

/obj/item/device/taperecorder/duty_officer/record()
	set name = "Start Recording"
	set category = "Recorder"

	if(!usr.client.holder)
		usr  << "<span class='notice'>The device beeps and flashes \"Unauthorised user.\".</span>"
		return
	if(usr.stat)
		return
	if(recording)
		usr  << "<span class='notice'>The device beeps and flashes \"Already recording, Aborting\".</span>"
		return

	var/case = input(usr, "Enter case name","Case Name") as null|text
	if(!case || case == "")
		usr  << "<span class='notice'>The device beeps and flashes \"No data entered, Aborting\".</span>"
		return
	var/interviewee = input(usr, "Enter interviewee name","Interviewee Name") as null|text
	if(!interviewee || interviewee == "")
		usr  << "<span class='notice'>The device beeps and flashed \"No data entered, Aborting\".</span>"
		return

	var/date_string = time2text(world.realtime, "YYYY_MM_DD")
	var/fileLoc = "data/dutylogs/[usr.ckey]/[date_string]-[case]-[interviewee].log"
	var/fileName = "[date_string]-[case].log"
	if(fexists(fileLoc))
		var/safe = 0
		var/i = 1
		while(!safe)
			fileLoc = "data/dutylogs/[usr.ckey]/[date_string]-[case]-[interviewee]-[i].log"
			if(!fexists(fileLoc))
				fileName = "[date_string]-[case]-[interviewee]-[i].log"
				safe = 1
				break
			i++
	sLogFile = file(fileLoc)
	sLogFile << "[case]-[interviewee]"
	sLogFile << "Case file: [case]"
	sLogFile << "--------------------------------"
	sLogFile << "Date: [date_string]"
	sLogFile << "--------------------------------"
	sLogFile << "Interviewer: [usr.name]"
	sLogFile << "Interviewee: [interviewee]"
	sLogFile << "Recorder started: [get_time()]"
	sLogFile << "--------------------------------"

	recording = 1
	icon_state = "taperecorderrecording"
	usr  << "<span class='notice'>The device beeps and flashes \"Writing to [fileName]\".</span>"

	return

/obj/item/device/taperecorder/duty_officer/stop()
	set name = "Stop"
	set category = "Recorder"

	if(usr.stat)
		return
	if(!usr.client.holder)
		usr  << "<span class='notice'>The device beeps and flashes \"Unauthorised user.\".</span>"
		return
	if(!recording)
		usr  << "<span class='notice'>The device beeps and flashes \"Not recording, Aborting\".</span>"
		return

	recording = 0
	paused = 0
	sLogFile << "--------------------------------"
	sLogFile << "Recorder stopped: [get_time()]"
	sLogFile << "--------------------------------"
	sLogFile = null
	usr  << "<span class='notice'>The device beeps and flashes \"Recording stopped log saved.\".</span>"
	icon_state = "taperecorderidle"

	return

/obj/item/device/taperecorder/duty_officer/print_transcript()
	set name = "Print Transcript"
	set category = "Recorder"

	if(usr.stat)
		return
	if(!usr.client.holder)
		usr  << "<span class='notice'>The device beeps and flashes \"Unauthorised user\".</span>"
		return
	if(recording)
		usr  << "<span class='notice'>The device beeps and flashes \"Device recording, Aborting\".</span>"
		return

	var/path = usr.client.browse_files("data/dutylogs/")
	if(!path)
		return

	message_admins("[key_name_admin(usr)] accessed file: [path]")
	var/list/lFile = file2list(path)
	var/dat = ""
	var/firstLine = null
	for(var/line in lFile)
		if(!line)
			continue
		if(!firstLine)
			firstLine = "[line]"
			continue

		dat += "[line]<br>"

	var/obj/item/weapon/paper/P = new /obj/item/weapon/paper(src)
	P.name = "[firstLine]"
	P.info = "[dat]"
	P.update_icon()
	P.loc = get_turf(src.loc)

	return

/obj/item/device/taperecorder/duty_officer/verb/pause_recording()
	set name = "Pause"
	set category = "Recorder"

	if(usr.stat)
		return
	if(!usr.client.holder)
		usr  << "<span class='notice'>The device beeps and flashes \"Unauthorised user.\".</span>"
		return
	if(!recording)
		usr  << "<span class='notice'>The device beeps and flashes \"Not recording, Aborting\".</span>"
		return

	if(!paused)
		sLogFile << "--------------------------------"
		sLogFile << "Recorder paused at: [get_time()]"
		usr  << "<span class='notice'>The device beeps and flashes \"Recording resumed\".</span>"
		paused = 1
	else
		sLogFile << "Recorder resumed at: [get_time()]"
		sLogFile << "--------------------------------"
		usr << "<span class='notice'>The device beeps and flashes \"Recording paused\".</span>"
		paused = 0
	return

/obj/item/device/taperecorder/duty_officer/attack_self(mob/user)
	return

//redundent for now
/obj/item/device/taperecorder/duty_officer/clear_memory()
	set name = "Clear Memory"
	set category = null

	return

/obj/item/device/taperecorder/duty_officer/playback_memory()
	set name = "Playback Memory"
	set category = null

	return

/obj/item/device/taperecorder/duty_officer/explode()
	return

