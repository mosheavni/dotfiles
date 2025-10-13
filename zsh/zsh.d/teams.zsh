# Widget function to run teams-call
teams-call-widget() {
    echo  # Add a newline for clean output
    teams-call
    zle reset-prompt  # Refresh the prompt after the script runs
}

# Create the widget
zle -N teams-call-widget

# Bind it to a key combination (e.g., Ctrl+T)
bindkey '^[t' teams-call-widget
