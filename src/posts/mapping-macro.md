# Mapping C macros over variadic arguments

Here is a short post about a favorite little CPP trick of mine:
a `MAP`-macro which applies another macro to each of its arguments.
So for example, the code

```c
#define F(...) MAP(SOME_MACRO, __VA_ARGS__)

F(x, y, z)
```

expands to

```c
SOME_MACRO(x)
SOME_MACRO(y)
SOME_MACRO(z)
```

The `MAP` macro relies on two helper macros which I will explain first.
The first one is called `NARGS` and it -- you guessed it -- returns the number of arguments passed to it.
This version can count up to 8 but with enough typing it can count arbitrarily many.

```c
#define NARGS(...) _NARGS(__VA_ARGS__, 8, 7, 6, 5, 4, 3, 2, 1)
#define _NARGS(_1, _2, _3, _4, _5, _6, _7, _8, N, ...) N
```

`_NARGS` always picks the 9th argument and then `NARGS` uses `__VA_ARGS__` to
"push" the correct number into the 9th slot.
I think about it like this:
the more arguments `__VA_ARGS__` expands to, the further down the high numbers are pushed.
For example:

```c
NARGS(a, b, c) // expands to...
_NARGS(a, b, c, 8, 7, 6, 5, 4, 3, 2, 1) // expands to...
3
```

The next helper macro we need is `CAT`.
This is even more common than `NARGS`
so you have probably already seen it.

```c
#define _CAT(x, y) x ## y
#define CAT(x, y) _CAT(x, y)
```

It uses the indirection to expand its arguments _before_ they are concatenated.
Here is an example showing why the `CAT` macro is necessary:
The code

```c
#define SKIBIDI sigma
#define TOILET(x) rizz

// Naïve approach
#define NAIVE_CAT(x,y) x ## y
NAIVE_CAT(SKIBIDI, TOILET(3))

// Goated approach
CAT(SKIBIDI, TOILET(3))
```

expands to:

```c
// Naïve approach
SKIBIDITOILET(3)

// Goated approach
sigmarizz
```

Now we are ready to implement `MAP`:

```c
#define MAP(F, ...) CAT(_APPLY, NARGS(__VA_ARGS__))(F, __VA_ARGS__)
#define _APPLY1(F, _1) F(_1)
#define _APPLY2(F, _1, _2) F(_1) F(_2)
#define _APPLY3(F, _1, _2, _3) F(_1) F(_2) F(_3)
#define _APPLY4(F, _1, _2, _3, _4) F(_1) F(_2) F(_3) F(_4)
#define _APPLY5(F, _1, _2, _3, _4, _5) F(_1) F(_2) F(_3) F(_4) F(_5)
#define _APPLY6(F, _1, _2, _3, _4, _5, _6) F(_1) F(_2) F(_3) F(_4) F(_5) F(_6)
#define _APPLY7(F, _1, _2, _3, _4, _5, _6, _7) F(_1) F(_2) F(_3) F(_4) F(_5) F(_6) F(_7)
#define _APPLY8(F, _1, _2, _3, _4, _5, _6, _7, _8) F(_1) F(_2) F(_3) F(_4) F(_5) F(_6) F(_7) F(_8)
```

<? proc applyN {} { emit {<code>_APPLY<em>N</em></code>} } ?>
It is using `NARGS` and `CAT` to select which <? applyN ?> function to (...) apply.
Then we manually (or using some Vim-fu) type out all the different <? applyN ?>-functions.

Here is (I think) the full sequence of expansions for the example from the intro:

```c
F(x, y, z) // expands to...
MAP(SOME_MACRO, x, y, z) // expands to...
CAT(_APPLY, NARGS(x, y, z))(SOME_MACRO, x, y, z) // expands to...
_CAT(_APPLY, _NARGS(x, y, z, 8, 7, 6, 5, 4, 3, 2, 1))(SOME_MACRO, x, y, z) // expands to...
_APPLY ## 3(SOME_MACRO, x, y, z) // expands to...
_APPLY3(SOME_MACRO, x, y, z) // expands to...
SOME_MACRO(x) SOME_MACRO(y) SOME_MACRO(z)
```
