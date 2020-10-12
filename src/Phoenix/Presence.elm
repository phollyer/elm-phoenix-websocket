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


{-| A type alias representing a
[Presence](https://hexdocs.pm/phoenix/1.5.3/Phoenix.Presence.html#content).
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

`InvalidMsg` means that a msg has been received from the accompanying JS
that cannot be handled. This should not happen, if it does, please raise an
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
            case decodePresence payload of
                Ok presence ->
                    toMsg (Join topic presence)

                Result.Err error ->
                    toMsg (DecoderError (JD.errorToString error))

        "Leave" ->
            case decodePresence payload of
                Ok presence ->
                    toMsg (Leave topic presence)

                Result.Err error ->
                    toMsg (DecoderError (JD.errorToString error))

        "State" ->
            case decodeState payload of
                Ok state ->
                    toMsg (State topic state)

                Result.Err error ->
                    toMsg (DecoderError (JD.errorToString error))

        "Diff" ->
            case decodeDiff payload of
                Ok diff ->
                    toMsg (Diff topic diff)

                Result.Err error ->
                    toMsg (DecoderError (JD.errorToString error))

        _ ->
            toMsg (InvalidMsg topic msg)



{- Decoders -}


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
        |> andMap (JD.field "user" JD.value)
        |> andMap (JD.field "presence" JD.value)


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


decodeState : Value -> Result JD.Error (List Presence)
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
