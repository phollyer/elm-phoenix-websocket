module Internal.Push exposing
    ( Push
    , allQueued
    , allTimeouts
    , dropQueued
    , dropSent
    , dropSentByRef
    , dropTimeout
    , hasTimedOut
    , init
    , isQueued
    , maybeRetryStrategy
    , preFlight
    , queued
    , reset
    , send
    , sendAll
    , sendByTopic
    , setTimeouts
    , timedOut
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


preFlight : PushConfig r -> Push r msg -> ( Push r msg, Ref )
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


send : Ref -> Push r msg -> ( Push r msg, Cmd msg )
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


compareWith : (PushConfig r -> Bool) -> Config Ref (InternalConfig r) -> Bool
compareWith compareFunc config =
    partition (\_ { pushConfig } -> compareFunc pushConfig) config
        |> matchFound


matchFound : ( Config Ref (InternalConfig r), Config Ref (InternalConfig r) ) -> Bool
matchFound =
    Tuple.first >> Config.exists


timeoutsExist : Push r msg -> Bool
timeoutsExist (Push { timeouts }) =
    Config.exists timeouts



{- Queries -}


allTimeouts : Push r msg -> Config Ref (List (PushConfig r))
allTimeouts (Push { timeouts }) =
    foldl allPushConfigs Config.empty timeouts


allQueued : Push r msg -> Config Topic (List (PushConfig r))
allQueued (Push { queue }) =
    foldl allPushConfigs Config.empty queue


allPushConfigs : InternalConfig r -> Config Ref (List (PushConfig r)) -> Config Ref (List (PushConfig r))
allPushConfigs { pushConfig } config =
    Config.update pushConfig.topic (maybeToList pushConfig) config


maybeToList : PushConfig r -> Maybe (List (PushConfig r)) -> Maybe (List (PushConfig r))
maybeToList push maybeList =
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


maybeRetryStrategy : Ref -> Push r msg -> Maybe r
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


toMaybeCount : (InternalConfig r -> Maybe Int) -> (Config Ref (InternalConfig r) -> Maybe Int)
toMaybeCount countdownFunc =
    Config.values >> List.head >> Maybe.andThen countdownFunc



{- Setters -}


setTimeouts : Config Ref (InternalConfig r) -> Push r msg -> Push r msg
setTimeouts timeouts (Push push) =
    Push { push | timeouts = timeouts }


timedOut : Ref -> Push r msg -> Push r msg
timedOut ref (Push push) =
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


timeoutTick :
    (Ref -> InternalConfig r -> Bool)
    -> (InternalConfig r -> InternalConfig r)
    -> (InternalConfig r -> Bool)
    -> Push r msg
    -> ( Config Ref (InternalConfig r), Config Ref (InternalConfig r) )
timeoutTick retry nextBackoff dropBackoff (Push push) =
    Push { push | timeouts = map tick push.timeouts }
        |> partitionTimeouts retry
        |> Tuple.mapFirst resetTimeoutTick
        |> Tuple.mapFirst (map nextBackoff)
        |> Tuple.mapSecond (filter dropBackoff)


tick : InternalConfig r -> InternalConfig r
tick internalConfig =
    { internalConfig | timeoutTick = internalConfig.timeoutTick + 1 }


resetTimeoutTick : Config Ref (InternalConfig r) -> Config Ref (InternalConfig r)
resetTimeoutTick timeouts =
    map (\internalConfig -> { internalConfig | timeoutTick = 0 }) timeouts



{- Delete -}


dropSentByRef : Ref -> Push r msg -> Push r msg
dropSentByRef ref (Push push) =
    Push { push | sent = Config.remove ref push.sent }


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


partitionTimeouts : (Ref -> InternalConfig r -> Bool) -> Push r msg -> ( Config Ref (InternalConfig r), Config Ref (InternalConfig r) )
partitionTimeouts compareFunc (Push push) =
    partition compareFunc push.timeouts


partition : (Ref -> InternalConfig r -> Bool) -> Config Ref (InternalConfig r) -> ( Config Ref (InternalConfig r), Config Ref (InternalConfig r) )
partition compareFunc config =
    Config.partition compareFunc config


filter : (InternalConfig r -> Bool) -> Config Ref (InternalConfig r) -> Config Ref (InternalConfig r)
filter func config =
    Config.filter (\_ internalConfig -> func internalConfig) config


foldl : (InternalConfig r -> acc -> acc) -> acc -> Config Ref (InternalConfig r) -> acc
foldl func acc config =
    Config.foldl (\_ internalConfig -> func internalConfig) acc config


map : (InternalConfig r -> InternalConfig r) -> Config Ref (InternalConfig r) -> Config Ref (InternalConfig r)
map func config =
    Config.map (\_ internalConfig -> func internalConfig) config
