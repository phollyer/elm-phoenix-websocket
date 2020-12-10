module Internal.Push exposing
    ( Push
    , addTimeout
    , allQueued
    , allTimeouts
    , dropQueued
    , dropQueuedByRef
    , dropSent
    , dropTimeout
    , filter
    , hasTimedOut
    , init
    , isQueued
    , map
    , maybeRetryStrategy
    , partitionTimeouts
    , preFlight
    , queued
    , reset
    , resetTimeoutTick
    , send
    , sendAll
    , sendByTopic
    , setTimeouts
    , timeoutCountdown
    , timeoutTick
    , timeoutsExist
    )

import Internal.Config as Config exposing (Config)
import Json.Encode exposing (Value)
import Phoenix.Channel as Channel exposing (Event, Payload, Topic)



{- Model -}


type Push r msg
    = Push
        { count : Int
        , queue : Config Ref (InternalConfig r)
        , sent : Config Ref (InternalConfig r)
        , timeouts : Config Ref (InternalConfig r)
        , portOut : { msg : String, payload : Value } -> Cmd msg
        }


type alias Ref =
    String


type alias InternalConfig r =
    { pushConfig : PushConfig r
    , ref : Ref
    , retryStrategy : r
    , timeoutTick : Int
    }


type alias PushConfig r =
    { topic : Topic
    , event : Event
    , payload : Payload
    , timeout : Maybe Int
    , retryStrategy : r
    , ref : Maybe Ref
    }


init : ({ msg : String, payload : Value } -> Cmd msg) -> Push r msg
init portOut =
    Push
        { count = 0
        , queue = Config.empty
        , sent = Config.empty
        , timeouts = Config.empty
        , portOut = portOut
        }


reset : Push r msg -> Push r msg
reset (Push push) =
    init push.portOut



{- Actions -}


preFlight : PushConfig r -> Push r msg -> ( Push r msg, String )
preFlight ({ ref, retryStrategy } as pushConfig) (Push ({ count, queue } as push)) =
    let
        ( ref_, newCount ) =
            case ref of
                Nothing ->
                    ( count + 1 |> String.fromInt
                    , count + 1
                    )

                Just r ->
                    ( r, count )

        internalConfig =
            { pushConfig = { pushConfig | ref = Just ref_ }
            , ref = ref_
            , retryStrategy = retryStrategy
            , timeoutTick = 0
            }
    in
    ( Push
        { push
            | count = newCount
            , queue = Config.insert ref_ internalConfig queue
        }
    , ref_
    )


send : String -> Push r msg -> ( Push r msg, Cmd msg )
send ref (Push push) =
    case Config.get ref push.queue of
        Nothing ->
            ( Push push, Cmd.none )

        Just internalConfig ->
            ( Push
                { push
                    | sent = Config.insert ref internalConfig push.sent
                    , queue = Config.remove ref push.queue
                    , timeouts = Config.remove ref push.timeouts
                }
            , Channel.push internalConfig.pushConfig push.portOut
            )


sendByTopic : Topic -> Push r msg -> ( Push r msg, Cmd msg )
sendByTopic topic (Push ({ queue } as push)) =
    let
        ( toGo, toKeep ) =
            partition
                (\_ { pushConfig } -> pushConfig.topic == topic)
                queue
    in
    Push { push | queue = toKeep }
        |> sendAll toGo


sendAll : Config Ref (InternalConfig r) -> Push r msg -> ( Push r msg, Cmd msg )
sendAll config push =
    Config.toList config
        |> List.map Tuple.second
        |> List.foldl batchPush ( push, Cmd.none )


batchPush : InternalConfig r -> ( Push r msg, Cmd msg ) -> ( Push r msg, Cmd msg )
batchPush ({ ref, pushConfig } as internalConfig) ( Push ({ portOut } as push), cmd ) =
    ( Push { push | sent = Config.insert ref internalConfig push.sent }
    , Cmd.batch
        [ cmd, Channel.push pushConfig portOut ]
    )



{- Predicates -}


hasTimedOut : (PushConfig r -> Bool) -> Push r msg -> Bool
hasTimedOut compareFunc (Push { timeouts }) =
    compareWith compareFunc timeouts


isQueued : (PushConfig r -> Bool) -> Push r msg -> Bool
isQueued compareFunc (Push { queue }) =
    compareWith compareFunc queue


compareWith : (PushConfig r -> Bool) -> Config String (InternalConfig r) -> Bool
compareWith compareFunc config =
    partition (\_ { pushConfig } -> compareFunc pushConfig) config
        |> matchFound


matchFound : ( Config String (InternalConfig r), Config String (InternalConfig r) ) -> Bool
matchFound =
    Tuple.first >> Config.exists


timeoutsExist : Push r msg -> Bool
timeoutsExist (Push { timeouts }) =
    Config.exists timeouts



{- Queries -}


