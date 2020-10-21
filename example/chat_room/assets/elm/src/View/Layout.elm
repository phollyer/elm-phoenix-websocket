module View.Layout exposing
    ( Template(..)
    , button
    , code
    , column
    , example
    , homeMsg
    , init
    , introduction
    , menu
    , paragraph
    , render
    , title
    )

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font
import Element.Input as Input
import Phoenix
import Template.Layout.Blank as Blank
import Template.Layout.Example as Example
import Template.Layout.Home as Home
import Template.Layout.NotFound as NotFound


type alias Config msg =
    { homeMsg : Maybe msg
    , title : String
    , introduction : List (Element msg)
    , menu : Element msg
    , example : Element msg
    , column : List (Element msg)
    }


type Template
    = Example
    | Home
    | Blank
    | NotFound


init : Config msg
init =
    { homeMsg = Nothing
    , title = ""
    , introduction = []
    , menu = El.none
    , example = El.none
    , column = []
    }


render : Template -> Config msg -> Element msg
render template config =
    case template of
        Home ->
            Home.render config

        Example ->
            Example.render config

        Blank ->
            Blank.render

        NotFound ->
            NotFound.render


homeMsg : Maybe msg -> Config msg -> Config msg
homeMsg msg config =
    { config | homeMsg = msg }


title : String -> Config msg -> Config msg
title text config =
    { config | title = text }


introduction : List (Element msg) -> Config msg -> Config msg
introduction list config =
    { config | introduction = list }


example : Element msg -> Config msg -> Config msg
example example_ config =
    { config | example = example_ }


menu : Element msg -> Config msg -> Config msg
menu menu_ config =
    { config | menu = menu_ }


column : List (Element msg) -> Config msg -> Config msg
column content config =
    { config | column = content }


paragraph : Template -> List (Element msg) -> Element msg
paragraph template content =
    case template of
        Example ->
            Example.paragraph content

        _ ->
            El.none


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

        _ ->
            El.none


code : Template -> String -> Element msg
code template text =
    case template of
        Example ->
            Example.code text

        _ ->
            El.none
