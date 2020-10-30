module Extra.String exposing
    ( printBool
    , printList
    , printMaybe
    , printQuoted
    )


printBool : Bool -> String
printBool bool =
    if bool then
        "True"

    else
        "False"


printQuoted : String -> String
printQuoted str =
    "\"" ++ str ++ "\""


printList : List String -> String
printList list =
    List.foldl
        (\str acc ->
            acc ++ "\n, " ++ printQuoted str
        )
        ""
        list
        |> String.dropLeft 3
        |> asList


printMaybe : String -> Maybe a -> String
printMaybe justStr maybe =
    case maybe of
        Nothing ->
            "Nothing"

        Just _ ->
            "Just " ++ justStr


asList : String -> String
asList string =
    if string == "" then
        "[ ]"

    else
        "[ " ++ string ++ " ]"
