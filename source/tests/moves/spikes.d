module tests.moves.spikes;

import logging;
import sets;
import state;
import test;

mixin TestModule;

PokeTest spikes_basic() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("unown", 30)
				.ability("levitate")
				.moves(["recover"]),
			PokeSet("caterpie", 7)
				.moves(["recover"]),
		]))
		.enemy(PokeTeam([
			PokeSet("rattata", 29)
				.moves(["roar", "spikes"])
		]))
		.turn("recover", "spikes")
		.turn("recover", "roar")
		.validate((state, player, enemy) {
			assert(player.hp < player.maxHp, "Spikes should have hurt");
		})
	;
}

PokeTest spikes_levitate() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("unown", 30)
				.ability("levitate")
				.moves(["recover"]),
			PokeSet("unown", 7)
				.ability("levitate")
				.moves(["recover"]),
		]))
		.enemy(PokeTeam([
			PokeSet("rattata", 29)
				.moves(["roar", "spikes"])
		]))
		.turn("recover", "spikes")
		.turn("recover", "roar")
		.validate((state, player, enemy) {
			assert(player.hp == player.maxHp, "Spikes doesn't affect Levitate");
		})
	;
}

PokeTest spikes_levitate_mold_breaker() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("unown", 30)
				.ability("levitate")
				.moves(["recover"]),
			PokeSet("unown", 7)
				.ability("levitate")
				.moves(["recover"]),
		]))
		.enemy(PokeTeam([
			PokeSet("ampharos", 29)
				.ability("mold_breaker")
				.moves(["roar", "spikes"])
		]))
		.turn("recover", "spikes")
		.turn("recover", "roar")
		.validate((state, player, enemy) {
			assert(player.hp < player.maxHp, "MB Roar vs Levitator still takes Spikes damage");
		})
	;
}
