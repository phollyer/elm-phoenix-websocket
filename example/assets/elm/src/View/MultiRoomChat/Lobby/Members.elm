module View.MultiRoomChat.Lobby.Members exposing
    ( init
    , members
    , view
    )

import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font



{- Model -}


type Config
    = Config (List User)


type alias User =
    { id : String
    , username : String
    }


init : Config
init =
    Config []


members : List User -> Config -> Config
members users _ =
    Config users



{- View -}


view : Device -> Config -> Element msg
view _ (Config users) =
    El.column
        [ Border.rounded 10
        , Background.color Color.steelblue
        , El.padding 10
        , El.spacing 10
        , El.width El.fill
        , Font.color Color.skyblue
        ]
        [ El.el
            [ El.centerX ]
            (El.text "Members")
        , El.paragraph
            [ El.width El.fill ]
            [ toMembers users ]
        ]


toMembers : List User -> Element msg
toMembers users =
    List.map .username users
        |> List.intersperse ", "
        |> String.concat
        |> El.text
