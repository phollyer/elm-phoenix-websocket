module Internal.Socket exposing
    ( Socket
    , addOptions
    , connect
    , connectionState
    , currentState
    , disconnect
    , disconnectReason
    , endPointURL
    , init
    , isConnected
    , protocol
    , reconnect
    , setDisconnectReason
    , setInfo
    , setOptions
    , setParams
    , setReconnect
    , setState
    )

import Internal.Presence exposing (state)
import Json.Encode exposing (Value)
import Phoenix.Socket as Socket exposing (ConnectOption(..))



{- Model -}


type Socket state msg
    = Socket
        { options : List ConnectOption
        , params : Maybe Value
        , disconnectReason : Maybe String
        , reconnect : Bool
        , info : Info
        , state : state
        , portOut : { msg : String, payload : Value } -> Cmd msg
        }


init : ({ msg : String, payload : Value } -> Cmd msg) -> state -> Socket state msg
init portOut state =
    Socket
        { options = []
        , params = Nothing
        , disconnectReason = Nothing
        , reconnect = False
        , info =
            { connectionState = ""
            , endPointURL = ""
            , isConnected = False
            , makeRef = ""
            , protocol = ""
            }
        , state = state
        , portOut = portOut
        }



{- Types -}


type alias Info =
    { connectionState : String
    , endPointURL : String
    , isConnected : Bool
    , makeRef : String
    , protocol : String
    }



{- Actions -}


connect : Socket state msg -> Cmd msg
connect (Socket { options, params, portOut }) =
    Socket.connect options params portOut


disconnect : Maybe Int -> Socket state msg -> Cmd msg
disconnect code (Socket { portOut }) =
    Socket.disconnect code portOut



{- Queries -}


currentState : Socket state msg -> state
currentState (Socket { state }) =
    state


disconnectReason : Socket state msg -> Maybe String
disconnectReason (Socket socket) =
    socket.disconnectReason


reconnect : Socket state msg -> Bool
reconnect (Socket socket) =
    socket.reconnect


connectionState : Socket state msg -> String
connectionState (Socket { info }) =
    info.connectionState


endPointURL : Socket state msg -> String
endPointURL (Socket { info }) =
    info.endPointURL


isConnected : Socket state msg -> Bool
isConnected (Socket { info }) =
    info.isConnected


protocol : Socket state msg -> String
protocol (Socket { info }) =
    info.protocol



{- Setters -}


addOptions : List ConnectOption -> Socket state msg -> Socket state msg
addOptions options (Socket socket) =
    Socket { socket | options = List.append options socket.options }


setOptions : List ConnectOption -> Socket state msg -> Socket state msg
setOptions options (Socket socket) =
    Socket { socket | options = options }


setParams : Maybe Value -> Socket state msg -> Socket state msg
setParams maybeParams (Socket socket) =
    Socket { socket | params = maybeParams }


setDisconnectReason : Maybe String -> Socket state msg -> Socket state msg
setDisconnectReason maybeReason (Socket socket) =
    Socket { socket | disconnectReason = maybeReason }


setInfo : Info -> Socket state msg -> Socket state msg
setInfo info_ (Socket socket) =
    Socket { socket | info = info_ }


setReconnect : Bool -> Socket state msg -> Socket state msg
setReconnect reconnect_ (Socket socket) =
    Socket { socket | reconnect = reconnect_ }


setState : state -> Socket state msg -> Socket state msg
setState state (Socket socket) =
    Socket { socket | state = state }
