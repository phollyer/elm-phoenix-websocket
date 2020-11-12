module Template.Rooms.PhonePortrait exposing (view)

import Element as El exposing (Element)


type alias Config c =
    { c
        | list : List Room
    }


type alias Room =
    { id : String
    , owner : User
    , messages : List Message
    }


type alias Message =
    { id : String
    , text : String
    , owner : User
    }


type alias User =
    { id : String
    , username : String
    }


view : Config c -> Element msg
view config =
    El.column
        [ El.width El.fill
        , El.spacing 10
        ]
    <|
        List.map roomView config.list


roomView : Room -> Element msg
roomView room =
    El.el
        []
        (El.text room.id)
