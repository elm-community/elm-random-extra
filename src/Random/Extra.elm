module Random.Extra exposing (..)

{-| Module providing extra functionality to the core Random module.

# Constant Generators
@docs constant

# Generator Transformers
@docs flattenList

# Select
@docs select, selectWithDefault, frequency, merge

# Maps
For `map` and `mapN` up through N=5, use the core library.
@docs map6, andMap, mapConstraint

# Flat Maps
@docs flatMap, flatMap2, flatMap3, flatMap4, flatMap5, flatMap6

# Zips
@docs zip, zip3, zip4, zip5, zip6

# Reducers
@docs reduce, fold

# Filtering Generators
@docs keepIf, dropIf

# Functions that generate random values from Generators
@docs generateN, quickGenerate, cappedGenerateUntil, generateIterativelyUntil, generateIterativelySuchThat, generateUntil, generateSuchThat

-}

import Random exposing (Generator, Seed, step, list, int, float, initialSeed)
import Utils exposing (get)
import List
import Maybe


{-| Create a generator that chooses a generator from a tuple of generators
based on the provided likelihood. The likelihood of a given generator being
chosen is its likelihood divided by the sum of all likelihood. A default
generator must be provided in the case that the list is empty or that the
sum of the likelihoods is 0. Note that the absolute values of the likelihoods
is always taken.
-}
frequency : List ( Float, Generator a ) -> Generator a -> Generator a
frequency pairs defaultGenerator =
    let
        total =
            List.sum <| List.map (abs << fst) pairs

        pick choices n =
            case choices of
                ( k, g ) :: rest ->
                    if n <= k then
                        g
                    else
                        pick rest (n - k)

                _ ->
                    defaultGenerator
    in
        if total == 0 then
            defaultGenerator
        else
            float 0 total `Random.andThen` pick pairs


{-| Convert a generator into a generator that only generates values
that satisfy a given predicate.
Note that if the predicate is unsatisfiable, the generator will not terminate.
-}
keepIf : (a -> Bool) -> Generator a -> Generator a
keepIf predicate generator =
    generator
        `Random.andThen` (\a ->
                            if predicate a then
                                constant a
                            else
                                keepIf predicate generator
                         )


{-| Convert a generator into a generator that only generates values
that do not satisfy a given predicate.
-}
dropIf : (a -> Bool) -> Generator a -> Generator a
dropIf predicate =
    keepIf (\a -> not (predicate a))


{-| Turn a list of generators into a generator of lists.
-}
flattenList : List (Generator a) -> Generator (List a)
flattenList generators =
    case generators of
        [] ->
            constant []

        g :: gs ->
            Random.map2 (::) g (flattenList gs)


{-| Generator that randomly selects an element from a list.
-}
select : List a -> Generator (Maybe a)
select list =
    Random.map (\index -> get index list)
        (int 0 (List.length list - 1))


{-| Generator that randomly selects an element from a list with a default value
(in case you pass in an empty list).
-}
selectWithDefault : a -> List a -> Generator a
selectWithDefault defaultValue list =
    Random.map (Maybe.withDefault defaultValue) (select list)


{-| Create a generator that always returns the same value.
-}
constant : a -> Generator a
constant value =
    Random.map (\_ -> value) Random.bool


{-| Apply a generator of functions to a generator of values.
Useful for chaining generators.
-}
andMap : Generator (a -> b) -> Generator a -> Generator b
andMap funcGenerator generator =
    Random.map2 (<|) funcGenerator generator


{-| Reduce a generator using a reducer and an initial value.
Note that the initial value is always passed to the function;
not the previously generator value.
-}
reduce : (a -> b -> b) -> b -> Generator a -> Generator b
reduce reducer initial generator =
    Random.map (\a -> reducer a initial) generator


{-| Alias for reduce.
-}
fold : (a -> b -> b) -> b -> Generator a -> Generator b
fold =
    reduce


{-| -}
zip : Generator a -> Generator b -> Generator ( a, b )
zip =
    Random.map2 (,)


{-| -}
zip3 : Generator a -> Generator b -> Generator c -> Generator ( a, b, c )
zip3 =
    Random.map3 (,,)


{-| -}
zip4 : Generator a -> Generator b -> Generator c -> Generator d -> Generator ( a, b, c, d )
zip4 =
    Random.map4 (,,,)


{-| -}
zip5 : Generator a -> Generator b -> Generator c -> Generator d -> Generator e -> Generator ( a, b, c, d, e )
zip5 =
    Random.map5 (,,,,)


{-| -}
zip6 : Generator a -> Generator b -> Generator c -> Generator d -> Generator e -> Generator f -> Generator ( a, b, c, d, e, f )
zip6 =
    map6 (,,,,,)


{-| -}
flatMap : (a -> Generator b) -> Generator a -> Generator b
flatMap =
    flip Random.andThen


{-| -}
flatMap2 : (a -> b -> Generator c) -> Generator a -> Generator b -> Generator c
flatMap2 constructor generatorA generatorB =
    generatorA
        `Random.andThen` (\a ->
                            generatorB
                                `Random.andThen` (\b ->
                                                    constructor a b
                                                 )
                         )


{-| -}
flatMap3 : (a -> b -> c -> Generator d) -> Generator a -> Generator b -> Generator c -> Generator d
flatMap3 constructor generatorA generatorB generatorC =
    generatorA
        `Random.andThen` (\a ->
                            generatorB
                                `Random.andThen` (\b ->
                                                    generatorC
                                                        `Random.andThen` (\c ->
                                                                            constructor a b c
                                                                         )
                                                 )
                         )


