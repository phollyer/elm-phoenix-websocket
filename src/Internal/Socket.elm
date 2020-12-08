module Internal.Socket exposing
    ( Socket
    , addOptions
    , connect
    , connectionState
    , disconnect
    , disconnectReason
    , endPointURL
    , init
    , isConnected
    , protocol
    , reconnect
    , reset
    , setDisconnectReason
    , setInfo
    , setOptions
    , setParams
    , setReconnect
    )

import Internal.SocketInfo as Info exposing (Info)
import Json.Encode as JE exposing (Value)
import Phoenix.Socket as Socket exposing (ConnectOption(..))


type Socket msg
    = Socket
        { options : List ConnectOption
        , params : Maybe Value
        , disconnectReason : Maybe String
        , reconnect : Bool
        , info : Info
        , portOut : { msg : String, payload : Value } -> Cmd msg
        }


init : ({ msg : String, payload : Value } -> Cmd msg) -> Socket msg
init portOut =
    Socket
        { options = []
        , params = Nothing
        , disconnectReason = Nothing
        , reconnect = False
        , info = Info.init
        , portOut = portOut
        }


reset : Socket msg -> Socket msg
reset (Socket { portOut }) =
    init portOut


addOptions : List ConnectOption -> Socket msg -> Socket msg
addOptions options (Socket socket) =
    Socket { socket | options = List.append options socket.options }


setOptions : List ConnectOption -> Socket msg -> Socket msg
setOptions options (Socket socket) =
    Socket { socket | options = options }


setParams : Maybe Value -> Socket msg -> Socket msg
setParams maybeParams (Socket socket) =
    Socket { socket | params = maybeParams }


connect : Socket msg -> Cmd msg
connect (Socket { options, params, portOut }) =
    Socket.connect options params portOut


disconnect : Maybe Int -> Socket msg -> Cmd msg
disconnect code (Socket { portOut }) =
    Socket.disconnect code portOut


disconnectReason : Socket msg -> Maybe String
disconnectReason (Socket socket) =
    socket.disconnectReason


reconnect : Socket msg -> Bool
reconnect (Socket socket) =
    socket.reconnect


setDisconnectReason : Maybe String -> Socket msg -> Socket msg
setDisconnectReason maybeReason (Socket socket) =
    Socket { socket | disconnectReason = maybeReason }


setReconnect : Bool -> Socket msg -> Socket msg
setReconnect reconnect_ (Socket socket) =
    Socket { socket | reconnect = reconnect_ }



{- Info -}


setInfo : Info -> Socket msg -> Socket msg
setInfo info_ (Socket socket) =
    Socket { socket | info = info_ }


connectionState : Socket msg -> String
connectionState (Socket { info }) =
    info.connectionState


endPointURL : Socket msg -> String
endPointURL (Socket { info }) =
    info.endPointURL


isConnected : Socket msg -> Bool
isConnected (Socket { info }) =
    info.isConnected


protocol : Socket msg -> String
protocol (Socket { info }) =
    info.protocol
