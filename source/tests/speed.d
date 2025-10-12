module tests.speed;

import logging;
import sets;
import state;
import test;

mixin TestModule!(mixin(__MODULE__));

PokeTest speed_levels() {
	// The player should outspeed with a level advantage
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("charizard", 10)
				.moves(["ember"])
		]))
		.enemy(PokeTeam([
			PokeSet("charizard", 9)
				.moves(["ember"])
		]))
		.turn("ember", "ember")
		.validate((state, player, enemy) {
			assert(player.spe > enemy.spe);
			assert(player.wentFirst);
		})
	;
}

PokeTest speed_DVs() {
	// The enemy should outspeed with higher DVs
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("charizard", 20)
				.dvs([0, 0, 0, 0, 0, 0])
				.moves(["ember"])
		]))
		.enemy(PokeTeam([
			PokeSet("charizard", 20)
				.dvs([15, 15, 15, 15, 15, 15])
				.moves(["ember"])
		]))
		.turn("ember", "ember")
		.validate((state, player, enemy) {
			assert(enemy.wentFirst);
		})
	;
}

PokeTest speed_nature() {
	// The enemy should outspeed with a beneficial nature
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("charizard", 20)
				.moves(["ember"])
		]))
		.enemy(PokeTeam([
			PokeSet("charizard", 20)
				.nature("spe", "atk")
				.moves(["ember"])
		]))
		.turn("ember", "ember")
		.validate((state, player, enemy) {
			assert(enemy.wentFirst);
		})
	;
}

PokeTest speed_priority() {
	// Moves should execute based on priority
	// Otherwise, a higher level player should go first
	return new PokeTest()
		.player(PokeTeam([
			PokeSet("charizard", 90)
				.moves(["protect", "mach_punch", "tackle", "avalanche"])
		]))
		.enemy(PokeTeam([
			PokeSet("charizard", 89)
				.moves(["protect", "mach_punch", "tackle", "avalanche"])
		]))
		.turn("protect", "tackle")
		.validate((state, player, enemy) {
			assert(player.wentFirst);
		})
		.turn("avalanche", "tackle")
		.validate((state, player, enemy) {
			assert(player.spe > enemy.spe);
			assert(enemy.wentFirst);
		})
		.turn("avalanche", "protect")
		.validate((state, player, enemy) {
			assert(enemy.wentFirst);
		})
		.turn("protect", "mach_punch")
		.validate((state, player, enemy) {
			assert(player.wentFirst);
		})
		.turn("tackle", "mach_punch")
		.validate((state, player, enemy) {
			assert(enemy.wentFirst);
		})
	;
}

