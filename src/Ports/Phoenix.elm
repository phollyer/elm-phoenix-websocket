port module Ports.Phoenix exposing
    ( channelReceiver
    , phoenixSend
    , presenceReceiver
    , socketReceiver
    )

import Json.Encode as JE


type alias PackageOut =
    { event : String
    , payload : JE.Value
    }


type alias SocketPackage =
    { event : String
    , payload : JE.Value
    }


type alias ChannelPackage =
    { topic : String
    , event : String
    , payload : JE.Value
    }


port phoenixSend : PackageOut -> Cmd msg


port socketReceiver : (SocketPackage -> msg) -> Sub msg


port channelReceiver : (ChannelPackage -> msg) -> Sub msg


port presenceReceiver : (ChannelPackage -> msg) -> Sub msg
