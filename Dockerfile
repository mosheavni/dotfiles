FROM ubuntu:kinetic

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_PRIORITY=critical

RUN apt-get update && apt-get install -y \
  curl \
  git \
  gnupg2 \
  libfuse2 \
  python3 \
  python3-pip \
  software-properties-common \
  wget \
  zip

# Install RipGrep
RUN curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb \
  && dpkg -i ripgrep_13.0.0_amd64.deb

# Install neovim nightly
RUN wget https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz && \
  tar xzf nvim-linux64.tar.gz && \
  ln -s ${PWD}/nvim-linux64/bin/nvim /usr/local/bin/nvim

# Yarn and nodejs
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
  apt-get install -y nodejs && \
  npm install -g yarn neovim

# RUN python3 -m pip install pynvim neovim && npm install -g neovim

# Install Java Corretto
RUN wget -O- https://apt.corretto.aws/corretto.key | apt-key add - && \
  add-apt-repository 'deb https://apt.corretto.aws stable main' && \
  apt-get update && apt-get install -y java-17-amazon-corretto-jdk

COPY ./.config/nvim /root/.config/nvim
RUN nvim --headless "+Lazy! sync" +qa
# Run this step always without cache
# ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache
# RUN git clone https://github.com/mosheavni/dotfiles.git && \
#   gem install effuse && \
#   cd dotfiles && \
#   git checkout fix-dockerfile \
#   && effuse

# Set locale
# ENV LANG=en_US LC_ALL=en_US.UTF-8 LC_CTYPE=en_US.UTF-8
