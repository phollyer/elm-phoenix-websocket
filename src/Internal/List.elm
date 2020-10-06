module Internal.List exposing (replace)


replace : (a -> a -> Bool) -> a -> List a -> List a
replace compareFunc newItem list =
    List.map
        (\item ->
            if compareFunc item newItem then
                newItem

            else
                item
        )
        list
