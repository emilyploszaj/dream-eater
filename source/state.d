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

void runTurns(EmulatorState state, Turn[] turnSeq) {
	state.turns = turnSeq[];
}
