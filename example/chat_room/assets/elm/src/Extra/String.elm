module Extra.String exposing (fromBool)


fromBool : Bool -> String
fromBool bool =
    if bool then
        "True"

    else
        "False"
