module constants;

import std.conv;
import std.file;
import std.regex;
import std.string;

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

struct Constants {
	int[string] arr;

	int get(string s) {
		if (s in arr) {
			return arr[s.toLower()];
		}
		throw new Exception("Value " ~ s ~ " not in constant table");
	}
}