allTimeouts : Push r msg -> Config String (List (PushConfig r))
allTimeouts (Push { timeouts }) =
    foldl allPushConfigs Config.empty timeouts


allQueued : Push r msg -> Config Topic (List (PushConfig r))
allQueued (Push { queue }) =
    foldl allPushConfigs Config.empty queue


allPushConfigs : InternalConfig r -> Config String (List (PushConfig r)) -> Config String (List (PushConfig r))
allPushConfigs { pushConfig } dict =
    Config.update pushConfig.topic (toList pushConfig) dict


toList : PushConfig r -> Maybe (List (PushConfig r)) -> Maybe (List (PushConfig r))
toList push maybeList =
    case maybeList of
        Just list ->
            Just (push :: list)

        Nothing ->
            Just [ push ]


queued : Topic -> Push r msg -> List (PushConfig r)
queued topic (Push { queue }) =
    Config.values queue
        |> List.filterMap (byTopic topic)


byTopic : Topic -> InternalConfig r -> Maybe (PushConfig r)
byTopic topic { pushConfig } =
    if topic == pushConfig.topic then
        Just pushConfig

    else
        Nothing


maybeRetryStrategy : String -> Push r msg -> Maybe r
maybeRetryStrategy ref (Push push) =
    Config.get ref push.sent
        |> Maybe.map .retryStrategy


timeoutCountdown : (PushConfig r -> Bool) -> (InternalConfig r -> Maybe Int) -> Push r msg -> Maybe Int
timeoutCountdown compareFunc countdownFunc (Push { timeouts }) =
    filter (keepWith compareFunc) timeouts
        |> toMaybeCount countdownFunc


keepWith : (PushConfig r -> Bool) -> InternalConfig r -> Bool
keepWith compareFunc { pushConfig } =
    compareFunc pushConfig


toMaybeCount : (InternalConfig r -> Maybe Int) -> (Config String (InternalConfig r) -> Maybe Int)
toMaybeCount countdownFunc =
    Config.values >> List.head >> Maybe.andThen countdownFunc



{- Setters -}


addTimeout : String -> Push r msg -> Push r msg
addTimeout ref (Push push) =
    Push
        { push
            | sent = Config.remove ref push.sent
            , timeouts =
                case Config.get ref push.sent of
                    Just config ->
                        Config.insert ref config push.timeouts

                    Nothing ->
                        push.timeouts
        }


setTimeouts : Config String (InternalConfig r) -> Push r msg -> Push r msg
setTimeouts timeouts (Push push) =
    Push { push | timeouts = timeouts }


resetTimeoutTick : Config String (InternalConfig r) -> Config String (InternalConfig r)
resetTimeoutTick timeouts =
    map (\config -> { config | timeoutTick = 0 }) timeouts


timeoutTick : Push r msg -> Push r msg
timeoutTick (Push push) =
    Push { push | timeouts = map tick push.timeouts }


tick : InternalConfig r -> InternalConfig r
tick config =
    { config | timeoutTick = config.timeoutTick + 1 }



{- Delete -}


dropQueuedByRef : String -> Push r msg -> Push r msg
dropQueuedByRef ref (Push push) =
    Push { push | queue = Config.remove ref push.queue }


dropQueued : (PushConfig r -> Bool) -> Push r msg -> Push r msg
dropQueued compareFunc (Push push) =
    Push { push | queue = filter (discardWith compareFunc) push.queue }


dropSent : (PushConfig r -> Bool) -> Push r msg -> Push r msg
dropSent compareFunc (Push push) =
    Push { push | sent = filter (discardWith compareFunc) push.sent }


dropTimeout : (PushConfig r -> Bool) -> Push r msg -> Push r msg
dropTimeout compareFunc (Push push) =
    Push { push | timeouts = filter (discardWith compareFunc) push.timeouts }


discardWith : (PushConfig r -> Bool) -> InternalConfig r -> Bool
discardWith compareFunc { pushConfig } =
    not <| compareFunc pushConfig



{- Transform -}


partitionTimeouts : (String -> InternalConfig r -> Bool) -> Push r msg -> ( Config String (InternalConfig r), Config String (InternalConfig r) )
partitionTimeouts compareFunc (Push push) =
    partition compareFunc push.timeouts


partition : (String -> InternalConfig r -> Bool) -> Config String (InternalConfig r) -> ( Config String (InternalConfig r), Config String (InternalConfig r) )
partition compareFunc config =
    Config.partition compareFunc config


filter : (InternalConfig r -> Bool) -> Config String (InternalConfig r) -> Config String (InternalConfig r)
filter func dict =
    Config.filter (\_ config -> func config) dict


foldl : (InternalConfig r -> acc -> acc) -> acc -> Config comparable (InternalConfig r) -> acc
foldl func acc dict =
    Config.foldl (\_ config -> func config) acc dict


map : (InternalConfig r -> InternalConfig r) -> Config String (InternalConfig r) -> Config String (InternalConfig r)
map func dict =
    Config.map (\_ config -> func config) dict
