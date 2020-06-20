# Example Chat Application for Elm-Phoenix-Websocket package

This is an example chat application using an
[Elixir](https://elixir-lang.org) backend with the
[Phoenix Framework](https://www.phoenixframework.org/) and an Elm front end.

It is intended to demonstrate the use of the Elm-Phoenix-Websocket package.
Some knowledge of [Elixir](https://elixir-lang.org), the
[Phoenix Framework](https://www.phoenixframework.org/) and Elm is expected.
Although, if you are new to any of these, and fancy taking a peek, the
following installation and setup instructions should be enough for you to run
the application locally.


## Install Elixir

You need the `elixir` language if you do not have it installed already. You can
find the installation instructions
[here](https://elixir-lang.org/install.html).

The example was built with `v1.10.3` which is the latest at the time of
writing, if you have an older version and are having problems, you should
consider upgrading.

Once you have installed `elixir`, run the following command to install the Hex
package manager:

`mix local.hex`

(If you already have it installed, this will upgrade it to the latest version.)

## Install Phoenix

You need the `Phoenix Framework` generator if you do not have it installed
already. Once you have `elixir` and `hex` installed, you can install the
generator with


`mix archive.install hex phx_new 1.5.3`

`v1.5.3` is the latest at the time of writing.


## Install NodeJS

You will need `NodeJS` if you do not have it installed already. Installation
instructions can be found [here](https://nodejs.org/en/download/).

## Install Elm

You will need `Elm` installed if you do not have it installed already (which is
probably unlikely if you are interested in Elm-Phoenix-Websocket).

The installation instructions can be found
[here](https://guide.elm-lang.org/install/elm.html).

## Clone this Repo

`git clone https://github.com/phollyer/elm-phoenix-websocket.git`

## Install Dependencies

`cd elm-phoenix-websocket/example/chat_room/assets`

`npm install --save-dev webpack`

`npm install --save elm-webpack-loader`

`cd ../`

`mix deps.get`

`mix deps.compile`

## Run the Phoenix Application

`mix phx.server`

## Docs

The file
[assets/elm/src/ExampleChatProgram.elm](https://github.com/phollyer/elm-phoenix-websocket/tree/master/example/chat_room/assets/elm/src/ExampleChatProgram.elm)
is commented and documented, so as well as browsing through the file, you can
navigate to `example/chat_room/assets/elm` and use
[elm-doc-preview](https://github.com/dmy/elm-doc-preview) to read the docs.