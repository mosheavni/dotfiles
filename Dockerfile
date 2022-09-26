FROM ubuntu:bionic

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_PRIORITY=critical

RUN apt update && apt install -y gnupg2 git curl python3 python3-pip wget libfuse2 software-properties-common ripgrep

# Install RipGrep
RUN curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb \
  && dpkg -i ripgrep_13.0.0_amd64.deb

# Install neovim nightly
RUN add-apt-repository -y ppa:neovim-ppa/unstable \
  && apt-get update \
  && apt-get install -y neovim

# Yarn and nodejs
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt update && \
  apt install -y yarn rubygems && \
  apt-get clean autoclean && \
  apt-get autoremove --yes && \
  rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN python3 -m pip install pynvim neovim && npm install -g neovim

WORKDIR /root

# add alias
RUN echo 'alias vim="nvim"' >> ~/.bashrc

# Run this step always without cache
ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache
RUN git clone https://github.com/mosheavni/dotfiles.git && \
  gem install effuse && \
  cd dotfiles && \
  git checkout fix-dockerfile \
  && effuse

# Set locale
ENV LANG=en_US LC_ALL=en_US.UTF-8 LC_CTYPE=en_US.UTF-8

# RUN nvim --headless +CocInstallAll +qall
  # join(get(g:, 'coc_global_extensions', []))

CMD [ "nvim" ]
