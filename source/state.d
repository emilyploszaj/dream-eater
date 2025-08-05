module state;

import app;
import emulator;
import logging;
import sets;

struct TurnAction {
	string chosenMove;
}

struct Turn { 
	TurnAction playerAction, enemyAction;
	void delegate() callback;
}

struct MonData {
	EmulatorState state;
	bool player;
	string prefix;

	bool wentFirst() {
		return player == (wEnemyGoesFirst == 0);
	}

	ushort maxHp() {
		return state.emu.read16BE(symbols.lookup(prefix ~ "MaxHP"));
	}

	ushort hp() {
		return state.emu.read16BE(symbols.lookup(prefix ~ "HP"));
	}

	ushort atk() {
		return state.emu.read16BE(symbols.lookup(prefix ~ "Attack"));
	}

	ushort def() {
		return state.emu.read16BE(symbols.lookup(prefix ~ "Defense"));
	}

	ushort spa() {
		return state.emu.read16BE(symbols.lookup(prefix ~ "SpAtk"));
	}

	ushort spd() {
		return state.emu.read16BE(symbols.lookup(prefix ~ "SpDef"));
	}

	ushort spe() {
		return state.emu.read16BE(symbols.lookup(prefix ~ "Speed"));
	}
}

MonData player(EmulatorState state) {
	return MonData(state, true, "wBattleMon");
}

MonData enemy(EmulatorState state) {
	return MonData(state, false, "wEnemyMon");
}

void runTurns(EmulatorState state, Turn[] turnSeq) {
	state.turns = turnSeq[];
}

private ubyte wEnemyGoesFirst;

void endTurn(EmulatorState state) {
	wEnemyGoesFirst = state.emu.read(symbols.lookup("wEnemyGoesFirst"));
	state.turns[state.turn].callback();
	state.turn++;
}

void endBattle(EmulatorState state) {
	state.endTurn();
	state.ended = true;
}
