module Login exposing (main)

import Browser
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



-- MAIN


main : Program () LoginOptions Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type LoginOptions
    = Login LoginForm
    | SignUp SignUpForm


type alias SignUpForm =
    { username : String
    , email : String
    , password : String
    , serverResponse : String
    }


type alias LoginForm =
    { username : String
    , password : String
    , serverResponse : String
    }


emptyLoginForm : LoginForm
emptyLoginForm =
    LoginForm "" "" ""


emptySignUpForm : SignUpForm
emptySignUpForm =
    SignUpForm "" "" "" ""



-- INIT


init : () -> ( LoginOptions, Cmd msg )
init _ =
    ( Login emptyLoginForm
    , Cmd.none
    )



-- UPDATE


baseUrl : String
baseUrl =
    "http://127.0.0.1:8000"


loginAuthUrl : String
loginAuthUrl =
    baseUrl ++ "/api/login"


type Msg
    = UpdateLoginForm LoginForm
    | UpdateSignUpForm SignUpForm
    | GotoSignUp
    | GotoLogin
    | SendLoginRequest
    | ReceivedLoginRequestResponse (Result Http.Error String)


encodeLoginCreds : LoginOptions -> JsonEncode.Value
encodeLoginCreds loginOptions =
    let
        loginCreds =
            case loginOptions of
                Login loginData ->
                    loginData

                SignUp _ ->
                    emptyLoginForm
    in
    JsonEncode.object
        [ ( "username", JsonEncode.string loginCreds.username )
        , ( "password", JsonEncode.string loginCreds.password )
        ]


sendLoginRequest : LoginOptions -> Cmd Msg
sendLoginRequest loginOptions =
    Http.post
        { url = loginAuthUrl
        , body = Http.jsonBody (encodeLoginCreds loginOptions)
        , expect = Http.expectString ReceivedLoginRequestResponse
        }


update : Msg -> LoginOptions -> ( LoginOptions, Cmd Msg )
update msg loginOptions =
    case msg of
        UpdateLoginForm loginForm ->
            ( Login loginForm
            , Cmd.none
            )

        UpdateSignUpForm signUpForm ->
            ( SignUp signUpForm
            , Cmd.none
            )

        GotoSignUp ->
            ( SignUp emptySignUpForm
            , Cmd.none
            )

        GotoLogin ->
            ( Login emptyLoginForm
            , Cmd.none
            )

        SendLoginRequest ->
            ( loginOptions
            , sendLoginRequest loginOptions
            )

        ReceivedLoginRequestResponse response ->
            case response of
                -- TODO - actually handle the errors! - https://package.elm-lang.org/packages/elm/http/latest/Http#Error
                Err _ ->
                    case loginOptions of
                        Login loginForm ->
                            ( Login { loginForm | serverResponse = "ERROR!" }
                            , Cmd.none
                            )

                        SignUp _ ->
                            ( Login { emptyLoginForm | serverResponse = "ERROR!" }
                            , Cmd.none
                            )

                Ok responseString ->
                    case loginOptions of
                        Login loginForm ->
                            ( Login { emptyLoginForm | serverResponse = responseString }
                            , Cmd.none
                            )

                        SignUp _ ->
                            ( Login { emptyLoginForm | serverResponse = responseString }
                            , Cmd.none
                            )



-- SUBSCRIPTIONS


subscriptions : LoginOptions -> Sub msg
subscriptions loginFormOptions =
    Sub.none



-- VIEW


baseBgColour =
    Elem.rgb 0.09 0.09 0.1


elementBgColour =
    Elem.rgb 0.2 0.2 0.23


inputFieldBgColour =
    Elem.rgb 0.25 0.25 0.28


baseFontFgColor =
    Elem.rgb 0.9 0.9 0.9


colourLightGreen =
    Elem.rgb 0.3 0.5 0.3


colorBlack =
    Elem.rgb 0 0 0


colorBlue =
    Elem.rgb 0.3 0.3 0.7


view : LoginOptions -> Html Msg
view loginOptions =
    Elem.layout
        [ ElemBg.color baseBgColour
        , ElemFont.color baseFontFgColor
        ]
    <|
        Elem.column
            [ Elem.width Elem.fill
            , Elem.height Elem.fill
            , Elem.centerY
            , Elem.centerX
            ]
            [ navBar
            , Elem.column
                [ Elem.width Elem.shrink
                , Elem.height Elem.shrink
                , Elem.centerX
                , Elem.centerY
                , Elem.padding 60
                , Elem.spacing 25
                , ElemBg.color elementBgColour
                , ElemBorder.rounded 15
                , ElemBorder.shadow
                    { size = 5.0
                    , offset = ( 0.0, 0.0 )
                    , blur = 30.0
                    , color = Elem.rgb 0.05 0.05 0.05
                    }
                ]
                [ formHead
                , formInputs loginOptions
                ]
            ]


