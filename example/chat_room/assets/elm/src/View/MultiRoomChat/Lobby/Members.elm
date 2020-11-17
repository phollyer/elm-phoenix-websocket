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
        (El.el
            [ El.centerX ]
            (El.text "Members")
            :: List.map toMember users
        )


toMember : User -> Element msg
toMember user =
    El.text user.username
