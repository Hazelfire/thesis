module Classification exposing
    ( Classification
    , CodeCategory(..)
    , Element(..)
    , LibraryDetails
    , MSCClassification
    , MSCDescription(..)
    , Package
    , TopClassification
    , classifyCode
    , codeToPrefix
    , describeCode
    , getAllPackages
    , getChildren
    , getClassifiedPackages
    , getExcluded
    , getFilteredTree
    , getTop
    , getTree
    , getUnclassified
    , libraryToLibraryDetails
    , new
    , packageIsExcluded
    , packages
    , underPrefix
    )

import Dict
import ITP


type alias BotClassificationCache =
    { name : String
    , code : String
    , packages : List Package
    }


type alias MidClassificationCache =
    { name : String
    , code : String
    , classifications : Dict.Dict String BotClassificationCache
    , packages : List Package
    }


type alias TopClassificationCache =
    { name : String
    , code : String
    , subclassifications : Dict.Dict String MidClassificationCache
    , classifications : Dict.Dict String BotClassificationCache
    , packages : List Package
    }


type ClassificationCache
    = TopClass TopClassificationCache
    | MidClass MidClassificationCache
    | BotClass BotClassificationCache


type alias ClassificationCacheCommon =
    { name : String
    , code : String
    , packages : List Package
    }


classificationCacheToCommon : ClassificationCache -> ClassificationCacheCommon
classificationCacheToCommon cache =
    case cache of
        TopClass class ->
            { name = class.name
            , code = class.code
            , packages = class.packages
            }

        MidClass class ->
            { name = class.name
            , code = class.code
            , packages = class.packages
            }

        BotClass class ->
            { name = class.name
            , code = class.code
            , packages = class.packages
            }


type alias Package =
    { name : String
    , library : LibraryDetails
    , url : String
    , description : String
    , authors : String
    , verified : Bool
    , msc : String
    }


type alias LibraryDetails =
    { prover : String
    , section : String
    , url : String
    , totalPackageCount : Int
    , totalVerifiedPackages : Int
    , totalClassifiedPackages : Int
    , totalExcludedPackages : Int
    }


packageIsUnclassified : { a | msc : String } -> Bool
packageIsUnclassified package =
    package.msc == "None" || package.msc == "NA" || package.msc == ""


packageIsExcluded : { a | msc : String } -> Bool
packageIsExcluded package =
    String.startsWith "Exclude" package.msc


libraryToLibraryDetails : String -> ITP.Library -> LibraryDetails
libraryToLibraryDetails prefix x =
    let
        modules =
            List.filter (\p -> String.startsWith prefix p.msc) x.entries

        excludedCount =
            List.length (List.filter packageIsExcluded modules)
    in
    { prover = x.itp
    , section = x.section
    , url = x.url
    , totalPackageCount = List.length modules
    , totalVerifiedPackages = List.length (List.filter .verified modules)
    , totalClassifiedPackages = List.length (List.filter (packageIsUnclassified >> not) modules) - excludedCount
    , totalExcludedPackages = excludedCount
    }


type alias Classification =
    { classification : Dict.Dict String TopClassificationCache
    , unclassified : List Package
    , excluded : List Package
    , notExcluded : List Package
    }


type alias BotClassification =
    { name : String
    , code : String
    }


type alias MidClassification =
    { name : String
    , code : String
    , classifications : List BotClassification
    }


type alias TopClassification =
    { short_name : String
    , code : String
    , subclassifications : List MidClassification
    , classifications : List BotClassification
    }


new : List TopClassification -> List ITP.Library -> Classification
new classifications libraries =
    { classification = Dict.fromList <| List.map (topParseClassification (packagesFromLibrary "" libraries) >> (\topClass -> ( topClass.code, topClass ))) classifications
    , unclassified = List.filter packageIsUnclassified (packagesFromLibrary "" libraries)
    , excluded = List.filter packageIsExcluded (packagesFromLibrary "" libraries)
    , notExcluded = List.filter (not << packageIsExcluded) (packagesFromLibrary "" libraries)
    }


packagesFromLibrary : String -> List ITP.Library -> List Package
packagesFromLibrary prefix libraries =
    List.concatMap
        (\library ->
            List.map
                (\package ->
                    { name = package.name
                    , url = package.url
                    , description = package.description
                    , authors = package.authors
                    , verified = package.verified
                    , msc = package.msc
                    , library = libraryToLibraryDetails prefix library
                    }
                )
                library.entries
        )
        libraries


topParseClassification : List Package -> TopClassification -> TopClassificationCache
topParseClassification allPackages classification =
    let
        myPackages =
            List.filter (\package -> String.toLower package.msc == String.toLower classification.code) allPackages

        botClasses =
            List.map (botParseClassification allPackages) classification.classifications
                |> List.map (\class -> ( class.code, class ))
                |> Dict.fromList

        midClasses =
            List.map (midParseClassification allPackages) classification.subclassifications
                |> List.map (\class -> ( class.code, class ))
                |> Dict.fromList
    in
    { name = classification.short_name
    , code = classification.code
    , classifications = botClasses
    , subclassifications = midClasses
    , packages = myPackages
    }


