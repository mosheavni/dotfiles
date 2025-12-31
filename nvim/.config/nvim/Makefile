.PHONY: all test prepare clean

all: test

prepare:
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim ../plenary.nvim

test:
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory lua/tests/ { minimal_init = './scripts/minimal_init.vim' }"

clean:
	rm -rf ../plenary.nvim
