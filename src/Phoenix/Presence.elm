module Phoenix.Presence exposing
    ( PortIn, Topic, Presence, PresenceState, PresenceDiff, Msg(..), subscriptions
    , decodeMetas
    )

{-| Use this module to work directly with Phoenix
[Presence](https://hexdocs.pm/phoenix/1.5.3/Phoenix.Presence.html#content).

Before you can receive presence information, you first need to connect to a
[socket](Socket) and join a [channel](Channel). Once this is done, you can then
[subscribe](#subscribe) to start receiving [Presence](#Presence) data as your
users come and go.

If you are new to Phoenix Presence, you will need to setup your backend
channel as described
[here](https://hexdocs.pm/phoenix/1.5.3/Phoenix.Presence.html#content).
Currently, only the `metas` key is supported.
]

@docs PortIn, Topic, Presence, PresenceState, PresenceDiff, Msg, subscriptions


# Decoders

@docs decodeMetas

-}

import Json.Decode as JD exposing (Value)
import Json.Decode.Extra exposing (andMap)
import Json.Encode as JE


{-| A type alias representing the `port` function required to communicate with
the accompanying JS.

You will find this `port` function in the
[Port](https://github.com/phollyer/elm-phoenix-websocket/tree/master/src/Ports)
module.

-}
type alias PortIn msg =
    ({ topic : String
     , msg : String
     , payload : JE.Value
     }
     -> msg
    )
    -> Sub msg


{-| A type alias representing the channel topic. Use this to identify the
channel a [Msg](#Msg) relates to.
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


{-| All of the presence msgs that can come from the channel.

If you are using more than one channel, then you can check `Topic` to determine
which channel the [Msg](#Msg) relates to. If you are only using a single
channel, you can ignore `Topic`.

`InvalidMsg` means that a msg has been received from the accompanying JS
that cannot be handled. This should not happen, if it does, please raise an
[issue](https://github.com/phollyer/elm-phoenix-websocket/issues).

-}
type Msg
    = Join Topic (Result JD.Error Presence)
    | Leave Topic (Result JD.Error Presence)
    | State Topic (Result JD.Error PresenceState)
    | Diff Topic (Result JD.Error PresenceDiff)
    | InvalidMsg Topic String


{-| Subscribe to receive incoming presence msgs.

    import Phoenix.Presence
    import Port

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
            decodePresence payload
                |> Join topic
                |> toMsg

        "Leave" ->
            decodePresence payload
                |> Leave topic
                |> toMsg

        "State" ->
            decodeState payload
                |> State topic
                |> toMsg

        "Diff" ->
            decodeDiff payload
                |> Diff topic
                |> toMsg

        _ ->
            toMsg (InvalidMsg topic msg)



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


decodePresence : JD.Value -> Result JD.Error Presence
decodePresence payload =
    JD.decodeValue
        presenceDecoder
        payload


presenceDecoder : JD.Decoder Presence
presenceDecoder =
    JD.succeed
        Presence
        |> andMap (JD.field "id" JD.string)
        |> andMap (JD.field "metas" (JD.list JD.value))


decodeDiff : JE.Value -> Result JD.Error PresenceDiff
decodeDiff payload =
    JD.decodeValue
        diffDecoder
        payload


diffDecoder : JD.Decoder PresenceDiff
diffDecoder =
    JD.succeed
        PresenceDiff
        |> andMap (JD.field "joins" listDecoder)
        |> andMap (JD.field "leaves" listDecoder)


decodeState : Value -> Result JD.Error PresenceState
decodeState payload =
    JD.decodeValue
        stateDecoder
        payload


stateDecoder : JD.Decoder (List Presence)
stateDecoder =
    JD.succeed
        identity
        |> andMap (JD.field "list" listDecoder)


listDecoder : JD.Decoder (List Presence)
listDecoder =
    JD.list presenceDecoder
