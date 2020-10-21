module Example exposing
    ( Action(..)
    , Example(..)
    , fromString
    , toAction
    , toString
    )

{- Model -}


type Action
    = Anything
    | Connect
    | Disconnect
    | Join
    | Leave
    | On
    | Off
    | Send


type Example
    = SimpleConnect Action
    | ConnectWithGoodParams Action
    | ConnectWithBadParams Action
    | ManageSocketHeartbeat Action
    | ManageChannelMessages Action
    | ManagePresenceMessages Action


fromString : String -> Example
fromString example =
    case example of
        "SimpleConnect" ->
            SimpleConnect Anything

        "ConnectWithGoodParams" ->
            ConnectWithGoodParams Anything

        "ConnectWithBadParams" ->
            ConnectWithBadParams Anything

        "ManageSocketHeartbeat" ->
            ManageSocketHeartbeat Anything

        "ManageChannelMessages" ->
            ManageChannelMessages Anything

        "ManagePresenceMessages" ->
            ManagePresenceMessages Anything

        _ ->
            SimpleConnect Anything


toString : Example -> String
toString example =
    case example of
        SimpleConnect _ ->
            "Simple Connect"

        ConnectWithGoodParams _ ->
            "Connect with Good Params"

        ConnectWithBadParams _ ->
            "Connect with Bad Params"

        ManageSocketHeartbeat _ ->
            "Manage the Socket Heartbeat"

        ManageChannelMessages _ ->
            "Manage Channel Messages"

        ManagePresenceMessages _ ->
            "Manage Presence Messages"


toAction : Example -> Action
toAction example =
    case example of
        SimpleConnect action ->
            action

        ConnectWithGoodParams action ->
            action

        ConnectWithBadParams action ->
            action

        ManageSocketHeartbeat action ->
            action

        ManageChannelMessages action ->
            action

        ManagePresenceMessages action ->
            action
