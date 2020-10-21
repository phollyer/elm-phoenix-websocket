module View.UI exposing
    ( Template(..)
    , button
    , code
    , paragraph
    )

import Element exposing (Element)
import Template.UI.Example as Example


type Template
    = Example


paragraph : Template -> List (Element msg) -> Element msg
paragraph template content =
    case template of
        Example ->
            Example.paragraph content


type alias Button a msg =
    { enabled : Bool
    , label : String
    , example : a
    , onPress : a -> msg
    }


button : Template -> Button a msg -> Element msg
button template config =
    case template of
        Example ->
            Example.button config


code : Template -> String -> Element msg
code template text =
    case template of
        Example ->
            Example.code text
