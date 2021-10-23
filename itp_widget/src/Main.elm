port module Main exposing (main)

import Browser
import Classification
import HashSet
import Html
import Html.Attributes as Attr
import Html.Events as Event
import ITP
import Json.Decode
import Json.Encode
import List.Extra
import Time
import VegaLite


type alias Flags =
    { provers : List ITP.ITP
    , counterExampleGenerators : List ITP.CounterExampleGenerator
    , msc : List Classification.TopClassification
    }


type alias Model =
    { provers : List ITP.ITP
    , msc : Classification.Classification
    , view : View
    , filteredLibraries : HashSet.HashSet Classification.LibraryDetails
    , openLibrarySection : String
    , showEmptyCategories : Bool
    , showUnverifiedPackages : Bool
    , openPackage : Maybe String
    , showUnclassifiedPackages : Bool
    , counterExampleGenerators : List ITP.CounterExampleGenerator
    }


type ViewModel
    = ProverListViewModel (List ITP.ITP)
    | LibraryViewModel (FeatureViewModel LibraryViewModelData)
    | ProjectViewModel (List ITP.Project)
    | ProverViewModel ITP.ITP
    | CounterExampleViewModel (FeatureViewModel (List ITP.CounterExampleGenerator))
    | GenericFeatureViewModel (FeatureViewModel GenericFeatureViewModelData)


type alias FeatureViewModel a =
    { similarProvers : List ITP.ITP
    , featureInfo : a
    }


type alias GenericFeatureViewModelData =
    { featureName : String
    , featureValue : String
    }


type alias LibraryViewModelData =
    { libraries : List ProverLibraryViewModelData
    , mscChildren : List Classification.MSCClassification
    , openClassificationCodeView : Maybe Classification.MSCDescription
    , showUnclassifiedPackages : Bool
    , showEmptyCategories : Bool
    , hasLibrary : Bool
    , unclassifiedPackages : List PackageView
    , classificationFileContents : String
    , vegaSpec : Json.Decode.Value
    , showUnverifiedPackages : Bool
    , packages : List PackageView
    , openPackage : Maybe PackageView
    }


type alias ClassificationBar =
    { count : Int
    , prover : String
    , msc : String
    , name : String
    }


type alias ProverLibraryViewModelData =
    { library : Classification.LibraryDetails
    , filtered : Bool
    }


type alias PackageView =
    { name : String
    , prover : String
    , msc : String
    , section : String
    , url : String
    , verified : Bool
    , description : String
    , authors : String
    , open : Bool
    }


packageToPackageView : Maybe String -> Classification.Package -> PackageView
packageToPackageView currentlyOpenPackage package =
    { name = package.name
    , url = package.url
    , prover = package.library.prover
    , section = package.library.section
    , description = package.description
    , verified = package.verified
    , authors = package.authors
    , open = Just package.name == currentlyOpenPackage
    , msc = package.msc
    }


type alias File =
    { contents : String
    , name : String
    }


type alias VegaGraph =
    { id : String
    , spec : Json.Decode.Value
    }


port renderVegaSpec : VegaGraph -> Cmd msg


port saveFile : File -> Cmd msg


modelToViewModel : Model -> ViewModel
modelToViewModel model =
    case model.view of
        ProverView prover ->
            ProverViewModel prover

        ProverListView ->
            ProverListViewModel model.provers

        FeatureView (CounterExampleFeatureValue _) ->
            CounterExampleViewModel
                { similarProvers =
                    List.filter
                        (\itp -> List.length itp.counterExampleIntegrations > 0)
                        model.provers
                , featureInfo = model.counterExampleGenerators
                }

        FeatureView (LibraryFeatureValue value) ->
            let
                libraries =
                    List.map (Classification.libraryToLibraryDetails (Classification.codeToPrefix model.openLibrarySection)) <| List.concatMap (\prover -> prover.libraries) model.provers

                all_packages =
                    getClassificationsFromTree
                        (\p ->
                            if model.showUnverifiedPackages then
                                True

                            else
                                p.verified
                        )
                        model.msc
                        model.openLibrarySection

                bars =
                    createClassificationBars all_packages

                codeDescription =
                    Classification.describeCode model.msc model.openLibrarySection

                filter =
                    if model.showUnverifiedPackages then
                        always True

                    else
                        .verified

                viewedPackages =
                    List.map (packageToPackageView model.openPackage) (List.filter (\p -> p.msc == model.openLibrarySection) (List.filter (.library >> flip HashSet.member model.filteredLibraries) (Classification.getAllPackages model.msc)))
            in
            LibraryViewModel
                { similarProvers = List.filter (\itp -> itp.library == value) model.provers
                , featureInfo =
                    { libraries = List.map (\library -> { library = library, filtered = HashSet.member library model.filteredLibraries }) libraries
                    , showUnclassifiedPackages = model.showUnclassifiedPackages
                    , showUnverifiedPackages = model.showUnverifiedPackages
                    , mscChildren =
                        List.filter
                            (\child ->
                                if model.showEmptyCategories then
                                    True

                                else
                                    child.packageCount > 0
                            )
                        <|
                            Maybe.withDefault (Classification.getTop filter model.msc) <|
                                Classification.getChildren
                                    filter
                                    model.msc
                                    model.openLibrarySection
                    , openClassificationCodeView = codeDescription
                    , showEmptyCategories = model.showEmptyCategories
                    , hasLibrary = value
                    , unclassifiedPackages = List.map (packageToPackageView model.openPackage) (List.filter (.library >> flip HashSet.member model.filteredLibraries) (Classification.getUnclassified model.msc))
                    , vegaSpec = createClassifiedPackagesGraph bars
                    , classificationFileContents = packageListToCsv (Classification.getAllPackages model.msc)
                    , packages = viewedPackages
                    , openPackage = List.Extra.find (\p -> Just p.name == model.openPackage) viewedPackages
                    }
                }

        FeatureView ProjectsFeatureValue ->
            let
                projects =
                    List.concat <| List.map (\itp -> itp.projects) model.provers
            in
            ProjectViewModel projects

        FeatureView (GenericFeatureValue name value) ->
            GenericFeatureViewModel
                { similarProvers =
                    List.filter
                        (\itp ->
                            case ITP.attributeByName name of
                                Just attr ->
                                    attr.getValue itp == value

                                Nothing ->
                                    False
                        )
                        model.provers
                , featureInfo =
                    { featureName = name
                    , featureValue = value
                    }
                }


