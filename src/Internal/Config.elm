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


empty : Dict k v
empty =
    Dict.empty


exists : Config comparable value -> Bool
exists =
    isEmpty >> not


foldl : (comparable -> value -> acc -> acc) -> acc -> Dict comparable value -> acc
foldl =
    Dict.foldl


get : comparable -> Dict comparable value -> Maybe value
get =
    Dict.get


filter : (comparable -> value -> Bool) -> Dict comparable value -> Dict comparable value
filter =
    Dict.filter


insert : comparable -> value -> Dict comparable value -> Dict comparable value
insert =
    Dict.insert


isEmpty : Dict comparable value -> Bool
isEmpty =
    Dict.isEmpty


map : (comparable -> a -> b) -> Dict comparable a -> Dict comparable b
map =
    Dict.map


partition : (comparable -> value -> Bool) -> Dict comparable value -> ( Dict comparable value, Dict comparable value )
partition =
    Dict.partition


remove : comparable -> Dict comparable value -> Dict comparable value
remove =
    Dict.remove


toList : Dict comparable value -> List ( comparable, value )
toList =
    Dict.toList


update : comparable -> (Maybe value -> Maybe value) -> Dict comparable value -> Dict comparable value
update =
    Dict.update


values : Dict comparable value -> List value
values =
    Dict.values
