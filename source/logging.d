module logging;

import std.stdio;

import test;

__gshared bool shouldTrace = false;
__gshared bool shouldLog = true;

void trace(T...)(T args) {
	if (shouldTrace) {
		writeln("\033[0K\033[94m[t] \033[0m", args);
	}
}

void log(T...)(T args) {
	if (shouldLog) {
		writeln("\033[0K\033[92m[l] \033[0m", args, getTestStatus());
	}
}

void error(T...)(T args) {
	if (shouldLog) {
		writeln("\033[0K\033[91m[e] \033[0m", args);
	}
}
