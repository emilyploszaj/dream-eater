module input;

struct InputSequence {
	uint[] inputs;

	InputSequence press(uint buttons, uint frames) {
		for (uint i = 0; i < frames; i++) {
			inputs ~= buttons;
		}
		return this;
	}

	InputSequence repeat(InputSequence sequence, uint times) {
		for (uint i = 0; i < times; i++) {
			inputs ~= sequence.inputs;
		}
		return this;
	}
}
