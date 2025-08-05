module gambatte;

import core.stdc.stdio;
import core.stdc.stdlib;
import core.sys.posix.dlfcn;
import std.format;
import std.string: toStringz;

import logging;

public enum uint JOY_A = 0x01;
public enum uint JOY_B = 0x02;
public enum uint JOY_SELECT = 0x04;
public enum uint JOY_START = 0x08;
public enum uint D_RIGHT = 0x10;
public enum uint D_LEFT = 0x20;
public enum uint D_UP = 0x40;
public enum uint D_DOWN  = 0x80;

private class GambatteFlags {
	private enum uint CGB_MODE = 1;
	private enum uint GBA_FLAG = 2;
	private enum uint MULTICART_COMPAT = 4;
	private enum uint SGB_MODE = 8;
	private enum uint READONLY_SAV = 16;
}
private enum uint VIDEO_BUFFER_WIDTH = 160;
private enum uint VIDEO_BUFFER_HEIGHT = 144;
private enum uint VIDEO_BUFFER_SIZE = VIDEO_BUFFER_WIDTH * VIDEO_BUFFER_HEIGHT;
private enum uint AUDIO_BUFFER_SIZE = (35_112 + 2064) * 2;
private enum uint NUM_SAMPLES_PER_FRAME = 35_112;

private uint[ulong] joypad;

extern (C) uint extern_getInput(void* some) {
	return joypad[cast(ulong) some];
}

class Emulator {
	private static ulong NEXT_ID = 0;
	private ulong id;
	private static void* libgambatte;
	private void* gb;
	private uint[VIDEO_BUFFER_SIZE * 4] videoBuffer;
	private uint[AUDIO_BUFFER_SIZE * 4] audioBuffer;
	private Interrupt[] interrupts;

	public this() {
		id = NEXT_ID++;
		libgambatte = dlopen("lib/libgambatte.so", RTLD_LAZY);
		if (!libgambatte) {
			fprintf(stderr, "dlopen error: %s\n", dlerror());
			exit(1);
		}
	}

	void setupInput() {
		alias FUNC = extern (C) uint function(void* some);
		alias SIG = extern(C) void* function(void*, FUNC, void*) nothrow;
		SIG gambatte_setinputgetter = loadFunction!(SIG, "gambatte_setinputgetter");
		gambatte_setinputgetter(gb, &extern_getInput, cast(void*) id);
	}

	void exportScreenshot(string name) {
		import output;
		writeImage(videoBuffer, name);
	}

	void create() {
		alias SIG = extern(C) void* function() nothrow;
		SIG gambatte_create = loadFunction!(SIG, "gambatte_create");
		gb = gambatte_create();
		setupInput();
	}

	void loadBios(string path) {
		alias SIG = extern(C) uint function(void*, immutable(char)*, uint, uint) nothrow;
		SIG gambatte_loadbios = loadFunction!(SIG, "gambatte_loadbios");
		gambatte_loadbios(gb, path.toStringz(), 0, 0);
	}

	void load(string path) {
		alias SIG = extern(C) uint function(void*, immutable(char)*, uint) nothrow;
		SIG gambatte_load = loadFunction!(SIG, "gambatte_load");
		uint flags = GambatteFlags.CGB_MODE | GambatteFlags.GBA_FLAG | GambatteFlags.READONLY_SAV;
		gambatte_load(gb, path.toStringz(), flags);
	}

	void saveState(string filename) {
		alias SIG = extern(C) void function(void*, uint*, int, immutable(char)*) nothrow;
		SIG gambatte_savestate = loadFunction!(SIG, "gambatte_savestate");
		gambatte_savestate(gb, cast(uint*) 0, 160, filename.toStringz());
	}

	void loadState(string filename) {
		alias SIG = extern(C) void function(void*, immutable(char)*, int) nothrow;
		SIG gambatte_loadstate = loadFunction!(SIG, "gambatte_loadstate");
		gambatte_loadstate(gb, filename.toStringz(), 0);
	}

	Registers readRegisters() {
		alias SIG = extern(C) void function(void*, int*) nothrow;
		SIG gambatte_getregs = loadFunction!(SIG, "gambatte_getregs");
		int[] regs;
		regs.length = 10;
		gambatte_getregs(gb, regs.ptr);
		return Registers(regs[]);
	}

	void writeRegisters(Registers reg) {
		alias SIG = extern(C) void function(void*, int*) nothrow;
		SIG gambatte_setregs = loadFunction!(SIG, "gambatte_setregs");
		gambatte_setregs(gb, reg.arr.ptr);
	}

	ubyte read(uint addr) {
		alias SIG = extern(C) ubyte function(void*, ushort) nothrow;
		SIG gambatte_cpuread = loadFunction!(SIG, "gambatte_cpuread");
		return gambatte_cpuread(gb, cast(ushort) addr);
	}

