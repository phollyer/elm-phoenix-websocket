module Internal.SocketInfo exposing
    ( Info
    , init
    , updateConnectionState
    , updateEndPointURL
    , updateHasLogger
    , updateIsConnected
    , updateMakeRef
    , updateProtocol
    )


type alias Info =
    { connectionState : String
    , endPointURL : String
    , hasLogger : Maybe Bool
    , isConnected : Bool
    , makeRef : String
    , protocol : String
    }


init : Info
init =
    { connectionState = ""
    , endPointURL = ""
    , hasLogger = Nothing
    , isConnected = False
    , makeRef = ""
    , protocol = ""
    }


updateConnectionState : String -> Info -> Info
updateConnectionState state info =
    { info | connectionState = state }


updateEndPointURL : String -> Info -> Info
updateEndPointURL endPointURL socketInfo =
    { socketInfo
        | endPointURL = endPointURL
    }


updateHasLogger : Maybe Bool -> Info -> Info
updateHasLogger hasLogger socketInfo =
    { socketInfo
        | hasLogger = hasLogger
    }


updateIsConnected : Bool -> Info -> Info
updateIsConnected isConnected socketInfo =
    { socketInfo
        | isConnected = isConnected
    }


updateMakeRef : String -> Info -> Info
updateMakeRef ref socketInfo =
    { socketInfo
        | makeRef = ref
    }


updateProtocol : String -> Info -> Info
updateProtocol protocol socketInfo =
    { socketInfo
        | protocol = protocol
    }
