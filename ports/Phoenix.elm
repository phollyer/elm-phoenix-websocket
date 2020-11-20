port module Ports.Phoenix exposing
    ( channelReceiver
    , config
    , phoenixSend
    , presenceReceiver
    , socketReceiver
    )

{-| Ports to be used by the Elm-Phoenix-Websocket package.

Copy this module into your Elm `src`, or copy the functions into an existing
`port` module.

If you are using the Phoenix module, only the `config` function needs to be
exposed.

-}

import Json.Encode exposing (Value)


{-| Helper function for use with the Phoenix module.

    import Phoenix
    import Ports.Phoenix as Ports

    Phoenix.init Ports.config

-}
config =
    { phoenixSend = phoenixSend
    , socketReceiver = socketReceiver
    , channelReceiver = channelReceiver
    , presenceReceiver = presenceReceiver
    }


{-| Send messages out to the accompanying JS file.

This function will be passed in as a parameter to various Socket and Channel
functions. The package docs show you where this is required, and the Elm
compiler will help too.

If you are using the Phoenix module, this is taken care of for you.

-}
port phoenixSend : { msg : String, payload : Value } -> Cmd msg


{-| Receive messages from the socket.

This is passed in as parameter to the `subscriptions` function in the Socket
module.

If you are using the Phoenix module, this is taken care of for you.

-}
port socketReceiver : ({ msg : String, payload : Value } -> msg) -> Sub msg


{-| Receive messages from channels.

This is passed in as parameter to the `subscriptions` function in the Channel
module.

If you are using the Phoenix module, this is taken care of for you.

-}
port channelReceiver : ({ topic : String, msg : String, payload : Value } -> msg) -> Sub msg


{-| Receive presence messages.

This is passed in as parameter to the `subscriptions` function in the Presence
module.

If you are using the Phoenix module, this is taken care of for you.

-}
port presenceReceiver : ({ topic : String, msg : String, payload : Value } -> msg) -> Sub msg
