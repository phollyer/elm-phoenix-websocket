module Internal.Unique exposing
    ( Unique
    , empty
    , exists
    , foldl
    , insert
    , map
    , remove
    , toList
    )

import Set exposing (Set)


type alias Unique comparable =
    Set comparable



{- Build -}


empty : Unique comparable
empty =
    Set.empty


insert : comparable -> Unique comparable -> Unique comparable
insert =
    Set.insert


remove : comparable -> Unique comparable -> Unique comparable
remove =
    Set.remove



{- Query -}


exists : comparable -> Unique comparable -> Bool
exists =
    Set.member



{- Lists -}


toList : Unique a -> List a
toList =
    Set.toList



{- Transform -}


foldl : (comparable -> acc -> acc) -> acc -> Unique comparable -> acc
foldl =
    Set.foldl


map : (comparable -> comparable2) -> Unique comparable -> Unique comparable2
map =
    Set.map
