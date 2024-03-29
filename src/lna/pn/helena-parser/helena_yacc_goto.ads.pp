package Helena_Yacc_Goto is

   type Small_Integer is range -32_000 .. 32_000;

   type Goto_Entry is record
      Nonterm  : Small_Integer;
      Newstate : Small_Integer;
   end record;

   --pragma suppress(index_check);

   subtype Row is Integer range -1 .. Integer'Last;

   type Goto_Parse_Table is array (Row range <>) of Goto_Entry;

   Goto_Matrix : constant Goto_Parse_Table :=
     ((-1, -1)  -- Dummy Entry.
   -- State  0
     ,
      (-137, 2),
      (-3, 1),
      (-2, 4)
   -- State  1

   -- State  2

   -- State  3

   -- State  4

   -- State  5
     ,
      (-4, 7)

   -- State  6

   -- State  7
     ,
      (-39, 19),
      (-38, 18),
      (-19, 15),
      (-18, 14),
      (-14, 20),
      (-13, 13),
      (-12, 12),
      (-11, 11),
      (-10, 10),
      (-9, 9),
      (-8, 8),
      (-7, 28)

   -- State  8

   -- State  9

   -- State  10

   -- State  11

   -- State  12

   -- State  13

   -- State  14

   -- State  15

   -- State  16
     ,
      (-137, 29),
      (-107, 30)
   -- State  17
     ,
      (-137, 31),
      (-93, 32)

   -- State  18

   -- State  19

   -- State  20

   -- State  21

   -- State  22
     ,
      (-137, 34),
      (-16, 35)
   -- State  23
     ,
      (-137, 36),
      (-36, 37)

   -- State  24
     ,
      (-137, 38),
      (-40, 39)
   -- State  25

   -- State  26
     ,
      (-137, 34),
      (-16, 41)

   -- State  27
     ,
      (-5, 42)
   -- State  28

   -- State  29

   -- State  30

   -- State  31

   -- State  32

   -- State  33
     ,
      (-137, 29),
      (-136, 46),
      (-107, 45)

   -- State  34

   -- State  35

   -- State  36

   -- State  37

   -- State  38

   -- State  39

   -- State  40
     ,
      (-137, 38),
      (-40, 50)
   -- State  41
     ,
      (-137, 51),
      (-17, 52)

   -- State  42
     ,
      (-128, 56),
      (-6, 55)
   -- State  43
     ,
      (-108, 58)
   -- State  44
     ,
      (-94, 60)

   -- State  45

   -- State  46

   -- State  47
     ,
      (-28, 70),
      (-27, 69),
      (-26, 68),
      (-25, 67),
      (-24, 66),
      (-23, 65),
      (-22, 64),
      (-21, 63),
      (-20, 78)
   -- State  48
     ,
      (-137, 34),
      (-16, 79)
   -- State  49
     ,
      (-137, 34),
      (-45, 81),
      (-44, 80),
      (-41, 83),
      (-16, 82)

   -- State  50

   -- State  51

   -- State  52
     ,
      (-92, 86)
   -- State  53
     ,
      (-137, 87),
      (-129, 88)
   -- State  54
     ,
      (-137, 87),
      (-129, 89)
   -- State  55

   -- State  56

   -- State  57

   -- State  58
     ,
      (-109, 92)
   -- State  59

   -- State  60
     ,
      (-95, 94)
   -- State  61
     ,
      (-137, 29),
      (-136, 95),
      (-107, 45)
   -- State  62
     ,
      (-137, 29),
      (-107, 96)

   -- State  63

   -- State  64

   -- State  65

   -- State  66

   -- State  67

   -- State  68

   -- State  69

   -- State  70

   -- State  71
     ,
      (-137, 127),
      (-77, 125),
      (-73, 124),
      (-66, 116),
      (-65, 115),
      (-64, 114),
      (-63, 113),
      (-62, 112),
      (-61, 111),
      (-60, 110),
      (-59, 109),
      (-58, 108),
      (-57, 107),
      (-56, 106),
      (-55, 105),
      (-54, 104),
      (-53, 103),
      (-52, 102),
      (-51, 101),
      (-50, 100),
      (-49, 99),
      (-48, 98),
      (-47, 97),
      (-40, 117),
      (-29, 118)
   -- State  72

   -- State  73

   -- State  74

   -- State  75

   -- State  76

   -- State  77
     ,
      (-137, 127),
      (-77, 125),
      (-73, 124),
      (-66, 116),
      (-65, 115),
      (-64, 114),
      (-63, 113),
      (-62, 112),
      (-61, 111),
      (-60, 110),
      (-59, 109),
      (-58, 108),
      (-57, 107),
      (-56, 106),
      (-55, 105),
      (-54, 104),
      (-53, 103),
      (-52, 102),
      (-51, 101),
      (-50, 100),
      (-49, 99),
      (-48, 98),
      (-47, 97),
      (-40, 117),
      (-29, 146)
   -- State  78

   -- State  79
     ,
      (-37, 149),
      (-28, 148)

   -- State  80

   -- State  81

   -- State  82
     ,
      (-137, 51),
      (-17, 151)
   -- State  83

   -- State  84
     ,
      (-137, 34),
      (-45, 81),
      (-44, 80),
      (-41, 153),
      (-16, 82)
   -- State  85
     ,
      (-137, 127),
      (-77, 125),
      (-73, 124),
      (-66, 116),
      (-65, 115),
      (-64, 114),
      (-63, 113),
      (-62, 112),
      (-61, 111),
      (-60, 110),
      (-59, 109),
      (-58, 108),
      (-57, 107),
      (-56, 106),
      (-55, 105),
      (-54, 104),
      (-53, 103),
      (-52, 102),
      (-51, 101),
      (-50, 100),
      (-49, 99),
      (-48, 98),
      (-47, 97),
      (-40, 117),
      (-29, 154)

   -- State  86

   -- State  87

   -- State  88

   -- State  89

   -- State  90
     ,
      (-112, 158)
   -- State  91

   -- State  92
     ,
      (-110, 161)
   -- State  93
     ,
      (-137, 34),
      (-97, 162),
      (-96, 165),
      (-16, 164)
   -- State  94
     ,
      (-104, 171),
      (-103, 170),
      (-102, 169),
      (-101, 168),
      (-100, 167),
      (-99, 166),
      (-98, 179)
   -- State  95

   -- State  96

   -- State  97

   -- State  98

   -- State  99

   -- State  100

   -- State  101

   -- State  102

   -- State  103

   -- State  104

   -- State  105

   -- State  106

   -- State  107

   -- State  108

   -- State  109

   -- State  110

   -- State  111

   -- State  112

   -- State  113

   -- State  114

   -- State  115

   -- State  116

   -- State  117

   -- State  118

   -- State  119
     ,
      (-137, 127),
      (-77, 125),
      (-73, 124),
      (-66, 116),
      (-65, 115),
      (-64, 114),
      (-63, 113),
      (-62, 112),
      (-61, 111),
      (-60, 110),
      (-59, 109),
      (-58, 108),
      (-57, 107),
      (-56, 106),
      (-55, 105),
      (-54, 104),
      (-53, 103),
      (-52, 102),
      (-51, 101),
      (-50, 100),
      (-49, 99),
      (-48, 98),
      (-47, 97),
      (-40, 117),
      (-29, 203)
   -- State  120
     ,
      (-137, 127),
      (-77, 125),
      (-73, 124),
      (-66, 116),
      (-65, 115),
      (-64, 114),
      (-63, 113),
      (-62, 112),
      (-61, 111),
      (-60, 110),
      (-59, 109),
      (-58, 108),
      (-57, 107),
      (-56, 106),
      (-55, 105),
      (-54, 104),
      (-53, 103),
      (-52, 102),
      (-51, 101),
      (-50, 100),
      (-49, 99),
      (-48, 98),
      (-47, 97),
      (-40, 117),
      (-29, 204)
   -- State  121
     ,
      (-137, 127),
      (-77, 125),
      (-73, 124),
      (-66, 116),
      (-65, 115),
      (-64, 114),
      (-63, 113),
      (-62, 112),
      (-61, 111),
      (-60, 110),
      (-59, 109),
      (-58, 108),
      (-57, 107),
      (-56, 106),
      (-55, 105),
      (-54, 104),
      (-53, 103),
      (-52, 102),
      (-51, 101),
      (-50, 100),
      (-49, 99),
      (-48, 98),
      (-47, 97),
      (-40, 117),
      (-29, 205)

   -- State  122
     ,
      (-137, 127),
      (-77, 125),
      (-73, 124),
      (-66, 116),
      (-65, 115),
      (-64, 114),
      (-63, 113),
      (-62, 112),
      (-61, 111),
      (-60, 110),
      (-59, 109),
      (-58, 108),
      (-57, 107),
      (-56, 106),
      (-55, 105),
      (-54, 104),
      (-53, 103),
      (-52, 102),
      (-51, 101),
      (-50, 100),
      (-49, 99),
      (-48, 98),
      (-47, 97),
      (-40, 117),
      (-29, 206)
   -- State  123
     ,
      (-137, 127),
      (-77, 125),
      (-73, 124),
      (-66, 116),
      (-65, 115),
      (-64, 114),
      (-63, 113),
      (-62, 112),
      (-61, 111),
      (-60, 110),
      (-59, 109),
      (-58, 108),
      (-57, 107),
      (-56, 106),
      (-55, 105),
      (-54, 104),
      (-53, 103),
      (-52, 102),
      (-51, 101),
      (-50, 100),
      (-49, 99),
      (-48, 98),
      (-47, 97),
      (-40, 117),
      (-29, 207)
   -- State  124

   -- State  125

   -- State  126
     ,
      (-137, 127),
      (-77, 125),
      (-73, 124),
      (-66, 116),
      (-65, 115),
      (-64, 114),
      (-63, 113),
      (-62, 112),
      (-61, 111),
      (-60, 110),
      (-59, 109),
      (-58, 108),
 