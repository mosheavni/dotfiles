# shellcheck shell=bash
Describe 'zsh.d/functions.zsh'
  Include zsh/zsh.d/functions.zsh

  Describe 'take'
    It 'creates a nested directory and cds into it'
      cd "$SHELLSPEC_TMPBASE" || return
      When call take proj/sub
      The status should be success
      The variable PWD should eq "$SHELLSPEC_TMPBASE/proj/sub"
    End

    It 'fails without exactly one argument'
      When call take
      The status should be failure
    End
  End

  Describe 'ssh2'
    ssh() { echo "ssh:$1"; }

    It 'converts ip-dashed hostname to dotted IP'
      When call ssh2 ip-10-1-2-3
      The line 1 of output should eq '10.1.2.3'
      The line 2 of output should eq 'ssh:10.1.2.3'
    End

    It 'leaves regular hostnames untouched'
      When call ssh2 example.com
      The line 1 of output should eq 'example.com'
      The line 2 of output should eq 'ssh:example.com'
    End
  End

  Describe 'git_current_branch'
    It 'prints the current branch'
      cd "$SHELLSPEC_TMPBASE" || return
      git init --quiet --initial-branch=spec-branch repo
      cd repo || return
      When call git_current_branch
      The output should eq 'spec-branch'
    End

    It 'prints nothing outside a repository'
      mkdir -p "$SHELLSPEC_TMPBASE/no-repo"
      cd "$SHELLSPEC_TMPBASE/no-repo" || return
      GIT_CEILING_DIRECTORIES="$SHELLSPEC_TMPBASE"
      export GIT_CEILING_DIRECTORIES
      When call git_current_branch
      The status should be failure
      The output should eq ''
    End
  End
End
