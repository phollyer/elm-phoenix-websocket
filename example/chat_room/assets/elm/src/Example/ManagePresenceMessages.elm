module Example.ManagePresenceMessages exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Extra.String as String
import Json.Decode as JD
import Json.Decode.Extra exposing (andMap)
import Json.Encode as JE exposing (Value)
import Phoenix
import UI
import View.ApplicableFunctions as ApplicableFunctions
import View.Button as Button
import View.Example as Example
import View.ExampleControls as ExampleControls
import View.Feedback as Feedback
import View.FeedbackContent as FeedbackContent
import View.FeedbackInfo as FeedbackInfo
import View.FeedbackPanel as FeedbackPanel
import View.Group as Group
import View.LabelAndValue as LabelAndValue
import View.UsefulFunctions as UsefulFunctions



{- Init -}


init : Device -> Phoenix.Model -> ( Model, Cmd Msg )
init device phoenix =
    let
        ( phx, phxCmd ) =
            Phoenix.join "example_controller:control" phoenix
    in
    ( { device = device
      , phoenix = phx
      , messages = []
      , receiveMessages = True
      , maybeExampleId = Nothing
      , maybeUserId = Nothing
      }
    , Cmd.map GotPhoenixMsg phxCmd
    )



{- Model -}


type alias Model =
    { device : Device
    , phoenix : Phoenix.Model
    , messages : List PresenceInfo
    , receiveMessages : Bool
    , maybeExampleId : Maybe ID
    , maybeUserId : Maybe ID
    }


type alias PresenceInfo =
    { topic : String
    , event : String
    , payload : Value
    }


type alias ID =
    String


type Action
    = Join
    | Leave
    | On
    | Off


pushConfig : Phoenix.Push
pushConfig =
    { topic = ""
    , event = ""
    , payload = JE.null
    , timeout = Nothing
    , retryStrategy = Phoenix.Drop
    , ref = Nothing
    }



{- Update -}


type Msg
    = GotControlClick Action
    | GotPhoenixMsg Phoenix.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotControlClick action ->
            case action of
                Join ->
                    Phoenix.join (controllerTopic model.maybeExampleId) model.phoenix
                        |> updatePhoenix model

                Leave ->
                    Phoenix.leave (controllerTopic model.maybeExampleId) model.phoenix
                        |> updatePhoenix model

                On ->
                    ( { model | receiveMessages = True }
                    , Phoenix.socketPresenceMessagesOn model.phoenix
                        |> Cmd.map GotPhoenixMsg
                    )

                Off ->
                    ( { model | receiveMessages = False }
                    , Phoenix.socketPresenceMessagesOff model.phoenix
                        |> Cmd.map GotPhoenixMsg
                    )

        GotPhoenixMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Phoenix.update subMsg model.phoenix
                        |> updatePhoenix model
            in
            case Phoenix.phoenixMsg newModel.phoenix of
                Phoenix.SocketMessage (Phoenix.PresenceMessage info) ->
                    updateMessages info ( newModel, cmd )

                Phoenix.SocketMessage (Phoenix.ChannelMessage { topic, event, payload }) ->
                    case ( Phoenix.topicParts topic, event ) of
                        ( ( "example_controller", "control" ), "phx_reply" ) ->
                            case decodeExampleIdResponse payload of
                                Ok { response } ->
                                    Phoenix.leave "example_controller:control" newModel.phoenix
                                        |> updatePhoenix { newModel | maybeExampleId = Just response.exampleId }
                                        |> batch [ cmd ]

                                Err _ ->
                                    ( newModel, cmd )

                        ( ( "example_controller", exampleId ), "phx_reply" ) ->
                            case decodeUserIdResponse payload of
                                Ok { response } ->
                                    ( { newModel | maybeUserId = Just response.userId }
                                    , cmd
                                    )

                                Err _ ->
                                    ( newModel, cmd )

                        _ ->
                            ( newModel, cmd )

                _ ->
                    ( newModel, cmd )


