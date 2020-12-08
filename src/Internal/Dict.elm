module Internal.Dict exposing (prependOne)

import Dict exposing (Dict)


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
