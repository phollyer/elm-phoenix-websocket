module Template.StatusReports.TabletLandscape exposing (view)

import Element as El exposing (Element)
import Element.Font as Font
import Template.StatusReports.Common as Common exposing (Config)


view : Config msg c -> Element msg
view config =
    El.column
        Common.containerAttrs
        [ title config.title
        , static config.static
        , scrollable config.scrollable
        ]


title : String -> Element msg
title title_ =
    El.el
        (Font.size 22
            :: Common.titleAttrs
        )
        (El.text title_)


scrollable : List (Element msg) -> Element msg
scrollable elements =
    case elements of
        [] ->
            El.none

        _ ->
            El.column
                (Font.size 20
                    :: List.append
                        Common.scrollableAttrs
                        Common.contentAttrs
                )
                elements


static : List (Element msg) -> Element msg
static elements =
    case elements of
        [] ->
            El.none

        _ ->
            El.column
                (Font.size 20
                    :: List.append
                        Common.staticAttrs
                        Common.contentAttrs
                )
                elements
