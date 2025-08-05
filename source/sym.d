module sym;

import std.conv;
import std.file;
import std.string;

SymbolTable getSymbols(string path) {
	uint[string] labels;
	string[uint] reverse;
	string file = cast(string) read(path);
	foreach (line; file.split("\n")) {
		line = line.strip();
		if (line.length > 8 && line[0] != ';') {
			int bank = line[0..2].to!uint(16);
			int addr = line[3..7].to!uint(16);
			string label = line[8..$];
			uint a = (bank << 16) | addr;
			labels[label] = a;
			reverse[a] = label;
		}
	}
	return SymbolTable(labels, reverse);
}

struct SymbolTable {
	private uint[string] _lookup;
	private string[uint] _reverse;

	uint lookup(string name) {
		if (name in _lookup) {
			return _lookup[name];
		} else {
			throw new Exception(name ~ " does not exist in symbol table!");
		}
	}

	string reverse(uint addr) {
		if (addr in _reverse) {
			return _reverse[addr];
		}
		return "";
	}
}