# Dream Eater
Dream Eater is a testing framework designed for [Polished Crystal](https://github.com/Rangi42/polishedcrystal).
It functions by using [Gambatte Speedrun](https://github.com/pokemon-speedrunning/gambatte-speedrun) to run real, in-engine battle sequences and compare results with expected outcomes.

Data is collected from source files for constant names and ROM and RAM addresses are parsed from the output `.sym` symbol table, built with the ROM.

### Usage
Dream Eater is written in [D](https://dlang.org/) and requires [dub](https://dub.pm/) to build.

From Polished Crystal, Dream Eater needs either a source copy or symlink to the project at `polishedcrystal` to scrape necessary data. A built version of the game at `rom/polishedcrystal.gbc` and the `.sym` file at `rom/polishedcrystal.sym` is required to actually run the game and access up to date memory addresses.

Additionally, Dream Eater requires `lib/libgambatte.so` and `rom/gbc_bios.bin` be present in the project directory, both of which need to be acquired separately to run.
