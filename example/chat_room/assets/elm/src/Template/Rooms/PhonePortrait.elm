module Template.Rooms.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border


type alias Config c =
    { c
        | list : List Room
    }


type alias Room =
    { id : String
    , owner : User
    , members : List User
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
        [ Background.color Color.aliceblue
        , Border.rounded 10
        , Border.color Color.darkblue
        , Border.width 1
        , El.padding 10
        , El.width El.fill
        ]
        (El.column
            [ El.width El.fill
            , El.spacing 10
            ]
            [ El.row
                [ El.spacing 10
                , El.width El.fill
                , El.clipX
                ]
                [ El.text "Owner:"
                , El.text room.owner.username
                ]
            , El.column
                [ El.width El.fill ]
                (El.text "Members"
                    :: List.map
                        (\member ->
                            El.text member.username
                        )
                        room.members
                )
            ]
        )
