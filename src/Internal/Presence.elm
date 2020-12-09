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



{- Model -}


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



{- Accessors -}


diff : Topic -> Presence -> List P.PresenceDiff
diff topic (Presence presence) =
    all topic presence.diff


state : Topic -> Presence -> List P.Presence
state topic (Presence presence) =
    all topic presence.state


joins : Topic -> Presence -> List P.Presence
joins topic (Presence presence) =
    all topic presence.joins


leaves : Topic -> Presence -> List P.Presence
leaves topic (Presence presence) =
    all topic presence.leaves


lastJoin : Topic -> Presence -> Maybe P.Presence
lastJoin topic (Presence presence) =
    last topic presence.joins


lastLeave : Topic -> Presence -> Maybe P.Presence
lastLeave topic (Presence presence) =
    last topic presence.leaves



{- Setters -}


setState : Topic -> List P.Presence -> Presence -> Presence
setState topic state_ (Presence presence) =
    Presence { presence | state = Dict.insert topic state_ presence.state }


addDiff : Topic -> P.PresenceDiff -> Presence -> Presence
addDiff topic diff_ (Presence presence) =
    Presence { presence | diff = add topic diff_ presence.diff }


addJoin : Topic -> P.Presence -> Presence -> Presence
addJoin topic join (Presence presence) =
    Presence { presence | joins = add topic join presence.joins }


addLeave : Topic -> P.Presence -> Presence -> Presence
addLeave topic leave (Presence presence) =
    Presence { presence | leaves = add topic leave presence.leaves }



{- Private -}


add : comparable -> v -> Dict comparable (List v) -> Dict comparable (List v)
add key value dict =
    Dict.update key
        (\maybeV ->
            case maybeV of
                Just v ->
                    Just (value :: v)

                Nothing ->
                    Just [ value ]
        )
        dict


all : comparable -> Dict comparable (List v) -> List v
all key dict =
    Dict.get key dict
        |> Maybe.withDefault []


last : comparable -> Dict comparable (List v) -> Maybe v
last key dict =
    all key dict
        |> List.head
