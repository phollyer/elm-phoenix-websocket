module Internal.Config exposing
    ( Config
    , empty
    , exists
    , filter
    , foldl
    , get
    , insert
    , isEmpty
    , map
    , partition
    , remove
    , toList
    , update
    , values
    )

import Dict exposing (Dict)


type alias Config comparable value =
    Dict comparable value



{- Build -}


empty : Dict k v
empty =
    Dict.empty


insert : comparable -> value -> Config comparable value -> Config comparable value
insert =
    Dict.insert


remove : comparable -> Config comparable value -> Config comparable value
remove =
    Dict.remove


update : comparable -> (Maybe value -> Maybe value) -> Config comparable value -> Config comparable value
update =
    Dict.update



{- Query -}


exists : Config comparable value -> Bool
exists =
    isEmpty >> not


get : comparable -> Config comparable value -> Maybe value
get =
    Dict.get


isEmpty : Config comparable value -> Bool
isEmpty =
    Dict.isEmpty



{- Lists -}


toList : Config comparable value -> List ( comparable, value )
toList =
    Dict.toList


values : Config comparable value -> List value
values =
    Dict.values



{- Transform -}


filter : (comparable -> value -> Bool) -> Config comparable value -> Config comparable value
filter =
    Dict.filter


foldl : (comparable -> value -> acc -> acc) -> acc -> Config comparable value -> acc
foldl =
    Dict.foldl


map : (comparable -> a -> b) -> Config comparable a -> Config comparable b
map =
    Dict.map


partition : (comparable -> value -> Bool) -> Config comparable value -> ( Config comparable value, Config comparable value )
partition =
    Dict.partition
