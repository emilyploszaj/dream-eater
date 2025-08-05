module emulator;

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

	this(Emulator emu) {
		this.emu = emu;
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
}