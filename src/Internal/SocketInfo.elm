module Internal.SocketInfo exposing
    ( Info
    , init
    )


type alias Info =
    { connectionState : String
    , endPointURL : String
    , isConnected : Bool
    , makeRef : String
    , protocol : String
    }


init : Info
init =
    { connectionState = ""
    , endPointURL = ""
    , isConnected = False
    , makeRef = ""
    , protocol = ""
    }