controllerTopic : Maybe ID -> String
controllerTopic maybeId =
    case maybeId of
        Just id ->
            "example_controller:" ++ id

        Nothing ->
            ""


updatePhoenix : Model -> ( Phoenix.Model, Cmd Phoenix.Msg ) -> ( Model, Cmd Msg )
updatePhoenix model ( phoenix, phoenixCmd ) =
    ( { model | phoenix = phoenix }
    , Cmd.map GotPhoenixMsg phoenixCmd
    )


updateMessages : PresenceInfo -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
updateMessages info ( model, cmd ) =
    ( { model | messages = info :: model.messages }, cmd )


batch : List (Cmd Msg) -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
batch cmds ( model, cmd ) =
    ( model
    , Cmd.batch (cmd :: cmds)
    )



{- Decoders -}


type alias ExampleIdResponse =
    { response : ExampleID }


type alias ExampleID =
    { exampleId : String }


type alias UserIdResponse =
    { response : UserID }


type alias UserID =
    { userId : String }


decodeExampleIdResponse : Value -> Result JD.Error ExampleIdResponse
decodeExampleIdResponse payload =
    JD.decodeValue exampleIdResponseDecoder payload


exampleIdResponseDecoder : JD.Decoder ExampleIdResponse
exampleIdResponseDecoder =
    JD.succeed
        ExampleIdResponse
        |> andMap (JD.field "response" exampleIdDecoder)


exampleIdDecoder : JD.Decoder ExampleID
exampleIdDecoder =
    JD.succeed
        ExampleID
        |> andMap (JD.field "example_id" JD.string)


decodeUserIdResponse : Value -> Result JD.Error UserIdResponse
decodeUserIdResponse payload =
    JD.decodeValue userIdResponseDecoder payload


userIdResponseDecoder : JD.Decoder UserIdResponse
userIdResponseDecoder =
    JD.succeed
        UserIdResponse
        |> andMap (JD.field "response" userIdDecoder)


userIdDecoder : JD.Decoder UserID
userIdDecoder =
    JD.succeed
        UserID
        |> andMap (JD.field "user_id" JD.string)



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map GotPhoenixMsg <|
        Phoenix.subscriptions model.phoenix



{- View -}


view : Model -> Element Msg
view model =
    Example.init
        |> Example.id model.maybeExampleId
        |> Example.description (description model)
        |> Example.controls (controls model)
        |> Example.feedback (feedback model)
        |> Example.view model.device



{- Description -}


description : Model -> List (Element msg)
description { maybeExampleId } =
    [ UI.paragraph
        [ El.text "Choose whether to receive Presence messages as an incoming Socket message." ]
    ]



{- Controls -}


controls : Model -> Element Msg
controls { device, phoenix, maybeUserId, maybeExampleId, receiveMessages } =
    let
        joinedChannel =
            Phoenix.channelJoined (controllerTopic maybeExampleId) phoenix
    in
    ExampleControls.init
        |> ExampleControls.userId maybeUserId
        |> ExampleControls.elements
            [ join device GotControlClick (not <| joinedChannel)
            , on device (not receiveMessages)
            , off device receiveMessages
            , leave device GotControlClick joinedChannel
            ]
        |> ExampleControls.group
            (Group.init
                |> Group.layouts
                    [ ( Phone, Portrait, [ 2, 2 ] ) ]
                |> Group.order
                    [ ( Phone, Portrait, [ 0, 2, 3, 1 ] ) ]
            )
        |> ExampleControls.view device


join : Device -> (Action -> Msg) -> Bool -> Element Msg
join device onPress enabled =
    Button.init
        |> Button.label "Join"
        |> Button.onPress (Just (onPress Join))
        |> Button.enabled enabled
        |> Button.view device


leave : Device -> (Action -> Msg) -> Bool -> Element Msg
leave device onPress enabled =
    Button.init
        |> Button.label "Leave"
        |> Button.onPress (Just (onPress Leave))
        |> Button.enabled enabled
        |> Button.view device


