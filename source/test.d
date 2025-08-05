module test;

import core.exception;
import core.sync;

import std.conv;

import app;
import emulator;
import gambatte;
import logging;
import sets;
import state;

alias TestCallback = void delegate(EmulatorState, MonData, MonData);

class PokeTest {
	private PokeTeam playerSets, enemySets;
	private Turn[] turns;
	private Turn currentTurn;
	private TestCallback[] currentCallbacks;
	private EmulatorState state;

	PokeTest player(PokeTeam team) {
		this.playerSets = team;
		return this;	
	}

	PokeTest enemy(PokeTeam team) {
		this.enemySets = team;
		return this;
	}

	PokeTest both(PokeTeam team) {
		this.playerSets = team;
		this.enemySets = team;
		return this;
	}

	PokeTest turn(string playerMove, string enemyMove) {
		appendTurn();
		currentTurn.playerAction.chosenMove = playerMove;
		currentTurn.enemyAction.chosenMove = enemyMove;
		return this;
	}

	PokeTest validate(TestCallback callback) {
		currentCallbacks ~= callback;
		return this;
	}

	private void appendTurn() {
		if (currentTurn.playerAction.chosenMove != "") {
			TestCallback[] callbacks = currentCallbacks[];

			currentTurn.callback = () {
				foreach (callback; callbacks) {
					callback(state, state.player, state.enemy);
				}
			};
			turns ~= currentTurn;

			currentTurn = Turn();
			currentCallbacks.length = 0;
		}
	}

	void run() {
		try {
			appendTurn();
			assert(playerSets.sets.length > 0 && enemySets.sets.length > 0, "Player and enemy have sets");
			state = setupEmulator();
			state.playerTeam = playerSets;
			state.enemyTeam = enemySets;
			runTurns(state, turns);
			state.executeInputs();
			assert(!state.ended, "Battle ended early on turn " ~ state.turn.to!string);
		} catch (AssertError e) {
			state.emu.exportScreenshot("fail");
			throw e;
		}
	}
}

private struct TestCase {
	PokeTest delegate() test;
	string name;
}
__gshared private TestCase[] allTests;
__gshared private Mutex testMutex;
__gshared private int nextTest = 0;
__gshared private int doneTests = 0;

string getTestStatus() {
	enum string FOURTY_EQUALS = "========================================";
	enum string FOURTY_DASHES = "----------------------------------------";
	enum string FOURTY_SPACES = "                                        ";
	ulong done = doneTests;
	ulong running = nextTest - doneTests;
	ulong total = allTests.length;
	ulong donePortion = done * 40 / total;
	ulong runningPortion = running * 40 / total;
	if (runningPortion == 0 && running > 0) {
		runningPortion = 1;
	}
	ulong unstartedPortion = 40 - donePortion - runningPortion;
	string progress = "[\033[92m" ~ FOURTY_EQUALS[0..donePortion];
	progress ~= "\033[94m" ~ FOURTY_DASHES[0..runningPortion];
	progress ~= FOURTY_SPACES[0..unstartedPortion];
	progress ~= "\033[0m]";
	return "\n  Progress: " ~ progress ~ "\033[1F";
}

void initTesting() {
	testMutex = new Mutex();
}

bool runNextTest() {
	TestCase test;
	testMutex.lock();
	if (nextTest < allTests.length) {
		test = allTests[nextTest++];
		testMutex.unlock();
		runTest(test.test, test.name);
		testMutex.lock();
		doneTests++;
		testMutex.unlock();
		return true;
	} else {
		if (nextTest == doneTests) {
			import std.stdio;
			writeln("\033[0KFinished testing");
		}
		testMutex.unlock();
		return false;
	}
}

void runTest(PokeTest delegate() test, string name) {
	log("Running \033[95m", name, "\033[0m...");
	import std.datetime.stopwatch;
	StopWatch sw = StopWatch(AutoStart.yes);
	try {
		test().run();
	} catch (AssertError e) {
		error("\033[95m", name, "\033[0m failed with the following exception\n", e);
		return;
	}
	import std.conv: to;
	log("\033[95m", name, "\033[0m completed successfully (\033[93m" ~ sw.peek.total!("msecs").to!string ~ "ms\033[0m)");
}

void addTestCase(PokeTest delegate() test, string name) {
	allTests ~= TestCase(test, name);
}

template TestModule() {
	shared static this() {
		import std.traits: ReturnType;
		static foreach (m; __traits(derivedMembers, mixin(__MODULE__))) {
			{
				static if (__traits(isStaticFunction, __traits(getMember, mixin(__MODULE__), m))) {
					static if(is(ReturnType!(__traits(getMember, mixin(__MODULE__), m)) == PokeTest)) {
						PokeTest delegate() test = () => __traits(getMember, mixin(__MODULE__), m)();
						addTestCase(test, __traits(fullyQualifiedName, __traits(getMember, mixin(__MODULE__), m)));
					}
				}
			}
		}
	}
}
