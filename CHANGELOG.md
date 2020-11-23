# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.1] - 2020-11-23

### Added

Link to live example application in README.md

## [3.0.0] - 2020-11-22

### Added

Phoenix module - this wraps the Socket, Channel and Presence modules in order to automate connecting to a socket and joining a channel. It also provides additional features which can be found in the docs.

### Moved

Socket.elm, Channel.elm, Presence.elm into the Phoenix directory.

### Improved

Converted the seperate JS files into a single file in order to simplify installation.

## [2.0.0] - 2020-09-30

### Changed

Channel timeouts now also return the original payload back to Elm. This affects joining and pushing to channels and requires the user to replace their existing channel.js file with the current one.

## [1.1.0] - 2020-06-25

### Added

`eventsOn` function to `Channel.elm`
`eventsOff` function to `Channel.elm`

### Updated

README with better usage instructions.

## [1.0.4] - 2020-06-20

### Updated

Documentation - fixed typo.


## [1.0.3] - 2020-06-20

### Updated

Documentation - lots of improvements, added more links, added README's to folders to help with understanding the contents.

## [1.0.2] - 2020-06-20

### Updated

Documentation - improved an example.


## [1.0.1] - 2020-06-20

### Updated

Documentation - fixed a typo, improved an example, used better English.

## [1.0.0] - 2020-06-20

### Added

Initial Commit.

[3.0.1]: https://github.com/phollyer/elm-phoenix-websocket/compare/3.0.0...3.0.1
[3.0.0]: https://github.com/phollyer/elm-phoenix-websocket/compare/2.0.0...3.0.0
[2.0.0]: https://github.com/phollyer/elm-phoenix-websocket/compare/1.1.0...2.0.0
[1.1.0]: https://github.com/phollyer/elm-phoenix-websocket/compare/1.0.4...1.1.0
[1.0.4]: https://github.com/phollyer/elm-phoenix-websocket/compare/1.0.3...1.0.4
[1.0.3]: https://github.com/phollyer/elm-phoenix-websocket/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/phollyer/elm-phoenix-websocket/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/phollyer/elm-phoenix-websocket/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/phollyer/elm-phoenix-websocket/releases/tag/v1.0.0

