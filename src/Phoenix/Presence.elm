module Phoenix.Presence exposing
    ( Presence, PresenceDiff
    , Topic
    , Msg(..)
    , PortIn, subscriptions
    )

{-| This module is not intended to be used directly, the top level
[Phoenix](Phoenix#) module provides a much nicer experience.

@docs Presence, PresenceDiff

@docs Topic

@docs Msg

@docs PortIn, subscriptions

-}

import Json.Decode as JD exposing (Value)
import Json.Decode.Extra exposing (andMap)
import Json.Encode as JE


{-| A type alias representing a Presence on a Channel.

  - `id` - The `id` used to identify the Presence map in the
    [Presence.track/3](https://hexdocs.pm/phoenix/Phoenix.Presence.html#c:track/3)
    Elixir function. The recommended approach is to use the users' `id`.

  - `metas`- A list of metadata as stored in the
    [Presence.track/3](https://hexdocs.pm/phoenix/Phoenix.Presence.html#c:track/3)
    Elixir function.

  - `user` - The user data that is pulled from the DB and stored on the
    Presence in the
    [fetch/2](https://hexdocs.pm/phoenix/Phoenix.Presence.html#c:fetch/2)
    Elixir callback function. This is the recommended approach for storing user
    data on the Presence. If
    [fetch/2](https://hexdocs.pm/phoenix/Phoenix.Presence.html#c:fetch/2) is
    not being used then `user` will be equal to
    [Json.Encode.null](https://package.elm-lang.org/packages/elm/json/latest/Json-Encode#null).

  - `presence` - The whole Presence map. This provides a way to access any
    additional data that is stored on the Presence.

```
-- MyAppWeb.MyChannel.ex

def handle_info(:after_join, socket) do
  {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
    online_at: System.os_time(:millisecond)
  })

  push(socket, "presence_state", Presence.list(socket))

  {:noreply, socket}
end

-- MyAppWeb.Presence.ex

defmodule MyAppWeb.Presence do
  use Phoenix.Presence,
    otp_app: :my_app,
    pubsub_server: MyApp.PubSub

  def fetch(_topic, presences) do
    query =
      from u in User,
      where: u.id in ^Map.keys(presences),
      select: {u.id, u}

    users = query |> Repo.all() |> Enum.into(%{})

    for {key, %{metas: metas}} <- presences, into: %{} do
      {key, %{metas: metas, user: users[key]}}
    end
  end
end
```

-}
type alias Presence =
    { id : String
    , metas : List Value
    , user : Value
    , presence : Value
    }


{-| A type alias representing the `joins` and `leaves` on the Channel as they
happen.
-}
type alias PresenceDiff =
    { joins : List Presence
    , leaves : List Presence
    }


{-| A type alias representing the Channel topic id. For example
`"topic:subTopic"`.
-}
type alias Topic =
    String


{-| All of the Presence `Msg`s that can come from the Channel.

If you are using more than one Channel, then you can check `Topic` to determine
which Channel the [Msg](#Msg) relates to.

`DecoderError` and `InvalidMsg` mean that a message has been received from the
accompanying JS that cannot be handled. This should not happen, but will if the
JS and this module are out of sync, if it does, please raise an
[issue](https://github.com/phollyer/elm-phoenix-websocket/issues).

-}
type Msg
    = Join Topic Presence
    | Leave Topic Presence
    | State Topic (List Presence)
    | Diff Topic PresenceDiff
    | DecoderError String
    | InvalidMsg Topic String


{-| A type alias representing the `port` function required to receive
a [Msg](#Msg) from Phoenix Presence.

You will find this `port` function in the
[Port](https://github.com/phollyer/elm-phoenix-websocket/tree/master/ports)
module.

-}
type alias PortIn msg =
    ({ topic : Topic
     , msg : String
     , payload : JE.Value
     }
     -> msg
    )
    -> Sub msg


{-| Subscribe to receive incoming Presence [Msg](#Msg)s.

    import Phoenix.Presence as Presence
    import Ports.Phoenix as Port

    type Msg
      = PresenceMsg Presence.Msg
      | ...


    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Presence.subscriptions
            PresenceMsg
            Port.presenceReceiver

-}
subscriptions : (Msg -> msg) -> PortIn msg -> Sub msg
subscriptions msg portIn =
    portIn <|
        handleIn msg


type alias Package =
    { topic : String
    , msg : String
    , payload : JE.Value
    }


handleIn : (Msg -> msg) -> Package -> msg
handleIn toMsg { topic, msg, payload } =
    case msg of
        "Join" ->
            decodePresence toMsg topic Join presenceDecoder payload

        "Leave" ->
            decodePresence toMsg topic Leave presenceDecoder payload

        "State" ->
            decodePresence toMsg topic State stateDecoder payload

        "Diff" ->
            decodePresence toMsg topic Diff diffDecoder payload

        _ ->
            toMsg (InvalidMsg topic msg)



{- Decoders -}


decodePresence : (Msg -> msg) -> Topic -> (Topic -> a -> Msg) -> JD.Decoder a -> Value -> msg
decodePresence toMsg topic presenceMsg decoder payload =
    case JD.decodeValue decoder payload of
        Ok presence ->
            toMsg (presenceMsg topic presence)

        Err error ->
            toMsg (DecoderError (JD.errorToString error))


presenceDecoder : JD.Decoder Presence
presenceDecoder =
    JD.succeed
        Presence
        |> andMap (JD.field "id" JD.string)
        |> andMap (JD.field "metas" (JD.list JD.value))
        |> andMap (JD.field "user" JD.value)
        |> andMap (JD.field "presence" JD.value)


diffDecoder : JD.Decoder PresenceDiff
diffDecoder =
    JD.succeed
        PresenceDiff
        |> andMap (JD.field "joins" listDecoder)
        |> andMap (JD.field "leaves" listDecoder)


stateDecoder : JD.Decoder (List Presence)
stateDecoder =
    JD.succeed
        identity
        |> andMap (JD.field "list" listDecoder)


listDecoder : JD.Decoder (List Presence)
listDecoder =
    JD.list presenceDecoder