packageListToCsv : List Classification.Package -> String
packageListToCsv packages =
    String.join "\n"
        ("ITP,Library,Name,MSC,Verified"
            :: List.map
                (\p ->
                    String.join ","
                        [ p.library.prover
                        , p.library.section
                        , String.concat [ "\"", p.name, "\"" ]
                        , p.msc
                        , if p.verified then
                            "Yes"

                          else
                            "No"
                        ]
                )
                packages
        )


createClassificationBars : List ClassifiedPackage -> List ClassificationBar
createClassificationBars packages =
    let
        gathered =
            List.Extra.gatherWith (\a b -> a.msc == b.msc && a.prover == b.prover) packages
    in
    List.map (\( value, list ) -> { name = value.mscName, msc = value.msc, prover = value.prover, count = List.length (value :: list) }) gathered


type alias ClassifiedPackage =
    { name : String
    , msc : String
    , section : String
    , verified : Bool
    , prover : String
    , mscName : String
    }


getClassificationsFromTree : (Classification.Package -> Bool) -> Classification.Classification -> String -> List ClassifiedPackage
getClassificationsFromTree filter class code =
    let
        all_packages =
            Classification.getAllPackages class

        childClassifications =
            if code == "??-XX" then
                Classification.getTop filter class

            else
                Maybe.withDefault [] (Classification.getChildren filter class code)
    in
    List.concatMap
        (\child ->
            List.map
                (\package ->
                    { mscName = child.name
                    , msc = child.msc
                    , prover = package.library.prover
                    , section = package.library.section
                    , verified = package.verified
                    , name = package.name
                    }
                )
                (List.filter (.msc >> Classification.underPrefix child.msc) all_packages)
        )
        childClassifications


flip : (a -> b -> c) -> b -> a -> c
flip f x y =
    f y x


