module tests.moves.fixed_damage;

import logging;
import sets;
import state;
import test;

mixin TestModule;

PokeTest fixedDamage_amount() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("totodile", 50)
				.moves(["sonic_boom", "dragon_rage"])
		]))
		.enemy(PokeTeam([
			PokeSet("totodile", 50)
				.moves(["sonic_boom", "dragon_rage"])
		]))
		.turn("sonic_boom", "dragon_rage")
		.validate((state, player, enemy) {
			assert(player.damageDealt == 20, "Sonic Boom should deal exactly 20 damage");
			assert(enemy.damageDealt == 40, "Dragon Rage should deal exactly 40 damage");
		})
	;
}

PokeTest fixedDamage_effectiveness() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("clefairy", 50)
				.moves(["sonic_boom", "dragon_rage"])
		]))
		.enemy(PokeTeam([
			PokeSet("omanyte", 50)
				.moves(["sonic_boom", "dragon_rage"])
		]))
		.turn("sonic_boom", "dragon_rage")
		.validate((state, player, enemy) {
			assert(player.damageDealt == 20, "Sonic Boom should not deal less damage against Rock types");
			assert(enemy.damageDealt == 0, "Dragon Rage should be effected by immunities");
		})
	;
}

PokeTest fixedDamage_stab() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("porygon", 50)
				.moves(["sonic_boom", "dragon_rage"])
		]))
		.enemy(PokeTeam([
			PokeSet("dratini", 50)
				.moves(["sonic_boom", "dragon_rage"])
		]))
		.turn("sonic_boom", "dragon_rage")
		.validate((state, player, enemy) {
			assert(player.damageDealt == 20, "Sonic Boom should not get STAB");
			assert(enemy.damageDealt == 40, "Dragon Rage should not get STAB");
		})
	;
}
