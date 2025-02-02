//Used by the Taunting Tirade scripture as a trail.
/obj/structure/destructible/clockwork/taunting_trail
	name = "strange smoke"
	desc = "A cloud of purple smoke."
	clockwork_desc = "A cloud of purple smoke that confuses and knocks down non-Servants that enter it."
	gender = PLURAL
	max_integrity = 5
	density = TRUE
	color = list("#AF0AAF", "#AF0AAF", "#AF0AAF", rgb(0,0,0))
	icon = 'icons/effects/effects.dmi'
	icon_state = "smoke"
	break_message = null
	break_sound = 'sound/magic/teleport_app.ogg'
	debris = list()
	var/timerid

/obj/structure/destructible/clockwork/taunting_trail/Initialize(mapload)
	. = ..()
	timerid = QDEL_IN_STOPPABLE(src, 15)
	var/obj/structure/destructible/clockwork/taunting_trail/Tt = locate(/obj/structure/destructible/clockwork/taunting_trail) in loc
	if(Tt && Tt != src)
		if(!step(src, pick(GLOB.alldirs)))
			qdel(Tt)
		else
			for(var/obj/structure/destructible/clockwork/taunting_trail/TT in loc)
				if(TT != src)
					qdel(TT)
	setDir(pick(GLOB.cardinals))
	transform = matrix()*1.3
	animate(src, alpha = 100, time = 15)

	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)


/obj/structure/destructible/clockwork/taunting_trail/Destroy()
	deltimer(timerid)
	return ..()

/obj/structure/destructible/clockwork/taunting_trail/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	playsound(src, 'sound/items/welder.ogg', 50, 1)

/obj/structure/destructible/clockwork/taunting_trail/CanAllowThrough(atom/movable/mover, border_dir)
	..()
	return TRUE

/obj/structure/destructible/clockwork/taunting_trail/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	affect_mob(AM)

/obj/structure/destructible/clockwork/taunting_trail/Bumped(atom/movable/AM)
	affect_mob(AM)
	return ..()

/obj/structure/destructible/clockwork/taunting_trail/Bump(atom/movable/AM)
	affect_mob(AM)
	return ..()

/obj/structure/destructible/clockwork/taunting_trail/proc/affect_mob(mob/living/L)
	if(istype(L) && !is_servant_of_ratvar(L))
		if(!L.anti_magic_check(chargecost = 0))
			L.confused = min(L.confused + 15, 50)
			L.dizziness = min(L.dizziness + 15, 50)
			if(L.confused >= 25)
				L.DefaultCombatKnockdown(FLOOR(L.confused * 0.8, 1))
		take_damage(max_integrity)
