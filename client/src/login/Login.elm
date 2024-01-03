module Login exposing (main)

import Browser
import Browser.Navigation as Nav
import Components
import Element as Elem
import Element.Background as ElemBg
import Element.Border as ElemBorder
import Element.Font as ElemFont
import Element.Input as ElemInput
import Element.Region as ElemRegion
import Html exposing (Html)
import Http
import Json.Decode as JsonDecode
import Json.Encode as JsonEncode
import PageStyle as Style



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type Model
    = Login



-- INIT


init : () -> ( Model, Cmd msg )
init _ =
    ( Login
    , Cmd.none
    )



-- UPDATE


baseUrl : String
baseUrl =
    "http://127.0.0.1:8000"


loginAuthUrl : String
loginAuthUrl =
    baseUrl ++ "/api/login"


dashboardUrl : String
dashboardUrl =
    baseUrl ++ "/dashboard"


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    Elem.layout
        [ ElemBg.color Style.baseBgColour
        , ElemFont.color Style.baseFontFgColor
        ]
    <|
        Elem.text "login page loaded"
