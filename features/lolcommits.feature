Feature: Basic UI functionality

  Background:
    Given a mocked home directory

  Scenario: App just runs
    When I get help for "lolcommits"
    Then the exit status should be 0
    And the banner should be present

  Scenario: Help should show the animate option on a Mac platform
    Given I am using a "darwin" platform
    When I get help for "lolcommits"
    Then the following options should be documented:
      | --animate | which is optional |
      | -a        | which is optional |

  Scenario: Help should not show the animate option on a Windows plaftorm
    Given I am using a "win32" platform
    When I get help for "lolcommits"
    Then the output should not match /\-a\, \-\-animate\=SECONDS/

  Scenario: Enable in a naked git repo
    Given I am in a git repo
    When I successfully run `lolcommits --enable`
    Then the output should contain "installed lolcommit hook to:"
      And the lolcommits post-commit hook should be properly installed
      And the exit status should be 0

  Scenario: Enable in a git repo that already has a post-commit hook
    Given I am in a git repo
    And a post-commit hook with "#!/bin/sh\n\n/my/own/script"
    When I successfully run `lolcommits --enable`
    Then the output should contain "installed lolcommit hook to:"
      And the lolcommits post-commit hook should be properly installed
      And the post-commit hook should contain "#!/bin/sh"
      And the post-commit hook should contain "/my/own/script"
      And the exit status should be 0

  Scenario: Enable in a git repo that has post-commit hook with a bad shebang
    Given I am in a git repo
    And a post-commit hook with "#!/bin/ruby"
    And I run `lolcommits --enable`
      Then the output should contain "doesn't start with a good shebang"
      And the post-commit hook should not contain "lolcommits --capture"
      And the exit status should be 1

  Scenario: Enable in a git repo passing capture arguments
    Given I am in a git repo
    When I successfully run `lolcommits --enable -w 5 --fork`
    Then the post-commit hook should contain "lolcommits --capture -w 5 --fork"
    And the exit status should be 0

  Scenario: Disable in a enabled git repo
    Given I am in a git repo with lolcommits enabled
    When I successfully run `lolcommits --disable`
    Then the output should contain "uninstalled"
    And a file named ".git/hooks/post-commit" should exist
    And the exit status should be 0

  Scenario: Trying to enable while not in a git repo fails
    Given I am in a directory named "svnrulez"
    When I run `lolcommits --enable`
    Then the output should contain:
      """
      You don't appear to be in the base directory of a git project.
      """
    And the exit status should be 1

  Scenario: Capture doesnt break in forked mode
    Given I am in a git repo named "forked"
    And I do a git commit
    When I successfully run `lolcommits --capture --fork`
    Then there should be exactly 1 pid in "~/.lolcommits/forked"
    When I wait for the child process to exit in "forked"
    Then a directory named "~/.lolcommits/forked" should exist
      And a file named "~/.lolcommits/forked/tmp_snapshot.jpg" should not exist
      And there should be exactly 1 jpg in "~/.lolcommits/forked"

  Scenario: Commiting in an enabled repo triggers successful capture
    Given I am in a git repo named "myrepo" with lolcommits enabled
    When I do a git commit
    Then the output should contain "*** Preserving this moment in history."
      And a directory named "~/.lolcommits/myrepo" should exist
      And a file named "~/.lolcommits/myrepo/tmp_snapshot.jpg" should not exist
      And there should be exactly 1 jpg in "~/.lolcommits/myrepo"

  Scenario: Commiting in enabled repo subdirectory triggers successful capture
    Given I am in a git repo named "testcapture" with lolcommits enabled
      And a directory named "subdir"
      And an empty file named "subdir/FOOBAR"
    When I cd to "subdir/"
      And I do a git commit
    Then the output should contain "*** Preserving this moment in history."
      And a directory named "~/.lolcommits/testcapture" should exist
      And a directory named "~/.lolcommits/subdir" should not exist
      And there should be exactly 1 jpg in "~/.lolcommits/testcapture"

  Scenario: Stealth mode does not alert the user
    Given I am in a git repo named "teststealth"
    And I do a git commit
    When I run `lolcommits --stealth --capture`
    Then the output should not contain "*** Preserving this moment in history."
    And there should be exactly 1 jpg in "~/.lolcommits/teststealth"

  Scenario: Commiting in stealth mode captures without alerting the committer
    Given I am in a git repo with lolcommits enabled
    And I have environment variable LOLCOMMITS_STEALTH set to 1
    When I do a git commit
    Then the output should not contain "*** Preserving this moment in history."
    And there should be exactly 1 jpg in its loldir

  Scenario: Show plugins
    When I successfully run `lolcommits --plugins`
    Then the output should contain a list of plugins

  Scenario: Configuring plugin
    Given I am in a git repo named "config-test"
    When I run `lolcommits --config` interactively
      And I wait for output to contain "Name of plugin to configure:"
      Then I type "loltext"
      And I wait for output to contain "enabled:"
      Then I type "true"
    Then the output should contain "Successfully configured plugin: loltext"
    And the output should contain a list of plugins
    And a file named "~/.lolcommits/config-test/config.yml" should exist
    When I successfully run `lolcommits --show-config`
    Then the output should match /loltext:\s+enabled: true/

  Scenario: Configuring plugin in test mode affects test loldir not repo loldir
    Given I am in a git repo named "testmode-config-test"
    When I run `lolcommits --config --test` interactively
      And I wait for output to contain "Name of plugin to configure:"
      Then I type "loltext"
      And I wait for output to contain "enabled:"
      Then I type "true"
    Then the output should contain "Successfully configured plugin: loltext"
    And a file named "~/.lolcommits/test/config.yml" should exist
    When I successfully run `lolcommits --test --show-config`
    Then the output should match /loltext:\s+enabled: true/

  Scenario: test capture should work regardless of whether in a git repo
    Given I am in a directory named "nothingtoseehere"
    When I run `lolcommits --test --capture`
    Then the output should contain "*** Capturing in test mode."
      And the output should not contain "path does not exist (ArgumentError)"
      And the exit status should be 0

  Scenario: test capture should store in its own test directory
    Given I am in a git repo named "randomgitrepo" with lolcommits enabled
    When I successfully run `lolcommits --test --capture`
    Then a directory named "~/.lolcommits/test" should exist
    And a directory named "~/.lolcommits/randomgitrepo" should not exist

  Scenario: last command should work properly when in a lolrepo
    Given I am in a git repo
    And its loldir has 2 lolimages
    When I run `lolcommits --last`
    Then the exit status should be 0

  Scenario: last command should work properly when in a lolrepo subdirectory
    Given I am in a git repo
      And its loldir has 2 lolimages
      And a directory named "randomdir"
      And I cd to "randomdir"
    When I run `lolcommits --last`
    Then the output should not contain:
      """
      Can't do that since we're not in a valid git repository!
      """
    And the exit status should be 0

  @in-tempdir
  Scenario: last command should fail gracefully if not in a lolrepo
    Given I am in a directory named "gitsuxcvs4eva"
    When I run `lolcommits --last`
    Then the output should contain:
      """
      Can't do that since we're not in a valid git repository!
      """
    And the exit status should be 1

  Scenario: last command should fail gracefully if zero lolimages in lolrepo
    Given I am in a git repo
    And its loldir has 0 lolimages
    When I run `lolcommits --last`
    Then the output should contain:
      """
      No lolcommits have been captured for this repository yet.
      """
    Then the exit status should be 1

  Scenario: browse command should work properly when in a lolrepo
    Given I am in a git repo
    And its loldir has 2 lolimages
    When I run `lolcommits --browse`
    Then the exit status should be 0

  Scenario: browse command should work properly when in a lolrepo subdirectory
    Given I am in a git repo
      And its loldir has 2 lolimages
      And a directory named "subdir"
      And I cd to "subdir"
    When I run `lolcommits --browse`
    Then the output should not contain:
      """
      Can't do that since we're not in a valid git repository!
      """
    And the exit status should be 0

  @in-tempdir
  Scenario: browse command should fail gracefully when not in a lolrepo
    Given I am in a directory named "gitsuxcvs4eva"
    When I run `lolcommits --browse`
    Then the output should contain:
      """
      Can't do that since we're not in a valid git repository!
      """
    And the exit status should be 1

  Scenario: handle commit messages with quotation marks
    Given I am in a git repo with lolcommits enabled
    When I successfully run `git commit --allow-empty -m 'no "air quotes" bae'`
    Then the exit status should be 0
    And there should be exactly 1 jpg in its loldir

  Scenario: generate gif should store in its own archive directory
    Given I am in a git repo named "giffy" with lolcommits enabled
      And a loldir named "giffy" with 2 lolimages
    When I successfully run `lolcommits -g`
    Then the output should contain "Generating animated gif."
      And a directory named "~/.lolcommits/giffy/archive" should exist
      And a file named "~/.lolcommits/giffy/archive/archive.gif" should exist

  Scenario: generate gif with argument 'today'
    Given I am in a git repo named "sunday" with lolcommits enabled
      And a loldir named "sunday" with 2 lolimages
    When I successfully run `lolcommits -g today`
    Then there should be exactly 1 gif in "~/.lolcommits/sunday/archive"

  @mac-only
  Scenario: should generate an animated gif on the Mac platform
    Given I am in a git repo named "animate"
      And I do a git commit
    When I run `lolcommits --capture --animate=1`
    Then the output should contain "*** Preserving this moment in history."
      And a directory named "~/.lolcommits/animate" should exist
      And a file named "~/.lolcommits/animate/tmp_video.mov" should not exist
      And a directory named "~/.lolcommits/animate/tmp_frames" should not exist
      And there should be exactly 1 gif in "~/.lolcommits/animate"

  @fake-no-ffmpeg
  Scenario: gracefully fail when ffmpeg not installed and --animate is used
    Given I am using a "darwin" platform
    When I run `lolcommits --animate=3`
    Then the output should contain:
      """
      ffmpeg does not appear to be properly installed
      """
    And the exit status should be 1

  Scenario: Enable on windows platform setting PATH in post-commit hook
    Given I am using a "win32" platform
      And I am in a git repo
    When I successfully run `lolcommits --enable`
    Then the post-commit hook should contain "set path"
    And the exit status should be 0
