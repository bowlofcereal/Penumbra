/datum/advclass/carpenter
	name = "Carpenter"
	tutorial = "A skilled carpenter, able to manipulate wood to suit their needs \
	building forts and stores, carpenting floors, putting up crosses. You can do it all with enough logs"
	allowed_sexes = list(MALE, FEMALE)
	allowed_races = RACES_ALL_KINDS
	outfit = /datum/outfit/job/roguetown/adventurer/carpenter

	category_tags = list(CTAG_PILGRIM, CTAG_TOWNER)

/datum/outfit/job/roguetown/adventurer/carpenter/pre_equip(mob/living/carbon/human/H)
	..()
	if(H.mind)
		H.mind.adjust_skillrank(/datum/skill/combat/axes, 2, TRUE)
		H.mind.adjust_skillrank(/datum/skill/misc/athletics, 1, TRUE)
		H.mind.adjust_skillrank(/datum/skill/combat/wrestling, 1, TRUE)
		H.mind.adjust_skillrank(/datum/skill/misc/swimming, 1, TRUE)
		H.mind.adjust_skillrank(/datum/skill/misc/climbing, 3, TRUE) // They work at great heights. (M EDIT: you know what? sure)
		H.mind.adjust_skillrank(/datum/skill/craft/crafting, 2, TRUE)
		H.mind.adjust_skillrank(/datum/skill/craft/carpentry, 3, TRUE)
		H.mind.adjust_skillrank(/datum/skill/misc/reading, 2, TRUE)
		H.mind.adjust_skillrank(/datum/skill/craft/traps, 1, TRUE)
		H.mind.adjust_skillrank(/datum/skill/labor/lumberjacking, 2, TRUE)
		H.mind.adjust_skillrank(/datum/skill/combat/improvised, 3, TRUE)
	head = /obj/item/clothing/head/roguetown/hatfur
	if(prob(50))
		head = /obj/item/clothing/head/roguetown/hatblu
	armor = /obj/item/clothing/suit/roguetown/armor/workervest
	pants = /obj/item/clothing/under/roguetown/trou
	shirt = /obj/item/clothing/suit/roguetown/shirt/undershirt/random
	shoes = /obj/item/clothing/shoes/roguetown/boots/leather
	belt = /obj/item/storage/belt/rogue/leather
	beltr = /obj/item/storage/belt/rogue/pouch/coins/mid
	beltl = /obj/item/rogueweapon/hammer/claw
	backl = /obj/item/storage/backpack/rogue/backpack
	backpack_contents = list(/obj/item/flint = 1, /obj/item/rogueweapon/huntingknife = 1)
	H.change_stat("strength", 1)
	H.change_stat("endurance", 2)
	H.change_stat("constitution", 1)
	H.change_stat("intelligence", 1)
	H.change_stat("speed", -1)
