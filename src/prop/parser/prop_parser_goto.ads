package Prop_Parser_Goto is

    type Small_Integer is range -32_000 .. 32_000;

    type Goto_Entry is record
        Nonterm  : Small_Integer;
        Newstate : Small_Integer;
    end record;

  --pragma suppress(index_check);

    subtype Row is Integer range -1 .. Integer'Last;

    type Goto_Parse_Table is array (Row range <>) of Goto_Entry;

    Goto_Matrix : constant Goto_Parse_Table :=
       ((-1,-1)  -- Dummy Entry.
-- State  0
,(-2, 1)
-- State  1
,(-3, 5)
-- State  2

-- State  3

-- State  4

-- State  5

-- State  6
,(-4, 9)
-- State  7
,(-4, 10)

-- State  8

-- State  9

-- State  10

-- State  11
,(-5, 14)
-- State  12
,(-10, 15),(-6, 23),(-4, 17)

-- State  13
,(-7, 26),(-4, 25)
-- State  14

-- State  15

-- State  16
,(-10, 31),(-4, 17)

-- State  17

-- State  18

-- State  19

-- State  20
,(-10, 32),(-4, 17)
-- State  21
,(-10, 33),(-4, 17)

-- State  22
,(-10, 34),(-4, 17)
-- State  23

-- State  24

-- State  25

-- State  26

-- State  27
,(-10, 37),(-4, 17)

-- State  28
,(-10, 38),(-4, 17)
-- State  29
,(-10, 39),(-4, 17)

-- State  30
,(-10, 40),(-4, 17)
-- State  31

-- State  32

-- State  33

-- State  34

-- State  35

-- State  36
,(-8, 42)
-- State  37

-- State  38

-- State  39

-- State  40

-- State  41

-- State  42
,(-9, 44)

-- State  43
,(-7, 45),(-4, 25)
-- State  44

-- State  45

-- State  46

);
--  The offset vector
GOTO_OFFSET : array (0.. 46) of Integer :=
( 0,
 1, 2, 2, 2, 2, 2, 3, 4, 4, 4,
 4, 5, 8, 10, 10, 10, 12, 12, 12, 12,
 14, 16, 18, 18, 18, 18, 18, 20, 22, 24,
 26, 26, 26, 26, 26, 26, 27, 27, 27, 27,
 27, 27, 28, 30, 30, 30);

subtype Rule        is Natural;
subtype Nonterminal is Integer;

   Rule_Length : array (Rule range  0 ..  23) of Natural := ( 2,
 0, 2, 5, 6, 4, 1, 1, 0,
 2, 3, 1, 3, 1, 1, 1, 3,
 3, 3, 3, 2, 2, 2, 1);
   Get_LHS_Rule: array (Rule range  0 ..  23) of Nonterminal := (-1,
-2,-2,-3,-3,-5,-7,-7,-8,
-8,-9,-6,-10,-10,-10,-10,-10,
-10,-10,-10,-10,-10,-10,-4);
end Prop_Parser_Goto;
