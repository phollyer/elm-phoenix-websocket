# Elm 0.19.x package for Phoenix WebSockets

For more information about Phoenix WebSockets see
[Phoenix.Channel](https://hexdocs.pm/phoenix/1.5.3/Phoenix.Channel.html#content)
, [Phoenix.Presence](https://hexdocs.pm/phoenix/1.5.3/Phoenix.Presence.html#content)
and [PhoenixJS](https://hexdocs.pm/phoenix/js).

Multiple channels and Presences are supported from within your Elm program.

# Multiple Channels

All incoming events carry a `topic:subtopic` string to identify the channel.

All outgoing events take a `Maybe String` to identify the channel, apart from
**joining** a channel where the `topic:subtopic` string is required. So if you
supply a `Nothing` for an outgoing event rather than a `Just "topic:subtopic"`
then the channel used for that event will be:

1. The last channel used if using multiple channels, or
2. The only available channel if using just one.

So unless you are only using a single channel, it is probably best to always
supply the `Just "topic:subtopic"` to your outgoing events.

# Presences

There are no outgoing events for Presences, only incoming.

I chose to seperate Presences off from the Channel module because, although
Presences come in over the Channel, they are intended to be used in a different
context. So while the information is similar, it is not the same.

Channel events are likely to carry information relating to business logic,
while Presences simply carry information about users as they join and leave
specific channels.

As a result, it means that when receiving both Channel and Presence events in
the same module, there can be a seperatation of concerns that I feel is
slightly more explicit when pattern matching than there would otherwise be:

```
    import Channel
    import Presence

    type Msg
        = ChannelMsg Channel.EventIn
        | PresenceMsg Presence.EventIn

    update : Msg -> Model -> (Model, Cmd Msg)
    update msg model =
        case msg of
            ChannelMsg (Channel.Message "topic:subtopic" "msg" payload) ->
                ...

            PresenceMsg (Presence.State "topic:subtopic" payload) ->
                ...

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Sub.batch
            [ Channel.subscriptions
                ChannelMsg
                Phx.channelReceiver
            , Presence.subscriptions
                PresenceMsg
                Phx.presenceReceiver
            ]
```

# Workflow

The general workflow would go like this:

1. First connect to the socket:

    ```
    import Ports.Phoenix as Phx
    import Socket

    Socket.send
        (Socket.Connect Nothing)
        Phx.sendMessage
    ```
    `Socket.send` returns a `Cmd msg` so this can go in your `init` function, your
    `update` function or any module where you are able to return a `Cmd msg`.

2. Once the socket is opened, you can join a channel:

    ```
    import Channel
    import Ports.Phoenix as Phx
    import Socket

    type Msg
        = SocketMsg Socket.EventIn

    update : Msg -> Model -> (Model, Cmd Msg)
    update msg model =
        case msg of
            SocketMsg Socket.Opened ->
                ( model
                , Channel.send
                    (Channel.Join
                        { topic = "topic:subtopic"
                        , timeout = Nothing
                        , payload = Nothing
                        }
                    )
                    Phx.sendMessage
                )

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Socket.subscriptions
            SocketMsg
            Phx.socketReceiver
    ```

3. Once you have joined the channel, you can turn incoming events on.

    ```
    import Channel
    import Ports.Phoenix as Phx

    type Msg
        = ChannelMsg Channel.EventIn

    update : Msg -> Model -> (Model, Cmd Msg)
    update msg model =
        case msg of
            ChannelMsg (Channel.JoinOk "topic:subtopic" payload) ->
                ( model
                , Channel.eventsOn
                    (Just topic)
                    [ "msg1"
                    , "msg2"
                    , "msg3"
                    ]
                    Phx.sendMessage
                )

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Channel.subscriptions
            ChannelMsg
            Phx.channelReceiver
    ```

4. And then you can receive those events as follows:

    ```
    import Channel
    import Ports.Phoenix as Phx

    type Msg
        = ChannelMsg Channel.EventIn

    update : Msg -> Model -> (Model, Cmd Msg)
    update msg model =
        case msg of
            ChannelMsg (Channel.Message "topic:subtopic" "msg1" payload) ->
                ( model, Cmd.none )

            ChannelMsg (Channel.Message "topic:subtopic" "msg2" payload) ->
                ( model, Cmd.none )

            ChannelMsg (Channel.Message "topic:subtopic" "msg3" payload) ->
                ( model, Cmd.none )

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Channel.subscriptions
            ChannelMsg
            Phx.channelReceiver
    ```


# How To

In order for your Elm program to talk to
[PhoenixJS](https://hexdocs.pm/phoenix/js), you will need to add a very small
[`port`](https://github.com/phollyer/elm-phoenix-websocket/blob/master/src/Ports/Phoenix.elm)
module to your Elm `src` files, and some
[JavaScript](https://github.com/phollyer/elm-phoenix-websocket/tree/master/elmPhoenixWebSocket)
files to your Phoenix project.

## Set up JavaScript

You first need to copy the contents of the
[`elmPhoenixWebSocket`](https://github.com/phollyer/elm-phoenix-websocket/tree/master/elmPhoenixWebSocket)
folder into `assets/js`.

*Assuming you already have Elm setup in your Phoenix project and instantiated
as `app`:*


```
import ElmPhoenixWebSocket from "path/to/elmPhoenixWebSocket";

ElmPhoenixWebSocket.init(app.ports);
```

# Set up Elm

Add
[`Ports/Phoenix.elm`](https://github.com/phollyer/elm-phoenix-websocket/tree/master/src/Ports)
to your Elm `src` folder, changing the module name to suit if required.

Install the package.

    elm install phollyer/elm-phoenix-websocket

# Example

There is a working example
[here](https://github.com/phollyer/elm-phoenix-websocket/tree/master/example/chat_room)
that you can run locally and also inspect the code.

The file
[example/chat_room/assets/elm/src/ExampleChatProgram.elm](https://github.com/phollyer/elm-phoenix-websocket/tree/master/example/chat_room/assets/elm/src/ExampleChatProgram.elm)
is commented and documented, so as well as browsing through the file, you can
navigate to `example/chat_room/assets/elm` and use
[elm-doc-preview](https://github.com/dmy/elm-doc-preview) to read the docs.