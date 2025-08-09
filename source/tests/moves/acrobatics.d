module tests.moves.acrobatics;

import logging;
import sets;
import state;
import test;

mixin TestModule;

PokeTest acrobatics_damage() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("pikachu", 50)
				.item("hard_stone")
				.moves(["acrobatics"])
		]))
		.enemy(PokeTeam([
			PokeSet("pikachu", 50)
				.moves(["acrobatics"])
		]))
		.turn("acrobatics", "acrobatics")
		.validate((state, player, enemy) {
			assert(within(player.move.damage * 2, enemy.move.damage, 3), "Acrobatics deals double damage without an item");
		})
	;
}

PokeTest acrobatics_itemLoss() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("pikachu", 50)
				.item("jaboca_berry")
				.nature("spa", "spe")
				.moves(["acrobatics"])
		]))
		.enemy(PokeTeam([
			PokeSet("pikachu", 50)
				.moves(["acrobatics"])
		]))
		.turn("acrobatics", "acrobatics")
		.validate((state, player, enemy) {
			assert(enemy.wentFirst);
			assert(player.move.damage == enemy.move.damage, "Acrobatics still deals double damage after consuming an item");
		})
	;
}
