module Template.Username.PhonePortrait exposing (view)

import Element as El exposing (Element)
import Element.Border as Border
import Element.Input as Input


type alias Config msg c =
    { c
        | onChange : Maybe (String -> msg)
        , value : String
    }


view : Config msg c -> Element msg
view config =
    case config.onChange of
        Just onChange ->
            Input.text
                [ Border.rounded 5
                , El.width El.fill
                ]
                { onChange = onChange
                , text = config.value
                , placeholder = Just (Input.placeholder [] (El.text "Username"))
                , label = Input.labelHidden "Username"
                }

        Nothing ->
            El.none
