module Internal.Unique exposing
    ( Unique
    , empty
    , exists
    , insert
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
