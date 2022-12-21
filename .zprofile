# =========== #
# Pyenv Setup #
# =========== #
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

if ! [[ -f ~/.openapi-key ]]; then
  export OPENAI_API_KEY=$(lpass show -j ai.vim | jq -r '.[].password')
  echo $OPENAI_API_KEY >~/.openapi-key
else
  export OPENAI_API_KEY=$(<~/.openapi-key)
fi
