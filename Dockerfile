FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_PRIORITY=critical

RUN apt update && apt install -y gnupg2 git curl python3 python3-pip

# Yarn and nodejs
RUN curl -sL https://deb.nodesource.com/setup_15.x | bash - && \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt update && \
  apt install -y fzf nodejs yarn neovim rubygems exuberant-ctags && \
  apt-get clean autoclean && \
  apt-get autoremove --yes && \
  rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN python3 -m pip install pynvim neovim && npm install -g neovim

WORKDIR /root

# Run this step always without cache
ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache
RUN git clone https://github.com/Moshem123/dotfiles.git && \
  gem install effuse && \
  cd dotfiles && \
  effuse

# Install vim-plug
RUN sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# Run PlugInstall
RUN nvim --headless +'PlugInstall --sync' +qall
RUN cd ~/.vim/plugged/coc.nvim && yarn install
# RUN nvim --headless +CocInstallAll +qall
# join(get(g:, 'coc_global_extensions', []))

CMD [ "vim" ]
