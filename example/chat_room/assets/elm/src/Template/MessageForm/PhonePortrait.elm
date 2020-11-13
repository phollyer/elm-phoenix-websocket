module Template.MessageForm.PhonePortrait exposing (view)

import Element as El exposing (Element)
import Element.Input as Input


type alias Config msg c =
    { c
        | text : String
        , onChange : Maybe (String -> msg)
        , onSubmit : Element msg
    }


view : Config msg c -> Element msg
view config =
    El.column
        [ El.spacing 10
        , El.width El.fill
        ]
        [ inputField config
        ]


inputField : Config msg c -> Element msg
inputField config =
    case config.onChange of
        Nothing ->
            El.none

        Just onChange ->
            Input.multiline
                [ El.width El.fill ]
                { onChange = onChange
                , text = config.text
                , placeholder = Nothing
                , label = Input.labelAbove [] (El.text "Message")
                , spellcheck = True
                }
