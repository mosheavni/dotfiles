# shellcheck shell=bash
# shellcheck disable=SC2329  # aws mocks are invoked indirectly by shellspec
Describe 'zsh.d/aws-profile.zsh'
  export AWS_PROFILE_ENV="$SHELLSPEC_TMPBASE/aws/profile.env"
  Include zsh/zsh.d/aws-profile.zsh

  Describe '_aws_profile_save'
    It 'writes a quoted export line'
      When call _aws_profile_save 'my profile'
      The status should be success
      The contents of file "$AWS_PROFILE_ENV" should eq 'export AWS_PROFILE=my\ profile'
    End
  End

  Describe '_aws_profile_load'
    It 'exports the saved profile'
      _aws_profile_save staging
      unset AWS_PROFILE
      When call _aws_profile_load
      The variable AWS_PROFILE should eq 'staging'
    End
  End

  Describe '_aws_profile_account'
    It 'uses sso_account_id when present'
      aws() { [[ $* == *sso_account_id* ]] && echo 111111111111; }
      When call _aws_profile_account someprofile
      The output should eq '111111111111'
    End

    It 'extracts the account from role_arn when sso is absent'
      aws() {
        case "$*" in
          *sso_account_id*) return 1 ;;
          *role_arn*) echo 'arn:aws:iam::222222222222:role/dev' ;;
          *) return 1 ;;
        esac
      }
      When call _aws_profile_account someprofile
      The output should eq '222222222222'
    End

    It 'falls back to sts get-caller-identity'
      aws() {
        case "$*" in
          *get-caller-identity*) echo 333333333333 ;;
          *) return 1 ;;
        esac
      }
      When call _aws_profile_account someprofile
      The output should eq '333333333333'
    End

    It 'prints ? when nothing resolves'
      aws() { return 1; }
      When call _aws_profile_account someprofile
      The output should eq '?'
    End
  End
End
