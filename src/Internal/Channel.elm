module Internal.Channel exposing
    ( Channel
    , allJoined
    , allQueuedJoins
    , allQueuedLeaves
    , dropJoin
    , dropLeave
    , dropQueuedJoin
    , init
    , isJoined
    , join
    , joinIsQueued
    , joined
    , leave
    , queueJoin
    , queueLeave
    , setJoinConfig
    , setLeaveConfig
    , updateJoins
    , updateQueuedJoins
    , updateQueuedLeaves
    )

import Internal.Config as Config exposing (Config)
import Internal.Unique as Unique exposing (Unique)
import Json.Encode exposing (Value)
import Phoenix.Channel as Channel exposing (JoinConfig, LeaveConfig, Topic, joinConfig)



{- Model -}


type Channel msg
    = Channel
        { joinConfigs : Config Topic JoinConfig
        , leaveConfigs : Config Topic LeaveConfig
        , queuedJoins : Unique Topic
        , joinedChannels : Unique Topic
        , queuedLeaves : Unique Topic
        , portOut : { msg : String, payload : Value } -> Cmd msg
        }


init : ({ msg : String, payload : Value } -> Cmd msg) -> Channel msg
init portOut =
    Channel
        { joinConfigs = Config.empty
        , leaveConfigs = Config.empty
        , queuedJoins = Unique.empty
        , joinedChannels = Unique.empty
        , queuedLeaves = Unique.empty
        , portOut = portOut
        }



{- Actions -}


join : Topic -> Channel msg -> ( Channel msg, Cmd msg )
join topic ((Channel { joinConfigs, portOut }) as channel) =
    case Config.get topic joinConfigs of
        Just joinConfig ->
            ( queueJoin topic channel
            , Channel.join joinConfig portOut
            )

        Nothing ->
            setJoinConfig (defaultJoinConfig topic) channel
                |> join topic


leave : Topic -> Channel msg -> ( Channel msg, Cmd msg )
leave topic ((Channel { leaveConfigs, portOut }) as channel) =
    case Config.get topic leaveConfigs of
        Just config ->
            ( queueLeave topic channel
            , Channel.leave config portOut
            )

        Nothing ->
            setLeaveConfig (defaultLeaveConfig topic) channel
                |> leave topic



{- Predicates -}


joinIsQueued : Topic -> Channel msg -> Bool
joinIsQueued topic (Channel { queuedJoins }) =
    Unique.exists topic queuedJoins


isJoined : Topic -> Channel msg -> Bool
isJoined topic (Channel { joinedChannels }) =
    Unique.exists topic joinedChannels



{- Queries -}


allJoined : Channel msg -> List Topic
allJoined (Channel { joinedChannels }) =
    Unique.toList joinedChannels


allQueuedJoins : Channel msg -> List Topic
allQueuedJoins (Channel { queuedJoins }) =
    Unique.toList queuedJoins


allQueuedLeaves : Channel msg -> List Topic
allQueuedLeaves (Channel { queuedLeaves }) =
    Unique.toList queuedLeaves



{- Setters -}


joined : Topic -> Channel msg -> Channel msg
joined topic (Channel ({ joinedChannels, queuedJoins } as channel)) =
    Channel
        { channel
            | joinedChannels = Unique.insert topic joinedChannels
            , queuedJoins = Unique.remove topic queuedJoins
        }


queueJoin : Topic -> Channel msg -> Channel msg
queueJoin topic (Channel ({ queuedJoins } as channel)) =
    Channel { channel | queuedJoins = Unique.insert topic queuedJoins }


queueLeave : Topic -> Channel msg -> Channel msg
queueLeave topic (Channel ({ queuedLeaves } as channel)) =
    Channel { channel | queuedLeaves = Unique.insert topic queuedLeaves }


setJoinConfig : JoinConfig -> Channel msg -> Channel msg
setJoinConfig ({ topic } as config) (Channel ({ joinConfigs } as channel)) =
    Channel { channel | joinConfigs = Config.insert topic config joinConfigs }


setLeaveConfig : LeaveConfig -> Channel msg -> Channel msg
setLeaveConfig ({ topic } as config) (Channel ({ leaveConfigs } as channel)) =
    Channel { channel | leaveConfigs = Config.insert topic config leaveConfigs }


updateJoins : Unique Topic -> Channel msg -> Channel msg
updateJoins topics (Channel channel) =
    Channel { channel | joinedChannels = topics }


updateQueuedJoins : Unique Topic -> Channel msg -> Channel msg
updateQueuedJoins topics (Channel channel) =
    Channel { channel | queuedJoins = topics }


updateQueuedLeaves : Unique Topic -> Channel msg -> Channel msg
updateQueuedLeaves topics (Channel channel) =
    Channel { channel | queuedLeaves = topics }



{- Delete -}


dropJoin : Topic -> Channel msg -> Channel msg
dropJoin topic (Channel ({ joinedChannels } as channel)) =
    Channel { channel | joinedChannels = Unique.remove topic joinedChannels }


dropQueuedJoin : Topic -> Channel msg -> Channel msg
dropQueuedJoin topic (Channel ({ queuedJoins } as channel)) =
    Channel { channel | queuedJoins = Unique.remove topic queuedJoins }


dropLeave : Topic -> Channel msg -> Channel msg
dropLeave topic (Channel ({ queuedLeaves } as channel)) =
    Channel { channel | queuedLeaves = Unique.remove topic queuedLeaves }



{- Helpers -}


defaultJoinConfig : Topic -> JoinConfig
defaultJoinConfig topic =
    { joinConfig | topic = topic }


defaultLeaveConfig : Topic -> LeaveConfig
defaultLeaveConfig topic =
    { topic = topic
    , timeout = Nothing
    }
