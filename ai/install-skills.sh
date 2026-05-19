#!/bin/bash
# Install Claude Code skills from external sources via npx skills

set -e

echo "Installing Claude Code skills..."

# Individual skills — format: "repo:skill-name"
skills=(
  "obra/superpowers:brainstorming"
  "vercel-labs/skills:find-skills"
  "sickn33/antigravity-awesome-skills:clean-code"
  "anthropics/skills:pdf"
  "ComposioHQ/awesome-claude-skills:image-enhancer"
  "ComposioHQ/awesome-claude-skills:skill-creator"
  "ComposioHQ/awesome-claude-skills:youtube-downloader"
  "obra/superpowers"
  "nextlevelbuilder/ui-ux-pro-max-skill:ui-ux-pro-max"
)

for entry in "${skills[@]}"; do
  if [[ "$entry" == *:* ]]; then
    repo="${entry%%:*}"
    skill="${entry##*:}"
    if [[ -d ~/.agents/skills/"$skill" ]]; then
      echo "  [skip] $skill already installed"
    else
      npx skills add -g -y "$repo" -s "$skill"
    fi
  else
    npx skills add -g -y "$entry"
  fi
done

echo "Done. Run 'npx skills ls -g' to verify."
