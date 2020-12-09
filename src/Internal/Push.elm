module Internal.Push exposing
    ( InternalPush
    , Push
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
    , partitionTimeouts
    , preFlight
    , queued
    , reset
    , resetTimeoutTick
    , retryStrategy
    , send
    , sendAll
    , sendByTopic
    , setTimeouts
    , timeoutCountdown
    , timeoutTick
    , timeoutsExist
    )

import Dict exposing (Dict)
import Json.Encode exposing (Value)
import Phoenix.Channel as Channel exposing (Topic)


type Push r msg
    = Push
        { count : Int
        , queue : Dict String (InternalPush r)
        , sent : Dict String (InternalPush r)
        , timeouts : Dict String (InternalPush r)
        , portOut : { msg : String, payload : Value } -> Cmd msg
        }


type alias InternalPush r =
    { push : PushConfig r
    , ref : String
    , retryStrategy : r
    , timeoutTick : Int
    }


type alias PushConfig r =
    { topic : String
    , event : String
    , payload : Value
    , timeout : Maybe Int
    , retryStrategy : r
    , ref : Maybe String
    }


init : ({ msg : String, payload : Value } -> Cmd msg) -> Push r msg
init portOut =
    Push
        { count = 0
        , queue = Dict.empty
        , sent = Dict.empty
        , timeouts = Dict.empty
        , portOut = portOut
        }


reset : Push r msg -> Push r msg
reset (Push push) =
    init push.portOut


preFlight : PushConfig r -> Push r msg -> ( Push r msg, String )
preFlight config (Push push) =
    let
        ( ref, count ) =
            case config.ref of
                Nothing ->
                    ( push.count + 1 |> String.fromInt
                    , push.count + 1
                    )

                Just ref_ ->
                    ( ref_, push.count )

        internalConfig =
            { push = { config | ref = Just ref }
            , ref = ref
            , retryStrategy = config.retryStrategy
            , timeoutTick = 0
            }
    in
    ( Push
        { push
            | count = count
            , queue = Dict.insert ref internalConfig push.queue
        }
    , ref
    )


send : String -> Push r msg -> ( Push r msg, Cmd msg )
send ref (Push push) =
    case Dict.get ref push.queue of
        Nothing ->
            ( Push push, Cmd.none )

        Just internalConfig ->
            ( Push
                { push
                    | sent = Dict.insert ref internalConfig push.sent
                    , queue = Dict.remove ref push.queue
                }
            , Channel.push internalConfig.push push.portOut
            )


sendByTopic : Topic -> Push r msg -> ( Push r msg, Cmd msg )
sendByTopic topic (Push push_) =
    let
        ( toGo, toKeep ) =
            Dict.partition
                (\_ { push } -> push.topic == topic)
                push_.queue
    in
    Push { push_ | queue = toKeep }
        |> sendAll toGo


addTimeout : String -> Push r msg -> Push r msg
addTimeout ref (Push push) =
    Push
        { push
            | sent = Dict.remove ref push.sent
            , timeouts =
                case Dict.get ref push.sent of
                    Just config ->
                        Dict.insert ref config push.timeouts

                    Nothing ->
                        push.timeouts
        }


hasTimedOut : (PushConfig r -> Bool) -> Push r msg -> Bool
hasTimedOut compareFunc (Push push) =
    push.timeouts
        |> Dict.partition
            (\_ v -> compareFunc v.push)
        |> Tuple.first
        |> Dict.isEmpty
        |> not


setTimeouts : Dict String (InternalPush r) -> Push r msg -> Push r msg
setTimeouts timeouts (Push push) =
    Push { push | timeouts = timeouts }


partitionTimeouts : (String -> InternalPush r -> Bool) -> Push r msg -> ( Dict String (InternalPush r), Dict String (InternalPush r) )
partitionTimeouts compareFunc (Push push) =
    Dict.partition compareFunc push.timeouts


resetTimeoutTick : Dict String (InternalPush r) -> Dict String (InternalPush r)
resetTimeoutTick timeouts =
    Dict.map (\_ config -> { config | timeoutTick = 0 }) timeouts


sendAll : Dict String (InternalPush r) -> Push r msg -> ( Push r msg, Cmd msg )
sendAll pushConfigs model =
    pushConfigs
        |> Dict.toList
        |> List.map Tuple.second
        |> List.foldl
            batchPush
            ( model, Cmd.none )


