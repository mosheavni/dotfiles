.PHONY: all test test-nvim prepare clean

NVIM_DIR := nvim/.config/nvim

all: test

test: test-nvim

prepare:
	@test -d nvim/.config/plenary.nvim || git clone --depth 1 https://github.com/nvim-lua/plenary.nvim nvim/.config/plenary.nvim

test-nvim: prepare
	cd $(NVIM_DIR) && nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory lua/tests/ { minimal_init = './scripts/minimal_init.vim' }"

clean:
	rm -rf nvim/.config/plenary.nvim
