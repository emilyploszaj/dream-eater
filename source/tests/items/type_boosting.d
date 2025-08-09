module tests.items.type_boosting;

import logging;
import sets;
import state;
import test;

mixin TestModule;

PokeTest typeBoosting_silkScarf() {
	return createTypeBoostingTest("silk_scarf", "tackle");
}

PokeTest typeBoosting_blackBelt() {
	return createTypeBoostingTest("black_belt", "mach_punch");
}

PokeTest typeBoosting_sharpBeak() {
	return createTypeBoostingTest("sharp_beak", "peck");
}

PokeTest typeBoosting_poisonBarb() {
	return createTypeBoostingTest("poison_barb", "sludge");
}

PokeTest typeBoosting_softSand() {
	return createTypeBoostingTest("soft_sand", "earthquake");
}

PokeTest typeBoosting_hardStone() {
	return createTypeBoostingTest("hard_stone", "rock_throw");
}

PokeTest typeBoosting_silverpowder() {
	return createTypeBoostingTest("silverpowder", "bug_bite");
}

PokeTest typeBoosting_spellTag() {
	return createTypeBoostingTest("spell_tag", "shadow_ball");
}

PokeTest typeBoosting_metalCoat() {
	return createTypeBoostingTest("metal_coat", "bullet_punch");
}

PokeTest typeBoosting_charcoal() {
	return createTypeBoostingTest("charcoal", "ember");
}

PokeTest typeBoosting_mysticWater() {
	return createTypeBoostingTest("mystic_water", "bubble_beam");
}

PokeTest typeBoosting_miracleSeed() {
	return createTypeBoostingTest("miracle_seed", "vine_whip");
}

PokeTest typeBoosting_magnet() {
	return createTypeBoostingTest("magnet", "thunderbolt");
}

PokeTest typeBoosting_twistedspoon() {
	return createTypeBoostingTest("twistedspoon", "psychic_m");
}

PokeTest typeBoosting_nevermeltice() {
	return createTypeBoostingTest("nevermeltice", "aurora_beam");
}

PokeTest typeBoosting_dragonFang() {
	return createTypeBoostingTest("dragon_fang", "dragon_claw");
}

PokeTest typeBoosting_blackglasses() {
	return createTypeBoostingTest("blackglasses", "dark_pulse");
}

PokeTest typeBoosting_pinkBow() {
	return createTypeBoostingTest("pink_bow", "fairy_wind");
}

private PokeTest createTypeBoostingTest(string item, string move) {
	string other = item == "silk_scarf" ? "fairy_wind" : "tackle";
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("hypno", 70)
				.item(item)
				.moves([move, "recover"])
		]))
		.enemy(PokeTeam([
			PokeSet("hypno", 70)
				.moves([move, "recover"])
		]))
		.turn(move, move)
		.validate((state, player, enemy) {
			assert(within(enemy.move.damage * 12 / 10, player.move.damage, 2), "Item should increase damage by 20%");
		})
		.turn("recover", "recover")
		.turn(other, other)
		.validate((state, player, enemy) {
			assert(player.move.damage == player.move.damage, "Item should not increase damage for moves of the wrong type");
		})
	;
}
