# shellcheck shell=bash
Describe 'zsh.d/alias-finder.zsh'
  Include zsh/zsh.d/alias-finder.zsh

  Describe '_alias_parser'
    It 'prints the definition of an alias'
      alias gs='git status'
      When call _alias_parser gs
      The output should eq 'git status'
    End

    It 'prints nothing for a non-alias'
      When call _alias_parser not_an_alias
      The status should be failure
      The output should eq ''
    End
  End

  Describe '_alias_finder'
    It 'expands a simple alias and keeps arguments'
      alias gs='git status'
      When call _alias_finder 'gs -sb'
      The output should eq 'git status -sb'
    End

    It 'expands nested aliases recursively'
      alias kgp='kubectl get pods'
      alias kgpl='kgp -l'
      When call _alias_finder 'kgpl app=web'
      The output should eq 'kubectl get pods -l app=web'
    End

    It 'stops expanding when an alias references itself'
      alias ls='ls -G'
      When call _alias_finder 'ls'
      The output should eq 'ls -G'
    End

    It 'passes through plain commands'
      When call _alias_finder 'echo hello world'
      The output should eq 'echo hello world'
    End
  End
End
