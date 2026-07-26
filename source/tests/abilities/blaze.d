module tests.abilities.blaze;

import logging;
import sets;
import state;
import test;

mixin TestModule;

PokeTest blaze_boostsFire() {
	static uint initialDamage = 0;
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("charmander", 40)
				.nature("spa", "spe")
				.ability("blaze")
				.moves(["flamethrower"])
		]))
		.enemy(PokeTeam([
			PokeSet("tauros", 60)
				.moves(["false_swipe", "recover"])
		]))
		.turn("flamethrower", "recover")
		.validate((state, player, enemy) {
			assert(enemy.wentFirst);
			initialDamage = player.move.damage;
		})
		.turn("flamethrower", "false_swipe")
		.validate((state, player, enemy) {
			assert(enemy.wentFirst);
			assert(player.hp * 100 / player.maxHp < 33, "Player should be in pinch range");
			assert(initialDamage < player.move.damage, "Blaze should boost Flamethrower");
		})
	;
}

PokeTest blaze_doesNotBoostOtherTypes() {
	static uint initialDamage = 0;
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("charmander", 40)
				.nature("spa", "spe")
				.ability("blaze")
				.moves(["thunderbolt"])
		]))
		.enemy(PokeTeam([
			PokeSet("tauros", 60)
				.moves(["false_swipe", "recover"])
		]))
		.turn("thunderbolt", "recover")
		.validate((state, player, enemy) {
			assert(enemy.wentFirst);
			initialDamage = player.move.damage;
			assert(player.move.damage > 20);
		})
		.turn("thunderbolt", "false_swipe")
		.validate((state, player, enemy) {
			assert(enemy.wentFirst);
			assert(player.hp * 100 / player.maxHp < 33, "Player should be in pinch range");
			assert(initialDamage == player.move.damage, "Blaze should not boost Thunderbolt");
		})
	;
}
