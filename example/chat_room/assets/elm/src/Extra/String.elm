module Extra.String exposing (fromBool, listAsString)


fromBool : Bool -> String
fromBool bool =
    if bool then
        "True"

    else
        "False"


listAsString : String -> String
listAsString string =
    if string == "" then
        "[ ]"

    else
        "[ " ++ string ++ " ]"
