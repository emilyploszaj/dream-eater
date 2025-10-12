module tests.stats;

import logging;
import sets;
import state;
import test;

mixin TestModule!(mixin(__MODULE__));

PokeTest stats_natures() {
	// Natures should confer a 10% advantage or disadvantage in respective stats
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("skiploom", 100)
				.nature("spe", "atk")
				.moves(["protect"])
		]))
		.enemy(PokeTeam([
			PokeSet("skiploom", 100)
				.moves(["protect"])
		]))
		.turn("protect", "protect")
		.validate((state, player, enemy) {
			assert(player.spe == enemy.spe * 110 / 100, "Spe should be 10% higher");
			assert(player.atk == enemy.atk * 90 / 100, "Atk should be 10% lower");
			assert(player.maxHp == enemy.maxHp, "Other stats should be equal");
			assert(player.def == enemy.def, "Other stats should be equal");
			assert(player.spa == enemy.spa, "Other stats should be equal");
			assert(player.spd == enemy.spd, "Other stats should be equal");
		})
	;
}
