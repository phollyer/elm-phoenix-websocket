# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [unreleased]

- Nothing at the moment.

## [4.0.0] - 2021-09-02

### Fixed

- typos in Docs (thanks to [Alan Hoarf](https://github.com/hoarf))

### Added

- new OutMsg of PushTimeoutsSent which reports a list of push configs that are being attempted again (according to their retry strategy) after they timed out.

## [3.4.4] - 2021-02-20

### Fixed

- `topic` should be `params.topic` in the last change to the `leave` function.

## [3.4.3] - 2021-02-20

### Changed

- Calling `leave` on a channel topic that is not joined no longer causes a JS `Uncaught TypeError`. Fixes [Issue #11](https://github.com/phollyer/elm-phoenix-websocket/issues/11) (which wasn't really an issue). The only change was to the provided JS.

## [3.4.2] - 2020-12-31

### Fixed

- `Phoenix.disconnect` now resets the internal model correctly so that re-connects can happen. ([Issue #10](https://github.com/phollyer/elm-phoenix-websocket/issues/10).)

## [3.4.1] - 2020-12-30

### Fixed

- `Phoenix.pushWaiting` now reports back correctly. ([Issue #9](https://github.com/phollyer/elm-phoenix-websocket/issues/9).)

## [3.4.0] - 2020-12-28

### Added

- `pushInFlight` function to `Phoenix.elm` to determine if a `push` has been sent and is on its way to its Channel.
- `pushWaiting` function to `Phoenix.elm` to determine if a `push` is being actioned. This is different to `pushInFlight` in that it also reports back queued pushes and timeout pushes.

## [3.3.0] - 2020-12-18

### Added

- `joinAll` function to `Phoenix.elm` to enable joining a `List` of Channels.
- `leaveAll` function to `Phoenix.elm` to enable leaving all joined channels.

## [3.2.1] - 2020-12-13

### Fixed

- `Phoenix.disconnectAndReset` now disconnects the socket. ([Issue #8](https://github.com/phollyer/elm-phoenix-websocket/issues/8).)

## [3.2.0] - 2020-12-12

### Added

- `map` and `mapMsg` functions to ease working with the results of `update`.

## [3.1.0] - 2020-12-11

### Added

- `Phoenix.Channel.joinConfig` helper function to ease creating `JoinConfig`s.

### Changed

- Moved local functions in `Phoenix.elm` into `Internal` modules.
- Re-organised code within all modules for easier maintenance.

## [3.0.1] - 2020-11-23

### Added

- Link to live example application in README.md

## [3.0.0] - 2020-11-22

### Added

- `Phoenix.elm` module - this wraps the functionality of the `Socket`, `Channel` and `Presence` modules in order to automate and manage low level processes such as connecting the socket and joining a channel. It also provides additional features which can be found in the docs.

### Changed

- `Socket.elm`, `Channel.elm`, `Presence.elm` have been moved into the `Phoenix` directory.
- Converted the seperate JS files into a single file in order to simplify installation.

## [2.0.0] - 2020-09-30

### Changed

- Channel timeouts now also return the original payload back to Elm. This affects joining and pushing to channels and requires the user to replace their existing `channel.js` file with the current one.

## [1.1.0] - 2020-06-25

### Added

- `eventsOn` function to `Channel.elm`
- `eventsOff` function to `Channel.elm`

### Changed

- README usage instructions.

## [1.0.4] - 2020-06-20

### Changed

- Documentation - fixed typo.

## [1.0.3] - 2020-06-20

### Changed

- Documentation - lots of improvements, added more links, added README's to folders to help with understanding the contents.

## [1.0.2] - 2020-06-20

### Changed

- Documentation - improved an example.

## [1.0.1] - 2020-06-20

### Changed

- Documentation - fixed a typo, improved an example, used better English.

## [1.0.0] - 2020-06-20

### Added

- Initial Commit.

[unreleased]: https://github.com/phollyer/elm-phoenix-websocket/compare/4.0.0...HEAD
[4.0.0]: https://github.com/phollyer/elm-phoenix-websocket/compare/3.4.4...4.0.0
[3.4.4]: https://github.com/phollyer/elm-phoenix-websocket/compare/3.4.3...3.4.4
[3.4.3]: https://github.com/phollyer/elm-phoenix-websocket/compare/3.4.2...3.4.3
[3.4.2]: https://github.com/phollyer/elm-phoenix-websocket/compare/3.4.1...3.4.2
[3.4.1]: https://github.com/phollyer/elm-phoenix-websocket/compare/3.4.0...3.4.1
[3.4.0]: https://github.com/phollyer/elm-phoenix-websocket/compare/3.3.0...3.4.0
[3.3.0]: https://github.com/phollyer/elm-phoenix-websocket/compare/3.2.1...3.3.0
[3.2.1]: https://github.com/phollyer/elm-phoenix-websocket/compare/3.2.0...3.2.1
[3.2.0]: https://github.com/phollyer/elm-phoenix-websocket/compare/3.1.0...3.2.0
[3.1.0]: https://github.com/phollyer/elm-phoenix-websocket/compare/3.0.1...3.1.0
[3.0.1]: https://github.com/phollyer/elm-phoenix-websocket/compare/3.0.0...3.0.1
[3.0.0]: https://github.com/phollyer/elm-phoenix-websocket/compare/2.0.0...3.0.0
[2.0.0]: https://github.com/phollyer/elm-phoenix-websocket/compare/1.1.0...2.0.0
[1.1.0]: https://github.com/phollyer/elm-phoenix-websocket/compare/1.0.4...1.1.0
[1.0.4]: https://github.com/phollyer/elm-phoenix-websocket/compare/1.0.3...1.0.4
[1.0.3]: https://github.com/phollyer/elm-phoenix-websocket/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/phollyer/elm-phoenix-websocket/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/phollyer/elm-phoenix-websocket/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/phollyer/elm-phoenix-websocket/releases/tag/1.0.0
