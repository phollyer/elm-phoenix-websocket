module Internal.Presence exposing
    ( Presence
    , addDiff
    , addJoin
    , addLeave
    , diff
    , init
    , joins
    , lastJoin
    , lastLeave
    , leaves
    , setState
    , state
    )

import Dict exposing (Dict)
import Phoenix.Channel exposing (Topic)
import Phoenix.Presence as P


type Presence
    = Presence
        { diff : Dict Topic (List P.PresenceDiff)
        , state : Dict Topic (List P.Presence)
        , joins : Dict Topic (List P.Presence)
        , leaves : Dict Topic (List P.Presence)
        }


init : Presence
init =
    Presence
        { diff = Dict.empty
        , state = Dict.empty
        , joins = Dict.empty
        , leaves = Dict.empty
        }


addDiff : Topic -> P.PresenceDiff -> Presence -> Presence
addDiff topic diff_ (Presence presence) =
    Presence
        { presence
            | diff =
                Dict.update topic
                    (\maybeList ->
                        case maybeList of
                            Just list ->
                                Just (diff_ :: list)

                            Nothing ->
                                Just [ diff_ ]
                    )
                    presence.diff
        }


addJoin : Topic -> P.Presence -> Presence -> Presence
addJoin topic join (Presence presence) =
    Presence
        { presence
            | joins =
                Dict.update topic
                    (\maybeList ->
                        case maybeList of
                            Just list ->
                                Just (join :: list)

                            Nothing ->
                                Just [ join ]
                    )
                    presence.joins
        }


addLeave : Topic -> P.Presence -> Presence -> Presence
addLeave topic leave (Presence presence) =
    Presence
        { presence
            | leaves =
                Dict.update topic
                    (\maybeList ->
                        case maybeList of
                            Just list ->
                                Just (leave :: list)

                            Nothing ->
                                Just [ leave ]
                    )
                    presence.leaves
        }


setState : Topic -> List P.Presence -> Presence -> Presence
setState topic state_ (Presence presence) =
    Presence { presence | state = Dict.insert topic state_ presence.state }


diff : Topic -> Presence -> List P.PresenceDiff
diff topic (Presence presence) =
    Dict.get topic presence.diff
        |> Maybe.withDefault []


state : Topic -> Presence -> List P.Presence
state topic (Presence presence) =
    Dict.get topic presence.state
        |> Maybe.withDefault []


joins : Topic -> Presence -> List P.Presence
joins topic (Presence presence) =
    Dict.get topic presence.joins
        |> Maybe.withDefault []


leaves : Topic -> Presence -> List P.Presence
leaves topic (Presence presence) =
    Dict.get topic presence.leaves
        |> Maybe.withDefault []


lastJoin : Topic -> Presence -> Maybe P.Presence
lastJoin topic (Presence presence) =
    Dict.get topic presence.joins
        |> Maybe.withDefault []
        |> List.head


lastLeave : Topic -> Presence -> Maybe P.Presence
lastLeave topic (Presence presence) =
    Dict.get topic presence.leaves
        |> Maybe.withDefault []
        |> List.head