	ushort read16LE(uint addr) {
		ubyte lo = read(addr);
		ubyte hi = read(addr + 1);
		return cast(ushort) ((cast(ushort) hi << 8) | lo);
	}

	ushort read16BE(uint addr) {
		ubyte hi = read(addr);
		ubyte lo = read(addr + 1);
		return cast(ushort) ((cast(ushort) hi << 8) | lo);
	}

	void write(uint addr, ubyte[] values) {
		for (ushort i = 0; i < values.length; i++) {
			write(addr + i, values[i]);
		}
	}

	void write(uint addr, ubyte value) {
		alias SIG = extern(C) void function(void*, ushort, ubyte) nothrow;
		SIG gambatte_cpuwrite = loadFunction!(SIG, "gambatte_cpuwrite");
		gambatte_cpuwrite(gb, cast(ushort) addr, value);
	}

	void checkInterrupts() {
		uint hit = getHitInterrupt();
		if (hit == 0xFFFFFFFF) {
			return;
		}
		foreach (Interrupt i; interrupts) {
			if (hit == i.address) {
				i.callback();
				break;
			}
		}
		setInterrupt(0xFFFFFFFF);
		step();
		setInterrupts(interrupts);
	}

	void setInterrupts(Interrupt[] interrupts) {
		alias SIG = extern(C) uint function(void*, uint*, uint) nothrow;
		SIG gambatte_setinterruptaddresses = loadFunction!(SIG, "gambatte_setinterruptaddresses");
		this.interrupts = interrupts;
		uint[] addresses = [];
		foreach (Interrupt i; interrupts) {
			addresses ~= i.address;
		}
		gambatte_setinterruptaddresses(gb, addresses.ptr, cast(uint) addresses.length);
	}

	void setInterrupt(uint address) {
		alias SIG = extern(C) uint function(void*, uint*, uint) nothrow;
		SIG gambatte_setinterruptaddresses = loadFunction!(SIG, "gambatte_setinterruptaddresses");
		uint[] addresses = [ address ];
		if (address == 0xFFFFFFFF) {
			addresses.length = 0;
		}
		gambatte_setinterruptaddresses(gb, addresses.ptr, cast(uint) addresses.length);
	}

	uint getHitInterrupt() {
		alias SIG = extern(C) uint function(void*) nothrow;
		SIG gambatte_gethitinterruptaddress = loadFunction!(SIG, "gambatte_gethitinterruptaddress");
		return gambatte_gethitinterruptaddress(gb);
	}

	void step() {
		alias SIG = extern(C) void function(void*, uint*, int, uint* buffer, ulong* samples) nothrow;
		SIG gambatte_runfor = loadFunction!(SIG, "gambatte_runfor");
		ulong[4] samples;
		samples[0] = 4;
		gambatte_runfor(gb, videoBuffer.ptr, VIDEO_BUFFER_WIDTH, audioBuffer.ptr, samples.ptr);
	}

	void runFrame(uint joy) {
		alias SIG = extern(C) void function(void*, uint*, int, uint* buffer, ulong* samples) nothrow;
		SIG gambatte_runfor = loadFunction!(SIG, "gambatte_runfor");
		joypad[id] = joy;
		ulong[4] samples;
		samples[0] = NUM_SAMPLES_PER_FRAME;
		gambatte_runfor(gb, videoBuffer.ptr, VIDEO_BUFFER_WIDTH, audioBuffer.ptr, samples.ptr);
		checkInterrupts();
	}

	T loadFunction(T, string name)() {
		static T cached = null;
		if (cached !is null) {
			return cached;
		}
		T fn = cast(T) dlsym(libgambatte, name.toStringz);
		cached = fn;
		if (!fn) {
			fprintf(stderr, "dlsym error: %s\n", dlerror());
			exit(1);
		}
		return fn;
	}
}

struct Registers {
	private enum string[] REGS = [
		"pc", "sp",
		"a", "f",
		"b", "c",
		"d", "e",
		"h", "l",
	];
	int[] arr;

	static foreach(I, R; REGS) {
		mixin(q{
			Registers %s(ubyte val) {
				arr[I] = val;
				return this;
			}
			static if (I >= 2) {
				ubyte %s() {
					return cast(ubyte) arr[I];
				}
			}
		}.format(R, R));
	}

	ushort hl() {
		return cast(ushort) ((h() << 8) | l());
	}

	Registers hl(ushort val) {
		this.h(cast(ubyte) ((val >> 8) & 0xFF));
		this.l(cast(ubyte) (val & 0xFF));
		return this;
	}
}
struct Interrupt {
	uint address;
	void delegate() callback;
}
