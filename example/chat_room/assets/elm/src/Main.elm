module Main exposing (main)

import Browser exposing (Document)
import Browser.Events exposing (onResize)
import Browser.Navigation as Nav
import Element as El exposing (Device, Element)
import Html
import Page
import Page.Blank as Blank
import Page.ControlTheSocketConnection as ControlTheSocketConnection
import Page.HandleSocketMessages as HandleSocketMessages
import Page.Home as Home
import Page.JoinAndLeaveChannels as JoinAndLeaveChannels
import Page.NotFound as NotFound
import Page.SendAndReceive as SendAndReceive
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

        Just Route.HandleSocketMessages ->
            HandleSocketMessages.init session
                |> updateWith HandleSocketMessages GotHandleSocketMessagesMsg

        Just Route.JoinAndLeaveChannels ->
            JoinAndLeaveChannels.init session
                |> updateWith JoinAndLeaveChannels GotJoinAndLeaveChannelsMsg

        Just Route.SendAndReceive ->
            SendAndReceive.init session
                |> updateWith SendAndReceive GotSendAndReceiveMsg



{- Model -}


type Model
    = Redirect Session
    | NotFound Session
    | Home Home.Model
    | ControlTheSocketConnection ControlTheSocketConnection.Model
    | HandleSocketMessages HandleSocketMessages.Model
    | JoinAndLeaveChannels JoinAndLeaveChannels.Model
    | SendAndReceive SendAndReceive.Model



{- Update -}


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | WindowResized Int Int
    | GotHomeMsg Home.Msg
    | GotControlTheSocketConnectionMsg ControlTheSocketConnection.Msg
    | GotHandleSocketMessagesMsg HandleSocketMessages.Msg
    | GotJoinAndLeaveChannelsMsg JoinAndLeaveChannels.Msg
    | GotSendAndReceiveMsg SendAndReceive.Msg


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
            ( updateSession session model
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

        ( GotJoinAndLeaveChannelsMsg subMsg, JoinAndLeaveChannels subModel ) ->
            JoinAndLeaveChannels.update subMsg subModel
                |> updateWith JoinAndLeaveChannels GotJoinAndLeaveChannelsMsg

        ( GotSendAndReceiveMsg subMsg, SendAndReceive subModel ) ->
            SendAndReceive.update subMsg subModel
                |> updateWith SendAndReceive GotSendAndReceiveMsg

        _ ->
            ( model, Cmd.none )


updateWith : (subModel -> Model) -> (subMsg -> Msg) -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg ( subModel, subCmd ) =
    ( toModel subModel
    , Cmd.map toMsg subCmd
    )



{- Session -}


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

        JoinAndLeaveChannels subModel ->
            JoinAndLeaveChannels.toSession subModel

        SendAndReceive subModel ->
            SendAndReceive.toSession subModel


updateSession : Session -> Model -> Model
updateSession session model =
    case model of
        Redirect _ ->
            Redirect session

        NotFound _ ->
            NotFound session

        Home _ ->
            Home <|
                Home.updateSession session

        ControlTheSocketConnection subModel ->
            ControlTheSocketConnection <|
                ControlTheSocketConnection.updateSession session subModel

        HandleSocketMessages subModel ->
            HandleSocketMessages <|
                HandleSocketMessages.updateSession session subModel

        JoinAndLeaveChannels subModel ->
            JoinAndLeaveChannels <|
                JoinAndLeaveChannels.updateSession session subModel

        SendAndReceive subModel ->
            SendAndReceive <|
                SendAndReceive.updateSession session subModel



{- Device -}


toDevice : Model -> Device
toDevice model =
    Session.device (toSession model)



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Redirect _ ->
            onResize WindowResized

        NotFound _ ->
            onResize WindowResized

        Home subModel ->
            Sub.batch
                [ Sub.map GotHomeMsg <|
                    Home.subscriptions subModel
                , onResize WindowResized
                ]

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

        JoinAndLeaveChannels subModel ->
            Sub.batch
                [ Sub.map GotJoinAndLeaveChannelsMsg <|
                    JoinAndLeaveChannels.subscriptions subModel
                , onResize WindowResized
                ]

        SendAndReceive subModel ->
            Sub.batch
                [ Sub.map GotSendAndReceiveMsg <|
                    SendAndReceive.subscriptions subModel
                , onResize WindowResized
                ]



{- View -}


view : Model -> Document Msg
view model =
    let
        device =
            toDevice model
    in
    case model of
        Redirect _ ->
            Page.view device Blank.view

        NotFound _ ->
            Page.view device NotFound.view

        Home _ ->
            viewPage device GotHomeMsg (Home.view device)

        ControlTheSocketConnection subModel ->
            viewPage device GotControlTheSocketConnectionMsg (ControlTheSocketConnection.view subModel)

        HandleSocketMessages subModel ->
            viewPage device GotHandleSocketMessagesMsg (HandleSocketMessages.view subModel)

        JoinAndLeaveChannels subModel ->
            viewPage device GotJoinAndLeaveChannelsMsg (JoinAndLeaveChannels.view subModel)

        SendAndReceive subModel ->
            viewPage device GotSendAndReceiveMsg (SendAndReceive.view subModel)


viewPage : Device -> (msg -> Msg) -> { title : String, content : Element msg } -> Document Msg
viewPage device toMsg pageConfig =
    let
        { title, body } =
            Page.view device pageConfig
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
