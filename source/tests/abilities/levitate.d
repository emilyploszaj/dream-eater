module tests.abilities.levitate;

import logging;
import sets;
import state;
import test;

mixin TestModule;

PokeTest levitate_basic() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("unown", 30)
				.ability("levitate")
				.moves(["recover"])
		]))
		.enemy(PokeTeam([
			PokeSet("unown", 29)
				.ability("levitate")
				.moves(["mud_slap"])
		]))
		.turn("recover", "mud_slap")
		.validate((state, player, enemy) {
			assert(enemy.damageDealt == 0, "Levitate mons should not be hit by Ground moves");
		})
	;
}

PokeTest levitate_gravity() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("unown", 30)
				.ability("levitate")
				.moves(["gravity"])
		]))
		.enemy(PokeTeam([
			PokeSet("unown", 29)
				.ability("levitate")
				.moves(["mud_slap"])
		]))
		.turn("gravity", "mud_slap")
		.validate((state, player, enemy) {
			assert(enemy.damageDealt > 0, "Levitate mons should be hit by Ground moves during Gravity");
		})
	;
}

PokeTest levitate_ironBall() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("unown", 30)
				.ability("levitate")
				.item("iron_ball")
				.moves(["recover"])
		]))
		.enemy(PokeTeam([
			PokeSet("unown", 29)
				.ability("levitate")
				.moves(["mud_slap"])
		]))
		.turn("recover", "mud_slap")
		.validate((state, player, enemy) {
			assert(enemy.damageDealt > 0, "Levitate mons should be hit by Ground moves if holding Iron Ball");
		})
	;
}

PokeTest levitate_moldBreaker() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("unown", 30)
				.ability("levitate")
				.moves(["recover"])
		]))
		.enemy(PokeTeam([
			PokeSet("ampharos", 29)
				.ability("mold_breaker")
				.moves(["mud_slap"])
		]))
		.turn("recover", "mud_slap")
		.validate((state, player, enemy) {
			assert(enemy.damageDealt > 0, "Levitate mons should be hit by Ground moves if the user has Mold Breaker");
		})
	;
}
