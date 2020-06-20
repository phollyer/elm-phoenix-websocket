module Presence exposing
    ( subscriptions, EventIn(..), Topic, Presence, PresenceState, PresenceDiff
    , PortIn, Package
    , decodeMetas
    )

{-| This module is for working with Phoenix
[Presence](https://hexdocs.pm/phoenix/1.5.3/Phoenix.Presence.html#content).

Before you can receive presence information, you first need to
[connect to a socket](Socket) and [join a channel](Channel). Once this is done,
you can then [subscribe](#subscribe) to start receiving [Presence](#Presence)
data as your users come and go.

If you are new to Phoenix Presence, you will need to setup your backend
channel as described
[here](https://hexdocs.pm/phoenix/1.5.3/Phoenix.Presence.html#content).
Currently, only the `metas` key is supported.


# Receiving Messages

@docs subscriptions, EventIn, Topic, Presence, PresenceState, PresenceDiff

@docs PortIn, Package


# Decoders

@docs decodeMetas

-}

import Json.Decode as JD exposing (Value)
import Json.Decode.Extra exposing (andMap)
import Json.Encode as JE



-- Receiving Messages


{-| Subscribe to receive incoming presence events.

    import Presence
    import Ports.Phoenix as Phx

    type Msg
      = PresenceMsg Presence.EventIn
      | ...


    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Phx.presenceReceiver
          |> Presence.subscriptions
            PresenceMsg

-}
subscriptions : (EventIn -> msg) -> PortIn msg -> Sub msg
subscriptions msg portIn =
    portIn (handleIn msg)


handleIn : (EventIn -> msg) -> Package -> msg
handleIn toMsg { topic, event, payload } =
    case event of
        "Join" ->
            payload
                |> decodePresence
                |> Join
                    topic
                |> toMsg

        "Leave" ->
            payload
                |> decodePresence
                |> Leave
                    topic
                |> toMsg

        "State" ->
            payload
                |> decodeState
                |> State
                    topic
                |> toMsg

        "Diff" ->
            payload
                |> decodeDiff
                |> Diff
                    topic
                |> toMsg

        _ ->
            toMsg (InvalidEvent topic event)


{-| A type alias representing the data received from a channel. You will not
use this directly.
-}
type alias Package =
    { topic : String
    , event : String
    , payload : JE.Value
    }


{-| A type alias representing the `port` function required to receive
the [EventIn](#EventIn) from the channel.

You could write this yourself, if you do, it needs to be named
`presenceReceiver`, although you may find it simpler to just add
[this port module](https://github.com/phollyer/elm-phoenix-websocket/blob/master/src/Ports/Phoenix.elm)
to your `src` - it includes all the necessary `port` functions.

-}
type alias PortIn msg =
    (Package -> msg) -> Sub msg


{-| All of the presence events that can come from the channel.

If you are using more than one channel, then you can check `Topic` to determine
which channel the [EventIn](#EventIn) relates to. If you are only using a single
channel, you can ignore `Topic`.

`InvalidEvent` means that an event has been received from the accompanying JS
that cannot be handled. This should not happen, if it does, please raise an
[issue](https://github.com/phollyer/elm-phoenix-websocket/issues).

-}
type EventIn
    = Join Topic Presence
    | Leave Topic Presence
    | State Topic PresenceState
    | Diff Topic PresenceDiff
    | InvalidEvent Topic String


{-| A type alias representing the channel topic. Use this to identify the
channel an [EventIn](#EventIn) relates to.

If you are only using one channel, you can ignore this.

-}
type alias Topic =
    String


{-| A type alias representing a
[Presence](https://hexdocs.pm/phoenix/1.5.3/Phoenix.Presence.html#content).
-}
type alias Presence =
    { id : String
    , metas : List Value
    }


{-| A type alias representing a list of all [Presence](#Presence)s stored on
the channel.
-}
type alias PresenceState =
    List Presence


{-| A type alias representing the `joins` and `leaves` on the channel as they
happen.
-}
type alias PresenceDiff =
    { joins : List Presence
    , leaves : List Presence
    }



-- Decoders


{-| Decode the metas for a Presence.

Only you will know what `meta` information you are storing, so you will need to
provide your own decoder.

-}
decodeMetas : JD.Decoder a -> List Value -> List a
decodeMetas customDecoder metas =
    metas
        |> List.filterMap
            (decodeMeta customDecoder)


decodeMeta : JD.Decoder a -> Value -> Maybe a
decodeMeta customDecoder meta =
    meta
        |> JD.decodeValue
            customDecoder
        |> Result.toMaybe


decodePresence : JD.Value -> Presence
decodePresence value =
    value
        |> JD.decodeValue
            presenceDecoder
        |> Result.toMaybe
        |> Maybe.withDefault
            { id = ""
            , metas = []
            }


presenceDecoder : JD.Decoder Presence
presenceDecoder =
    JD.succeed
        Presence
        |> andMap (JD.field "id" JD.string)
        |> andMap (JD.field "metas" (JD.list JD.value))


decodeDiff : JE.Value -> PresenceDiff
decodeDiff value =
    value
        |> JD.decodeValue
            diffDecoder
        |> Result.toMaybe
        |> Maybe.withDefault
            { joins = []
            , leaves = []
            }


diffDecoder : JD.Decoder PresenceDiff
diffDecoder =
    JD.succeed
        PresenceDiff
        |> andMap (JD.field "joins" listDecoder)
        |> andMap (JD.field "leaves" listDecoder)


decodeState : Value -> PresenceState
decodeState value =
    value
        |> JD.decodeValue
            stateDecoder
        |> Result.toMaybe
        |> Maybe.withDefault
            []


stateDecoder : JD.Decoder (List Presence)
stateDecoder =
    JD.succeed
        identity
        |> andMap (JD.field "list" listDecoder)


listDecoder : JD.Decoder (List Presence)
listDecoder =
    JD.list presenceDecoder
