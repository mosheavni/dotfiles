In order to use python right, make sure pyenv virtualenv and pyenv pyright are installed:

```bash
git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv
git clone https://github.com/alefpereira/pyenv-pyright.git $(pyenv root)/plugins/pyenv-pyright
```

on a python project, run:

```bash
pyenv virtualenv 3.10.3 ${PWD##*/}
pyenv local ${PWD##*/}

```
