module ITP exposing
    ( Attribute
    , CounterExampleGenerator
    , ITP
    , Library
    , Project
    , allAttributes
    , attributeByName
    )

import Html


type alias Attribute msg =
    { name : String
    , description : String
    , possibilities : List String
    , toName : String -> String
    , getValue : ITP -> String
    , viewValue : String -> Html.Html msg
    }


allAttributes : List (Attribute a)
allAttributes =
    [ basedOn
    , logic
    , truthValue
    , calculus
    , programmingParadigm
    , userInterface
    , platforms
    , utf8Library
    ]


attributeByName : String -> Maybe (Attribute a)
attributeByName name =
    List.head (List.filter (\attribute -> attribute.name == name) allAttributes)


utf8Library : Attribute a
utf8Library =
    { name = "Math Symbols"
    , description = "Whether the prover uses math symbols"
    , possibilities = [ "Yes", "No" ]
    , toName = \x -> x
    , getValue = .utf8Library
    , viewValue =
        \value ->
            case value of
                "Yes" ->
                    Html.text "This ITP uses math symbols in its proofs"

                "No" ->
                    Html.text "This ITP uses plain text in its proofs"

                x ->
                    Html.text x
    }


counterexamples : Attribute a
counterexamples =
    { name = "Counterexample Generator"
    , description = "Whether counterexample generators are available for the ITP"
    , possibilities = [ "Yes", "External", "No" ]
    , toName = \x -> x
    , getValue = .counterexample
    , viewValue =
        \value ->
            case value of
                "Yes" ->
                    Html.text "This ITP has an internal counterexample generator"

                "External" ->
                    Html.text "This ITP has support for an external counterexample generator"

                "No" ->
                    Html.text "This ITP does not have support for counterexample generators"

                x ->
                    Html.text x
    }


platforms : Attribute a
platforms =
    { name = "Platforms"
    , description = "The operating systems that a prover runs on"
    , possibilities = [ "Windows", "Cross", "Win+Linux", "Mac", "Mac+Linux", "Mac+Windows" ]
    , toName =
        \value ->
            case value of
                "Win+Linux" ->
                    "Windows and Linux"

                "Mac+Linux" ->
                    "Mac and Linux"

                "Mac+Windows" ->
                    "Mac and Windows"

                x ->
                    x
    , getValue = .platforms
    , viewValue =
        \value ->
            case value of
                "Cross" ->
                    Html.text "A Cross platfrom application is available to run on all major operating systems"

                x ->
                    Html.text <| String.append "This prover can be run on " (platforms.toName x)
    }


userInterface : Attribute a
userInterface =
    { name = "User Interface"
    , description = "The way that you interact with the ITP"
    , possibilities = [ "GUI", "CLI", "CLI+GUI" ]
    , toName =
        \value ->
            case value of
                "CLI+GUI" ->
                    "CLI and GUI"

                x ->
                    x
    , getValue = .userInterface
    , viewValue =
        \value ->
            case value of
                "CLI" ->
                    Html.text "a prover with only a CLI or Command Line Interface has the most primitive type of interface, and is often interacted with through simply a Read Evaluate Print Loop on the command line. Although the interface is more primitive, some users prefer command line interfaces to graphical ones."

                "GUI" ->
                    Html.text "A prover with a GUI or Graphical User Interface allows for interaction through an interface that is distinct from a simple command line."

                "CLI+GUI" ->
                    Html.text "A prover with both a CLI and GUI interface offers both a CLI and a GUI"

                _ ->
                    Html.text "unknown"
    }


programmingParadigm : Attribute a
programmingParadigm =
    { name = "Programming Paradigm"
    , description = "The style of programming that is used in this ITP"
    , possibilities = [ "Func", "Impe", "LP", "Decl" ]
    , toName =
        \value ->
            case value of
                "Func" ->
                    "Functional"

                "Impe" ->
                    "Imperitive"

                "LP" ->
                    "Logical Programming"

                "Decl" ->
                    "Declarative"

                x ->
                    x
    , getValue = .paradigm
    , viewValue =
        \value ->
            case value of
                "Func" ->
                    Html.text "Functional programming is building software in a way that focuses on defining, composing and calling functions. Haskell, OCaml and ML are good examples of functional languages"

                "Impe" ->
                    Html.text "Imperitive programming is building software in a way that focuses on defining, often sequential, instructions. C, C++, Java, Python and JavaScript"

                "LP" ->
                    Html.text "Logic Programming is programming through the statement of facts. Prolog is a classic example."

                "Decl" ->
                    Html.text "A declarative programming language is one that makes statements about what is desired without specifying how what is desired is to acheived (or without specifying control flow)"

                _ ->
                    Html.text "Unknown"
    }


calculus : Attribute a
calculus =
    { name = "Calculus"
    , description = "Type of Calculus used within the theorem prover"
    , possibilities = [ "Inductive", "Deductive", "Ded+Indu" ]
    , toName =
        \value ->
            case value of
                "Inductive" ->
                    "Inductive"

                "Inductive and Deductive" ->
                    "Inductive and Deductive"

                "Deductive" ->
                    "Deductive"

                x ->
                    x
    , getValue = .calculus
    , viewValue =
        \value ->
            case value of
                "Inductive" ->
                    Html.text "An Inductive calculus is a calculus that allows you to prove propositions by the construction of inductive types. It is in a sense, a bottom up approach."

                "Inductive and Deductive" ->
                    Html.text "A prover with support for both Inductive and Dedective calculus"

                "Deductive" ->
                    Html.text "A deductive calculus in a calculus based on the rules of natural deduction, in that you prove propositions by breaking them appart and proving their components. Or a top down approach."

                x ->
                    Html.text x
    }


