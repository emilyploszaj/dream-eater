module tests.abilities.huge_power;

import logging;
import sets;
import state;
import test;

mixin TestModule;

PokeTest hugePower_boostsPhysicalDamage() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("azumarill", 40)
				.ability("thick_fat")
				.moves(["tackle"])
		]))
		.enemy(PokeTeam([
			PokeSet("azumarill", 40)
				.ability("huge_power")
				.moves(["tackle"])
		]))
		.turn("tackle", "tackle")
		.validate((state, player, enemy) {
			assert(player.atk == enemy.atk, "Base Atk should be equivalent");
			assert(enemy.move.damage > player.move.damage);
			assert(within(player.move.damage * 2, enemy.move.damage, 2));
		})
	;
}

PokeTest hugePower_doesNotBoostSpecialDamage() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("azumarill", 40)
				.ability("thick_fat")
				.moves(["confusion"])
		]))
		.enemy(PokeTeam([
			PokeSet("azumarill", 40)
				.ability("huge_power")
				.moves(["confusion"])
		]))
		.turn("confusion", "confusion")
		.validate((state, player, enemy) {
			assert(player.spa == enemy.spa, "Base SpA should be equivalent");
			assert(enemy.move.damage == player.move.damage);
		})
	;
}