.PHONY: all test test-nvim test-zsh prepare clean

NVIM_DIR := nvim/.config/nvim

all: test

test: test-nvim test-zsh

prepare:
	@test -d nvim/.config/plenary.nvim || git clone --depth 1 https://github.com/nvim-lua/plenary.nvim nvim/.config/plenary.nvim

test-nvim: prepare
	cd $(NVIM_DIR) && nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory lua/tests/ { minimal_init = './scripts/minimal_init.vim' }"

test-zsh:
	shellspec

clean:
	rm -rf nvim/.config/plenary.nvim