type View
    = ProverListView
    | ProverView ITP.ITP
    | FeatureView FeatureValue


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = modelToViewModel >> view
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        libraries =
            List.concatMap .libraries flags.provers
    in
    ( { provers = flags.provers
      , msc = Classification.new flags.msc libraries
      , view = ProverListView
      , openLibrarySection = "??-XX"
      , showEmptyCategories = False
      , openPackage = Nothing
      , showUnclassifiedPackages = False
      , showUnverifiedPackages = False
      , filteredLibraries = HashSet.fromList (List.map (Classification.libraryToLibraryDetails "") libraries) (\library -> library.prover ++ "-" ++ library.section)
      , counterExampleGenerators = flags.counterExampleGenerators
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


type Feature
    = LibraryFeature
    | ProjectsFeature
    | CounterExampleFeature
    | GenericFeature String


type FeatureValue
    = LibraryFeatureValue Bool
    | ProjectsFeatureValue
    | CounterExampleFeatureValue Bool
    | GenericFeatureValue String String


allFeatures : List Feature
allFeatures =
    [ LibraryFeature
    , CounterExampleFeature
    , GenericFeature "Math Symbols"
    ]


featureToText : Feature -> String
featureToText feature =
    case feature of
        LibraryFeature ->
            "Library Support"

        ProjectsFeature ->
            "Project Support"

        CounterExampleFeature ->
            "Counter Example Support"

        GenericFeature name ->
            name


type Msg
    = FocusView View
    | OpenLibrarySection String
    | DownloadFile String String
    | OpenPackage String
    | ShowUnclassifiedPackages Bool
    | SetSeeEmpty Bool
    | ToggleShowLibrary Classification.LibraryDetails Bool
    | SetShowUnverified Bool


createITPOverviewChart : Model -> VegaLite.Spec
createITPOverviewChart model =
    let
        all_packages =
            Classification.getAllPackages model.msc

        bars =
            List.Extra.gatherEqualsBy (.library >> .prover) all_packages

        data =
            VegaLite.dataFromRows []
                (List.concatMap
                    (\( example, packages ) ->
                        let
                            ( excluded, notExcluded ) =
                                List.partition Classification.packageIsExcluded (example :: packages)

                            ( verified, unverified ) =
                                List.partition .verified notExcluded
                        in
                        VegaLite.dataRow
                            [ ( "prover", VegaLite.str example.library.prover )
                            , ( "class", VegaLite.str "verified" )
                            , ( "count", VegaLite.num (toFloat (List.length verified)) )
                            ]
                            (List.concat
                                [ VegaLite.dataRow
                                    [ ( "prover", VegaLite.str example.library.prover )
                                    , ( "class", VegaLite.str "unverified" )
                                    , ( "count", VegaLite.num (toFloat <| List.length unverified) )
                                    ]
                                    []
                                , VegaLite.dataRow
                                    [ ( "prover", VegaLite.str example.library.prover )
                                    , ( "class", VegaLite.str "excluded" )
                                    , ( "count", VegaLite.num (toFloat <| List.length excluded) )
                                    ]
                                    []
                                ]
                            )
                    )
                    bars
                )

        enc =
            VegaLite.encoding
                << VegaLite.column [ VegaLite.fName "prover", VegaLite.fHeader [ VegaLite.hdOrient VegaLite.siBottom ] ]
                << VegaLite.position VegaLite.X [ VegaLite.pName "class", VegaLite.pAxis [] ]
                << VegaLite.color [ VegaLite.mName "class", VegaLite.mTitle "Classification" ]
                << VegaLite.position VegaLite.Y
                    [ VegaLite.pName "count"
                    , VegaLite.pAggregate VegaLite.opSum
                    , VegaLite.pTitle "Package Count"
                    , VegaLite.pAxis [ VegaLite.axGrid False ]
                    ]
                << VegaLite.tooltips [ [ VegaLite.tName "prover" ], [ VegaLite.tName "count" ], [ VegaLite.tName "class" ] ]

        mark =
            VegaLite.bar

        conf =
            VegaLite.configure
                << VegaLite.configuration (VegaLite.coView [ VegaLite.vicoStroke (Just "transparent") ])
    in
    VegaLite.toVegaLite [ data, enc [], mark [], conf [] ]


createSingleCategoryBarChart : Model -> VegaLite.Spec
createSingleCategoryBarChart model =
    let
        all_packages =
            List.filter
                (if model.showUnverifiedPackages then
                    always True

                 else
                    .verified
                )
                (Classification.getAllPackages model.msc)

        filtered_packages =
            List.filter (.msc >> (==) model.openLibrarySection) all_packages

        bars =
            List.Extra.gatherEqualsBy (.library >> .prover) filtered_packages

        data =
            VegaLite.dataFromRows []
                (List.concatMap
                    (\( example, packages ) ->
                        VegaLite.dataRow
                            [ ( "prover", VegaLite.str example.library.prover )
                            , ( "count", VegaLite.num (toFloat (List.length (example :: packages))) )
                            ]
                            []
                    )
                    bars
                )

        enc =
            VegaLite.encoding
                << VegaLite.position VegaLite.X [ VegaLite.pName "prover", VegaLite.pTitle "Theorem Prover", VegaLite.pSort [ VegaLite.soByChannel VegaLite.chY, VegaLite.soDescending ] ]
                << VegaLite.color [ VegaLite.mName "prover", VegaLite.mTitle "Prover" ]
                << VegaLite.position VegaLite.Y [ VegaLite.pName "count", VegaLite.pAggregate VegaLite.opSum, VegaLite.pTitle "Package Count" ]
                << VegaLite.tooltips [ [ VegaLite.tName "prover" ], [ VegaLite.tName "count" ] ]

        mark =
            VegaLite.bar []
    in
    VegaLite.toVegaLite [ data, enc [], mark ]


updateVegaSpec : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
updateVegaSpec ( model, command ) =
    case Classification.classifyCode model.openLibrarySection of
        Just (Classification.BottomLevel _ _) ->
            ( model, Cmd.batch [ command, renderVegaSpec (VegaGraph "library-graph" <| createSingleCategoryBarChart model) ] )

        Just (Classification.BotFromTop _) ->
            ( model, Cmd.batch [ command, renderVegaSpec (VegaGraph "library-graph" <| createSingleCategoryBarChart model) ] )

        _ ->
            let
                all_packages =
                    getClassificationsFromTree
                        (\p ->
                            if model.showUnverifiedPackages then
                                True

                            else
                                p.verified
                        )
                        model.msc
                        model.openLibrarySection

                bars =
                    createClassificationBars
                        (List.filter
                            (\p ->
                                if model.showUnverifiedPackages then
                                    True

                                else
                                    p.verified
                            )
                            all_packages
                        )
            in
            ( model, Cmd.batch [ command, renderVegaSpec (VegaGraph "library-graph" (createClassifiedPackagesGraph bars)) ] )


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        SetShowUnverified value ->
            updateVegaSpec <| ( { model | showUnverifiedPackages = value }, Cmd.none )

        SetSeeEmpty value ->
            ( { model | showEmptyCategories = value }, Cmd.none )

        FocusView (FeatureView (LibraryFeatureValue True)) ->
            updateVegaSpec <| ( { model | view = FeatureView (LibraryFeatureValue True) }, renderVegaSpec (VegaGraph "overview-graph" (createITPOverviewChart model)) )

        FocusView newView ->
            ( { model | view = newView }, Cmd.none )

        OpenLibrarySection section ->
            updateVegaSpec <| ( { model | openLibrarySection = section, openPackage = Nothing }, Cmd.none )

        OpenPackage section ->
            ( { model | openPackage = Just section }, Cmd.none )

        ShowUnclassifiedPackages show ->
            ( { model | showUnclassifiedPackages = show }, Cmd.none )

        ToggleShowLibrary library show ->
            ( { model
                | filteredLibraries =
                    if show then
                        HashSet.insert library model.filteredLibraries

                    else
                        HashSet.remove library model.filteredLibraries
              }
            , Cmd.none
            )

        DownloadFile name contents ->
            ( model, saveFile { contents = contents, name = name } )


view : ViewModel -> Html.Html Msg
view model =
    case model of
        ProverViewModel prover ->
            featureFrame <| viewProverInterface prover

        ProverListViewModel provers ->
            Html.table []
                (viewTableHeader
                    :: List.map viewProverCard provers
                )

        LibraryViewModel { similarProvers, featureInfo } ->
            featureFrame <| viewLibrary similarProvers featureInfo

        ProjectViewModel projects ->
            featureFrame <| viewProjects projects

        CounterExampleViewModel { similarProvers, featureInfo } ->
            featureFrame <| viewCounterExampleGenerators similarProvers featureInfo

        GenericFeatureViewModel { similarProvers, featureInfo } ->
            featureFrame <| viewGenericValue similarProvers featureInfo


list_text : List String -> String
list_text texts =
    case texts of
        [] ->
            ""

        [ item ] ->
            item

        [ x1, x2 ] ->
            String.concat [ x1, " and ", x2 ]

        x1 :: x2 :: x3 ->
            x1 ++ ", " ++ list_text (x2 :: x3)


viewCounterExampleGenerators : List ITP.ITP -> List ITP.CounterExampleGenerator -> Html.Html Msg
viewCounterExampleGenerators similarProvers cegs =
    Html.div []
        [ Html.p [] [ Html.text "Current counterexample generators or ITPS" ]
        , Html.div []
            (List.map
                (\ceg ->
                    Html.div []
                        [ Html.b [] [ Html.text <| ceg.name ++ ": " ]
                        , Html.text ceg.description
                        , Html.text " "
                        , Html.span []
                            [ Html.text <|
                                list_text (List.map .prover (List.filter (\i -> i.name == ceg.name) (List.concatMap .counterExampleIntegrations similarProvers)))
                            ]
                        ]
                )
                cegs
            )
        ]


formatDate : Time.Posix -> String
formatDate time =
    String.join " " [ formatMonth (Time.toMonth Time.utc time), String.fromInt (Time.toYear Time.utc time) ]


formatMonth : Time.Month -> String
formatMonth month =
    case month of
        Time.Jan ->
            "January"

        Time.Feb ->
            "Febuary"

        Time.Mar ->
            "March"

        Time.Apr ->
            "April"

        Time.May ->
            "May"

        Time.Jun ->
            "June"

        Time.Jul ->
            "July"

        Time.Aug ->
            "August"

        Time.Sep ->
            "September"

        Time.Oct ->
            "October"

        Time.Nov ->
            "November"

        Time.Dec ->
            "December"


viewProverInterface : ITP.ITP -> Html.Html Msg
viewProverInterface prover =
    Html.div []
        [ Html.a [ Attr.href prover.homepage ] [ Html.h2 [ Attr.class "prover-title" ] [ Html.img [ Attr.src prover.logo, Attr.width 50 ] [], Html.span [ Attr.class "prover-name" ] [ Html.text prover.name ] ] ]
        , Html.div [ Attr.class "prover-details" ]
            [ Html.p []
                [ Html.text
                    (if prover.firstRelease /= "" then
                        "First Released: " ++ prover.firstRelease

                     else
                        ""
                    )
                ]
            , Html.p []
                [ Html.text "Latest Release: "
                , if prover.lastReleaseUrl /= "" then
                    Html.a [ Attr.href prover.lastReleaseUrl ] [ Html.text prover.lastReleaseName ]

                  else
                    Html.text prover.lastReleaseName
                , Html.text <| String.concat [ " (", formatDate (Time.millisToPosix prover.lastReleaseDate), ")" ]
                ]
            ]
        , Html.div []
            (List.map
                (\attribute ->
                    Html.div []
                        [ Html.h3 [ Attr.class "clickable", Event.onClick (FocusView (FeatureView (GenericFeatureValue attribute.name (attribute.getValue prover)))) ] [ Html.text (String.concat [ attribute.name, ": ", attribute.toName <| attribute.getValue prover ]) ]
                        , attribute.viewValue (attribute.getValue prover)
                        ]
                )
                ITP.allAttributes
            )
        ]


viewGenericValue : List ITP.ITP -> GenericFeatureViewModelData -> Html.Html Msg
viewGenericValue similarProvers { featureName, featureValue } =
    let
        matches =
            List.filter (\attribute -> featureName == attribute.name) ITP.allAttributes
    in
    case matches of
        [ attribute ] ->
            Html.div []
                [ Html.h2 [] [ Html.text (String.concat [ attribute.name, ": ", attribute.toName featureValue ]) ]
                , Html.p []
                    [ Html.b [] [ Html.text "Other Possible Values: " ]
                    , otherOptionsSelector featureValue attribute.possibilities attribute.toName (GenericFeatureValue featureName)
                    ]
                , Html.p []
                    [ Html.b [] [ Html.text "Provers with this feature: " ]
                    , viewSimilarProvers similarProvers
                    ]
                , attribute.viewValue featureValue
                ]

        _ ->
            Html.text "Invalid Attribute"


viewTableHeader : Html.Html Msg
viewTableHeader =
    Html.tr []
        ([ Html.th [] [ Html.text "" ]
         , Html.th [] [ Html.text "Name" ]
         ]
            ++ List.map (\feature -> Html.th [] [ Html.text (featureToText feature) ]) allFeatures
        )


viewFeatureCell : ITP.ITP -> Feature -> Html.Html Msg
viewFeatureCell prover feature =
    case feature of
        LibraryFeature ->
            if prover.library then
                let
                    allPackages =
                        List.concatMap (\l -> List.filter (Classification.packageIsExcluded >> not) l.entries) prover.libraries

                    allPackageCount =
                        List.length allPackages

                    verifiedPackageCount =
                        List.length (List.filter .verified allPackages)
                in
                Html.span [ Attr.class "clickable", Event.onClick (FocusView (FeatureView (LibraryFeatureValue True))) ] [ Html.text <| String.concat [ "Total Modules: ", String.fromInt allPackageCount, ". Verified Modules: ", String.fromInt verifiedPackageCount, "." ] ]

            else
                Html.span [ Attr.class "clickable", Event.onClick (FocusView (FeatureView (LibraryFeatureValue False))) ] [ Html.text "Does not have library support" ]

        ProjectsFeature ->
            Html.span [ Attr.class "clickable", Event.onClick (FocusView (FeatureView ProjectsFeatureValue)) ] [ Html.text <| String.fromInt (List.length prover.projects) ++ " projects" ]

        CounterExampleFeature ->
            let
                hasSupport =
                    List.length prover.counterExampleIntegrations > 0
            in
            Html.span [ Attr.class "clickable", Event.onClick (FocusView (FeatureView (CounterExampleFeatureValue hasSupport))) ]
                [ Html.text
                    (if hasSupport then
                        "Support"

                     else
                        "No Support"
                    )
                ]

        GenericFeature name ->
            case ITP.attributeByName name of
                Just attribute ->
                    Html.span [ Attr.class "clickable", Event.onClick (FocusView (FeatureView (GenericFeatureValue name (attribute.getValue prover)))) ] [ Html.text (attribute.toName (attribute.getValue prover)) ]

                Nothing ->
                    Html.text "Invalid Attribute"


featureFrame : Html.Html Msg -> Html.Html Msg
featureFrame body =
    Html.div []
        [ Html.div [] [ Html.button [ Event.onClick (FocusView ProverListView) ] [ Html.text "Back" ] ]
        , body
        ]


boolToText : Bool -> String
boolToText value =
    if value then
        "Yes"

    else
        "No"


otherOptionsSelector : a -> List a -> (a -> String) -> (a -> FeatureValue) -> Html.Html Msg
otherOptionsSelector current list toString message =
    Html.span [ Attr.class "option-selector" ]
        (List.map
            (\possibleValue ->
                (if possibleValue == current then
                    Html.strong

                 else
                    Html.span
                )
                    [ Attr.class "option", Event.onClick (FocusView (FeatureView (message possibleValue))) ]
                    [ Html.text (toString possibleValue) ]
            )
            list
        )


viewSimilarProvers : List ITP.ITP -> Html.Html Msg
viewSimilarProvers similarProvers =
    Html.span [] (List.intersperse (Html.text " ") (List.map (\prover -> Html.span [ Attr.class "clickable", Event.onClick (FocusView (ProverView prover)) ] [ Html.text prover.name ]) similarProvers))


viewLibrary : List ITP.ITP -> LibraryViewModelData -> Html.Html Msg
viewLibrary similarProvers { openClassificationCodeView, mscChildren, showEmptyCategories, unclassifiedPackages, hasLibrary, showUnclassifiedPackages, libraries, vegaSpec, classificationFileContents, showUnverifiedPackages, packages, openPackage } =
    Html.div []
        [ Html.h3 [] [ Html.text "Library Support" ]
        , Html.p []
            [ Html.b [] [ Html.text "Other Possible Values: " ]
            , otherOptionsSelector hasLibrary [ True, False ] boolToText LibraryFeatureValue
            ]
        , Html.p []
            [ Html.b [] [ Html.text "Provers with this feature: " ]
            , viewSimilarProvers similarProvers
            ]
        , if hasLibrary then
            Html.div []
                [ Html.text "Provers that have libraries allow for the extension of their cabalities through libraries and packages. The following provers have libraries "
                , Html.div [ Attr.id "overview-graph" ] []
                , Html.div [] [ checkbox "Show empty categories" showEmptyCategories SetSeeEmpty ]
                , Html.div [] [ checkbox "Show unverified packages" showUnverifiedPackages SetShowUnverified ]
                , viewClassification openClassificationCodeView mscChildren
                , Html.div [ Attr.id "library-graph" ] []
                , Html.div [] [ viewLibraryDetails libraries ]
                , Html.details []
                    [ Html.summary [] [ Html.text "Downloads" ]
                    , Html.button [ Event.onClick (DownloadFile "library_graph.json" (Json.Encode.encode 0 vegaSpec)) ] [ Html.text "Download vega lite spec" ]
                    , Html.button [ Event.onClick (DownloadFile "library_stats.csv" (createLibraryCsv libraries)) ] [ Html.text "Download library stats" ]
                    , Html.button [ Event.onClick (DownloadFile "classification.csv" classificationFileContents) ] [ Html.text "Download all modules" ]
                    ]
                , Html.h3 [] [ Html.text "Packages of this category:" ]
                , viewPackageList packages
                , Maybe.withDefault (Html.div [] []) (Maybe.map viewPackageDetails openPackage)
                , Html.div [ Attr.class "clickable", Event.onClick (ShowUnclassifiedPackages (not showUnclassifiedPackages)) ] [ Html.strong [] [ Html.text "Unclassified Packages" ] ]
                , Html.div []
                    (if showUnclassifiedPackages then
                        [ viewPackageList unclassifiedPackages ]

                     else
                        []
                    )
                ]

          else
            Html.div [] [ Html.text "Provers that do not have library support are often heavily automated" ]
        ]


createLibraryCsv : List ProverLibraryViewModelData -> String
createLibraryCsv libraries =
    String.join "\n"
        ("ITP,Library,Total,Verified,Classified,Excluded"
            :: List.map
                (\lib ->
                    String.join ","
                        [ lib.library.prover
                        , lib.library.section
                        , String.fromInt lib.library.totalPackageCount
                        , String.fromInt lib.library.totalVerifiedPackages
                        , String.fromInt lib.library.totalClassifiedPackages
                        , String.fromInt lib.library.totalExcludedPackages
                        ]
                )
                libraries
        )


formatFloat : Float -> String
formatFloat x =
    String.fromInt (floor x) ++ "." ++ String.fromInt (floor (x * 100) - floor x * 100)


viewLibraryDetails : List ProverLibraryViewModelData -> Html.Html Msg
viewLibraryDetails libraryList =
    Html.table []
        [ Html.thead [] [ Html.th [] [ Html.text "Prover" ], Html.th [] [ Html.text "Library" ], Html.th [] [ Html.text "Total Packages" ], Html.th [] [ Html.text "Verified Packages" ], Html.th [] [ Html.text "Classified Packages" ], Html.th [] [ Html.text "Excluded Packages" ] ]
        , Html.tbody []
            (List.map
                (\model ->
                    Html.tr []
                        [ Html.td [] [ Html.text model.library.prover ]
                        , Html.td [] [ Html.a [ Attr.href model.library.url, Attr.target "_blank" ] [ Html.text model.library.section ] ]
                        , Html.td [] [ Html.text <| String.fromInt model.library.totalPackageCount ]
                        , Html.td [] [ Html.text <| String.fromInt model.library.totalVerifiedPackages ++ " (" ++ formatFloat (toFloat model.library.totalVerifiedPackages / toFloat model.library.totalPackageCount * 100) ++ "%)" ]
                        , Html.td [] [ Html.text <| String.fromInt model.library.totalClassifiedPackages ++ " (" ++ formatFloat (toFloat model.library.totalClassifiedPackages / toFloat model.library.totalPackageCount * 100) ++ "%)" ]
                        , Html.td [] [ Html.text <| String.fromInt model.library.totalExcludedPackages ]
                        ]
                )
                (List.filter (\lib -> lib.library.totalPackageCount > 0) libraryList)
            )
        ]


descriptionToClassification : Classification.MSCDescription -> Classification.MSCClassification
descriptionToClassification descr =
    case descr of
        Classification.TopCodeDescr x ->
            x

        Classification.MidCodeDescr _ x ->
            x

        Classification.BotFromTopCodeDesc _ x ->
            x

        Classification.BotCodeDescr _ _ x ->
            x


viewClassification : Maybe Classification.MSCDescription -> List Classification.MSCClassification -> Html.Html Msg
viewClassification currentlyOpenSection children =
    Html.details []
        [ Html.summary [] [ Html.text <| Maybe.withDefault "All Topics" (Maybe.map (descriptionToClassification >> (\section -> section.msc ++ ": " ++ section.name)) currentlyOpenSection) ]
        , Html.ul []
            [ Html.li []
                [ Html.b [ Attr.class "clickable", Event.onClick (OpenLibrarySection "??-XX") ] [ Html.text "All Topics" ]
                , case currentlyOpenSection of
                    Nothing ->
                        viewClassificationOptions children

                    Just (Classification.TopCodeDescr classification) ->
                        Html.ul []
                            [ Html.li []
                                [ Html.b [ Attr.class "clickable", Event.onClick (OpenLibrarySection classification.msc) ] [ Html.text (classification.msc ++ ": " ++ classification.name) ]
                                , viewClassificationOptions children
                                ]
                            ]

                    Just (Classification.MidCodeDescr topClass midClass) ->
                        Html.ul []
                            [ Html.li []
                                [ Html.b [ Attr.class "clicakble", Event.onClick (OpenLibrarySection topClass.msc) ] [ Html.text (topClass.msc ++ ": " ++ topClass.name) ]
                                , Html.ul [] [ Html.li [] [ Html.b [] [ Html.text (midClass.msc ++ ": " ++ midClass.name) ], viewClassificationOptions children ] ]
                                ]
                            ]

                    Just (Classification.BotFromTopCodeDesc topClass midClass) ->
                        Html.ul []
                            [ Html.li []
                                [ Html.b [ Attr.class "clickable", Event.onClick (OpenLibrarySection topClass.msc) ] [ Html.text (topClass.msc ++ ": " ++ topClass.name) ]
                                , Html.ul [] [ Html.li [] [ Html.b [] [ Html.text (midClass.msc ++ ": " ++ midClass.name) ], viewClassificationOptions children ] ]
                                ]
                            ]

                    Just (Classification.BotCodeDescr topClass midClass botClass) ->
                        Html.ul []
                            [ Html.li []
                                [ Html.b [ Attr.class "clickable", Event.onClick (OpenLibrarySection topClass.msc) ] [ Html.text (topClass.msc ++ ": " ++ topClass.name) ]
                                , Html.ul []
                                    [ Html.li []
                                        [ Html.b [ Attr.class "clickable", Event.onClick (OpenLibrarySection midClass.msc) ] [ Html.text (midClass.msc ++ ": " ++ midClass.name) ]
                                        , Html.ul [] [ Html.li [] [ Html.b [] [ Html.text (botClass.msc ++ ": " ++ botClass.name) ] ] ]
                                        ]
                                    ]
                                ]
                            ]
                ]
            ]
        ]


viewClassificationOptions : List Classification.MSCClassification -> Html.Html Msg
viewClassificationOptions classifications =
    Html.ul []
        (List.map
            (\model ->
                Html.li []
                    [ Html.li []
                        [ Html.span
                            [ Event.onClick (OpenLibrarySection model.msc)
                            , Attr.class <|
                                if model.packageCount == 0 then
                                    "emptycategory clickable"

                                else
                                    "clickable"
                            ]
                            [ Html.text (model.msc ++ ": " ++ model.name ++ " (" ++ String.fromInt model.packageCount ++ " packages)") ]
                        ]
                    ]
            )
            classifications
        )


viewPackageList : List PackageView -> Html.Html Msg
viewPackageList packages =
    let
        grouped =
            List.Extra.gatherWith (\a b -> a.prover == b.prover && a.section == b.section) packages
    in
    Html.div []
        (List.map
            (\( example, packageList ) ->
                Html.span []
                    [ Html.span [ Attr.class "package-itp-name" ] [ Html.text example.prover ]
                    , Html.span [ Attr.class "package-itp-library" ] [ Html.text example.section ]
                    , Html.span [] (List.map viewPackage (example :: packageList))
                    ]
            )
            grouped
        )


viewPackage : PackageView -> Html.Html Msg
viewPackage package =
    Html.div
        [ Attr.class "package" ]
        [ (if package.open then
            Html.b

           else
            Html.span
          )
            [ Attr.class <|
                if package.verified then
                    "verified clickable"

                else
                    "unverified clickable"
            , Event.onClick (OpenPackage package.name)
            ]
            [ Html.text package.name ]
        ]


viewPackageDetails : PackageView -> Html.Html Msg
viewPackageDetails package =
    Html.div []
        [ Html.h4 [] [ Html.text package.name ]
        , Html.div [] [ Html.a [ Attr.href package.url ] [ Html.text "Homepage" ] ]
        , Html.div [] [ Html.text package.description ]
        , Html.div [] [ Html.text package.authors ]
        ]


viewProjects : List ITP.Project -> Html.Html Msg
viewProjects model =
    Html.div []
        [ Html.text "Projects done by a prover"
        , Html.div [] <|
            List.map viewProjectCard model
        ]


viewProjectCard : ITP.Project -> Html.Html Msg
viewProjectCard project =
    Html.div []
        [ Html.h4 []
            [ Html.text
                (project.prover
                    ++ ": "
                    ++ project.name
                    ++ (case ( project.startDate, project.endDate ) of
                            ( Just startDate, Just endDate ) ->
                                "(" ++ String.fromInt startDate ++ "-" ++ String.fromInt endDate ++ ")"

                            ( Just startDate, Nothing ) ->
                                "(" ++ String.fromInt startDate ++ ")"

                            _ ->
                                ""
                       )
                )
            ]
        , Html.p [] [ Html.text ("Category: " ++ project.category) ]
        , Html.p [] [ Html.a [ Attr.href project.website ] [ Html.text "website" ] ]
        , Html.i [] [ Html.text project.author ]
        , Html.p [] [ Html.text project.description ]
        ]


viewProverCard : ITP.ITP -> Html.Html Msg
viewProverCard itp =
    Html.tr []
        ([ Html.td
            [ Attr.class "clickable"
            , Event.onClick (FocusView (ProverView itp))
            ]
            [ Html.img [ Attr.src itp.logo, Attr.width 50 ] [] ]
         , Html.td
            [ Attr.class "clickable"
            , Event.onClick (FocusView (ProverView itp))
            ]
            [ Html.text itp.name ]
         ]
            ++ List.map (viewFeatureCell itp >> List.singleton >> Html.td []) allFeatures
        )


checkbox : String -> Bool -> (Bool -> a) -> Html.Html a
checkbox name value msg =
    Html.span []
        [ Html.label [] [ Html.text name ]
        , Html.input [ Attr.checked value, Attr.type_ "checkbox", Event.onClick (msg (not value)) ] []
        ]


createClassifiedPackagesGraph : List ClassificationBar -> VegaLite.Spec
createClassifiedPackagesGraph classification =
    let
        data =
            VegaLite.dataFromRows []
                (List.concatMap
                    (\bar ->
                        VegaLite.dataRow
                            [ ( "code", VegaLite.str bar.msc )
                            , ( "prover", VegaLite.str bar.prover )
                            , ( "count", VegaLite.num (toFloat bar.count) )
                            , ( "msc-name", VegaLite.str bar.name )
                            ]
                            []
                    )
                    classification
                )

        enc =
            VegaLite.encoding
                << VegaLite.position VegaLite.X [ VegaLite.pName "msc-name", VegaLite.pTitle "MSC Classification", VegaLite.pSort [ VegaLite.soByChannel VegaLite.chY, VegaLite.soDescending ] ]
                << VegaLite.color [ VegaLite.mName "prover", VegaLite.mTitle "Prover" ]
                << VegaLite.position VegaLite.Y [ VegaLite.pName "count", VegaLite.pAggregate VegaLite.opSum, VegaLite.pTitle "Package Count" ]
                << VegaLite.tooltips [ [ VegaLite.tName "prover" ], [ VegaLite.tName "count" ], [ VegaLite.tName "msc-name" ] ]

        mark =
            VegaLite.bar []
    in
    VegaLite.toVegaLite [ data, enc [], mark ]
