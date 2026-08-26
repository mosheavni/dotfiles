#!/bin/bash
# Install Claude Code skills from external sources via npx skills

set -e

echo "Installing Claude Code skills..."

# Individual skills — format: "repo:skill-name"
skills=(
  "ComposioHQ/awesome-claude-skills:image-enhancer"
  "ComposioHQ/awesome-claude-skills:skill-creator"
  "ComposioHQ/awesome-claude-skills:youtube-downloader"
  "anthropics/skills:pdf"
  "mattpocock/skills:grill-me"
  "nextlevelbuilder/ui-ux-pro-max-skill:ui-ux-pro-max"
  "rebelytics/one-skill-to-rule-them-all:task-observer"
  "sickn33/antigravity-awesome-skills:clean-code"
  "vercel-labs/skills:find-skills"
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

# obra/superpowers ships as one 14-skill bundle. Installing its skills one by
# one via -s triggers the CLI's whole-repo batch path anyway and hits a bug
# where it reports "PromptScript does not support global skill installation"
# for every skill in the batch — even though the Claude Code install itself
# succeeds. Install it as a single repo-wide step instead, gated on one
# representative skill so reruns stay a no-op.
if [[ -d ~/.agents/skills/using-superpowers ]]; then
  echo "  [skip] obra/superpowers already installed"
else
  npx skills add -g -y obra/superpowers
fi

echo "Done. Run 'npx skills ls -g' to verify."
