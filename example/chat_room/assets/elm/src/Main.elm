module Main exposing (main)

import Browser exposing (Document)
import Browser.Dom as Dom
import Browser.Events exposing (onResize)
import Browser.Navigation as Nav
import Element as El exposing (Element)
import Html
import Page
import Page.Blank as Blank
import Page.ControlTheSocketConnection as ControlTheSocketConnection
import Page.HandleSocketMessages as HandleSocketMessages
import Page.Home as Home
import Page.NotFound as NotFound
import Route exposing (Route)
import Session exposing (Session)
import Url exposing (Url)



{- Init -}


init : { width : Int, height : Int } -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    changeRouteTo (Route.fromUrl url)
        (Redirect (Session.init navKey (El.classifyDevice flags)))


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

        Just (Route.HandleSocketMessages maybeExample maybeId) ->
            HandleSocketMessages.init session maybeExample maybeId
                |> updateWith HandleSocketMessages GotHandleSocketMessagesMsg


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

        HandleSocketMessages subModel ->
            HandleSocketMessages.toSession subModel


updateSession : Session -> Model -> Model
updateSession session model =
    case model of
        Redirect _ ->
            Redirect session

        NotFound _ ->
            NotFound session

        Home subModel ->
            Home <|
                Home.updateSession session subModel

        ControlTheSocketConnection subModel ->
            ControlTheSocketConnection <|
                ControlTheSocketConnection.updateSession session subModel

        HandleSocketMessages subModel ->
            HandleSocketMessages <|
                HandleSocketMessages.updateSession session subModel



{- Model -}


type Model
    = Redirect Session
    | NotFound Session
    | Home Home.Model
    | ControlTheSocketConnection ControlTheSocketConnection.Model
    | HandleSocketMessages HandleSocketMessages.Model



{- Update -}


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | WindowResized Int Int
    | GotHomeMsg Home.Msg
    | GotControlTheSocketConnectionMsg ControlTheSocketConnection.Msg
    | GotHandleSocketMessagesMsg HandleSocketMessages.Msg


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

        ( WindowResized width height, _ ) ->
            let
                session =
                    Session.updateDevice
                        (El.classifyDevice { width = width, height = height })
                        (toSession model)
            in
            ( model
            , Cmd.none
            )

        ( GotHomeMsg subMsg, Home subModel ) ->
            Home.update subMsg subModel
                |> updateWith Home GotHomeMsg

        ( GotControlTheSocketConnectionMsg subMsg, ControlTheSocketConnection subModel ) ->
            ControlTheSocketConnection.update subMsg subModel
                |> updateWith ControlTheSocketConnection GotControlTheSocketConnectionMsg

        ( GotHandleSocketMessagesMsg subMsg, HandleSocketMessages subModel ) ->
            HandleSocketMessages.update subMsg subModel
                |> updateWith HandleSocketMessages GotHandleSocketMessagesMsg

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
            Sub.batch
                [ Sub.map GotControlTheSocketConnectionMsg <|
                    ControlTheSocketConnection.subscriptions subModel
                , onResize WindowResized
                ]

        HandleSocketMessages subModel ->
            Sub.batch
                [ Sub.map GotHandleSocketMessagesMsg <|
                    HandleSocketMessages.subscriptions subModel
                , onResize WindowResized
                ]

        _ ->
            onResize WindowResized



{- View -}


view : Model -> Document Msg
view model =
    case model of
        Redirect _ ->
            Page.view Blank.view

        NotFound _ ->
            Page.view NotFound.view

        Home subModel ->
            viewPage GotHomeMsg (Home.view subModel)

        ControlTheSocketConnection subModel ->
            viewPage GotControlTheSocketConnectionMsg (ControlTheSocketConnection.view subModel)

        HandleSocketMessages subModel ->
            viewPage GotHandleSocketMessagesMsg (HandleSocketMessages.view subModel)


viewPage : (msg -> Msg) -> { title : String, content : Element msg } -> Document Msg
viewPage toMsg pageConfig =
    let
        { title, body } =
            Page.view pageConfig
    in
    { title = title
    , body = List.map (Html.map toMsg) body
    }



{- Program -}


main : Program { width : Int, height : Int } Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        }