{-| -}
flatMap4 : (a -> b -> c -> d -> Generator e) -> Generator a -> Generator b -> Generator c -> Generator d -> Generator e
flatMap4 constructor generatorA generatorB generatorC generatorD =
    generatorA
        `Random.andThen` (\a ->
                            generatorB
                                `Random.andThen` (\b ->
                                                    generatorC
                                                        `Random.andThen` (\c ->
                                                                            generatorD
                                                                                `Random.andThen` (\d ->
                                                                                                    constructor a b c d
                                                                                                 )
                                                                         )
                                                 )
                         )


{-| -}
flatMap5 : (a -> b -> c -> d -> e -> Generator f) -> Generator a -> Generator b -> Generator c -> Generator d -> Generator e -> Generator f
flatMap5 constructor generatorA generatorB generatorC generatorD generatorE =
    generatorA
        `Random.andThen` (\a ->
                            generatorB
                                `Random.andThen` (\b ->
                                                    generatorC
                                                        `Random.andThen` (\c ->
                                                                            generatorD
                                                                                `Random.andThen` (\d ->
                                                                                                    generatorE
                                                                                                        `Random.andThen` (\e ->
                                                                                                                            constructor a b c d e
                                                                                                                         )
                                                                                                 )
                                                                         )
                                                 )
                         )


{-| -}
flatMap6 : (a -> b -> c -> d -> e -> f -> Generator g) -> Generator a -> Generator b -> Generator c -> Generator d -> Generator e -> Generator f -> Generator g
flatMap6 constructor generatorA generatorB generatorC generatorD generatorE generatorF =
    generatorA
        `Random.andThen` (\a ->
                            generatorB
                                `Random.andThen` (\b ->
                                                    generatorC
                                                        `Random.andThen` (\c ->
                                                                            generatorD
                                                                                `Random.andThen` (\d ->
                                                                                                    generatorE
                                                                                                        `Random.andThen` (\e ->
                                                                                                                            generatorF
                                                                                                                                `Random.andThen` (\f ->
                                                                                                                                                    constructor a b c d e f
                                                                                                                                                 )
                                                                                                                         )
                                                                                                 )
                                                                         )
                                                 )
                         )


{-| -}
map6 : (a -> b -> c -> d -> e -> f -> g) -> Generator a -> Generator b -> Generator c -> Generator d -> Generator e -> Generator f -> Generator g
map6 f generatorA generatorB generatorC generatorD generatorE generatorF =
    Random.map5 f generatorA generatorB generatorC generatorD generatorE `andMap` generatorF


{-| Choose between two generators with a 50-50 chance.
Useful for merging two generators that cover different areas of the same type.
-}
merge : Generator a -> Generator a -> Generator a
merge generator1 generator2 =
    frequency
        [ ( 1, generator1 )
        , ( 1, generator2 )
        ]
        generator1


{-| Generate n values from a generator.
-}
generateN : Int -> Generator a -> Seed -> List a
generateN n generator seed =
    if n <= 0 then
        []
    else
        let
            ( value, nextSeed ) =
                step generator seed
        in
            value :: generateN (n - 1) generator nextSeed


{-| Generate a value from a generator that satisfies a given predicate
-}
generateSuchThat : (a -> Bool) -> Generator a -> Seed -> ( a, Seed )
generateSuchThat predicate generator seed =
    step (keepIf predicate generator) seed


{-| Generate a list of values from a generator until the given predicate
is satisfied
-}
generateUntil : (a -> Bool) -> Generator a -> Seed -> List a
generateUntil predicate generator seed =
    let
        ( value, nextSeed ) =
            step generator seed
    in
        if predicate value then
            value :: generateUntil predicate generator nextSeed
        else
            []


{-| Generate iteratively a list of values from a generator parametrized by
the value of the iterator until either the given maxlength is reached or
the predicate ceases to be satisfied.

    generateIterativelySuchThat maxLength predicate constructor seed
-}
generateIterativelySuchThat : Int -> (a -> Bool) -> (Int -> Generator a) -> Seed -> List a
generateIterativelySuchThat maxLength predicate =
    generateIterativelyUntil maxLength (\a -> not (predicate a))


{-| Generate iteratively a list of values from a generator parametrized by
the value of the iterator until either the given maxlength is reached or
the predicate is satisfied.

    generateIterativelyUntil maxLength predicate constructor seed
-}
generateIterativelyUntil : Int -> (a -> Bool) -> (Int -> Generator a) -> Seed -> List a
generateIterativelyUntil maxLength predicate constructor seed =
    let
        iterate index =
            if index >= maxLength then
                []
            else
                (generateUntil predicate (constructor index) seed)
                    ++ (iterate (index + 1))
    in
        iterate 0


{-| Generate iteratively a list of values from a generator until either
the given maxlength is reached or the predicate is satisfied.

    cappedGenerateUntil maxLength predicate generator seed
-}
cappedGenerateUntil : Int -> (a -> Bool) -> Generator a -> Seed -> List a
cappedGenerateUntil maxGenerations predicate generator seed =
    if maxGenerations <= 0 then
        []
    else
        let
            ( value, nextSeed ) =
                step generator seed
        in
            if predicate value then
                value :: cappedGenerateUntil (maxGenerations - 1) predicate generator nextSeed
            else
                []


{-| Quickly generate a value from a generator disregarding seeds.
-}
quickGenerate : Generator a -> a
quickGenerate generator =
    (fst (step generator (initialSeed 1)))


{-| Apply a constraint onto a generator and returns both the input to
the constraint and the result of applying the constaint.
-}
mapConstraint : (a -> b) -> Generator a -> Generator ( a, b )
mapConstraint constraint generator =
    Random.map (\a -> ( a, constraint a )) generator
