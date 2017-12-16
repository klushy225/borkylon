/obj/item/device/electropack
	name = "electropack"
	desc = "Dance my monkeys! DANCE!!!"
	icon = 'icons/obj/radio.dmi'
	icon_state = "electropack0"
	item_state = "electropack"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	flags_1 = CONDUCT_1
	slot_flags = SLOT_BACK
	w_class = WEIGHT_CLASS_HUGE
	materials = list(MAT_METAL=10000, MAT_GLASS=2500)
	var/on = TRUE
	var/code = 2
	var/frequency = FREQ_ELECTROPACK
	var/shock_cooldown = 0

/obj/item/device/electropack/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] hooks [user.p_them()]self to the electropack and spams the trigger! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return (FIRELOSS)

/obj/item/device/electropack/Initialize()
	. = ..()
	SSradio.add_object(src, frequency, RADIO_SIGNALER)

/obj/item/device/electropack/Destroy()
	SSradio.remove_object(src, frequency)
	return ..()

/obj/item/device/electropack/attack_hand(mob/user)
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		if(src == C.back)
			to_chat(user, "<span class='warning'>You need help taking this off!</span>")
			return
	..()

/obj/item/device/electropack/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/clothing/head/helmet))
		var/obj/item/assembly/shock_kit/A = new /obj/item/assembly/shock_kit( user )
		A.icon = 'icons/obj/assemblies.dmi'

		if(!user.transferItemToLoc(W, A))
			to_chat(user, "<span class='warning'>[W] is stuck to your hand, you cannot attach it to [src]!</span>")
			return
		W.master = A
		A.part1 = W

		user.transferItemToLoc(src, A, TRUE)
		master = A
		A.part2 = src

		user.put_in_hands(A)
		A.add_fingerprint(user)
		if(src.flags_1 & NODROP_1)
			A.flags_1 |= NODROP_1
	else
		return ..()

/obj/item/device/electropack/Topic(href, href_list)
	//..()
	var/mob/living/carbon/C = usr
	if(usr.stat || usr.restrained() || C.back == src)
		return
	if((ishuman(usr) && usr.contents.Find(src)) || usr.contents.Find(master) || (in_range(src, usr) && isturf(loc)))
		usr.set_machine(src)
		if(href_list["freq"])
			SSradio.remove_object(src, frequency)
			frequency = sanitize_frequency(frequency + text2num(href_list["freq"]))
			SSradio.add_object(src, frequency, RADIO_SIGNALER)
		else
			if(href_list["code"])
				code += text2num(href_list["code"])
				code = round(code)
				code = min(100, code)
				code = max(1, code)
			else
				if(href_list["power"])
					on = !( on )
					icon_state = "electropack[on]"
		if(!( master ))
			if(ismob(loc))
				attack_self(loc)
			else
				for(var/mob/M in viewers(1, src))
					if(M.client)
						attack_self(M)
		else
			if(ismob(master.loc))
				attack_self(master.loc)
			else
				for(var/mob/M in viewers(1, master))
					if(M.client)
						attack_self(M)
	else
		usr << browse(null, "window=radio")
		return
	return

/obj/item/device/electropack/receive_signal(datum/signal/signal)
	if(!signal || signal.data["code"] != code)
		return

	if(isliving(loc) && on)
		if(shock_cooldown != 0)
			return
		shock_cooldown = 1
		spawn(100)
			shock_cooldown = 0
		var/mob/living/L = loc
		step(L, pick(GLOB.cardinals))

		to_chat(L, "<span class='danger'>You feel a sharp shock!</span>")
		var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
		s.set_up(3, 1, L)
		s.start()

		L.Knockdown(100)

	if(master)
		master.receive_signal()
	return