on : Device -> Bool -> Element Msg
on device enabled =
    Button.init
        |> Button.label "Presence On"
        |> Button.onPress (Just (GotControlClick On))
        |> Button.enabled enabled
        |> Button.view device


off : Device -> Bool -> Element Msg
off device enabled =
    Button.init
        |> Button.label "Presence Off"
        |> Button.onPress (Just (GotControlClick Off))
        |> Button.enabled enabled
        |> Button.view device



{- Feedback -}


feedback : Model -> Element Msg
feedback { device, phoenix, maybeExampleId, messages } =
    Feedback.init
        |> Feedback.elements
            [ FeedbackPanel.init
                |> FeedbackPanel.title "Info"
                |> FeedbackPanel.static (static device messages)
                |> FeedbackPanel.scrollable (scrollable device messages)
                |> FeedbackPanel.view device
            , FeedbackPanel.init
                |> FeedbackPanel.title "Applicable Functions"
                |> FeedbackPanel.scrollable [ applicableFunctions device ]
                |> FeedbackPanel.view device
            , FeedbackPanel.init
                |> FeedbackPanel.title "Useful Functions"
                |> FeedbackPanel.scrollable [ usefulFunctions device phoenix maybeExampleId ]
                |> FeedbackPanel.view device
            ]
        |> Feedback.group
            (Group.init
                |> Group.layouts
                    [ ( Phone, Landscape, [ 1, 2 ] )
                    , ( Tablet, Portrait, [ 1, 2 ] )
                    , ( Tablet, Landscape, [ 1, 2 ] )
                    , ( Desktop, Portrait, [ 1, 2 ] )
                    ]
            )
        |> Feedback.view device


static : Device -> List PresenceInfo -> List (Element Msg)
static device messages =
    [ LabelAndValue.init
        |> LabelAndValue.label "Message Count"
        |> LabelAndValue.value (messages |> List.length |> String.fromInt)
        |> LabelAndValue.view device
    ]


scrollable : Device -> List PresenceInfo -> List (Element Msg)
scrollable device messages =
    List.map
        (\info ->
            FeedbackContent.init
                |> FeedbackContent.title (Just "SocketMessage")
                |> FeedbackContent.label "PresenceMessage"
                |> FeedbackContent.element (presenceInfo device info)
                |> FeedbackContent.view device
        )
        messages


presenceInfo : Device -> PresenceInfo -> Element Msg
presenceInfo device info =
    FeedbackInfo.init
        |> FeedbackInfo.topic info.topic
        |> FeedbackInfo.event info.event
        |> FeedbackInfo.payload info.payload
        |> FeedbackInfo.view device


applicableFunctions : Device -> Element Msg
applicableFunctions device =
    ApplicableFunctions.init
        |> ApplicableFunctions.functions
            [ "Phoenix.join"
            , "Phoenix.socketPresenceMessagesOn"
            , "Phoenix.socketPresenceMessagesOff"
            , "Phoeinx.leave"
            ]
        |> ApplicableFunctions.view device


usefulFunctions : Device -> Phoenix.Model -> Maybe ID -> Element Msg
usefulFunctions device phoenix maybeExampleId =
    let
        topic =
            controllerTopic maybeExampleId
    in
    UsefulFunctions.init
        |> UsefulFunctions.functions
            [ ( "Phoenix.socketState", Phoenix.socketStateToString phoenix )
            , ( "Phoenix.connectionState", Phoenix.connectionState phoenix |> String.printQuoted )
            , ( "Phoenix.isConnected", Phoenix.isConnected phoenix |> String.printBool )
            , ( "Phoenix.channelJoined", Phoenix.channelJoined topic phoenix |> String.printBool )
            , ( "Phoenix.joinedChannels", Phoenix.joinedChannels phoenix |> String.printList )
            , ( "Phoenix.lastPresenceJoin", Phoenix.lastPresenceJoin topic phoenix |> String.printMaybe "Presence" )
            , ( "Phoenix.lastPresenceLeave", Phoenix.lastPresenceLeave topic phoenix |> String.printMaybe "Presence" )
            ]
        |> UsefulFunctions.view device