midParseClassification : List Package -> MidClassification -> MidClassificationCache
midParseClassification allPackages classification =
    let
        myPackages =
            List.filter (\package -> String.toLower package.msc == String.toLower classification.code) allPackages

        childClassifications =
            List.map (botParseClassification allPackages) classification.classifications
                |> List.map (\class -> ( class.code, class ))
                |> Dict.fromList
    in
    { name = classification.name
    , code = classification.code
    , classifications = childClassifications
    , packages = myPackages
    }


botParseClassification : List Package -> BotClassification -> BotClassificationCache
botParseClassification allPackages classification =
    let
        myPackages =
            List.filter (\package -> String.toLower package.msc == String.toLower classification.code) allPackages
    in
    { name = classification.name
    , code = classification.code
    , packages = myPackages
    }


type CodeCategory
    = TopLevel
    | MidLevel String
    | BotFromTop String
    | BottomLevel String String


classifyCode : String -> Maybe CodeCategory
classifyCode name =
    case String.toInt (String.left 2 name) of
        Just _ ->
            case String.toLower <| String.right 2 name of
                "xx" ->
                    case String.right 1 <| String.left 3 name of
                        "-" ->
                            Just TopLevel

                        _ ->
                            Just (MidLevel (String.append (String.left 2 name) "-XX"))

                _ ->
                    case String.right 1 <| String.left 3 name of
                        "-" ->
                            Just (BotFromTop (String.append (String.left 3 name) "XX"))

                        _ ->
                            Just (BottomLevel (String.append (String.left 2 name) "-XX") (String.append (String.left 3 name) "xx"))

        _ ->
            Nothing


getClassification : Classification -> String -> Maybe ClassificationCache
getClassification classification code =
    classifyCode code
        |> Maybe.andThen
            (\level ->
                case level of
                    TopLevel ->
                        Maybe.map TopClass <| Dict.get code classification.classification

                    MidLevel topLevel ->
                        Maybe.map MidClass
                            (Dict.get topLevel classification.classification
                                |> Maybe.andThen (.subclassifications >> Dict.get code)
                            )

                    BotFromTop topLevel ->
                        Maybe.map BotClass <|
                            (Dict.get topLevel classification.classification
                                |> Maybe.andThen (.classifications >> Dict.get code)
                            )

                    BottomLevel topLevel midLevel ->
                        Maybe.map BotClass <|
                            (Dict.get topLevel classification.classification
                                |> Maybe.andThen (.subclassifications >> Dict.get midLevel)
                                |> Maybe.andThen (.classifications >> Dict.get code)
                            )
            )


type alias MSCClassification =
    { name : String, msc : String, packageCount : Int }


type MSCDescription
    = TopCodeDescr MSCClassification
    | MidCodeDescr MSCClassification MSCClassification
    | BotFromTopCodeDesc MSCClassification MSCClassification
    | BotCodeDescr MSCClassification MSCClassification MSCClassification


codeToPrefix : String -> String
codeToPrefix code =
    if String.toLower code == "??-xx" then
        ""

    else if String.endsWith "-xx" (String.toLower code) then
        String.slice 0 2 code

    else if String.endsWith "xx" (String.toLower code) then
        String.slice 0 3 code

    else
        code


underPrefix : String -> String -> Bool
underPrefix code value =
    String.startsWith (codeToPrefix code) value


describeCode : Classification -> String -> Maybe MSCDescription
describeCode class msc =
    classifyCode msc
        |> Maybe.andThen
            (\classification ->
                case classification of
                    TopLevel ->
                        Maybe.map
                            (\topClass ->
                                TopCodeDescr { name = topClass.name, msc = topClass.code, packageCount = List.length (List.filter (.msc >> underPrefix topClass.code) class.notExcluded) }
                            )
                            (Dict.get msc class.classification)

                    MidLevel topCode ->
                        Dict.get topCode class.classification
                            |> Maybe.andThen
                                (\topClass ->
                                    Maybe.map
                                        (\midClass ->
                                            MidCodeDescr { name = topClass.name, msc = topClass.code, packageCount = List.length (List.filter (.msc >> underPrefix topClass.code) class.notExcluded) }
                                                { name = midClass.name, msc = midClass.code, packageCount = List.length (List.filter (.msc >> underPrefix midClass.code) class.notExcluded) }
                                        )
                                        (Dict.get msc topClass.subclassifications)
                                )

                    BotFromTop topCode ->
                        Dict.get topCode class.classification
                            |> Maybe.andThen
                                (\topClass ->
                                    Maybe.map
                                        (\midClass ->
                                            BotFromTopCodeDesc { name = topClass.name, msc = topClass.code, packageCount = List.length (List.filter (.msc >> underPrefix topClass.code) class.notExcluded) }
                                                { name = midClass.name, msc = midClass.code, packageCount = List.length (List.filter (.msc >> underPrefix midClass.code) class.notExcluded) }
                                        )
                                        (Dict.get msc topClass.classifications)
                                )

                    BottomLevel topCode midCode ->
                        Dict.get topCode class.classification
                            |> Maybe.andThen
                                (\topClass ->
                                    Maybe.andThen
                                        (\midClass ->
                                            Maybe.map
                                                (\botClass ->
                                                    BotCodeDescr { name = topClass.name, msc = topClass.code, packageCount = List.length (List.filter (.msc >> underPrefix topClass.code) class.notExcluded) }
                                                        { name = midClass.name, msc = midClass.code, packageCount = List.length (List.filter (.msc >> underPrefix midClass.code) class.notExcluded) }
                                                        { name = botClass.name, msc = botClass.code, packageCount = List.length (List.filter (.msc >> underPrefix botClass.code) class.notExcluded) }
                                                )
                                                (Dict.get msc midClass.classifications)
                                        )
                                        (Dict.get midCode topClass.subclassifications)
                                )
            )


