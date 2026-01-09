module output;

import imaged;

void writeImage(uint[] bytes, string name) {
	import std.file: mkdir, exists;
	if (!exists("screenshots")) {
		mkdir("screenshots");
	}
	ubyte[] data = cast(ubyte[]) bytes;
	Image myImg = new Img!(Px.R8G8B8A8)(160, 144, data);
	myImg.write("screenshots/" ~ name ~ ".png");
}