truthValue : Attribute a
truthValue =
    { name = "Truth Value"
    , description = ""
    , possibilities = [ "Binary", "Intuition" ]
    , toName =
        \value ->
            case value of
                "Binary" ->
                    "Binary"

                "Intuition" ->
                    "Intuition"

                x ->
                    x
    , getValue = .truthValue
    , viewValue =
        \value ->
            case value of
                "Binary" ->
                    Html.text "A system with a binary truth value means that statements can only be true or false."

                "Intuition" ->
                    Html.text "An intuitionistic or constructive logic means that a statement is only true if from the axioms, a proof can be constructed of it, and false if assuming the statement leads to a contradiction."

                _ ->
                    Html.text "Unknown value"
    }


logic : Attribute a
logic =
    { name = "Logic"
    , description = "The logic that the system is based on"
    , possibilities = [ "FOL", "HOL", "FOL+HOL", "TT", "HOTT" ]
    , toName =
        \value ->
            case value of
                "FOL" ->
                    "First-Order Logic"

                "HOL" ->
                    "Higher-Order Logic"

                "FOL+HOL" ->
                    "First-Order Logic and Higher-Order Logic"

                "TT" ->
                    "Type Theory"

                "HOTT" ->
                    "Higher Order Type Theory"

                x ->
                    x
    , getValue = .logic
    , viewValue =
        \value ->
            case value of
                "FOL" ->
                    Html.text "First order logic is a collection of logics very commonly used in many areas of philosophy, mathematics and computer science. It is mainly propositional logic (which means logic that uses the standard \"and\" and \"or\" as well as the ability to quantify variables, such as stating there exists x for which .... (existential quantification) and for all x there is ... (universal quantification)"

                "HOL" ->
                    Html.text "Higher Order Logic is a logic that extends first order logic with the use of functions. The logic is inspired from functional programming, and is often used alongside types to prove propositions."

                "TT" ->
                    Html.text "Type Theory is the use of Type systems, mainly Dependent types, which allow the proof of propositions"

                "FOL+HOL" ->
                    Html.text "First Order Logic and Higher Order Logic"

                "HOTT" ->
                    Html.text "Higher Order Logic and Type Theory"

                _ ->
                    Html.text ""
    }


basedOn : Attribute a
basedOn =
    { name = "Based On"
    , description = "What the logic is based on"
    , possibilities = [ "Syllogism", "DP", "FP", "LF" ]
    , toName =
        \value ->
            case value of
                "Syllogism" ->
                    "Syllogism"

                "DP" ->
                    "Decision Procedures"

                "FP" ->
                    "Functional Programming"

                "LF" ->
                    "Logical Framework"

                x ->
                    x
    , getValue = .basedOn
    , viewValue =
        \value ->
            case value of
                "Syllogism" ->
                    Html.text "A prover based on syllogism proves propositions by keeping track of assumptions, and combining those assumptions to create a conclusion. These types of provers have a distinctly mathematical feel."

                "DP" ->
                    Html.text "Coq is a prover based on Decision Procedures. This is unique to Coq, but means that proving a theorem requires producing a proof object which is checked by the kernel. It's only possible to produce proof objects of valid propositions. In practice, this feature means that Coq is able to both construct proof objects by Dependent Programming such as systems like Agda, but also allow syllogistic style proofs like that of Isabelle"

                "FP" ->
                    Html.text "Agda is a Functional Programming theorem prover, this means that it allows the proof of propositions mainly through the using functional programming, particularly advanced type systems and dependent programming."

                "LF" ->
                    Html.text "Twelf is a theorem prover based on the LF Logical Framework. A Logical Framework works by creating a type that represents the proposition that you wish to prove, and then proving this property through creating an object that inhabits that type. It also uses dependent programming"

                _ ->
                    Html.text ""
    }


type alias ITP =
    { name : String
    , systemType : String
    , tpCategory : String
    , basedOn : String
    , logic : String
    , truthValue : String
    , calculus : String
    , setTheory : Bool
    , paradigm : String
    , architecture : String
    , programmingLanguage : String
    , userInterface : String
    , platforms : String
    , scalability : Bool
    , counterexample : String
    , utf8Library : String
    , multiThreaded : Bool
    , ide : Bool
    , library : Bool
    , programmability : Bool
    , tactic : Bool
    , logo : String
    , homepage : String
    , contributors : String
    , firstRelease : String
    , lastReleaseDate : Int
    , lastReleaseName : String
    , lastReleaseUrl : String
    , releasesUrl : String
    , libraries : List Library
    , projects : List Project
    , counterExampleIntegrations : List CounterExampleIntegration
    }


type alias CounterExampleGenerator =
    { name : String
    , description : String
    }


type alias CounterExampleIntegration =
    { name : String
    , prover : String
    , citation : String
    }


type alias Library =
    { itp : String
    , section : String
    , file : String
    , url : String
    , entries : List RawPackage
    }


type alias RawPackage =
    { name : String
    , url : String
    , description : String
    , authors : String
    , verified : Bool
    , msc : String
    }


type alias Project =
    { name : String
    , author : String
    , prover : String
    , description : String
    , website : String
    , startDate : Maybe Int
    , endDate : Maybe Int
    , category : String
    }
