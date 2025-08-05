import core.thread;

import std.algorithm;
import std.conv;
import std.stdio;

import constants;
import emulator;
import gambatte;
import input;
import logging;
import sets;
import sym;
import state;

int testThreads = 10;

__gshared Constants pokemonConstants, moveConstants, itemConstants;
__gshared SymbolTable symbols;

void main() {
	pokemonConstants = parseConstants("polishedcrystal/constants/pokemon_constants.asm");
	moveConstants = parseConstants("polishedcrystal/constants/move_constants.asm");
	itemConstants = parseConstants("polishedcrystal/constants/item_constants.asm");
	symbols = getSymbols("rom/polishedcrystal-debug-3.2.0.sym");
	import test;
	initTesting();
	for (int i = 0; i < testThreads; i++) {
		new Thread({
			while (runNextTest()) {
			}
		}).start();
	}
}

EmulatorState setupEmulator() {
	Emulator emu = new Emulator();
	EmulatorState state = new EmulatorState(emu);
	emu.create();
	emu.loadBios("rom/gbc_bios.bin");
	emu.load("rom/polishedcrystal-debug-3.2.0.gbc");
	Interrupt[] interrupts;
	interrupts ~= Interrupt(symbols.lookup("_TitleScreen"), () {
		trace("Title screen");
	});
	interrupts ~= Interrupt(symbols.lookup("SetInitialOptions"), () {
		trace("Init Options");
		emu.exportScreenshot("e");
		state.inputStack ~= [
			InputSequence()
				.repeat(InputSequence()
					.press(0, 5)
					.press(JOY_B, 5),
				20)
		];
	});
	interrupts ~= Interrupt(symbols.lookup("DoBattle"), () {
		trace("Starting battle");
	});
	interrupts ~= Interrupt(symbols.lookup("ExitBattle"), () {
		trace("Exiting battle");
		state.endBattle();
	});
	interrupts ~= Interrupt(symbols.lookup("_StdBattleTextbox"), () {
		trace("Battle Textbox (", symbols.reverse(0x200000 | emu.readRegisters().hl), ")");
	});
	interrupts ~= Interrupt(symbols.lookup("BattleTurn"), () {
		trace("New turn");
	});
	interrupts ~= Interrupt(symbols.lookup("BattleTurn.move_over"), () {
		trace("Done with move");
		state.endMove();
	});
	interrupts ~= Interrupt(symbols.lookup("BattleTurn.deferred_switch_over"), () {
		trace("Done with deferred switch");
	});
	interrupts ~= Interrupt(symbols.lookup("BattleTurn.end_of_turn_over"), () {
		trace("Done with end of turn");
		state.endTurn();
	});
	interrupts ~= Interrupt(symbols.lookup("BattleTurn.do_move"), () {
		trace(emu.read(symbols.lookup("hBattleTurn")) == 0 ? "Player turn:" : "Enemy turn:");
	});
	interrupts ~= Interrupt(symbols.lookup("MoveSelectionScreen"), () {
		TurnAction action = state.turns[state.turn].playerAction;
		emu.writeRegisters(emu.readRegisters()
			.hl(cast(ushort) moveConstants.get(action.chosenMove))
			.b(cast(ubyte) (state.playerTeam.sets[0].moves.countUntil(action.chosenMove) + 1))
		);
	});
	interrupts ~= Interrupt(symbols.lookup("AIChooseMove"), () {
		TurnAction action = state.turns[state.turn].enemyAction;
		emu.writeRegisters(emu.readRegisters()
			.hl(cast(ushort) moveConstants.get(action.chosenMove))
			.b(cast(ubyte) (state.enemyTeam.sets[0].moves.countUntil(action.chosenMove) + 1))
		);
	});
	interrupts ~= Interrupt(symbols.lookup("BattleCommand_damagevariation.got_multiplier"), () {
		emu.writeRegisters(emu.readRegisters()
			.a(100)
		);
	});
	interrupts ~= Interrupt(symbols.lookup("BattleCommand_critical.got_critical_chance"), () {
		emu.writeRegisters(emu.readRegisters()
			.a(23)
		);
	});
	interrupts ~= Interrupt(symbols.lookup("LoadBattleMenu"), () {
		trace("Load battle menu!");
		state.inputStack = [
			InputSequence()
				.repeat(InputSequence()
					.press(JOY_B, 5)
					.press(0, 5),
				1000),
			InputSequence()
				.press(0, 20)
				.press(JOY_A, 5),
		];
	});
	interrupts ~= Interrupt(symbols.lookup("ReadPlayerTestParty.manifest"), () {
		trace("Filled player test party");
		// We hear you, those who invoke our name
		// Part from us with our blessing
		// Serve faithfully with holy ferver
		// May we finally meet when your mission is through
		// Until then, we shall pass as ships through the night
		emu.write(0xFFFF & symbols.lookup("wTestPartyBuffer"), state.playerTeam.serialize());
	});
	interrupts ~= Interrupt(symbols.lookup("ReadEnemyTestParty.manifest"), () {
		trace("Filled enemy test party");
		// We hear you, those who invoke our name
		// Part from us with our blessing
		// Serve faithfully with holy ferver
		// May we finally meet when your mission is through
		// Until then, we shall pass as ships through the night
		emu.write(0xFFFF & symbols.lookup("wTestPartyBuffer"), state.enemyTeam.serialize());
	});

	emu.setInterrupts(interrupts);
	state.inputStack = [InputSequence()
		.repeat(InputSequence()
			.press(JOY_A, 5)
			.press(0, 5),
		6000)
	];
	state.executeInputs();
	return state;
}
