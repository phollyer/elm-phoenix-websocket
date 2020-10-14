module Main exposing (main)

import Browser exposing (Document)
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Element as El
import Html
import Page
import Page.Blank as Blank
import Page.ControlTheSocketConnection as ControlTheSocketConnection
import Page.Home as Home
import Page.NotFound as NotFound
import Route exposing (Route)
import Session exposing (Session)
import Url exposing (Url)



{- Init -}


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url navKey =
    changeRouteTo (Route.fromUrl url)
        (Redirect (Session.init navKey))


changeRouteTo : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    let
        session =
            toSession model
    in
    case maybeRoute of
        Nothing ->
            ( NotFound session, Cmd.none )

        Just Route.Root ->
            ( model, Route.replaceUrl (Session.navKey session) Route.Home )

        Just Route.Home ->
            Home.init session
                |> updateWith Home GotHomeMsg

        Just Route.ControlTheSocketConnection ->
            ControlTheSocketConnection.init session
                |> updateWith ControlTheSocketConnection GotControlTheSocketConnectionMsg


toSession : Model -> Session
toSession model =
    case model of
        Redirect session ->
            session

        NotFound session ->
            session

        Home subModel ->
            Home.toSession subModel

        ControlTheSocketConnection subModel ->
            ControlTheSocketConnection.toSession subModel



{- Model -}


{-| -}
type Model
    = Redirect Session
    | NotFound Session
    | Home Home.Model
    | ControlTheSocketConnection ControlTheSocketConnection.Model



{- Update -}


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | GotHomeMsg Home.Msg
    | GotControlTheSocketConnectionMsg ControlTheSocketConnection.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl (Session.navKey (toSession model)) (Url.toString url)
                    )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        ( ChangedUrl url, _ ) ->
            changeRouteTo (Route.fromUrl url) model

        ( GotHomeMsg subMsg, Home subModel ) ->
            Home.update subMsg subModel
                |> updateWith Home GotHomeMsg

        ( GotControlTheSocketConnectionMsg subMsg, ControlTheSocketConnection subModel ) ->
            ControlTheSocketConnection.update subMsg subModel
                |> updateWith ControlTheSocketConnection GotControlTheSocketConnectionMsg

        _ ->
            ( model, Cmd.none )


updateWith : (subModel -> Model) -> (subMsg -> Msg) -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg ( subModel, subCmd ) =
    ( toModel subModel
    , Cmd.map toMsg subCmd
    )



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        ControlTheSocketConnection subModel ->
            Sub.map GotControlTheSocketConnectionMsg <|
                ControlTheSocketConnection.subscriptions subModel

        _ ->
            Sub.none



{- View -}


view : Model -> Document Msg
view model =
    let
        phoenix =
            Session.phoenix (toSession model)

        viewPage page toMsg config =
            let
                { title, body } =
                    Page.view phoenix page config
            in
            { title = title
            , body = List.map (Html.map toMsg) body
            }
    in
    case model of
        Redirect _ ->
            Page.view phoenix Page.Other Blank.view

        NotFound _ ->
            Page.view phoenix Page.Other NotFound.view

        Home subModel ->
            viewPage Page.Home GotHomeMsg (Home.view subModel)

        ControlTheSocketConnection subModel ->
            viewPage Page.ControlTheSocketConnection GotControlTheSocketConnectionMsg (ControlTheSocketConnection.view subModel)



{- Program -}


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        }
