#!/bin/bash
# Install Claude Code skills from external sources via npx skills

set -e

echo "Installing Claude Code skills..."

# GSD (Get Shit Done) suite — 65+ project management skills
if [[ -f ~/.claude/get-shit-done/VERSION ]]; then
  echo "  [skip] GSD already installed ($(cat ~/.claude/get-shit-done/VERSION))"
else
  npx get-shit-done-cc@latest -g
fi

# Individual skills — format: "repo:skill-name"
skills=(
  "obra/superpowers:brainstorming"
  "vercel-labs/skills:find-skills"
  "sickn33/antigravity-awesome-skills:clean-code"
  "anthropics/skills:pdf"
  "ComposioHQ/awesome-claude-skills:image-enhancer"
  "ComposioHQ/awesome-claude-skills:skill-creator"
  "ComposioHQ/awesome-claude-skills:video-downloader"
)

for entry in "${skills[@]}"; do
  repo="${entry%%:*}"
  skill="${entry##*:}"
  if [[ -d ~/.agents/skills/"$skill" ]]; then
    echo "  [skip] $skill already installed"
  else
    npx skills add -g -y "$repo" -s "$skill"
  fi
done

echo "Done. Run 'npx skills ls -g' to verify."
