0.3.3 (2011-09-03)
------------------

* Refactored tests.
* Word wrapped more commands (should be all long outputs now).
* Source file reading bug fixed.
* Fixed an `all` style command bug.

0.3.2 (2011-08-31)
------------------

* Added dye kits with give support..
* Added a tool kit.
* Implemented command history.

0.3.1 (2011-08-30)
------------------

* Misc bug fixes.
* Revised README.
* Removed two time quotes.

0.3.0 (2011-08-29)
------------------

* Added `!warptime`, `!stop`, `!welcome`, `!memo`, `!disco`, `!dnd`, `!disturb`, `!printdnd`, `!todo`, `!finished`.
* Moved time commands out of `method_missing`.
* Added capability for users to not be disturbed by teleporting or `all` commands.
* Removed `add_command` calls, now indexes information from source code on initialization.
* Added more documentation (back at 100% coverage).
* Added many more test suites.
* Misc. bug fixes including lots of command feedback.
* Shortcuts and kits can now be accessed with `:` instead of `!s` or `!kit`.
* `!help` is now dynamic and includes command-specific help.
* Coloured terminal output.
* Basic word wrapped output.

0.2.1 (2011-08-22)
------------------

* Fixed `!points` and `!board`
* Bugfix on `call_command`
* Added more test suites.
* A `!help` command suitable for new privilege system.

0.2.0 (2011-08-21)
------------------

* Added configuration file capability.
* Added `!points`, `!board`, `!kickvote`, `!vote`, `!cancelvote`, `!kickvotes`, `!roulette`, `change_time`, `!om`, `!dehop`, `!hop`
* Added time changes (morning, night, dawn, etc...)
* Separated half-op and op privileges.
* `!property` now lists properties if none specified.
* Bugfix for `all` style commands (makes sure `:all => true`) is specified.
* `switch` is an alias for `lever`
* Refactored file saving/loading.
* Bugfix for default CLI options.
* Now saves instance files as well as executes `save-all` periodically.
* Bugfix for `uptime` stuff, offline users now can be computed.

0.1.0 (2011-08-20)
------------------

* Added yadocs.
* Updated README.
* Added test suites.

0.0.5 (2011-08-17)
------------------

* Added `savefreq` and `welcome_message` CLI options.
* Refactored `Minecraft` module, added a `Runtime` class.
* Added `!printtime`, `!printtimer`, `!s`, `!shortcuts` commands.
* Clarified console information/error messages.
* Fixed kits.
* Saves timers and shortcuts.
* Displays welcome message to connecting users.
* Major refactoring to server process handling.
* `save_all` on exit works now, proper exit handling.  No longer used `Thread#join`
* Toggling mob state (`--tempmob`) prints new state.

0.0.4 (2011-08-14)
------------------

* Added the `!rules` command and associated `rules` CLI option.
* Refactored `give` logic.
* `!property`, `!uptime` commands added.
* More intelligent quantifiers.
* Monitors kicks and bans.

0.0.3 (2011-08-13)
------------------

* Split command methods into the `Minecraft::Commands` module.
* Validates `!kit` command.
* Added `!list`, `!addtimer`, `!deltimer`, `!printtimer`, `!kitlist` commands.
* Approximate item names implemented.
* Fixed item naming bugs.
* Major refactoring done to commands.
* Logs user uptime.
* Catches processing exceptions.

0.0.2 (2011-08-13)
------------------

* Command line options added.
* Trapped the interrupt signal for an exit hook.
* `no_run`, `update`, `min_memory`, `max_memory`, `no_auto_save`, `tempmobs` CLI options implemented.
* Fixed indentation.
* `!giveall`, `!tpall`, `!help` commands implemented.
* Meta checks in place (ops, join/part).
* Privilege errors.
* Refactored `Minecraft::Server`, added `Minecraft::Tools`.

0.0.1 (2011-08-12)
------------------

* `:diamond`, `:garmour`, `:armour`, `:ranged`, `:nether`, `:portal` kits.
* Data values hash in place.
* Simple console processing in place.
* `!give`, `!kit`, `!tp`, `!nom` commands implemented.
