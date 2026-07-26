module tests.utils.set_config;

import app;
import logging;
import sets;
import state;
import test;

mixin TestModule;

PokeTest canSetSpecies() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("pikachu", 10)
				.moves(["recover"])
		]))
		.enemy(PokeTeam([
			PokeSet("unown", 10)
				.moves(["recover"])
		]))
		.turn("recover", "recover")
		.validate((state, player, enemy) {
			assert(state.emu.read("wBattleMonSpecies") == pokemonConstants.get("pikachu"));
			assert(state.emu.read("wEnemyMonSpecies") == pokemonConstants.get("unown"));
		})
	;
}

PokeTest canSetNormalAbility() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("marill", 10)
				.ability("huge_power")
				.moves(["recover"])
		]))
		.enemy(PokeTeam([
			PokeSet("marill", 10)
				.ability("thick_fat")
				.moves(["recover"])
		]))
		.turn("recover", "recover")
		.validate((state, player, enemy) {
			assert(state.emu.read("wPlayerAbility") == abilityConstants.get("huge_power"));
			assert(state.emu.read("wEnemyAbility") == abilityConstants.get("thick_fat"));
		})
	;
}

PokeTest canSetHiddenAbility() {
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("marill", 10)
				.ability("huge_power")
				.moves(["recover"])
		]))
		.enemy(PokeTeam([
			PokeSet("marill", 10)
				.ability("sap_sipper")
				.moves(["recover"])
		]))
		.turn("recover", "recover")
		.validate((state, player, enemy) {
			assert(state.emu.read("wPlayerAbility") == abilityConstants.get("huge_power"));
			assert(state.emu.read("wEnemyAbility") == abilityConstants.get("sap_sipper"));
		})
	;
}
