module Example exposing
    ( Action(..), Example(..)
    , fromString, toString, toAction, toFunc
    )

{-|

@docs Action, Example


# Helpers

@docs fromString, toString, toAction, toFunc

-}

{- Model -}


{-| The actions that can be carried out by the user when interacting with an
Example
-}
type Action
    = Anything
    | Connect
    | Disconnect
    | Join
    | Leave
    | On
    | Off
    | Send
    | Push


{-| -}
type Example
    = SimpleConnect Action
    | ConnectWithGoodParams Action
    | ConnectWithBadParams Action
    | ManageSocketHeartbeat Action
    | ManageChannelMessages Action
    | ManagePresenceMessages Action
    | SimpleJoinAndLeave Action
    | JoinWithGoodParams Action
    | JoinWithBadParams Action
    | JoinMultipleChannels Action
    | PushOneEvent Action
    | PushMultipleEvents Action
    | ReceiveEvents Action



{- Helpers -}


{-| -}
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

        "SimpleJoinAndLeave" ->
            SimpleJoinAndLeave Anything

        "JoinWithGoodParams" ->
            JoinWithGoodParams Anything

        "JoinWithBadParams" ->
            JoinWithBadParams Anything

        "JoinMultipleChannels" ->
            JoinMultipleChannels Anything

        "PushOneEvent" ->
            PushOneEvent Anything

        "PushMultipleEvents" ->
            PushMultipleEvents Anything

        "ReceiveEvents" ->
            ReceiveEvents Anything

        _ ->
            SimpleConnect Anything


{-| -}
toString : (Action -> Example) -> String
toString example =
    case example Anything of
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

        SimpleJoinAndLeave _ ->
            "Simple Join And Leave"

        JoinWithGoodParams _ ->
            "Join With Good Params"

        JoinWithBadParams _ ->
            "Join With Bad Params"

        JoinMultipleChannels _ ->
            "Join Multiple Channels"

        PushOneEvent _ ->
            "Push One Event"

        PushMultipleEvents _ ->
            "Push Multiple Events"

        ReceiveEvents _ ->
            "Receive Events"


{-| -}
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

        SimpleJoinAndLeave action ->
            action

        JoinWithGoodParams action ->
            action

        JoinWithBadParams action ->
            action

        JoinMultipleChannels action ->
            action

        PushOneEvent action ->
            action

        PushMultipleEvents action ->
            action

        ReceiveEvents action ->
            action


{-| -}
toFunc : Example -> (Action -> Example)
toFunc example =
    case example of
        SimpleConnect _ ->
            SimpleConnect

        ConnectWithGoodParams _ ->
            ConnectWithGoodParams

        ConnectWithBadParams _ ->
            ConnectWithBadParams

        ManageSocketHeartbeat _ ->
            ManageSocketHeartbeat

        ManageChannelMessages _ ->
            ManageChannelMessages

        ManagePresenceMessages _ ->
            ManagePresenceMessages

        SimpleJoinAndLeave _ ->
            SimpleJoinAndLeave

        JoinWithGoodParams _ ->
            JoinWithGoodParams

        JoinWithBadParams _ ->
            JoinWithBadParams

        JoinMultipleChannels _ ->
            JoinMultipleChannels

        PushOneEvent _ ->
            PushOneEvent

        PushMultipleEvents _ ->
            PushMultipleEvents

        ReceiveEvents _ ->
            ReceiveEvents