navBar : Elem.Element Msg
navBar =
    Elem.row
        [ Elem.width Elem.fill
        , Elem.height Elem.shrink
        , Elem.centerX
        , Elem.padding 25
        , ElemBg.color elementBgColour
        , ElemBorder.shadow
            { size = 3.0
            , offset = ( 0.0, 0.0 )
            , blur = 5.0
            , color = Elem.rgb 0.05 0.05 0.05
            }
        ]
        [ Elem.text "Breakdown"
        ]


formHead : Elem.Element Msg
formHead =
    Elem.column
        [ Elem.centerX
        ]
        [ Elem.row
            [ ElemRegion.heading 1
            , ElemFont.size 36
        
            ]
            [ Elem.text "Welcome to Breakdown!" ]

        -- Acts as spacer
        , Elem.row
            [ Elem.centerX
            , Elem.height (Elem.px 30)
            ]
            []
        ]


formInputs : LoginOptions -> Elem.Element Msg
formInputs loginOptions =
    case loginOptions of
        Login loginForm ->
            Elem.column
                [ Elem.centerX
                , Elem.spacing 30
                ]
                [ ElemInput.username
                    [ ElemBg.color inputFieldBgColour
                    ]
                    { text = loginForm.username
                    , placeholder = Nothing
                    , label = ElemInput.labelAbove [ ElemFont.size 20 ] (Elem.text "Username")
                    , onChange = \newUsername -> UpdateLoginForm { loginForm | username = newUsername }
                    }
                , ElemInput.currentPassword
                    [ ElemBg.color inputFieldBgColour
                    ]
                    { text = loginForm.password
                    , placeholder = Nothing
                    , label = ElemInput.labelAbove [ ElemFont.size 20 ] (Elem.text "Password")
                    , onChange = \newPassword -> UpdateLoginForm { loginForm | password = newPassword }
                    , show = False
                    }
                , ElemInput.button
                    [ ElemFont.size 30
                    , Elem.centerX
                    , Elem.padding 20
                    , ElemBorder.rounded 10
                    , ElemBg.color colourLightGreen
                    ]
                    { onPress = Just SendLoginRequest
                    , label = Elem.text "Login"
                    }

                -- Form Footer
                , Elem.row
                    [ Elem.centerX ]
                    [ Elem.text "Don't have an account?"
                    , ElemInput.button
                        [ ElemFont.size 18
                        , ElemFont.bold
                        , Elem.padding 10
                        , ElemBg.color colorBlue
                        , ElemBorder.rounded 5
                        ]
                        { onPress = Just GotoSignUp
                        , label = Elem.text "SignUp"
                        }
                    ]
                ]

        SignUp signUpForm ->
            Elem.column
                [ Elem.centerX
                , Elem.spacing 30
                ]
                [ ElemInput.username
                    [ ElemBg.color inputFieldBgColour
                    ]
                    { text = signUpForm.username
                    , placeholder = Nothing
                    , label = ElemInput.labelAbove [ ElemFont.size 20 ] (Elem.text "Username")
                    , onChange = \newUsername -> UpdateSignUpForm { signUpForm | username = newUsername }
                    }
                , ElemInput.email
                    [ ElemBg.color inputFieldBgColour
                    ]
                    { text = signUpForm.email
                    , placeholder = Nothing
                    , label = ElemInput.labelAbove [ ElemFont.size 20 ] (Elem.text "Email")
                    , onChange = \newEmail -> UpdateSignUpForm { signUpForm | email = newEmail }
                    }
                , ElemInput.newPassword
                    [ ElemBg.color inputFieldBgColour
                    ]
                    { text = signUpForm.password
                    , placeholder = Nothing
                    , label = ElemInput.labelAbove [ ElemFont.size 20 ] (Elem.text "New Password")
                    , onChange = \newPassword -> UpdateSignUpForm { signUpForm | password = newPassword }
                    , show = False
                    }
                , ElemInput.button
                    [ ElemFont.size 30
                    , Elem.centerX
                    , Elem.padding 20
                    , ElemBorder.rounded 10
                    , ElemBg.color colourLightGreen
                    ]
                    { onPress = Nothing
                    , label = Elem.text "SignUp"
                    }
                , Elem.row
                    [ Elem.centerX ]
                    [ Elem.text "Already have an account?  "
                    , ElemInput.button
                        [ ElemFont.size 18
                        , ElemFont.bold
                        , Elem.padding 10
                        , ElemBg.color colorBlue
                        , ElemBorder.rounded 5
                        ]
                        { onPress = Just GotoLogin
                        , label = Elem.text "Login"
                        }
                    ]
                ]
