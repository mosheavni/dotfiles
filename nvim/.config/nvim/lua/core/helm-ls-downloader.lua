local function write_bash_file(bash_file_content, file_path)
  local file = io.open(file_path, 'w')
  if not file then
    print 'Error: Unable to open file for writing.'
    return false
  end

  file:write(bash_file_content)
  file:close()
  return true
end

local function run_bash_script(script_path)
  local on_exit = function(obj, _)
    if obj.code ~= 0 then
      vim.notify 'An error occurred while downloading helm_ls.'
      vim.notify(obj.stderr)
      vim.notify(obj.stdout)
    end

    os.remove(script_path) -- Cleanup: Delete the temporary bash script
  end

  vim.system({ 'bash', script_path }, {
    cwd = vim.fn.getcwd(),
  }, on_exit)
end

-- Define the bash script content
local bash_script_content = [=[
#!/bin/bash
dest_path=/usr/local/bin/helm_ls
[[ -f $dest_path ]] && exit 0
echo "Downloading helm_ls"
arch=$(uname -m)
case "$arch" in
x86_64) platform="amd64" ;;
arm) platform="arm" ;;
aarch64) platform="arm64" ;;
*)
    echo "$arch not supported"
    exit 1
    ;;
esac
artifact_name=$(echo -n "helm_ls_$(uname -s | tr '[:upper:]' '[:lower:]')_${platform}")
latest_bin=$(curl -s https://api.github.com/repos/mrjosh/helm-ls/releases/latest | jq -r --arg artifact_name "$artifact_name" '.assets[] | select(.name == $artifact_name) | .browser_download_url')
curl -L "$latest_bin" --output "$dest_path"
chmod +x "$dest_path"
]=]

local bash_script_path = '/tmp/download_helm_ls.sh' -- You can change the path if necessary

if write_bash_file(bash_script_content, bash_script_path) then
  run_bash_script(bash_script_path)
else
  print 'Failed to create the bash script.'
end
