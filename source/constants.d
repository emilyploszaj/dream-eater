module constants;

import std.conv;
import std.file;
import std.regex;
import std.string;

import logging;

private enum DEF_REGEX = ctRegex!r"if\s+DEF\s*\((?P<def>[A-Z!]+)\)(?P<true>(.|\n)+?)(else(?P<false>(.|\n)+?))?endc";
private enum ABILITIES_REGEX = ctRegex!r"abilities_for\s+(?P<mon>\w+),\s*(?P<a1>\w+),\s*(?P<a2>\w+),\s*(?P<a3>\w+)";

Constants parseConstants(string path) {
	string file = cast(string) read(path);
	int c = -1;
	int[string] ret;
	foreach (string line; file.split('\n')) {
		line = line.strip();
		if (line.startsWith("const_def")) {
			if (c != -1) {
				break;
			}
			string[] parts = line.split(" ");
			if (parts.length > 1) {
				c = parts[1].to!int;
			} else {
				c = 0;
			}
		} else {
			auto m = matchFirst(line, r"const (\w+)");
			if (m) {
				string name = m[1].toLower();
				ret[name] = c++;
			}
		}
	}
	return Constants(ret);
}

AllBaseStats parseBaseStats(string path) {
	AllBaseStats stats;
	foreach (file; dirEntries(path, "*.asm", SpanMode.shallow)) {
		string contents = stripDefs(cast(string) read(file));
		auto m = contents.matchFirst(ABILITIES_REGEX);
		stats.stats[m["mon"].toLower()] = BaseStats([m["a1"].toLower(), m["a2"].toLower(), m["a3"].toLower()]);
	}
	return stats;
}

string stripDefs(string input) {
	return input.replaceAll!((m) {
		if (m["def"] == "FAITHFUL") {
			return m["false"];
		} else if (m["def"] == "!FAITHFUL") {
			return m["true"];
		}
		assert(0);
	})(DEF_REGEX);
}

struct AllBaseStats {
	BaseStats[string] stats;

	BaseStats get(string s) {
		return stats[s];
	}
}

struct BaseStats {
	string[] abilities;
}

struct Constants {
	int[string] arr;

	int get(string s) {
		if (s in arr) {
			return arr[s.toLower()];
		}
		throw new Exception("Value " ~ s ~ " not in constant table");
	}
}
