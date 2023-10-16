if ! [[ -f ~/.openapi-key ]] || ! [[ -s ~/.openapi-key ]]; then
  export OPENAI_API_KEY=$(lpass show -j ai.vim | jq -r '.[].password')
  echo $OPENAI_API_KEY >~/.openapi-key
else
  export OPENAI_API_KEY=$(<~/.openapi-key)
fi
