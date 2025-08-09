module emulator;

import app;
import gambatte;
import input;
import state;
import sets;

class EmulatorState {
	Emulator emu;
	InputSequence[] inputStack;
	uint turn = 0;
	bool ended = false;
	Turn[] turns;
	PokeTeam playerTeam;
	PokeTeam enemyTeam;
	private ubyte wEnemyGoesFirst;
	private MoveData[] playerMoves;
	private MoveData[] enemyMoves;

	this(Emulator emu) {
		this.emu = emu;
	}

	MonData player() {
		return MonData(this, true, "wBattleMon", playerMoves);
	}

	MonData enemy() {
		return MonData(this, false, "wEnemyMon", enemyMoves);
	}

	void executeInputs() {
		while (inputStack.length > 0 && turn < turns.length && !ended) {
			InputSequence seq = inputStack[$ - 1];
			int i = seq.inputs[0];
			seq.inputs = seq.inputs[1..$];
			if (seq.inputs.length == 0) {
				inputStack = inputStack[0..$ - 1];
			} else {
				inputStack[$ - 1] = seq;
			}
			emu.runFrame(i);
		}
	}

	private bool hBattleTurn() {
		return emu.read(symbols.lookup("hBattleTurn")) == 0;
	}

	void endMove() {
		ubyte missed = emu.read(symbols.lookup("wAttackMissed"));
		ubyte dmgHi = emu.read(symbols.lookup("wCurDamage"));
		ubyte dmgLo = emu.read(symbols.lookup("wCurDamage") + 1);
		uint dmg = ((dmgHi & 0xFF) << 8) | dmgLo;
		if (missed != 0) {
			dmg = 0;
		}
		uint hits = (dmg & 0xF000) >> 12;
		uint damage = dmg & 0x0FFF;
		MoveData data = MoveData(damage, hits, missed);
		if (hBattleTurn()) {
			playerMoves ~= data;
		} else {
			enemyMoves ~= data;
		}
	}

	void endTurn() {
		wEnemyGoesFirst = emu.read(symbols.lookup("wEnemyGoesFirst"));
		turns[turn].callback();
		turn++;
		playerMoves.length = 0;
		enemyMoves.length = 0;
	}
}

struct MoveData {
	uint damage;
	uint hits;
	uint missedType;
}

struct MonData {
	EmulatorState state;
	bool player;
	string prefix;
	MoveData[] moves;

	MoveData move() {
		assert(moves.length == 1, "Mon used exactly one move");
		return moves[0];
	}

	bool wentFirst() {
		return player == (state.wEnemyGoesFirst == 0);
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