getTop : (Package -> Bool) -> Classification -> List MSCClassification
getTop filter class =
    Dict.toList class.classification
        |> List.map
            (\( _, topClass ) ->
                { name = topClass.name
                , msc = topClass.code
                , packageCount = List.length (List.filter (\p -> underPrefix topClass.code p.msc && filter p) class.notExcluded)
                }
            )


getChildren : (Package -> Bool) -> Classification -> String -> Maybe (List MSCClassification)
getChildren filter classification code =
    Maybe.map
        (\level ->
            case level of
                TopClass cache ->
                    List.concat
                        [ List.map
                            (\( _, bot ) ->
                                { name = bot.name
                                , msc = bot.code
                                , packageCount = List.length (List.filter (\p -> underPrefix bot.code p.msc && filter p) classification.notExcluded)
                                }
                            )
                            (Dict.toList cache.classifications)
                        , List.map
                            (\( _, mid ) ->
                                { name = mid.name
                                , msc = mid.code
                                , packageCount = List.length (List.filter (\p -> underPrefix mid.code p.msc && filter p) classification.notExcluded)
                                }
                            )
                            (Dict.toList cache.subclassifications)
                        ]

                BotClass _ ->
                    []

                MidClass cache ->
                    List.map
                        (\( _, bot ) ->
                            { name = bot.name
                            , msc = bot.code
                            , packageCount = List.length (List.filter (\p -> underPrefix bot.code p.msc && filter p) classification.notExcluded)
                            }
                        )
                        (Dict.toList cache.classifications)
        )
        (getClassification classification code)


packages : Classification -> String -> Maybe (List Package)
packages classification code =
    Maybe.map (classificationCacheToCommon >> .packages) (getClassification classification code)


type Element
    = Element
        { name : String
        , code : String
        , subclassifications : Maybe (List Element)
        , packages : List Package
        , packageCount : Int
        }


makeElement : { a | name : String, code : String, packages : List Package } -> Maybe (List Element) -> (Package -> Bool) -> Element
makeElement value children filter =
    let
        myPackages =
            List.filter filter value.packages
    in
    Element
        { name = value.name
        , code = value.code
        , packages = myPackages
        , packageCount =
            case children of
                Nothing ->
                    List.length myPackages

                Just xs ->
                    List.sum (List.map (\(Element x) -> x.packageCount) xs) + List.length myPackages
        , subclassifications = children
        }


getTree : Classification -> List Element
getTree class =
    getFilteredTree class (always True)


getFilteredTree : Classification -> (Package -> Bool) -> List Element
getFilteredTree class filter =
    List.map
        (\( _, value ) ->
            makeElement value
                (Just <|
                    List.concat
                        [ List.map
                            (\( _, midValue ) ->
                                makeElement midValue Nothing filter
                            )
                            (Dict.toList value.classifications)
                        , List.map
                            (\( _, midValue ) ->
                                makeElement midValue
                                    (Just <|
                                        List.map
                                            (\( _, botValue ) ->
                                                makeElement botValue Nothing filter
                                            )
                                            (Dict.toList midValue.classifications)
                                    )
                                    filter
                            )
                            (Dict.toList value.subclassifications)
                        ]
                )
                filter
        )
        (Dict.toList class.classification)


getClassifiedPackages : Classification -> List Package
getClassifiedPackages class =
    List.concatMap packagesFromTree (getTree class)


packagesFromTree : Element -> List Package
packagesFromTree (Element e) =
    List.concat (e.packages :: List.map packagesFromTree (Maybe.withDefault [] e.subclassifications))


getUnclassified : Classification -> List Package
getUnclassified class =
    class.unclassified


getExcluded : Classification -> List Package
getExcluded class =
    class.excluded


getAllPackages : Classification -> List Package
getAllPackages class =
    List.concat [ class.notExcluded, class.excluded ]
