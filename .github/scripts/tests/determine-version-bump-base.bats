#!/usr/bin/env bats
# Tests for .github/scripts/determine-version-bump-base.sh
#
# Each test sets MAIN_VERSION in the environment so the script runs
# without calling gh api. See the script's header for the input contract.

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../determine-version-bump-base.sh"
}

@test "matching major routes to main (v-prefixed)" {
  MAIN_VERSION='14.0.0' run bash "$SCRIPT" v14.5.0
  [ "$status" -eq 0 ]
  [ "$output" = "main" ]
}

@test "matching major routes to main (no v prefix)" {
  MAIN_VERSION='14.0.0' run bash "$SCRIPT" 14.5.0
  [ "$status" -eq 0 ]
  [ "$output" = "main" ]
}

@test "older major routes to v{major}" {
  MAIN_VERSION='14.0.0' run bash "$SCRIPT" v13.35.1
  [ "$status" -eq 0 ]
  [ "$output" = "v13" ]
}

@test "future major routes to v{major}" {
  MAIN_VERSION='14.0.0' run bash "$SCRIPT" v15.0.0
  [ "$status" -eq 0 ]
  [ "$output" = "v15" ]
}

@test "main on v13 today: v13 release routes to main" {
  MAIN_VERSION='13.35.0' run bash "$SCRIPT" v13.35.1
  [ "$status" -eq 0 ]
  [ "$output" = "main" ]
}

@test "trailing newline in VERSION file is ignored" {
  MAIN_VERSION=$'14.0.0\n' run bash "$SCRIPT" v13.35.1
  [ "$status" -eq 0 ]
  [ "$output" = "v13" ]
}

@test "surrounding whitespace in VERSION file is ignored" {
  MAIN_VERSION='  14.0.0  ' run bash "$SCRIPT" v14.5.0
  [ "$status" -eq 0 ]
  [ "$output" = "main" ]
}

@test "empty VERSION file fails loudly" {
  MAIN_VERSION='' run bash "$SCRIPT" v13.35.1
  [ "$status" -ne 0 ]
  [[ "$output" == *"Could not read main's VERSION"* ]]
}

@test "missing version argument errors out" {
  MAIN_VERSION='14.0.0' run bash "$SCRIPT"
  [ "$status" -ne 0 ]
}
