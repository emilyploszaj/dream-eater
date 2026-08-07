module test;

import core.exception;
import core.sync.mutex;

import std.algorithm;
import std.array;
import std.conv;
import std.math;
import std.string;

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
		PokeSet playerSet = playerSets.sets[0];
		PokeSet enemySet = enemySets.sets[0];
		if (playerSet.moves.countUntil(playerMove) == -1) {
			error("Player's ", playerSet.species, "'s set does not have the move ", playerMove, " in ", playerSet.moves);
		}
		if (enemySet.moves.countUntil(enemyMove) == -1) {
			error("Enemy's ", enemySet.species, "'s set does not have the move ", enemyMove, " in ", enemySet.moves);
		}
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
			assert(state.started, "Battle never started! Is the ROM and BIOS correct?");
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
__gshared private int failedTests = 0;
__gshared string[] testShortlist;

string getTestStatus() {
	enum string FOURTY_EQUALS = "========================================";
	enum string FOURTY_DASHES = "----------------------------------------";
	enum string FOURTY_SPACES = "                                        ";
	ulong succeeded = doneTests - failedTests;
	ulong failed = failedTests;
	ulong running = nextTest - doneTests;
	ulong total = allTests.length;
	ulong succeededPortion = succeeded * 40 / total;
	ulong failedPortion = failed * 40 / total;
	ulong runningPortion = running * 40 / total;
	ulong startedPortion = (succeeded + failed + running) * 40 / total;
	if (succeededPortion == 0 && succeeded > 0) {
		succeededPortion = 1;
	}
	if (failedPortion == 0 && failed > 0) {
		failedPortion = 1;
	}
	if (runningPortion == 0 && running > 0) {
		runningPortion = 1;
	}
	while (succeededPortion + failedPortion + runningPortion > 40) {
		if (succeededPortion > failedPortion) {
			succeededPortion--;
		} else {
			failedPortion--;
		}
	}
	while (succeededPortion + failedPortion + runningPortion < startedPortion) {
		runningPortion++;
	}
	ulong unstartedPortion = 40 - succeededPortion - runningPortion - failedPortion;
	string progress = "[\033[92m" ~ FOURTY_EQUALS[0..succeededPortion];
	progress ~= "\033[94m" ~ FOURTY_DASHES[0..runningPortion];
	progress ~= FOURTY_SPACES[0..unstartedPortion];
	progress ~= "\033[91m" ~ FOURTY_EQUALS[0..failedPortion];
	progress ~= "\033[0m]";
	return "\n  Progress: " ~ progress ~ "\033[1F";
}

void initTesting() {
	if (testShortlist.length > 0) {
		log("Running subset of tests which contain one of ", testShortlist);
		allTests = allTests.filter!((t) {
			foreach (string sub; testShortlist) {
				if (t.name.indexOf(sub) >= 0) {
					return true;
				}
			}
			return false;
		}).array;
	}
	testMutex = new Mutex();
}

bool runNextTest() {
	TestCase test;
	testMutex.lock();
	if (nextTest < allTests.length) {
		test = allTests[nextTest++];
		testMutex.unlock();
		bool result = runTest(test.test, test.name);
		testMutex.lock();
		doneTests++;
		if (result == false) {
			failedTests++;
		}
		testMutex.unlock();
		return true;
	} else {
		if (nextTest == doneTests) {
			import std.stdio;
			writeln("\033[0KFinished testing");
			writeln("Passed: ", doneTests - failedTests, "/", doneTests);
		}
		testMutex.unlock();
		return false;
	}
}

bool runTest(PokeTest delegate() test, string name) {
	log("Running \033[95m", name, "\033[0m...");
	import std.datetime.stopwatch;
	StopWatch sw = StopWatch(AutoStart.yes);
	PokeTest pt;
	try {
		pt = test();
		pt.run();
	} catch (AssertError e) {
		string text = "\033[0m failed!\n"
			~ turnState(pt) ~ '\n'
			~ "Failed with the following exception\n";
		error("\033[95m", name, text, e);

		return false;
	} catch (Exception e) {
		string text = "\033[0m failed!\n"
			~ turnState(pt) ~ '\n'
			~ "Failed with the following exception\n";
		error("\033[95m", name, text, e);
		return false;
	}
	import std.conv: to;
	log("\033[95m", name, "\033[0m completed successfully (\033[93m" ~ sw.peek.total!("msecs").to!string ~ "ms\033[0m)");
	return true;
}

string turnState(PokeTest test) {
	if (test is null) {
		return "[test failed to initialize!]";
	} else {
		return test.state.turnLog.join("\n");
	}
}
void addTestCase(PokeTest delegate() test, string name) {
	allTests ~= TestCase(test, name);
}

bool within(int a, int b, int discretion) {
	return abs(a - b) <= discretion;
}

mixin template TestModule(alias M) {
	shared static this() {
		import std.traits;
		static foreach (m; __traits(allMembers, M)) {
			static if (__traits(compiles, ReturnType!(__traits(getMember, M, m)))) {
					static if (is(ReturnType!(__traits(getMember, M, m)) == PokeTest)) {
						static if (arity!(__traits(getMember, M, m)) == 0) {
							addTestCase(() => __traits(getMember, M, m)(), M.stringof ~ "." ~ m);
						}
					}
			}
		}
	}
}
