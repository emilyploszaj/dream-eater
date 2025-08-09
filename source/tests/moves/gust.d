module tests.moves.gust;

import logging;
import sets;
import state;
import test;

mixin TestModule;

PokeTest gust_doubleDamage() {
	static uint initialDamage = 0;
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("squirtle", 50)
				.nature("atk", "spe")
				.moves(["fly"])
		]))
		.enemy(PokeTeam([
			PokeSet("squirtle", 50)
				.moves(["gust"])
		]))
		.turn("fly", "gust")
		.validate((state, player, enemy) {
			assert(enemy.wentFirst);
			initialDamage = enemy.move.damage;
		})
		.turn("fly", "gust")
		.validate((state, player, enemy) {
			assert(enemy.wentFirst);
			assert(within(initialDamage * 2, enemy.move.damage, 2), "Gust should hit and deal double damage to flying targets");
		})
	;
}

PokeTest gust_missUnderground() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("squirtle", 50)
				.nature("spe", "atk")
				.moves(["dive"])
		]))
		.enemy(PokeTeam([
			PokeSet("squirtle", 50)
				.moves(["gust"])
		]))
		.turn("dive", "gust")
		.validate((state, player, enemy) {
			import app;
			assert(player.wentFirst);
			assert(enemy.move.damage == 0, "Gust should miss targets that are underground");
		})
	;
}
