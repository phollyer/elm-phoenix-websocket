port module Ports exposing
    ( channelReceiver
    , config
    , phoenixSend
    , presenceReceiver
    , socketReceiver
    )

{-| Ports to be used by the Elm-Phoenix-Websocket package.

Copy this module into your Elm `src`, or copy the functions into an existing
`port` module.

-}

import Json.Encode exposing (Value)


{-| Helper function for use with the Phoenix module.

    import Phoenix
    import Ports.Phoenix as Ports

    Phoenix.init Ports.config []

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

-}
port phoenixSend : { msg : String, payload : Value } -> Cmd msg


{-| Receive messages from the socket.

This is passed in as parameter to the `subscriptions` function in the Phoenix
and Socket modules.

-}
port socketReceiver : ({ msg : String, payload : Value } -> msg) -> Sub msg


{-| Receive messages from channels.

This is passed in as parameter to the `subscriptions` function in the Phoenix
and Channel modules.

-}
port channelReceiver : ({ topic : String, msg : String, payload : Value } -> msg) -> Sub msg


{-| Receive presence messages.

This is passed in as parameter to the `subscriptions` function in the Phoenix
and Presence modules.

-}
port presenceReceiver : ({ topic : String, msg : String, payload : Value } -> msg) -> Sub msg