allQueued : Push r msg -> Dict Topic (List (PushConfig r))
allQueued (Push { queue }) =
    Dict.foldl
        (\_ internalPush queue_ ->
            Dict.update
                internalPush.push.topic
                (\maybeQueue ->
                    case maybeQueue of
                        Nothing ->
                            Just [ internalPush.push ]

                        Just q ->
                            Just (internalPush.push :: q)
                )
                queue_
        )
        Dict.empty
        queue


allTimeouts : Push r msg -> Dict String (List (PushConfig r))
allTimeouts (Push { timeouts }) =
    Dict.foldl
        (\_ internalPush timeouts_ ->
            Dict.update
                internalPush.push.topic
                (\maybeQueue ->
                    case maybeQueue of
                        Nothing ->
                            Just [ internalPush.push ]

                        Just t ->
                            Just (internalPush.push :: t)
                )
                timeouts_
        )
        Dict.empty
        timeouts


isQueued : (PushConfig r -> Bool) -> Push r msg -> Bool
isQueued compareFunc (Push push) =
    push.queue
        |> Dict.partition
            (\_ v -> compareFunc v.push)
        |> Tuple.first
        |> Dict.isEmpty
        |> not


queued : Topic -> Push r msg -> List (PushConfig r)
queued topic (Push { queue }) =
    Dict.values queue
        |> List.filterMap
            (\internalPushConfig ->
                if internalPushConfig.push.topic == topic then
                    Just internalPushConfig.push

                else
                    Nothing
            )


dropQueued : (PushConfig r -> Bool) -> Push r msg -> Push r msg
dropQueued compareFunc (Push push) =
    Push
        { push
            | queue =
                Dict.filter
                    (\_ internalPush -> not (compareFunc internalPush.push))
                    push.queue
        }


dropSent : (PushConfig r -> Bool) -> Push r msg -> Push r msg
dropSent compareFunc (Push push) =
    Push
        { push
            | sent =
                Dict.filter
                    (\_ internalPush -> not (compareFunc internalPush.push))
                    push.sent
        }


dropTimeout : (PushConfig r -> Bool) -> Push r msg -> Push r msg
dropTimeout compareFunc (Push push) =
    Push
        { push
            | timeouts =
                Dict.filter
                    (\_ internalPush -> not (compareFunc internalPush.push))
                    push.timeouts
        }


dropQueuedByRef : String -> Push r msg -> Push r msg
dropQueuedByRef ref (Push push) =
    Push { push | queue = Dict.remove ref push.queue }


retryStrategy : String -> Push r msg -> Maybe r
retryStrategy ref (Push push) =
    Dict.get ref push.sent
        |> Maybe.map .retryStrategy


timeoutsExist : Push r msg -> Bool
timeoutsExist (Push { timeouts }) =
    not <| Dict.isEmpty timeouts


timeoutTick : Push r msg -> Push r msg
timeoutTick (Push push) =
    Push
        { push
            | timeouts =
                Dict.map
                    (\_ config -> { config | timeoutTick = config.timeoutTick + 1 })
                    push.timeouts
        }


timeoutCountdown : (PushConfig r -> Bool) -> (InternalPush r -> Maybe Int) -> Push r msg -> Maybe Int
timeoutCountdown compareFunc countdownFunc (Push { timeouts }) =
    Dict.filter (\_ internalPushConfig -> compareFunc internalPushConfig.push) timeouts
        |> Dict.values
        |> List.head
        |> Maybe.andThen countdownFunc


batchPush : InternalPush r -> ( Push r msg, Cmd msg ) -> ( Push r msg, Cmd msg )
batchPush { ref } ( push, cmd ) =
    let
        ( push_, cmd_ ) =
            send ref push
    in
    ( push_
    , Cmd.batch [ cmd, cmd_ ]
    )


filter : (InternalPush r -> Bool) -> Dict String (InternalPush r) -> Dict String (InternalPush r)
filter func dict =
    Dict.filter (\_ config -> func config) dict


map : (InternalPush r -> InternalPush r) -> Dict String (InternalPush r) -> Dict String (InternalPush r)
map func dict =
    Dict.map (\_ config -> func config) dict