/obj/item/device/electropack/attack_self(mob/user)

	if(!ishuman(user))
		return
	user.set_machine(src)
	var/dat = {"<TT>Turned [on ? "On" : "Off"] -
<A href='?src=[REF(src)];power=1'>Toggle</A><BR>
<B>Frequency/Code</B> for electropack:<BR>
Frequency:
<A href='byond://?src=[REF(src)];freq=-10'>-</A>
<A href='byond://?src=[REF(src)];freq=-2'>-</A> [format_frequency(frequency)]
<A href='byond://?src=[REF(src)];freq=2'>+</A>
<A href='byond://?src=[REF(src)];freq=10'>+</A><BR>

Code:
<A href='byond://?src=[REF(src)];code=-5'>-</A>
<A href='byond://?src=[REF(src)];code=-1'>-</A> [code]
<A href='byond://?src=[REF(src)];code=1'>+</A>
<A href='byond://?src=[REF(src)];code=5'>+</A><BR>
</TT>"}
	user << browse(dat, "window=radio")
	onclose(user, "radio")
	return

/obj/item/device/electropack/shockcollar
	name = "shock collar"
	desc = "A reinforced metal collar. It seems to have some form of wiring near the front. Strange.."
	icon = 'icons/obj/clothing/neck.dmi'
	icon_state = "shockcollar"
	item_state = "shockcollar"
	body_parts_covered = NECK
	slot_flags = SLOT_NECK
	w_class = WEIGHT_CLASS_SMALL
	strip_delay = 60
	equip_delay_other = 60
	materials = list(MAT_METAL=5000, MAT_GLASS=2000)
	var/tagname = null

/obj/item/device/electropack/shockcollar/attack_hand(mob/user)
	if(loc == user)
		if(slot_flags == SLOT_NECK)
			if(user.get_item_by_slot(slot_neck))
				to_chat(user, "<span class='warning'>The collar is fastened tight! You'll need help taking this off!</span>")
				return
	..()

/obj/item/device/electropack/shockcollar/receive_signal(datum/signal/signal)
	if(!signal || signal.data["code"] != code)
		return

	if(isliving(loc) && on)
		if(shock_cooldown != 0)
			return
		shock_cooldown = 1
		spawn(100)
			shock_cooldown = 0
		var/mob/living/L = loc
		step(L, pick(GLOB.cardinals))

		to_chat(L, "<span class='danger'>You feel a sharp shock from the collar!</span>")
		var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
		s.set_up(3, 1, L)
		s.start()

		L.Knockdown(100)

	if(master)
		master.receive_signal()
	return

/obj/item/device/electropack/shockcollar/attack_self(mob/user) //Turns out can't fully source this from the parent item, spritepath gets confused if power toggled. Will come back to this when I know how to code better and readd powertoggle..
	var/option = "Change Name"
	option = input(user, "What do you want to do?", "[src]", option) as null|anything in list("Change Name", "Change Frequency")
	switch(option)
		if("Change Name")
			var/t = input(user, "Would you like to change the name on the tag?", "Name your new pet", tagname ? tagname : "Spot") as null|text
			if(t)
				tagname = copytext(sanitize(t), 1, MAX_NAME_LEN)
				name = "[initial(name)] - [tagname]"
		if("Change Frequency")
			if(!ishuman(user))
				return
				user.set_machine(src)
			var/dat = {"<SK><BR>
		<B>Frequency/Code</B> for shock collar:<BR>
		Frequency:
		<A href='byond://?src=\ref[src];freq=-10'>-</A>
		<A href='byond://?src=\ref[src];freq=-2'>-</A> [format_frequency(frequency)]
		<A href='byond://?src=\ref[src];freq=2'>+</A>
		<A href='byond://?src=\ref[src];freq=10'>+</A><BR>
		Code:
		<A href='byond://?src=\ref[src];code=-5'>-</A>
		<A href='byond://?src=\ref[src];code=-1'>-</A> [code]
		<A href='byond://?src=\ref[src];code=1'>+</A>
		<A href='byond://?src=\ref[src];code=5'>+</A><BR>
		</SK>"}

			user << browse(dat, "window=radio")
			onclose(user, "radio")
			return
