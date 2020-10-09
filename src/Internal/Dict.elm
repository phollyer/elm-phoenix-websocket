module Internal.Dict exposing
    ( prepend
    , prependOne
    )

import Dict exposing (Dict)


prepend : comparable -> List a -> Dict comparable (List a) -> Dict comparable (List a)
prepend key items dict =
    Dict.update key
        (\maybeList ->
            case maybeList of
                Just list ->
                    Just (items ++ list)

                Nothing ->
                    Just items
        )
        dict


prependOne : comparable -> a -> Dict comparable (List a) -> Dict comparable (List a)
prependOne key item dict =
    Dict.update key
        (\maybeList ->
            case maybeList of
                Just list ->
                    Just (item :: list)

                Nothing ->
                    Just [ item ]
        )
        dict
