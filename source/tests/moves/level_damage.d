module tests.moves.level_damage;

import logging;
import sets;
import state;
import test;

mixin TestModule!(mixin(__MODULE__));

PokeTest levelDamage_amount() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("cyndaquil", 55)
				.moves(["night_shade", "seismic_toss"])
		]))
		.enemy(PokeTeam([
			PokeSet("cyndaquil", 65)
				.moves(["night_shade", "seismic_toss"])
		]))
		.turn("night_shade", "seismic_toss")
		.validate((state, player, enemy) {
			assert(player.move.damage == 55, "Night Shade should deal damage equal to attacker's level");
			assert(enemy.move.damage == 65, "Seismic Toss should deal damage equal to attacker's level");
		})
	;
}

PokeTest levelDamage_effectiveness() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("porygon", 50)
				.moves(["night_shade", "seismic_toss"])
		]))
		.enemy(PokeTeam([
			PokeSet("porygon", 50)
				.moves(["night_shade", "seismic_toss"])
		]))
		.turn("night_shade", "seismic_toss")
		.validate((state, player, enemy) {
			assert(player.move.damage == 0, "Night Shade should be effected by immunities");
			assert(enemy.move.damage == 50, "Seismic Toss should not deal more damage against Normal types");
		})
	;
}
