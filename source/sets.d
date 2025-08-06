module sets;

import std.algorithm;
import std.string;

import app;
import logging;

struct PokeTeam {
	PokeSet[] sets;

	ubyte[] serialize() {
		ubyte[] ret = [cast(ubyte) sets.length];
		foreach (PokeSet set; sets) {
			ret ~= set.serialize();
		}
		return ret;
	}
}

private enum string[] NATURE_NAMES = [
	"hardy",
	"lonely",
	"brave",
	"adamant",
	"naughty",
	"bold",
	"docile",
	"relaxed",
	"impish",
	"lax",
	"timid",
	"hasty",
	"serious",
	"jolly",
	"naive",
	"modest",
	"mild",
	"quiet",
	"bashful",
	"rash",
	"calm",
	"gentle",
	"sassy",
	"careful",
	"quirky",
];

struct PokeSet {
	string species = "";
	string _item = "";
	ubyte _ability = 0;
	ubyte _nature = 0;
	ubyte form = 0;
	ubyte level = 5;
	// hp, atk, def, spa, spd, spe
	ubyte[6] _dvs = [15, 15, 15, 15, 15, 15];
	ubyte[6] _evs = [0, 0, 0, 0, 0, 0];
	string[] _moves = [];

	this(string species, ubyte level) {
		this.species = species;
		this.level = level;
	}

	PokeSet item(string item) {
		this._item = item;
		return this;
	}

	PokeSet dvs(ubyte[6] dvs) {
		this._dvs = dvs;
		return this;
	}

	PokeSet evs(ubyte[6] evs) {
		this._evs = evs;
		return this;
	}

	PokeSet ability(string abil) {
		abil = abil.toLower();
		string[] abilities = stats.get(species).abilities;
		if (abilities[0] == abil) {
			_ability = 0;
		} else if (abilities[1] == abil) {
			_ability = 2;
		} else if (abilities[2] == abil) {
			_ability = 3;
		} else {
			throw new Exception(species ~ " does not have the ability " ~ abil);
		}
		return this;
	}

	PokeSet nature(string nat) {
		_nature = cast(ubyte) NATURE_NAMES.countUntil(nat);
		return this;
	}

	PokeSet nature(string up, string down) {
		ubyte[string] map = [
			"atk": 0,
			"def": 1,
			"spe": 2,
			"spa": 3,
			"spd": 4,
		];
		_nature = cast(ubyte) (map[up] * 5 + map[down]);
		return this;
	}

	PokeSet moves(string[] moves) {
		this._moves = moves;
		return this;
	}

	string[] moves() {
		return this._moves;
	}

	ubyte[] serialize() {
		ubyte[] ret;
		ret ~= level;
		// Species and form
		uint sf = mapSpecies(species, form);
		ret ~= sf & 0xFF;
		ret ~= (sf >> 8) & 0xFF;

		ret ~= mapItem(_item);

		ret ~= cast(ubyte) ((_dvs[0] << 4) | _dvs[1]); // hp, atk
		ret ~= cast(ubyte) ((_dvs[2] << 4) | _dvs[5]); // def, spe
		ret ~= cast(ubyte) ((_dvs[3] << 4) | _dvs[4]); // spa, spd

		ret ~= _evs[0..3]; // hp, atk, def
		ret ~= _evs[5]; // spe
		ret ~= _evs[3..5]; // spa, spd

		ret ~= cast(ubyte) ((_ability << 5) | _nature); // Personality

		// Moves
		for (int i = 0; i < 4; i++) {
			if (i < _moves.length) {
				ushort mc = mapMove(_moves[i]);
				ret ~= cast(ubyte) ((mc >> 0) & 0xFF);
				ret ~= cast(ubyte) ((mc >> 8) & 0xFF);
			} else {
				ret ~= 0;
				ret ~= 0;
			}
		}

		// Status
		ret ~= 0;
		return ret;
	}

}

private ushort mapSpecies(string species, ubyte form) {
	return cast(ushort) pokemonConstants.get(species);
}

private ubyte mapItem(string item) {
	if (item == "") {
		item = "no_item";
	}
	return cast(ubyte) itemConstants.get(item);
}

private ushort mapMove(string move) {
	return cast(ushort) moveConstants.get(move);
}
