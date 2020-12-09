module Internal.Channel exposing
    ( Channel
    , addJoin
    , addQueuedJoin
    , allJoined
    , allQueuedLeaves
    , channelQueued
    , dropJoin
    , dropLeave
    , dropQueuedJoin
    , init
    , isJoined
    , join
    , joinIsQueued
    , joined
    , leave
    , queueLeave
    , queuedChannels
    , reset
    , setJoinConfig
    , setLeaveConfig
    , updateJoins
    , updateQueuedJoins
    , updateQueuedLeaves
    )

import Dict exposing (Dict)
import Json.Encode exposing (Value)
import Phoenix.Channel as Channel exposing (JoinConfig, LeaveConfig, PortOut, Topic, joinConfig)
import Set exposing (Set)


type Channel msg
    = Channel
        { joinConfigs : Dict Topic JoinConfig
        , leaveConfigs : Dict Topic LeaveConfig
        , queuedJoins : Set Topic
        , joinedChannels : Set Topic
        , queuedLeaves : Set Topic
        , portOut : { msg : String, payload : Value } -> Cmd msg
        }


init : ({ msg : String, payload : Value } -> Cmd msg) -> Channel msg
init portOut =
    Channel
        { joinConfigs = Dict.empty
        , leaveConfigs = Dict.empty
        , queuedJoins = Set.empty
        , joinedChannels = Set.empty
        , queuedLeaves = Set.empty
        , portOut = portOut
        }


reset : Channel msg -> Channel msg
reset (Channel { portOut }) =
    init portOut


defaultJoinConfig : Topic -> JoinConfig
defaultJoinConfig topic =
    { joinConfig | topic = topic }


defaultLeaveConfig : Topic -> LeaveConfig
defaultLeaveConfig topic =
    { topic = topic
    , timeout = Nothing
    }


addQueuedJoin : Topic -> Channel msg -> Channel msg
addQueuedJoin topic (Channel channel) =
    Channel { channel | queuedJoins = Set.insert topic channel.queuedJoins }


joinIsQueued : Topic -> Channel msg -> Bool
joinIsQueued topic (Channel { queuedJoins }) =
    Set.member topic queuedJoins


queuedChannels : Channel msg -> List Topic
queuedChannels (Channel { queuedJoins }) =
    Set.toList queuedJoins


channelQueued : Topic -> Channel msg -> Bool
channelQueued topic (Channel { queuedJoins }) =
    Set.member topic queuedJoins


updateQueuedJoins : Set Topic -> Channel msg -> Channel msg
updateQueuedJoins topics (Channel channel) =
    Channel { channel | queuedJoins = topics }


dropQueuedJoin : Topic -> Channel msg -> Channel msg
dropQueuedJoin topic (Channel channel) =
    Channel { channel | queuedJoins = Set.remove topic channel.queuedJoins }


setJoinConfig : JoinConfig -> Channel msg -> Channel msg
setJoinConfig joinConfig (Channel channel) =
    Channel { channel | joinConfigs = Dict.insert joinConfig.topic joinConfig channel.joinConfigs }


join : Topic -> Channel msg -> ( Channel msg, Cmd msg )
join topic (Channel channel) =
    case Dict.get topic channel.joinConfigs of
        Just joinConfig ->
            ( addQueuedJoin topic (Channel channel)
            , Channel.join joinConfig channel.portOut
            )

        Nothing ->
            setJoinConfig (defaultJoinConfig topic) (Channel channel)
                |> join topic


joined : Topic -> Channel msg -> Bool
joined topic (Channel { joinedChannels }) =
    Set.member topic joinedChannels


addJoin : Topic -> Channel msg -> Channel msg
addJoin topic (Channel channel) =
    Channel { channel | joinedChannels = Set.insert topic channel.joinedChannels }


allJoined : Channel msg -> List Topic
allJoined (Channel { joinedChannels }) =
    Set.toList joinedChannels


isJoined : Topic -> Channel msg -> Bool
isJoined topic (Channel { joinedChannels }) =
    Set.member topic joinedChannels


dropJoin : Topic -> Channel msg -> Channel msg
dropJoin topic (Channel channel) =
    Channel { channel | joinedChannels = Set.remove topic channel.joinedChannels }


updateJoins : Set Topic -> Channel msg -> Channel msg
updateJoins topics (Channel channel) =
    Channel { channel | joinedChannels = topics }


setLeaveConfig : LeaveConfig -> Channel msg -> Channel msg
setLeaveConfig config (Channel channel) =
    Channel { channel | leaveConfigs = Dict.insert config.topic config channel.leaveConfigs }


leave : Topic -> Channel msg -> ( Channel msg, Cmd msg )
leave topic (Channel channel) =
    case Dict.get topic channel.leaveConfigs of
        Just config ->
            ( queueLeave topic (Channel channel)
            , Channel.leave config channel.portOut
            )

        Nothing ->
            setLeaveConfig (defaultLeaveConfig topic) (Channel channel)
                |> leave topic


queueLeave : Topic -> Channel msg -> Channel msg
queueLeave topic (Channel channel) =
    Channel { channel | queuedLeaves = Set.insert topic channel.queuedLeaves }


dropLeave : Topic -> Channel msg -> Channel msg
dropLeave topic (Channel channel) =
    Channel { channel | queuedLeaves = Set.remove topic channel.queuedLeaves }


allQueuedLeaves : Channel msg -> List Topic
allQueuedLeaves (Channel { queuedLeaves }) =
    Set.toList queuedLeaves


updateQueuedLeaves : Set Topic -> Channel msg -> Channel msg
updateQueuedLeaves topics (Channel channel) =
    Channel { channel | queuedLeaves = topics }
