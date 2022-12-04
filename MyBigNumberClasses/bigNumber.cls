VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "bigNumber"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Attribute VB_Ext_KEY = "Member0" ,"symbolcollection"
'bigNumber
' object class for big number object and associated methods
' Author: Joseph A. Brendler
' Date: 9 September 2004
' //Initially designed for large integer arithmetic
' Revision History:
'   18 Sep to 8 Nov 04 - generalized for large number arithmetic:
'      includes multiple precision floating point types
'      improves sign, exponent handling, and base conversion for
'      arithmetic operations that will handle two bigNumbers of non-similar base

' basic number architecture:
'  bigN = iSign*[lDigits(0) * lBase^0
'          + lDigits(1) * lBase^1 + ...
'          + lDigits(symbolcollection.Count - 1) * lBase^(symbolcollection.Count - 1)]
'          * lBase^lExponent
' The following are equivalent:
'    1.23456 * 10^5
'    123.456 * 10^3
'    1,234.56 * 10^2
'    123456 *10^0    (This is the way it is stored)
'
' Floating point numbers are stored as integers with a negative exponent
'    123456 * 10^-2 is the stored form of (1234.56)
'
' These numbers can be displayed a variety of ways as well (options of big2str method)
'
' These numbers can also be "read" from input media (files, text boxes, etc.) via str2big method
'    in these same forms, or in the form
'    1,234.56e2 and 1234.56E2 and 1234.56 x 10^2 are received as equivalent forms of 123456
'
' The base (or radix) of the number is stored as a property (public variable) of the number,
'    123.456e3(b10) is received as an equivalent form of 123456   (base 10 is default)
'    1,E24(b16) x 16^1 is received as a number equivalent to 123456, but it is stored as 1,E24(b16) x 16^1
'       (the normalize method with default format option removes trailing zeros for memory conservative storage)
'
' The sign of the number is stored as an integer property (public variable) of the number,
'    valid values of sign are 1 and -1
'    -123.456e3 is received by str2big as an equivalent form of the result of the calculation
'    -1 * 123456
'
' Note: use of bigNumber requires the public FlexiDecimalCollection of symbol to
'   string translations to be declared and initialized externally as follows:
'
'Public FlexiDecimalCollection As New FlexiDecimalCollection  'public declaration in main form code
'
'Private Sub Form_Load()   'main form load event
'   initialize the public flexidecimal symbol collection here
'    'load array of characters used to represent numbers with base > 10
'    For n = 0 To 9
'        'Flexidecimal(n) = Format$(n)
'        FlexiDecimalCollection.Add n, Format$(n)
'    Next n
'    For n = 10 To 255
'        'Flexidecimal(n) = Chr((n + 55) Mod 256)
'        'Debug.Print "chr(" & n & "): " & Chr((n + 55) Mod 256)
'        FlexiDecimalCollection.Add n, Chr((n + 55) Mod 256)
'        'Debug.Print "fdc.count: " & FlexiDecimalCollection.Count
'        'Debug.Print "fdc.item(): " & FlexiDecimalCollection.Item(FlexiDecimalCollection.Count).SymbolString
'    Next n
'
'End Sub

'************** Declarations *** Property variables of the bigNumber object *********************

'The base of the big number
Public lBase As Long
Attribute lBase.VB_VarDescription = "the base of the big number"

'the sign of the number "-" or "+"
Public iSign As Integer

'the exponent of a multiple precision floating point number
'   Note that if the exponent is positive then the number is an integer
'   and if the exponent is negative then the number is a floating point number
'      (unless it consists of at least as many "least significant zeros" as the
'      magnitude of the exponent)
Public lExponent As Long

'enumerated collection of symbol objects
'    Note - depends on the symbolcollection and symbol object classes
Public SymbolCollection As New SymbolCollection


Public Function setSymbol(digit As Long, place As Long)
    Dim i As Long
    'set this big number's place(place) "digit" to value digit
    '   (place corresponds to exp in N = sum(a x base ^ exp) )
    '   thus, the first symbol place is zero (0)
    '   However, the symbolcollection code does not allow a zero index, so
    '   the symbolcollection "starts" with symbolcollection.item(1)
    '   thus, we translate counting systems here and in setsymbol()
    
    'debugging - enumerate the symbolcollection (pre symbol-setting)
    'For i = 1 To Me.symbolcollection.Count
    '    Debug.Print "symbol(" & i & "): " & Me.symbolcollection.Item(i).Value
    'Next i
    
    'if we're trying to set a value for a symbol position which does not yet exist,
    '   then add zero valued symbols up to that position
    Do While Me.SymbolCollection.Count < place + 1
        Me.SymbolCollection.Add 0
    Loop
    Me.SymbolCollection.Item(place + 1).value = digit

    'debugging - enumerate the symbolcollection (post symbol-setting)
    'For i = 1 To Me.symbolcollection.Count
    '    Debug.Print "symbol(" & i & "): " & Me.symbolcollection.Item(i).Value
    'Next i
    'Debug.Print
End Function

Public Function getSymbol(place As Long) As Long
    '   place corresponds to exp in N = sum(a x base ^ exp)
    '   thus, the first symbol place is zero (0)
    '   However, the symbolcollection code does not allow a zero index, so
    '   the symbolcollection "starts" with symbolcollection.item(1)
    '   thus, we translate counting systems here and in setsymbol()
    If place <= Me.SymbolCollection.Count - 1 Then
        getSymbol = Me.SymbolCollection.Item(place + 1).value
    Else
        'error - calling for symbol that does not exist
        getSymbol = 0
    End If
    
End Function

'calculate (operand mod m) where m = modulus
'   Algorithm:  integer-divide operand by modulus, store result in bigTemp
'               subtract bigTemp from Operand to calculate the Remainder
'               store this remainder in the bigNumber that invoked the method
Public Function bigMod(Operand As bigNumber, Modulus As bigNumber) As Boolean
    Dim bigTemp1 As New bigNumber, bigTemp2 As New bigNumber
    Dim Base As Long    'temp to protect operand
    
    'default return false, true if successful
    bigMod = False
    Base = Me.lBase
    
    'integer-divide (precision = 0) operand by modulus
    'Debug.Print "Operand: " & Operand.big2str
    'Debug.Print "Modulus: " & Modulus.big2str
    bigTemp1.Divide Operand, Modulus, 0
    'Calculate remainder
    'Debug.Print "bigTemp1: " & bigTemp1.big2str
    'Debug.Print "Modulus: " & Modulus.big2str
    bigTemp2.Multiply bigTemp1, Modulus
    'Debug.Print "bigTemp1: " & bigTemp1.big2str
    'Debug.Print "Modulus: " & Modulus.big2str
    'Debug.Print "bigTemp2: " & bigTemp2.big2str
    'Debug.Print "Operand: " & Operand.big2str
    
    bigTemp1.bigInitialize 1, 1, Base, 0
    bigTemp1.Subtract Operand, bigTemp2
    'Debug.Print "Operand: " & Operand.big2str
    'Debug.Print "bigTemp2: " & bigTemp2.big2str
    'Debug.Print "bigTemp1: " & bigTemp1.big2str
    
    Assign bigTemp1
    'Debug.Print "Assigned: " & big2str()
    
    Normalize
    Operand.Normalize
    Modulus.Normalize
    bigMod = True

End Function

Public Function Log(Operand As bigNumber, Optional lBase As Long = 10) As bigNumber
End Function

Public Function OldSquareRootExponentHandling()
        '   calculate N = (a0*b^0 + a1*b^1 + ...)*b^exponent by building b^exponent as a
        '   bigNumber of the same form (c0*b^0 + c1*b^1 + ...) by recognizing that in any base
        '   b=10(base b) and raising (0*b^0 + 1*b^1) to the "exponent" power; then
        '   caclulate N = (a0*b^0 + a1*b^1 + ...) * (c0*b^0 + c1*b^1 + ...) by multiplication
        '   or N = (a0*b^0 + a1*b^1 + ...) / (c0*b^0 + c1*b^1 + ...) by multiplication
        '   depending on the sign of the exponent
        baseTemp.setSymbol 1, 0
        'raise (0*b^0 + 1*b^1) to the "exponent" power
        '  this is accomplished by left shifting the symbols of "1" by abs(exponent)
        '  places.  E.g. 10^2 = 100; 10^3 = 1000
        baseTemp.LeftShift Abs(Exponent)
        bigTemp.Assign baseTemp
        'debug.Print "bigTemp: " & bigTemp.big2str
        'debug.Print "baseTemp: " & baseTemp.big2str
        
        'remove the exponent from the operand, now that we'll be multiplying it back in
        baseTemp.Assign Operand
        baseTemp.lExponent = 0
        'debug.Print "baseTemp: " & baseTemp.big2str
        
        'restore the exponentiated value by multiplying or dividing it back in, depending on
        '   the sign of the exponent
        If Exponent <> 0 Then
            If Exponent > 0 Then
                'Dividend.sameBaseMultiply baseTemp, bigTemp
                Dividend.Multiply baseTemp, bigTemp
            Else
                Dividend.Divide baseTemp, bigTemp, Precision
            End If
        Else
            'exponent = 0 case
            Dividend.Assign baseTemp
        End If
        
        Dividend.Normalize 1
        'calculate the offset needed to properly place the floating point following
        '   calculation of the square root of the symbols as if they were an integer
        If Exponent < 0 Then
            FloatingPointOffset = Round(Abs(Exponent) / 2 + 0.3, 0)
        End If
        'don't need the exponent any more - it's been worked in
        Exponent = 0
        'debug.Print "bigTemp: " & bigTemp.big2str
        'debug.Print "baseTemp: " & baseTemp.big2str
        'debug.Print "Dividend: " & Dividend.big2str(1, Precision)

End Function
'calculate the square root of a multiple precision number (Operand),
'   within accuracy specified by precision
Public Function SquareRoot(Operand As bigNumber, Precision As Long) As Boolean
    Dim Base As Long, Exponent As Long, Sign As Integer     'temp holders - protect operand
    Dim bigPartDividend As New bigNumber, bigMultDivisor As New bigNumber
    Dim Divisor As New bigNumber, Dividend As New bigNumber
    Dim Quotient As New bigNumber, bigZero As New bigNumber
    Dim bigTemp As New bigNumber, bigOne As New bigNumber
    Dim baseTemp As New bigNumber, bigTwo As New bigNumber
    Dim bigCount As New bigNumber   'big loop counter
    Dim i As Long, n As Long        'loop counters
    Dim Done As Boolean, Divisible As Boolean
    Dim QuotientLength As Long
    Dim FloatingPointOffset As Long
    Dim oldLength As Long           'used with dividend to calculate floatingpointoffset
        
    'default boolean return is false - set true if subtraction successful
    SquareRoot = False
    
    'rebase does not apply - operand is same base similar
    'handle signs
    'handle exponents
    'divide
    
    'take base, exponent from operand
    Base = Operand.lBase
    Exponent = Operand.lExponent
    
    'handle the special cases
    bigZero.bigInitialize 1, 1, Base, 0
    bigOne.bigInitialize 1, 1, Base, 0
    bigOne.setSymbol 1, 0
    bigTwo.bigInitialize 1, 1, Base, 0
    bigTwo.setSymbol 2, 0
    'debug.Print "bigZero: " & bigZero.big2str
    'debug.Print "Operand: " & Operand.big2str
    
    'check for trivial cases of square root of zero or one
    If Operand.Equals(bigZero) Then
        'This is the trivial sqrt of zero case
        SquareRoot = True
        Assign bigZero
        Done = True
    Else
        If Operand.Equals(bigOne) Then
            'This is the trivial sqrt of one case
            SquareRoot = True
            Assign bigOne
            Done = True
        End If
    
    End If
        
    'handle sign - for now just return error if negative (complex number)
    Sign = Operand.iSign
    If Sign = -1 Then
        'this is a complex number
        SquareRoot = False
        Done = True
    End If
    
    If Not Done Then
    
        'initialize result bigNumber variable (that called this method)
        bigInitialize 1, 1, Base, 0
        
        'initialize temp bigNumber variables
        baseTemp.bigInitialize 1, 1, Base, 0
        bigTemp.bigInitialize 1, 1, Base, 0
        bigPartDividend.bigInitialize 1, 1, Base, 0
        bigMultDivisor.bigInitialize 1, 1, Base, 0
        Dividend.bigInitialize 1, 1, Base, 0
        Divisor.bigInitialize 1, 1, Base, 0
        Quotient.bigInitialize 1, 1, Base, 0
        
        
        'handle exponents
        '   Note the following relationships between numbers and their square roots:
        '      Number      float       Sqrt          float
        '      0.0002      2.00E-04    0.014142136   1.41E-02
        '      0.002       2.00E-03    0.04472136    4.47E-02
        '      0.02        2.00E-02    0.141421356   1.41E-01
        '      0.2         2.00E-01    0.447213595   4.47E-01
        '  N1= 2           2.00E+00    1.414213562   1.41E+00
        '      20          2.00E+01    4.472135955   4.47E+00
        '      200         2.00E+02    14.14213562   1.41E+01
        '      2000        2.00E+03    44.72135955   4.47E+01
        '      20000       2.00E+04    141.4213562   1.41E+02
        '      200000      2.00E+05    447.2135955   4.47E+02
        '      0.001024    1.02E-03    0.032         3.20E-02
        '      0.01024     1.02E-02    0.101192885   1.01E-01
        '      0.1024      1.02E-01    0.32          3.20E-01
        '      1.024       1.02E+00    1.011928851   1.01E+00
        '      10.24       1.02E+01    3.2           3.20E+00
        '      102.4       1.02E+02    10.11928851   1.01E+01
        '  N2= 1024        1.02E+03    32            3.20E+01
        '      10240       1.02E+04    101.1928851   1.01E+02
        '      102400      1.02E+05    320           3.20E+02
        '      1024000     1.02E+06    1011.928851   1.01E+03
        '-----------------------------------------------------
        '   Summary:
        '      Two forms:  sqrt(N1) and  sqrt(N1*10)=sqrt(N1)*sqrt(10) if N has odd # of symbols
        '      Two forms:  sqrt(N2) and  sqrt(N2/10)=sqrt(N2)/sqrt(10) if N has even # of symbols
        '                  where "10" represents the value of any base
        '      Each form appears for every value of the exponent in "scientific notation"
        '
        '   Algorithm for exponent handling:
        '   Normalize with format 1 - no positive exponent allowed, pad with zeros if necessary
        '      this completes handling of positive exponents.
        '   If resulting exponent is negative, then examine the exponent and length
        '      Count how many times we have to leftshift(2) to get all
        '         symbols to the left of the floating point (length + exp >=0)
        '         Note that leftshift(k) does not change the exponent, but adds k to length
        '         This allows us to calculate the square root of an integer with same
        '            odd/even length relationship to Number
        '       The count (FloatingPointOffset) of number of times we had to
        '          shift twice (leftshift(2)) is the number of times
        '          we will have to shift the resulting "quotient" back
        '
    
        '   Normalize with format 1 - no positive exponent allowed
        '      (pad on right with zeros to incorporate the exponent)
        'debug.Print "Dividend: " & Dividend.big2str
        Dividend.Assign Operand
        'debug.Print "Dividend: " & Dividend.big2str
        Dividend.Normalize 1
        'debug.Print "Dividend: " & Dividend.big2str
        'debug.Print "Dividend.symbolcollection.Count: " & Dividend.symbolcollection.Count
        'debug.Print "Dividend.lExponent " & Dividend.lExponent
        
        '   This completes handling of positive exponents.
        '   If Normalized dividend has a negative exponent, then examine the exponent and length
        If Dividend.lExponent < 0 Then
            '      Count how many times we have to leftshift(2) to get all
            '         symbols to the left of the floating point (length + exp >=0)
            oldLength = Dividend.SymbolCollection.Count
            FloatingPointOffset = 0
            Do Until Dividend.SymbolCollection.Count + Dividend.lExponent >= oldLength
                'Note that leftshift(k) does not change the exponent, but adds k to length
                Dividend.LeftShift 2
                'This allows us to calculate the square root of an integer with same
                '   odd/even length relationship to Number
                'The count (FloatingPointOffset) of number of times we had to
                '   shift twice (leftshift(2)) is the number of times
                '   we will have to shift the resulting "quotient" back
                FloatingPointOffset = FloatingPointOffset + 1
                'debug.Print "Dividend: " & Dividend.big2str
                'debug.Print "Dividend.symbolcollection.Count: " & Dividend.symbolcollection.Count
                'debug.Print "Dividend.lExponent " & Dividend.lExponent
                'debug.Print "FloatingPointOffset: " & FloatingPointOffset
            Loop
        End If
    End If
    'now that we've shifted symbols to generate an equivalent integer calculation,
    '   we can drop the exponent, since we've kept track of how far to shift back
    '   the resulting quotient
    Dividend.Normalize 1
    'debug.Print "Dividend: " & Dividend.big2str
    'debug.Print "Dividend.symbolcollection.Count: " & Dividend.symbolcollection.Count
    'debug.Print "Dividend.lExponent " & Dividend.lExponent
    'debug.Print "FloatingPointOffset: " & FloatingPointOffset
    Dividend.lExponent = 0
    Exponent = 0
    'debug.Print "Dividend: " & Dividend.big2str
    'debug.Print "Dividend.symbolcollection.Count: " & Dividend.symbolcollection.Count
    'debug.Print "Dividend.lExponent " & Dividend.lExponent
    'debug.Print "FloatingPointOffset: " & FloatingPointOffset
    
    'Calculate Square Root of Dividend
    'Algorithm:
    '   borrows manual method from Paul Black - NIST.gov web site
    'Definition: This describes a "long hand" or manual method of calculating or
    '   extracting square roots. Calculation of a square root by hand is a little
    '   like long-hand division.
    'Suppose you need to find the square root of 66564. Set up a "division" with the
    '   number under the radical. Mark off pairs of digits, starting from the decimal
    '   point. (Here the decimal point is a period (.) and a comma (,) marks pairs of
    '   digits.)
    '             ___________
    '           \/  6,65,64.
    'Look at the leftmost digit(s) (6 in this case). What is the largest number whose
    '   square is less than or equal to it? It is 2, whose square is 4.
    '   Write 2 above, write the square below and subtract.
    '              __2________
    '            \/  6,65,64.
    '               -4
    '               ----
    '                2
    'Now bring down the next two digits (65). The next "divisor" is double the number
    '   on top (2x2=4) and some other digit in the units position (4_).
    '              __2________
    '            \/  6,65,64.
    '               -4
    '               -----
    '           4_ ) 265
    'What is the largest number that we can put in the units and multiply times
    '   the divisor and still be less than or equal to what we have?
    '   (Algebraically, what is d such that d × 4d = 265?)
    '   It looks like 6 might work (since 6 * 40 = 240), but 6 is too big,
    '   since 6 * 46 = 276.
    '              __2__6_____
    '            \/  6,65,64.
    '               -4
    '               -----
    '            46 ) 265
    '                 276   TOO BIG - So try 5 instead.
    '
    '              __2__5_____
    '            \/  6,65,64.
    '               -4
    '               -----
    '           45 ) 265
    '               -225
    '               -------
    '                 40
    'Repeat: bring down the next two digits, and double the number on top (2x25=50)
    '   to make a "divisor", with another unit.
    '
    '              __2__5_____
    '            \/  6,65,64.
    '               -4
    '               -----
    '           45 ) 265
    '               -225
    '               -------
    '           50_ ) 4064
    '
    'It looks like 8 would work. Let's see.
    '              __2__5__8__
    '            \/  6,65,64.
    '               -4
    '               -----
    '           45 ) 265
    '               -225
    '               -------
    '           508 ) 4064
    '                -4064
    '                ------
    '                    0
    '
    'So the square root of 66564 is 258.
    'You can continue for as many decimal places as you need...
    '   just bring down more pairs of zeros.

    'Here we go
    '(1) for each group of two symbols (a partial dividend).
    '   (Note - first group may be a pair.  For dividend with odd number of symbols,
    '    the first group is the most significant symbol alone.   For dividend with even
    '    number of symbols, it is the two most significant symbols.
    If Not Done Then
        QuotientLength = Round((Dividend.SymbolCollection.Count / 2) + 0.3, 0)
    End If
    
    If Not Done And Dividend.SymbolCollection.Count Mod 2 = 0 Then
        bigPartDividend.setSymbol Dividend.getSymbol(Dividend.SymbolCollection.Count - 1), 1
        bigPartDividend.setSymbol Dividend.getSymbol(Dividend.SymbolCollection.Count - 2), 0
    Else
        If Not Done Then
            bigPartDividend.setSymbol Dividend.getSymbol(Dividend.SymbolCollection.Count - 1), 0
        End If
    End If
        
    '(2) find largest number whose square is less than or equal to the partial dividend
    If Not Done Then
        Divisor.Assign bigZero
        bigMultDivisor.Assign bigZero
        bigTemp.Subtract bigPartDividend, bigMultDivisor
        'debug.Print "Divisor: " & Divisor.big2str
        'debug.Print "bigMultDivisor: " & bigMultDivisor.big2str
        'debug.Print "bigPartDividend: " & bigPartDividend.big2str
        'debug.Print "bigTemp: " & bigTemp.big2str
        Do Until Not bigMultDivisor.LessThan(bigPartDividend)
            bigTemp.Add Divisor, bigOne
            Divisor.Assign bigTemp
            bigMultDivisor.bigExponent Divisor, 2
            bigTemp.Subtract bigPartDividend, bigMultDivisor
            'debug.Print "Divisor: " & Divisor.big2str
            'debug.Print "bigMultDivisor: " & bigMultDivisor.big2str
            'debug.Print "bigPartDividend: " & bigPartDividend.big2str
            'debug.Print "bigTemp: " & bigTemp.big2str
        Loop
    End If
    'correct for loop overshot if necessary
    If Not Done And bigMultDivisor.GreaterThan(bigPartDividend) Then
        bigTemp.Subtract Divisor, bigOne
        Divisor.Assign bigTemp
        bigMultDivisor.bigExponent Divisor, 2
        bigTemp.Subtract bigPartDividend, bigMultDivisor
        'debug.Print "Divisor: " & Divisor.big2str
        'debug.Print "bigMultDivisor: " & bigMultDivisor.big2str
        'debug.Print "bigPartDividend: " & bigPartDividend.big2str
        'debug.Print "bigTemp: " & bigTemp.big2str
    End If
    
    '(3) Put that number in the quotient
    '   note: should only take a square of one symbol to do this
    '   note 2: we'll left-shift the quotient as we get more symbols for it
    If Not Done Then
        'debug.Print "Quotient: " & Quotient.big2str
        Quotient.setSymbol Divisor.getSymbol(0), 0
        'debug.Print "Quotient: " & Quotient.big2str
    End If
    '(4) write the square below and subtract
    '   note: this subtraction was done above
    
    'reinitialize a loop counter to track position in the dividend
    '   note: if the result of subtraction was zero and the quotient
    '   has only one symbol, we're done - no more symbols are needed
    '   otherwise reset the loop counter to track the dividend symbols
    '   we're working on and calculate more quotient symbols
    i = -1
    If Not Done And QuotientLength >= 1 Then
        'covers quotient of one symbol
        bigPartDividend.Assign bigTemp
        'debug.Print "bigPartDividend: " & bigPartDividend.big2str
    End If
    
    If Not Done And QuotientLength >= 2 Then
        i = IIf(Dividend.SymbolCollection.Count Mod 2 = 0, Dividend.SymbolCollection.Count - 4, Dividend.SymbolCollection.Count - 3)
    End If
    Do While Not Done And i >= 0
        '(5) Now bring down the next two symbols and add to partial dividend in correct positions
        '   note: length of quotient was calculated above, first symbol of quotient accounting
        '         for first one or two symbols of dividend.  Regardless of even/odd length of
        '         dividend, second position of dividend corresponds to 2 x second position of
        '         quotient, and so on
        'debug.Print "bigPartDividend: " & bigPartDividend.big2str
        bigPartDividend.Normalize 1
        'debug.Print "bigPartDividend: " & bigPartDividend.big2str
        bigPartDividend.LeftShift 2
        'debug.Print "bigPartDividend: " & bigPartDividend.big2str
        bigPartDividend.setSymbol Dividend.getSymbol(i + 1), 1
        'debug.Print "bigPartDividend: " & bigPartDividend.big2str
        bigPartDividend.setSymbol Dividend.getSymbol(i), 0
        'debug.Print "bigPartDividend: " & bigPartDividend.big2str
        bigPartDividend.LeftTrim
        'debug.Print "Dividend: " & Dividend.big2str
        'debug.Print "bigPartDividend: " & bigPartDividend.big2str
        
        '(6) The next "divisor" is double the current quotient
        '   and some other symbol in the units position.  That is the largest number that
        '   we can put in the units position of the divisor and the least significant
        '   position of the quotient (and multiply times the new divisor) and have a result
        '   that is still less than or equal to the current, remaining dividend
        Quotient.LeftTrim
        Quotient.Normalize 1
        'debug.Print "Quotient: " & Quotient.big2str
        
        'if the partial dividend (or whole remaining dividend) is not zero,
        '   then calculate the next quotient symbol,
        '   but if it is zero, put a zero in the quotient symbol position
        If Not bigPartDividend.Equals(bigZero) Then
            bigTemp.Multiply Quotient, bigTwo
            Quotient.Normalize 1
            bigTemp.Normalize 1
            'debug.Print "bigTemp: " & bigTemp.big2str
            'debug.Print "Quotient: " & Quotient.big2str
            'renormalize this result as an integer since we don't need the exponent,
            '   just the symbols.  Be sure to safeguard significant trailing zero(s)
            '   since the normalize(0) function built into multiplication will have removed them
            '   and adjusted the exponent
            If bigTemp.lExponent > Quotient.lExponent Then
                'reinsert significant trailing zeros
                bigTemp.LeftShift (bigTemp.lExponent - Quotient.lExponent)
                'debug.Print "bigTemp: " & bigTemp.big2str
            End If
            bigTemp.lExponent = 0
            'debug.Print "bigTemp: " & bigTemp.big2str
            bigTemp.LeftShift 1
            'debug.Print "bigTemp: " & bigTemp.big2str
            Divisor.Assign bigTemp
            'debug.Print "Divisor: " & Divisor.big2str
            n = 1
            Divisor.setSymbol n, 0
            bigCount.bigInitialize 1, 1, Base, 0
            bigCount.setSymbol n, 0
            bigMultDivisor.Multiply Divisor, bigCount
            bigTemp.Subtract bigPartDividend, bigMultDivisor
            bigMultDivisor.Normalize 1
            bigTemp.Normalize 1
            'debug.Print "Divisor: " & Divisor.big2str
            'debug.Print "bigCount: " & bigCount.big2str
            'debug.Print "bigMultDivisor: " & bigMultDivisor.big2str
            'debug.Print "bigTemp: " & bigTemp.big2str
            'debug.Print "bigPartDividend: " & bigPartDividend.big2str
            Do While bigMultDivisor.LessThan(bigPartDividend) And n < Base - 1
                n = n + 1
                Divisor.setSymbol n, 0
                bigCount.setSymbol n, 0
                bigMultDivisor.Multiply Divisor, bigCount
                bigTemp.Subtract bigPartDividend, bigMultDivisor
                bigMultDivisor.Normalize 1
                bigTemp.Normalize 1
                'debug.Print "Divisor: " & Divisor.big2str
                'debug.Print "bigCount: " & bigCount.big2str
                'debug.Print "bigMultDivisor: " & bigMultDivisor.big2str
                'debug.Print "bigTemp: " & bigTemp.big2str
                
            Loop
            
            'correct for loop overshot if necessary
            If bigMultDivisor.GreaterThan(bigPartDividend) Then
                n = n - 1
                Divisor.setSymbol n, 0
                bigCount.setSymbol n, 0
                bigMultDivisor.Multiply Divisor, bigCount
                bigTemp.Subtract bigPartDividend, bigMultDivisor
                bigMultDivisor.Normalize 1
                bigTemp.Normalize 1
                'debug.Print "Divisor: " & Divisor.big2str
                'debug.Print "bigMultDivisor: " & bigMultDivisor.big2str
                'debug.Print "bigPartDividend: " & bigPartDividend.big2str
                'debug.Print "bigTemp: " & bigTemp.big2str
            End If
            
            '(7) Put that number in the quotient
            'debug.Print "Divisor: " & Divisor.big2str
            'debug.Print "Quotient: " & Quotient.big2str
            Quotient.LeftShift 1
            Divisor.Normalize 1
            'debug.Print "Divisor: " & Divisor.big2str
            'debug.Print "Quotient: " & Quotient.big2str
            Quotient.setSymbol Divisor.getSymbol(0), 0
            'debug.Print "Quotient: " & Quotient.big2str
            
            '(8) write the square below and subtract
            '   note: subtraction was done above
            bigPartDividend.Assign bigTemp
            bigPartDividend.Normalize 1
            
        Else    'partial dividend was zero, so put a zero symbol in the quotient
            Quotient.LeftShift 1
            Quotient.setSymbol 0, 0
            'debug.Print "Quotient: " & Quotient.big2str
            
        End If  'if partial dividend was zero
        
        'Repeat (5)-(8) until there are no more digits, or then pull down pairs of zeros
        '   until specified precision is reached.
        i = i - 2
    Loop
    
    'if precision is required, more work:
    'Repeat (5)-(8) until there are no more digits, or then pull down pairs of zeros
    '   until specified precision is reached.
    'Debug.Print "bigTemp: " & bigTemp.big2str
    'Debug.Print "bigPartDividend: " & bigPartDividend.big2str
    'If the remainder is not zero and the required precision has not been reached, keep going
    i = 1
    Do While Not Done And i <= Precision And Not bigPartDividend.Equals(bigZero)
        '(5) Now bring down two zeros and add to partial dividend in correct positions
        '   note: length of quotient was calculated above, first symbol of quotient accounting
        '         for first one or two symbols of dividend.  Regardless of even/odd length of
        '         dividend, second position of dividend corresponds to 2 x second position of
        '         quotient, and so on
        bigPartDividend.Normalize 1
        bigPartDividend.LeftShift 2
        bigPartDividend.LeftTrim
        'debug.Print "bigPartDividend: " & bigPartDividend.big2str
        
        '(6) The next "divisor" is double the current quotient
        '   and some other digit in the units position.  That is the largest number that
        '   we can put in the units and multiply times the divisor and still be less
        '   than or equal to what we have?
        Quotient.LeftTrim
        'debug.Print "Quotient: " & Quotient.big2str
        bigTemp.Multiply Quotient, bigTwo
        bigTemp.Normalize 1
        Quotient.Normalize 1
        'debug.Print "bigTemp: " & bigTemp.big2str
        'debug.Print "Quotient: " & Quotient.big2str
        'renormalize this result as an integer since we don't need the exponent,
        '   just the symbols.  Be sure to safeguard significant trailing zero(s)
        '   since the normalize(0) function built into multiplication will have removed them
        '   and adjusted the exponent (here, bigTemp should have same exponent as quotient)
        If bigTemp.lExponent > Quotient.lExponent Then
            'reinsert significant trailing zeros
            bigTemp.LeftShift (bigTemp.lExponent - Quotient.lExponent)
            'debug.Print "bigTemp: " & bigTemp.big2str
        End If
        bigTemp.lExponent = 0
        'debug.Print "bigTemp: " & bigTemp.big2str
        bigTemp.LeftShift 1
        'debug.Print "bigTemp: " & bigTemp.big2str
        Divisor.Assign bigTemp
        'debug.Print "Divisor: " & Divisor.big2str
        n = 1
        Divisor.setSymbol n, 0
        bigCount.bigInitialize 1, 1, Base, 0
        bigCount.setSymbol n, 0
        bigMultDivisor.Multiply Divisor, bigCount
        bigTemp.Subtract bigPartDividend, bigMultDivisor
        bigMultDivisor.Normalize 1
        bigTemp.Normalize 1
        'debug.Print "Divisor: " & Divisor.big2str
        'debug.Print "bigCount: " & bigCount.big2str
        'debug.Print "bigMultDivisor: " & bigMultDivisor.big2str
        'debug.Print "bigTemp: " & bigTemp.big2str
        Do While bigMultDivisor.LessThan(bigPartDividend) And n < 9
            n = n + 1
            Divisor.setSymbol n, 0
            bigCount.setSymbol n, 0
            bigMultDivisor.Multiply Divisor, bigCount
            bigTemp.Subtract bigPartDividend, bigMultDivisor
            bigMultDivisor.Normalize 1
            bigTemp.Normalize 1
            'debug.Print "Divisor: " & Divisor.big2str
            'debug.Print "bigCount: " & bigCount.big2str
            'debug.Print "bigMultDivisor: " & bigMultDivisor.big2str
            'debug.Print "bigTemp: " & bigTemp.big2str
            
        Loop
        
        'correct for loop overshot if necessary
        If bigMultDivisor.GreaterThan(bigPartDividend) Then
            n = n - 1
            Divisor.setSymbol n, 0
            bigCount.setSymbol n, 0
            bigMultDivisor.Multiply Divisor, bigCount
            bigTemp.Subtract bigPartDividend, bigMultDivisor
            bigMultDivisor.Normalize 1
            bigTemp.Normalize 1
            'debug.Print "Divisor: " & Divisor.big2str
            'debug.Print "bigCount: " & bigCount.big2str
            'debug.Print "bigMultDivisor: " & bigMultDivisor.big2str
            'debug.Print "bigPartDividend: " & bigPartDividend.big2str
            'debug.Print "bigTemp: " & bigTemp.big2str
        End If
        
        
        '(7) Put that number in the quotient,
        '    but decrement the exponent since it's to the right of the "decimal"
        Quotient.LeftShift 1
        Divisor.Normalize 1
        Quotient.setSymbol Divisor.getSymbol(0), 0
        Exponent = Exponent - 1
        Quotient.lExponent = Exponent
        'debug.Print "Quotient: " & Quotient.big2str
        
        '(8) write the square below and subtract
        '   note: subtraction was done above
        bigPartDividend.Assign bigTemp
        bigPartDividend.Normalize 1
        'Debug.Print "bigPartDividend: " & bigPartDividend.big2str
        
        'Repeat (5)-(8) until there are no more digits, or then pull down pairs of zeros
        '   until specified precision is reached.
        i = i + 1
    Loop
    
    If Not Done Then
        Quotient.lBase = Base
        Quotient.iSign = Sign
        Quotient.lExponent = Exponent - FloatingPointOffset
        Assign Quotient
        SquareRoot = True
    End If
End Function


'Divide one multiple precision number by another, assign sufficiently precise
'   quotient to the bigNumber that invoked the method
Public Function Divide(Operand1 As bigNumber, Operand2 As bigNumber, Precision As Long) As Boolean
    Dim Base As Long, Base2 As Long             'temp holders - protection during initialization
    Dim Sign As Integer, Exponent As Long       'temp holders - protection during initialization
    Dim Sign1 As Integer, Sign2 As Integer      'temp holders - protection during operand manipulation
    Dim bigPartDividend As New bigNumber, bigMultDivisor As New bigNumber
    Dim Divisor As New bigNumber, Dividend As New bigNumber
    Dim Quotient As New bigNumber, bigZero As New bigNumber
    Dim bigTemp As New bigNumber
    Dim i As Long, n As Long    'loop counters
    Dim Done As Boolean, Divisible As Boolean
        
    'default boolean return is false - set true if subtraction successful
    Divide = False
    
    'rebase operand 2 in base of operand 1 if necessary
    'multiply signs
    'subtract exponents
    'divide
    
    
    'take base from operand 1
    Base = Operand1.lBase
    Base2 = Operand2.lBase
    
    'Initialize Quotient, bigpartdividend
    Quotient.bigInitialize Sign, 1, Base, 0  'quotient
    bigPartDividend.bigInitialize 1, 1, Base, 0  'use for partial dividend
    
    'handle the special cases
    bigZero.bigInitialize 1, 1, Base, 0
    'debug.Print "bigZero: " & bigZero.big2str
    'debug.Print "Operand1: " & Operand1.big2str
    'debug.Print "Operand2: " & Operand2.big2str
    If Operand1.Equals(bigZero) Then
        'This is the trivial zero dividend case
        Divide = True
        Assign bigZero
        Done = True
    Else
        bigZero.bigInitialize 1, 1, Base2, 0
        If Operand2.Equals(bigZero) Then
            'this is the divide by zero case
            Divide = False
            Done = True
        Else
            'if bases aren't the same, convert operand2 to base of operand1
            If Operand1.lBase <> Operand2.lBase Then
                'debug.Print "Pre rebase Operand2: " & Operand2.big2str
                Divisor.ReBase Operand2, Base
                'debug.Print "Post rebase Divisor: " & Divisor.big2str
            Else
                Divisor.Assign Operand2
            End If
            'debug.Print "Divisor: " & Divisor.big2str
        
            'multiply signs to get sign for quotient,
            '   then make both operands positive for handling here
            '   Note: Divisor was assigned above, assign Dividend here
            '   this serves to preserve the operands, while manipulating their values
            Dividend.Assign Operand1                        'dividend
            'debug.Print "Dividend: " & Dividend.big2str
            
            Sign = Dividend.iSign * Divisor.iSign
            Divisor.iSign = 1
            Dividend.iSign = 1
        
            'initialize result bigNumber variable (that called this method)
            bigInitialize Sign, 1, Base, 0
            
            'check for dividend less than divisor and precision not requested
            '   (i.e. integer rather than floating point division)
            '   if so, return zero since there is not integer quotient
            If Dividend.LessThan(Divisor) And Precision = 0 Then
                'This is the "fraction < 1" case
                Divide = True
                Assign bigZero
                Done = True
            Else
                Done = False
            End If
            
            'Handle exponents
            'debug.Print "Dividend: " & Dividend.big2str
            'debug.Print "Operand1: " & Operand1.big2str
            'debug.Print "Divisor: " & Divisor.big2str
            'debug.Print "Operand2: " & Operand2.big2str
            'calculate the resultant exponent of the quotient and save for later
            '   note: Axb^E1 / Cxb^E2 = (A/C)xb^(E1-E2) -> save E1-E2 for later,
            '         Thus, calculate A/C where A and C are integers
            Exponent = Dividend.lExponent - Divisor.lExponent
            'Reset exponents of dividend and divisor to zero, per above
            Dividend.lExponent = 0
            Divisor.lExponent = 0
            'debug.Print "Dividend: " & Dividend.big2str
            'debug.Print "Divisor: " & Divisor.big2str
            
            'initialize bigNumber variables
            Quotient.bigInitialize Sign, 1, Base, Exponent  'quotient
            bigPartDividend.bigInitialize 1, 1, Base, 0  'use for partial dividend
            'debug.Print "Quotient: " & Quotient.big2str
            'debug.Print "bigPartDividend: " & bigPartDividend.big2str
                    
        End If
    End If
    
    'Algorithm:
    '   Operand1 is the dividend
    '   Operand2 (bigTemp) is the divisor
    '   Quotient is the Result
    '   Remainder is the remainder
    '   (1) get symbols from dividend into partial dividend until
    '       partial dividend is > divisor;
    '   (2) find the largest multiple (n) of divisor that is not > dividend
    '   (3) put n into quotient at the right symbol position
    '   (4) subtract n*divisor from dividend
    '   (5) this partial remainder is new dividend, repeat (1)-(4),
    '       - for each case where dividend is still not bigger than divisor,
    '       left-shift quotient and pad with a zero
    '       - if there are no more symbols in the full dividend, then either
    '       (a) pad with zeros to produce symbols for the quotient to the
    '       right of the "decimal point" until the result is sufficiently precise, or
    '       (b) we're done
    '   (6) when done, assign resulting qotient to the bigNumber that
    '       invoked the method
    
    If Not Done Then
        i = Dividend.SymbolCollection.Count - 1
    End If
    'i holds the symbol position in the quotient and dividend
    '   when i = 0, we have the last symbol in the dividend
    Do Until (i < 0) Or Done
        '   (1) get symbols from dividend into partial dividend until
        '       partial dividend is > divisor
        Do Until i < 0 Or Not Divisor.GreaterThan(bigPartDividend)
            bigPartDividend.LeftShift 1
            bigPartDividend.LeftTrim
            bigPartDividend.setSymbol Dividend.getSymbol(i), 0
            'debug.Print "bigPartDividend (" & i & "): " & bigPartDividend.big2str
            'debug.Print "Divisor (" & i & "): " & Divisor.big2str
            'debug.Print "Quotient (" & i & "): " & Quotient.big2str
            'increment loop counter (i holds symbol place for quotient)
            i = i - 1
            'set place digit in quotient to zero for now, if division follows,
            '   it will be rewritten, below.  If on the other hand, another shift
            '   is required to get a big enough partial dividend, then zero
            '   is correct for this position
            If i >= 0 Then
                Quotient.setSymbol 0, i
            End If
            'doevents
        Loop
        i = i + 1 'correct for loop overshot
        
        'check outcome for divisibility
        If Divisor.GreaterThan(bigPartDividend) Then
            Divisible = False
        Else
            Divisible = True
        End If
        
        If Divisible Then
            '   (2) find the largest multiple (n * divisor) that is not > dividend
            bigMultDivisor.Assign Divisor               'use for multiples of divisor
            n = 1
            'debug.Print "bigPartDividend (" & i & "): " & bigPartDividend.big2str
            'debug.Print "Divisor (" & i & "): " & Divisor.big2str
            'debug.Print "bigMultDivisor (" & n & "): " & bigMultDivisor.big2str
            
            'compare mult-divisor to dividend - adjust mult-divisor if necessary
            bigTemp.bigInitialize 1, 1, Base, 0
            bigTemp.Subtract bigPartDividend, bigMultDivisor
            'Debug.Print "bigPartDividend - bigMultDivisor = " & bigTemp.big2str
            Do While Not bigTemp.LessThan(Divisor)
                bigTemp.bigInitialize 1, 1, Base, 0
                bigTemp.Add bigMultDivisor, Divisor
                bigMultDivisor.Assign bigTemp
                'debug.Print "bigPartDividend (" & i & "): " & bigPartDividend.big2str
                'debug.Print "Divisor (" & i & "): " & Divisor.big2str
                'debug.Print "bigMultDivisor (" & n & "): " & bigMultDivisor.big2str
                n = n + 1
                'compare mult-divisor to dividend - adjust mult-divisor if necessary
                bigTemp.bigInitialize 1, 1, Base, 0
                bigTemp.Subtract bigPartDividend, bigMultDivisor
                'debug.Print "bigPartDividend - bigMultDivisor = " & bigTemp.big2str
                'doevents
            Loop
            
            '   (3) put n into quotient at the right symbol position
            If i >= 0 And Not bigPartDividend.Equals(bigZero) Then
                Quotient.setSymbol n, i
            End If
            '   (4) Assign result of subtraction (n*divisor from dividend)
            bigPartDividend.Assign bigTemp
            'debug.Print "BigMultDivisor: " & bigMultDivisor.big2str
            'debug.Print "Quotient: " & Quotient.big2str
            'debug.Print "Remainder: " & bigPartDividend.big2str
            '   (5) this partial remainder is new partial dividend, repeat (1)-(4),
            '       - for each case where dividend is still not bigger than divisor,
            '       that position in quotient is a zero
        End If   'divisible
        'not done integer part of division
        'get another digit from dividend on next pass
        i = i - 1
        'doevents
    Loop
    '       - if there are no more symbols in the full dividend, then either
    '       (a) pad dividend with zeros to produce symbols for calculating the
    '       quotient to the right of the "floating point" until the result is
    '       sufficiently precise, or
    '       (b) we're done
    Quotient.lExponent = Exponent
    
    i = 0
    'debug.Print "bigPartDividend (" & i & "): " & bigPartDividend.big2str
    Do Until i >= Precision Or bigPartDividend.Equals(bigZero) Or Done
        '   (1) "pull down" zeros into partial dividend since we have exhausted the
        '       symbols in the dividend, until partial dividend is > divisor
        Do Until i >= Precision Or Not Divisor.GreaterThan(bigPartDividend)
            bigPartDividend.LeftShift 1
            bigPartDividend.LeftTrim
            bigPartDividend.setSymbol 0, 0
            'debug.Print "bigPartDividend (" & i & "): " & bigPartDividend.big2str
            'debug.Print "Divisor (" & i & "): " & Divisor.big2str
            'debug.Print "Quotient (" & i & "): " & Quotient.big2str
            'increment loop counter (i holds symbol place for quotient)
            i = i + 1
            'set place digit in quotient to zero for now, if division follows,
            '   it will be rewritten, below.  If on the other hand, another shift
            '   is required to get a big enough partial dividend, then zero
            '   is correct for this position
            'decrement exponent for each shift here, since we're dividing beyond
            '   the "decimal" point
            If i <= Precision Then
                Quotient.LeftShift 1
                'debug.Print "Quotient (" & i & "): " & Quotient.big2str
                Quotient.lExponent = Quotient.lExponent - 1
                'debug.Print "Quotient (" & i & "): " & Quotient.big2str
            End If
            'doevents
        Loop
        i = i - 1 'correct for loop overshot
        
        'check outcome for divisibility
        If Divisor.GreaterThan(bigPartDividend) Then
            Divisible = False
        Else
            Divisible = True
        End If
        
        If Divisible Then
            '   (2) find the largest multiple (n * divisor) that is not > dividend
            bigMultDivisor.Assign Divisor               'use for multiples of divisor
            n = 1
            'debug.Print "bigPartDividend (" & i & "): " & bigPartDividend.big2str
            'debug.Print "Divisor (" & i & "): " & Divisor.big2str
            'debug.Print "bigMultDivisor (" & n & "): " & bigMultDivisor.big2str
            
            'compare mult-divisor to dividend - adjust mult-divisor if necessary
            bigTemp.bigInitialize 1, 1, Base, 0
            bigTemp.Subtract bigPartDividend, bigMultDivisor
            'debug.Print "bigPartDividend - bigMultDivisor = " & bigTemp.big2str
            Do While Not bigTemp.LessThan(Divisor)
                bigTemp.bigInitialize 1, 1, Base, 0
                bigTemp.Add bigMultDivisor, Divisor
                bigMultDivisor.Assign bigTemp
                'debug.Print "bigPartDividend (" & i & "): " & bigPartDividend.big2str
                'debug.Print "Divisor (" & i & "): " & Divisor.big2str
                'debug.Print "bigMultDivisor (" & n & "): " & bigMultDivisor.big2str
                n = n + 1
                'compare mult-divisor to dividend - adjust mult-divisor if necessary
                bigTemp.bigInitialize 1, 1, Base, 0
                bigTemp.Subtract bigPartDividend, bigMultDivisor
                'debug.Print "bigPartDividend - bigMultDivisor = " & bigTemp.big2str
                'doevents
            Loop
            
            '   (3) put n into quotient at the right symbol position
            If i <= Precision And Not bigPartDividend.Equals(bigZero) Then
                Quotient.setSymbol n, 0
            End If
            '   (4) Assign result of subtraction (n*divisor from dividend)
            bigPartDividend.Assign bigTemp
            'debug.Print "BigMultDivisor: " & bigMultDivisor.big2str
            'debug.Print "Quotient: " & Quotient.big2str
            'debug.Print "Remainder: " & bigPartDividend.big2str
            '   (5) this partial remainder is new partial dividend, repeat (1)-(4),
            '       - for each case where dividend is still not bigger than divisor,
            '       that position in quotient is a zero
        End If   'divisible
        'not done integer part of division
        'get another digit from dividend on next pass
        i = i + 1
        'doevents

    Loop
    
    '   (6) when done, assign resulting qotient to the bigNumber that
    '       invoked the method
        
    If Not Done Then
        Done = True
        'set the length of quotient by defaulting it to the length of divisor
        '   (largest possible for integer division) and then trimming zeros off the left
        Quotient.LeftTrim
        Assign Quotient
        Me.iSign = Sign
        'restore operand signs
        'Operand1.iSign = Sign1
        'Operand2.iSign = Sign2
        
        Divide = True
    End If
    Normalize
    Operand1.Normalize
    Operand2.Normalize
    
End Function

Public Function Multiply(Operand1 As bigNumber, Operand2 As bigNumber) As Boolean
    Dim Base As Long, Exponent As Long, Sign As Integer     'temp holders - protection during initialization
    Dim bigTemp As New bigNumber
    
    'default boolean return is false - set true if subtraction successful
    Multiply = False
    
    'rebase operand 2 in base of operand 1 if necessary
    'multiply signs
    'add exponents
    'call sameBaseMultiply
    
    'take sign and base from operand 1
    Sign = Operand1.iSign
    Base = Operand1.lBase
    
    'initialize result bigNumber variable (that called this method)
    bigInitialize Sign, 0, Base, 0
    
    'if bases aren't the same, convert operand2 to base of operand1
    If Operand1.lBase <> Operand2.lBase Then
        bigTemp.ReBase Operand2, Base
    Else
        bigTemp.Assign Operand2
    End If
    'debug.Print bigTemp.big2str
    
    'multiply signs
    Sign = Operand1.iSign * Operand2.iSign
        
        
    'add exponents
    Exponent = Operand1.lExponent + bigTemp.lExponent
    
    'Multiply
    sameBaseMultiply Operand1, bigTemp
    Me.iSign = Sign
    Me.lExponent = Exponent
    Normalize
    Operand1.Normalize
    Operand2.Normalize
    Multiply = True
    
End Function


Public Function ModuloMultiply(Operand1 As bigNumber, Operand2 As bigNumber, Modulus As bigNumber) As Boolean
    Dim Base As Long, Exponent As Long, Sign As Integer     'temp holders - protection during initialization
    Dim bigTemp As New bigNumber, bigTemp2 As New bigNumber
    
    'default boolean return is false - set true if subtraction successful
    ModuloMultiply = False
    
    'rebase operand 2 in base of operand 1 if necessary
    'multiply signs
    'add exponents
    'call sameBaseMultiply
    
    'take sign and base from operand 1
    Sign = Operand1.iSign
    Base = Operand1.lBase
    
    'initialize result bigNumber variable (that called this method)
    bigInitialize Sign, 0, Base, 0
    
    'if bases aren't the same, convert operand2 to base of operand1
    If Operand1.lBase <> Operand2.lBase Then
        bigTemp.ReBase Operand2, Base
    Else
        bigTemp.Assign Operand2
    End If
    'debug.Print bigTemp.big2str
    
    'multiply signs
    Sign = Operand1.iSign * Operand2.iSign
        
        
    'add exponents
    Exponent = Operand1.lExponent + bigTemp.lExponent
    
    'Multiply
    bigTemp2.sameBaseMultiply Operand1, bigTemp
    Me.bigMod bigTemp2, Modulus
    Me.iSign = Sign
    Me.lExponent = Exponent
    Normalize
    Operand1.Normalize
    Operand2.Normalize
    ModuloMultiply = True
    
End Function



Public Function LessThan(Operand As bigNumber) As Boolean
    Dim i As Long
    Dim negFlag As Integer
    Dim Done As Boolean
    Dim bigZero As New bigNumber, bigTemp As New bigNumber
    Dim Base As Long, Sign As Integer   'temp holders to protect operand
    Dim Exponent As Long                'temp holders to protect operand
    
    LessThan = False     'default for "equals case"
        
    negFlag = 1
    Base = Me.lBase
    Sign = Me.iSign
    Exponent = Me.lExponent
    Done = False
    
    'initialize bigZero
    bigZero.bigInitialize 1, 1, Base, 0
    
    'base comparison algorithm:
    '  convert the operand to the base of the number calling for its comparison
    '  compare signs
    '  compare exponents
    '  compare length
    '  compare symbol by symbol
    
    'convert operand to the base of the number calling for its comparison
    If Operand.lBase <> Me.lBase Then
        bigTemp.bigInitialize Sign, 0, Base
        bigTemp.ReBase Operand, Base
    Else
        bigTemp.Assign Operand
    End If
    'Debug.Print "number: " & big2str()
    'Debug.Print "operand: " & Operand.big2str
    'Debug.Print "bigTemp: " & bigTemp.big2str
    
    
    'compare signs
    If Me.iSign = 1 And bigTemp.iSign = -1 Then
        LessThan = False
        Done = True
    Else
        If Me.iSign = -1 And bigTemp.iSign = 1 Then
            LessThan = True
            Done = True
        Else
            If Me.iSign = -1 And bigTemp.iSign = -1 Then
                negFlag = -1
                'continue with comparison
            Else
                'signs must both be positive, so just continue
            End If
        End If
    End If
    
    'check for special cases (number or operand is zero)
    If bigTemp.Equals(bigZero) Then
        If negFlag = 1 Then
            LessThan = False
        Else
            If negFlag = -1 Then
                LessThan = True
            Else
                'error
            End If
        End If
        Done = True
    Else
        'the "Me." identifies the number that invoked the method
        If Me.Equals(bigZero) Then
            If negFlag = 1 Then
                LessThan = True
            Else
                If negFlag = -1 Then
                    LessThan = False
                Else
                    'error
                End If
            End If
            Done = True
        End If
    End If
    
    'compare exponent
    'Debug.Print "number: " & big2str()
    'Debug.Print "operand: " & Operand.big2str
    'Debug.Print "bigTemp: " & bigTemp.big2str
    If Not Done And Me.lExponent < bigTemp.lExponent Then
        'decrement the greater exponent and left shift the associated number
        bigTemp.LeftShift (bigTemp.lExponent - Exponent)
        bigTemp.lExponent = Exponent
        'Debug.Print "bigTemp: " & bigTemp.big2str
        'Debug.Print "Operand: " & Operand.big2str
        'Debug.Print "Me: " & big2str()
        Operand.Assign bigTemp
    Else
        If Not Done And bigTemp.lExponent < Me.lExponent Then
            'decrement the greater exponent and left shift the associated number
            LeftShift (lExponent - bigTemp.lExponent)
            Me.lExponent = bigTemp.lExponent
            'Debug.Print "bigTemp: " & bigTemp.big2str
            'Debug.Print "Operand: " & Operand.big2str
            'Debug.Print "Me: " & big2str()
        End If
    End If
    
    'compare length
    If Not Done And Me.SymbolCollection.Count < bigTemp.SymbolCollection.Count Then
        LessThan = True
        Done = True
    Else
        If Not Done And Me.SymbolCollection.Count > bigTemp.SymbolCollection.Count Then
            LessThan = False
            Done = True
        Else
            'must be same number of symbols
            '  compare symbol by symbol
            i = Me.SymbolCollection.Count - 1
            Do While i >= 0 And Not Done
                If getSymbol(i) < bigTemp.getSymbol(i) Then
                    LessThan = True
                    Done = True
                Else
                    If getSymbol(i) > bigTemp.getSymbol(i) Then
                        LessThan = False
                        Done = True
                    End If
                End If
                'this symbol was the same so compare the next
                ' less significant symbol
                i = i - 1
                'doevents
            Loop
        End If
    End If
    'If we got this far with no "done" flag, then they are equal
    If Not Done Then
        LessThan = False
    Else
    'check the flag for double negative which negates the comparison
        If negFlag = -1 Then
            LessThan = Not LessThan
        End If
    End If
End Function
Public Function GreaterThan(Operand As bigNumber) As Boolean
    Dim i As Long
    Dim negFlag As Integer
    Dim Done As Boolean
    Dim bigZero As New bigNumber, bigTemp As New bigNumber
    Dim Base As Long, Sign As Integer   'temp holders to protect operand
    Dim Exponent As Long                'temp holders to protect operand
    GreaterThan = False     'default for "equals case"
        
    negFlag = 1
    Base = Me.lBase
    Sign = Me.iSign
    Exponent = Me.lExponent
    Done = False
    
    'initialize bigZero
    bigZero.bigInitialize 1, 1, Base, 0
    
    'base comparison algorithm:
    '  convert the operand to the base of the number calling for its comparison
    '  compare signs
    '  compare exponents
    '  compare length
    '  compare symbol by symbol
    
    'convert operand to the base of the number calling for its comparison
    If Operand.lBase <> Me.lBase Then
        bigTemp.bigInitialize Sign, 0, Base
        bigTemp.ReBase Operand, Base
    Else
        bigTemp.Assign Operand
    End If
    
    'compare signs
    If Me.iSign = 1 And bigTemp.iSign = -1 Then
        GreaterThan = True
        Done = True
    Else
        If Me.iSign = -1 And bigTemp.iSign = 1 Then
            GreaterThan = False
            Done = True
        Else
            If Me.iSign = -1 And bigTemp.iSign = -1 Then
                negFlag = -1
                'continue with comparison
            Else
                'signs must both be positive, so just continue
            End If
        End If
    End If
    
    'Debug.Print "bigTemp: " & bigTemp.big2str
    'Debug.Print "Me: " & Me.big2str
    'Debug.Print "Operand: " & Operand.big2str
    'Debug.Print Chr(13) & Chr(10)
    'check for special cases (number or operand is zero)
    If bigTemp.Equals(bigZero) Then
        If negFlag = 1 Then
            GreaterThan = True
        Else
            If negFlag = -1 Then
                GreaterThan = False
            Else
                'error
            End If
        End If
        Done = True
    Else
        'the "Me." identifies the number that invoked the method
        If Me.Equals(bigZero) Then
            If negFlag = 1 Then
                GreaterThan = False
            Else
                If negFlag = -1 Then
                    GreaterThan = True
                Else
                    'error
                End If
            End If
            Done = True
        End If
    End If
    
    'compare exponent
    'Debug.Print "number: " & big2str()
    'Debug.Print "operand: " & Operand.big2str
    'Debug.Print "bigTemp: " & bigTemp.big2str
    If Not Done And Me.lExponent < bigTemp.lExponent Then
        'decrement the greater exponent and left shift the associated number
        bigTemp.LeftShift (bigTemp.lExponent - Exponent)
        bigTemp.lExponent = Exponent
        'Debug.Print "bigTemp: " & bigTemp.big2str
        'Debug.Print "Operand: " & Operand.big2str
        'Debug.Print "Me: " & big2str()
        Operand.Assign bigTemp
    Else
        If Not Done And bigTemp.lExponent < Me.lExponent Then
            'decrement the greater exponent and left shift the associated number
            LeftShift (lExponent - bigTemp.lExponent)
            Me.lExponent = bigTemp.lExponent
            'Debug.Print "bigTemp: " & bigTemp.big2str
            'Debug.Print "Operand: " & Operand.big2str
            'Debug.Print "Me: " & big2str()
        End If
    End If
    
    'compare length
    'Debug.Print "number: " & big2str()
    'Debug.Print "bigTemp: " & bigTemp.big2str
    If Not Done And Me.SymbolCollection.Count < bigTemp.SymbolCollection.Count Then
        GreaterThan = False
        Done = True
    Else
        If Not Done And Me.SymbolCollection.Count > bigTemp.SymbolCollection.Count Then
            GreaterThan = True
            Done = True
        Else
            'must be same number of symbols
            '  compare symbol by symbol
            i = Me.SymbolCollection.Count - 1
            Do While i >= 0 And Not Done
                If getSymbol(i) < bigTemp.getSymbol(i) Then
                    GreaterThan = False
                    Done = True
                Else
                    If getSymbol(i) > bigTemp.getSymbol(i) Then
                        GreaterThan = True
                        Done = True
                    End If
                End If
                'this symbol was the same so compare the next
                ' less significant symbol
                i = i - 1
                'doevents
            Loop
        End If
    End If
    'If we got this far with no "done" flag, then they are equal
    If Not Done Then
        GreaterThan = False
    Else
    'check the flag for double negative which negates the comparison
        If negFlag = -1 Then
            GreaterThan = Not GreaterThan
        End If
    End If
End Function

Public Function Equals(Operand As bigNumber) As Boolean
    Dim i As Long
    Dim negFlag As Integer
    Dim Done As Boolean
    Dim bigTemp As New bigNumber
    Dim Base As Long, Sign As Integer   'temp holders to protect operand
    Dim Exponent As Long                'temp holders to protect operand
    
    Equals = False     'default for "equals case"
        
    negFlag = 1
    Base = Me.lBase
    Sign = Me.iSign
    Exponent = Me.lExponent
    Done = False
    
    'base comparison algorithm:
    '  convert the operand to the base of the number calling for its comparison
    '  compare signs
    '  compare exponents
    '  compare length
    '  compare symbol by symbol
    
    'convert operand to the base of the number calling for its comparison
    If Operand.lBase <> Me.lBase Then
        bigTemp.bigInitialize Sign, 0, Base
        bigTemp.ReBase Operand, Base
    Else
        bigTemp.Assign Operand
    End If
    
    'compare signs
    If Me.iSign <> bigTemp.iSign Then
        Equals = False
        Done = True
    End If
    
    'compare exponent
    If Not Done And Exponent < bigTemp.lExponent Then
        'decrement the greater exponent and left shift the associated number
        bigTemp.LeftShift (bigTemp.lExponent - Exponent)
        bigTemp.lExponent = Exponent
        Operand.Assign bigTemp
        'Debug.Print "bigTemp: " & bigTemp.big2str
        'Debug.Print "operand: " & Operand.big2str
    Else
        If Not Done And Operand.lExponent < Me.lExponent Then
            'decrement the greater exponent and left shift the associated number
            LeftShift (lExponent - bigTemp.lExponent)
            Me.lExponent = bigTemp.lExponent
            'Debug.Print "bigTemp: " & bigTemp.big2str
            'Debug.Print "operand: " & Operand.big2str
            'Debug.Print "Me: " & big2str()
        End If
    End If
    
    'compare length
    If Not Done And Me.SymbolCollection.Count <> bigTemp.SymbolCollection.Count Then
        'debug.print "bigTemp: " & bigTemp.big2str
        'debug.print "calling: " & big2str()
        Equals = False
        Done = True
    Else
        'must be same number of symbols
        '  compare symbol by symbol
        i = Me.SymbolCollection.Count - 1
        Do While i >= 0 And Not Done
            If getSymbol(i) <> bigTemp.getSymbol(i) Then
                Equals = False
                Done = True
            End If
            'this symbol was the same so compare the next
            ' less significant symbol
            i = i - 1
            'doevents
        Loop
    End If
    'If we got this far with no "done" flag, then they are equal
    If Not Done Then
        Equals = True
    End If
End Function

Public Function big2str(Optional iFormat As Integer, Optional Precision As Long) As String
    Dim i As Long, n As Long
    Dim CrLf As String
    Dim Exponent As Long
    Dim FlexiDecimalCollection As FlexiDecimalCollection
    
    Set FlexiDecimalCollection = frmMain.FlexiDecimalCollection
    
    CrLf = Chr(10) & Chr(13) 'carriage return, line feed
    
    'initialize string
    big2str = ""
    i = Me.SymbolCollection.Count - 1
    Do While i >= 0
        'insert comma every third symbol, CR LF every 100th symbol
        If getSymbol(i) < 0 Then
            Me.iSign = -1
            setSymbol Me.iSign * getSymbol(i), i
        End If
        'note the flexidecimalcollection offset of one accomodates collection
        '   enumeration beginning at 1 whereas number symbol enumeration
        '   begins at 0
        big2str = big2str _
           & IIf(Int(getSymbol(i)) < 10, getSymbol(i), FlexiDecimalCollection.Item(getSymbol(i) + 1).SymbolString) _
           & IIf(i Mod 3 = 0 And i > 0 And iFormat = 0, ",", "") _
           & IIf((((Me.SymbolCollection.Count - 1) - i) Mod 100 = 0 And i > 0 And i < Me.SymbolCollection.Count - 1 And iFormat = 0), CrLf, "")
        'debug.print IIf((i Mod 45 = 0 And i > 0), CrLf, "") & getSymbol(i) & IIf(i Mod 3 = 0 And i > 0, ",", "") & big2str
        i = i - 1
        'doevents
    Loop
    
    Exponent = Me.lExponent
    'if precision is non-zero and greater than the number of symbols that can be represented
    '   to the right of the "decimal point" then pad right with zeros and decrement the exponent
    If Precision > 0 And iFormat <> 0 And Precision > Me.SymbolCollection.Count - 1 Then
        For i = 1 To Precision - (Me.SymbolCollection.Count - 1)
            big2str = big2str & "0"
            Exponent = Exponent - 1
        Next i
    End If
     Select Case iFormat
     Case 0
         'unformatted
         big2str = IIf(iSign >= 0, "", "-") & big2str & _
                 "(b" & Me.lBase & ")" & _
                 IIf(Exponent = 0, "", " x " & Me.lBase & "^" & Exponent)
    Case 1
         'scientific
         ' Note: exponent is decremented once for ea symbol moved to right of "decimal"
         Exponent = (Len(big2str) - 1) + Exponent
         big2str = IIf(iSign >= 0, "", "-") & _
                 Left(big2str, 1) & "." & _
                 Mid(big2str, 2, IIf(Precision > 0, Precision, Len(big2str) - 1)) & _
                 "(b" & Me.lBase & ")" & " x " & Me.lBase & "^" & Exponent

     Case 2
        'floating point
        ' Note: like scientific, but drop the exponential notation if exponent is zero
        Exponent = (Len(big2str) - 1) + Exponent
        big2str = IIf(iSign >= 0, "", "-") & _
                 Left(big2str, 1) & "." & _
                 Mid(big2str, 2, IIf(Precision > 0, Precision, Len(big2str) - 1)) & _
                 "(b" & Me.lBase & ")" & IIf(Exponent = 0, "", " x " & Me.lBase & "^" & Exponent)
       
     Case 3
         strFormat = "engineering"
    End Select
    

End Function

'convert a string to a bigNumber
'  works only for integers right now
'  Returns value to the bigNumber that invokes the method
Public Function str2big(bigString As String) As Boolean
    Dim i As Long, n As Long    'loop counters
    Dim Base As Long, Exponent As Long, Sign As Integer
    Dim numberString As String
    Dim strSymbol As String
    Dim symbolsLeftOfDecimalPoint As Long
    Dim FlexiDecimalCollection As FlexiDecimalCollection
    
    Set FlexiDecimalCollection = frmMain.FlexiDecimalCollection
    
    'Look for a "-" or "+" character to identify the sign
    If Left(Trim(bigString), 1) = "-" Then
        'negative
        Sign = -1
    Else
        If Left(Trim(bigString), 1) = "+" Then
            'positive
            Sign = 1
        Else
            'default to positive
            Sign = 1
        End If
    End If
    
    'Look for a "b" or "B" character to the right of a "(" character to identify the base
    If InStr(InStr(1, Trim(bigString), "(") + 1, Trim(bigString), "b") > 0 Then
        Base = Mid$(bigString, _
                InStr(InStr(1, Trim(bigString), "(") + 1, Trim(bigString), "b") + 1, _
                (InStr(1, bigString, ")") + 1) - _
                (InStr(InStr(1, Trim(bigString), "(") + 1, Trim(bigString), "b") + 1) - 1)
    Else
        If InStr(InStr(1, Trim(bigString), "(") + 1, Trim(bigString), "B") > 0 Then
            Base = Mid$(bigString, _
                    InStr(InStr(1, Trim(bigString), "(") + 1, Trim(bigString), "B") + 1, _
                    (InStr(1, bigString, ")") + 1) - _
                    (InStr(InStr(1, Trim(bigString), "(") + 1, Trim(bigString), "B") + 1) - 1)
        Else
            'default to base 10
            Base = 10
        End If
    End If
    
    'look for a "^" or "E" or "e" character to identify the exponent
    If InStr(1, Trim(bigString), "^") > 0 Then
        Exponent = Right$(Trim(bigString), (Len(Trim(bigString)) - InStr(1, Trim(bigString), "^")))
    Else
        'if base is less than 14, find the first E since E is not a valid symbol
        If Base < 14 And InStr(1, Trim(bigString), "E") > 0 Then
            Exponent = Right$(Trim(bigString), (Len(Trim(bigString)) - InStr(1, Trim(bigString), "E")))
        Else
            'if base is not less than 14, look for first E to the right of a ")" since that
            '   character must be present to represent the base, and the exponent must be
            '   to the right of it
            If Base >= 14 And _
                InStr(InStr(1, Trim(bigString), ")") + 1, Trim(bigString), "E") > 0 Then
                
                Exponent = Right$(Trim(bigString), (Len(Trim(bigString)) - _
                            InStr(InStr(1, Trim(bigString), ")") + 1, Trim(bigString), "E")))
            Else
                'if base is less than 46, find the first e since e is not a valid symbol
                If Base < 46 And InStr(1, Trim(bigString), "e") > 0 Then
                    Exponent = Right$(Trim(bigString), (Len(Trim(bigString)) - _
                                InStr(1, Trim(bigString), "e")))
                Else
                    'if base is not less than 46, look for first e to the right of a ")" since that
                    '   character must be present to represent the base, and the exponent must be
                    '   to the right of it
                    If Base >= 46 And _
                        InStr(InStr(1, Trim(bigString), ")") + 1, _
                        Trim(bigString), "e") > 0 Then
                    
                        Exponent = Right$(Trim(bigString), (Len(Trim(bigString)) - _
                                    InStr(InStr(1, Trim(bigString), ")") + 1, _
                                    Trim(bigString), "e")))
                    Else
                        'default to exponent = 0
                        Exponent = 0
                    End If
                End If
            End If
        End If
    End If
    
    Me.bigInitialize 1, 1, Base, 0
    'look for a "(" or "^" or "E" character to identify a
    '   base/exponent separation from number symbols
    If InStr(1, bigString, "(") > 0 Then
        numberString = Left$(bigString, InStr(1, bigString, "(") - 1)
    Else
        If InStr(1, bigString, "^") > 0 Then
            numberString = Left$(bigString, InStr(1, bigString, "^") - 1)
        Else
            If InStr(1, bigString, "E") > 0 Then
                numberString = Left$(bigString, InStr(1, bigString, "E") - 1)
            Else
                If InStr(1, bigString, "e") > 0 Then
                    numberString = Left$(bigString, InStr(1, bigString, "e") - 1)
                Else
                    numberString = bigString
                End If
            End If
        End If
    End If
    
    'adjust numberstring for sign
    If Left(numberString, 1) = "-" Or Left(numberString, 1) = "+" Then
        numberString = Mid(numberString, 2)
    End If
    
    symbolsLeftOfDecimalPoint = 0
    For i = 1 To Len(numberString)
        'check to ensure symbol is numeric (to weed out commas, etc.
        '   Note: if a "decimal" point is found, save position info for exponent adjustment
        '         use only the first "decimal point" found
        '   If it's not numeric - check to see if it's a possible symbol from a higher base
        
        strSymbol = Mid(numberString, i, 1)
        If IsNumeric(strSymbol) Then
            If i > 1 Then
                'don't shift first entry
                Me.LeftShift 1
            End If
            Me.setSymbol Int(strSymbol), 0
        Else
            If strSymbol = "." And symbolsLeftOfDecimalPoint = 0 Then
                'save relative position of the "decimal point" to adjust exponent later
                symbolsLeftOfDecimalPoint = Me.SymbolCollection.Count
            Else
                'not a numeric (0-9) and not a "." so check for alpha symbols from
                '   flexidecimal collection, as long as value is less than given base
                'If Asc(strSymbol) - 55 >= 10 And Asc(strSymbol) - 55 <= 255 Then
                    'find strSymbol in flexidecimal collection and get the numeric value
                    '  Note: flexidecimal collection enumerates from 1 while numbers enumerate from
                    '  zero (0), so add 1 to the index (i.e. find symbol n at fdc index n+1)
                    n = 10
                    Do Until FlexiDecimalCollection.Item(n + 1).SymbolString = strSymbol Or n >= Base
                        'Debug.Print "n: " & n & " fdc.symbol: " & FlexiDecimalCollection.Item(n + 1).SymbolString
                        n = n + 1
                    Loop
                    If FlexiDecimalCollection.Item(n + 1).SymbolString = strSymbol And n <= Base Then
                        If i > 1 Then
                            'don't shift first entry
                            Me.LeftShift 1
                        End If
                        Me.setSymbol n, 0
                    Else
                        'invalid symbol character
                    End If
                'End If
            End If
        End If
        'doevents
    Next i
    'adjust exponent if a decimal point was found
    If symbolsLeftOfDecimalPoint > 0 Then
        Exponent = Exponent - (Me.SymbolCollection.Count - symbolsLeftOfDecimalPoint)
    End If
    
    Me.lBase = Base
    Me.lExponent = Exponent
    Me.iSign = Sign
    'debug.Print "Number: " & Me.big2str
    'debug.Print "Base: " & Me.lBase
    'Debug.Print "Exponent: " & Me.lExponent
    'Debug.Print "Length: " & Me.symbolcollection.Count
    'Debug.Print "Sign: " & Me.iSign
End Function

'Add two multiple precision numbers
Public Function Add(Operand1 As bigNumber, Operand2 As bigNumber) As Boolean
    Dim i As Long, subLength As Long
    Dim Base As Long, Sign As Integer, Exponent As Long       'temp holders - protect operand
    Dim borrowFrom As Long, borrowTo As Long
    Dim bigTemp As New bigNumber
    Dim Op1 As New bigNumber, Op2 As New bigNumber  'protect operand
    
    'protect operand by assigning value to temp variables
    Op1.Assign Operand1
    Op2.Assign Operand2
    'debug.Print "Op1: " & Op1.big2str
    'debug.Print "Op2: " & Op2.big2str
    
    'default boolean return is false - set true if subtraction successful
    Add = False
    
    'Check signs and use "subtract" if necessary
    'check base
    'check exponent
    'adjust lengths by padding with zeros as necessary
    'perform operation symbol by symbol
    
    'check signs
    If Op1.iSign = 1 And Op2.iSign = -1 Then
        Op2.iSign = 1
        Subtract Op1, Op2
        Sign = Me.iSign
        Done = True
    Else
        If Op1.iSign = -1 And Op2.iSign = 1 Then
            'swap operands to subtract value of 1 from value of 2
            Op1.iSign = 1
            Subtract Op2, Op1
            Sign = Me.iSign
            Done = True
        Else
            If Op1.iSign = -1 And Op2.iSign = -1 Then
                Sign = -1
                Done = False
            Else
                'both signs positive, subtract operand 2 from 1
                Sign = 1
                Done = False
            End If
        End If
    End If
    
    If Not Done Then
        'take base and sign from first operand
        Base = Op1.lBase
        
        'if bases aren't the same, convert Op2 to base of Op1
        If Op1.lBase <> Op2.lBase Then
            bigTemp.ReBase Op2, Base
        Else
            bigTemp.Assign Op2
        End If
        'debug.Print bigTemp.big2str
        
        'initialize result bigNumber variable (that called this method)
        bigInitialize Sign, 1, Base, 0
        
        'handle exponents - make them the same
        If Op1.lExponent < bigTemp.lExponent Then
            'decrement the greater exponent and left shift the associated number
            'debug.Print "Op1: " & Op1.big2str
            'debug.Print "Op2: " & Op2.big2str
            'debug.Print "bigTemp: " & bigTemp.big2str
            'debug.Print Chr(10) & Chr(13)
            bigTemp.LeftShift (bigTemp.lExponent - Op1.lExponent)
            bigTemp.lExponent = Op1.lExponent
            Exponent = Op1.lExponent
            'debug.Print "Op1: " & Op1.big2str
            'debug.Print "Op2: " & Op2.big2str
            'debug.Print "bigTemp: " & bigTemp.big2str
            'debug.Print Chr(10) & Chr(13)
        Else
            If bigTemp.lExponent < Op1.lExponent Then
                'decrement the greater exponent and left shift the associated number
                'debug.Print "Op1: " & Op1.big2str
                'debug.Print "Op2: " & Op2.big2str
                'debug.Print "bigTemp: " & bigTemp.big2str
                'debug.Print Chr(10) & Chr(13)
                Op1.LeftShift (Op1.lExponent - bigTemp.lExponent)
                Op1.lExponent = bigTemp.lExponent
                Exponent = bigTemp.lExponent
                'debug.Print "Op1: " & Op1.big2str
                'debug.Print "Op2: " & Op2.big2str
                'debug.Print "bigTemp: " & bigTemp.big2str
                'debug.Print Chr(10) & Chr(13)
            End If
        End If
        'ensure exponent gets set
        '   in case they were already the same
        '   and skipped above, which makes them the same
        Exponent = Op1.lExponent
        
        'determine the number of "digit" addition operations
        If bigTemp.SymbolCollection.Count > Op1.SymbolCollection.Count Then
            addLength = bigTemp.SymbolCollection.Count
            'pad shorter number with zeros to be sure of value
            For i = Op1.SymbolCollection.Count To bigTemp.SymbolCollection.Count - 1
                Op1.setSymbol 0, i
                'doevents
            Next i
        Else
            addLength = Op1.SymbolCollection.Count
            'pad shorter number with zeros to be sure of value
            For i = bigTemp.SymbolCollection.Count To Op1.SymbolCollection.Count - 1
                bigTemp.setSymbol 0, i
                'doevents
            Next i
        End If
        'now do the actual addition
        sameBaseAdd Op1, bigTemp
    End If  'not done
    Me.iSign = Sign
    Me.lExponent = Exponent
    
    'debug.Print Me.big2str
    Normalize
    'debug.Print Me.big2str
    Add = True
End Function

'Add two bigNumber multiple precision numbers, store result in bigNumber that
'  invoked this method
'Note: the same base add and multiply methods are necessary to enable the
'   generality of multiple base arithmetic - need to add and multiply in a
'   single base in order to convert a number from one base to another
Public Function sameBaseAdd(Operand1 As bigNumber, Operand2 As bigNumber) As Boolean
    Dim i As Long, Carry As Long, addLength As Long, Base As Long
    
    'default boolean return is false - set true if addition successful
    sameBaseAdd = False
    
    'take the base from the first operand
    Base = Operand1.lBase
    Me.lBase = Base
    
    'determine the number of "digit" addition operations
    ' this is also the length of the sum (unless a carry is necessary below)
    If Operand2.SymbolCollection.Count >= Operand1.SymbolCollection.Count Then
        addLength = Operand2.SymbolCollection.Count
    Else
        addLength = Operand1.SymbolCollection.Count
    End If
    
    'add "digit" by "digit" - don't forget to "carry"
    'debug.Print "Operand1: " & Operand1.big2str
    'debug.Print "Operand2: " & Operand2.big2str
    Carry = 0
    For i = 0 To addLength - 1
        setSymbol (Operand1.getSymbol(i) + Operand2.getSymbol(i) + Carry), i
        Carry = Int(getSymbol(i) / Base)
        setSymbol (getSymbol(i) Mod Base), i
        'debug.Print "Add Result: " & getSymbol(i) & "   carry: " & Carry
        'doevents
    Next i
    If Carry >= 1 Then
        'put the carry into a new position. note that setSymbol uses a zero-indexed
        '   symbol position, so an index of "count" is one higher than the existing
        '   highest indexed position
        setSymbol Carry, Me.SymbolCollection.Count
    End If
    sameBaseAdd = True
End Function

'Subtract one multiple precision number from another (operand2 from operand1)
'   store result in bigNumber that invoked the method
Public Function Subtract(Operand1 As bigNumber, Operand2 As bigNumber) As Boolean
    Dim i As Long, subLength As Long
    Dim Base As Long, Sign As Integer       'temp holders - protect operand
    Dim Exponent As Long                    'temp holder - protect operand
    Dim borrowFrom As Long, borrowTo As Long
    Dim bigTemp As New bigNumber
    Dim Op1 As New bigNumber, Op2 As New bigNumber  'protect operand
    
    'protect operand by assigning value to temp variables
    Op1.Assign Operand1
    Op2.Assign Operand2
    
    'default boolean return is false - set true if subtraction successful
    Subtract = False
    
    'Check signs and use "add" if necessary
    'check base
    'check exponent
    'adjust lengths by padding with zeros as necessary
    'perform operation symbol by symbol
    
    'check signs
    If Op1.iSign = 1 And Op2.iSign = -1 Then
        Op2.iSign = 1
        Add Op1, Op2
        Sign = 1
        Done = True
    Else
        If Op1.iSign = -1 And Op2.iSign = 1 Then
            Op1.iSign = 1
            Add Op1, Op2
            Sign = -1
            Done = True
        Else
            If Op1.iSign = -1 And Op2.iSign = -1 Then
                'swap operands to subtract value of 1 from value of 2
                bigTemp.Assign Op2
                Op2.Assign Op1
                Op1.Assign bigTemp
                Op1.iSign = 1
                Op2.iSign = 1
                'negate sign and let magnitude of the two figure out what the sign should be
                Sign = -1
                Done = False
            Else
                'both signs positive, subtract operand 2 from 1
                'start with sign positive and let mag of two figure out what sign should be
                Sign = 1
                Done = False
            End If
        End If
    End If
    
    If Not Done Then
        'take base and sign from first operand
        Base = Op1.lBase
        
        'if bases aren't the same, convert Op2 to base of Op1
        If Op1.lBase <> Op2.lBase Then
            bigTemp.ReBase Op2, Base
        Else
            bigTemp.Assign Op2
        End If
        'Debug.Print "bigTemp: " & bigTemp.big2str
        'Debug.Print "Op2: " & Op2.big2str
        'Debug.Print "Op1: " & Op1.big2str
    
        'compare magnitude of operands and adjust sign
        '   if sign is "-1" then we already swapped and negated once.
        If Sign > 0 And bigTemp.GreaterThan(Op1) Then
            'Case "+,+" with second operand bigger - swap with first and negate sign
            Op2.Assign bigTemp
            bigTemp.Assign Op1
            Op1.Assign Op2
            Sign = -1 * Sign
        Else
            If Sign > 0 And Not bigTemp.GreaterThan(Op1) Then
                'Case "+,+" with second operand smaller - leave it all alone
            Else
                If Sign < 0 And bigTemp.GreaterThan(Op1) Then
                    'Case "-,-" with second operand bigger
                    '   - swap again with first (unswap), already negated sign
                    Op2.Assign bigTemp
                    bigTemp.Assign Op1
                    Op1.Assign Op2
                    Sign = 1 * Sign
                Else
                    If Sign < 0 And Not bigTemp.GreaterThan(Op1) Then
                        'Case "-,-" with second operand smaller
                        '   - swapped already, negated sign again (un-negate)
                        Sign = -1 * Sign
                    Else
                        'Error case
                    End If
                End If
            End If
        End If
        
        'initialize result bigNumber variable (that called this method)
        bigInitialize Sign, 0, Base
        
        'handle exponents - make them the same
        If Op1.lExponent < bigTemp.lExponent Then
            'decrement the greater exponent and left shift the associated number
            'Debug.Print "Op1: " & Op1.big2str
            'Debug.Print "Op2: " & Op2.big2str
            'Debug.Print "bigTemp: " & bigTemp.big2str
            'Debug.Print Chr(10) & Chr(13)
            bigTemp.LeftShift (bigTemp.lExponent - Op1.lExponent)
            bigTemp.lExponent = Op1.lExponent
            Exponent = Op1.lExponent
            'Debug.Print "Op1: " & Op1.big2str
            'Debug.Print "Op2: " & Op2.big2str
            'Debug.Print "bigTemp: " & bigTemp.big2str
            'Debug.Print Chr(10) & Chr(13)
        Else
            If bigTemp.lExponent < Op1.lExponent Then
                'decrement the greater exponent and left shift the associated number
                'Debug.Print "Op1: " & Op1.big2str
                'Debug.Print "Op2: " & Op2.big2str
                'Debug.Print "bigTemp: " & bigTemp.big2str
                'Debug.Print Chr(10) & Chr(13)
                Op1.LeftShift (Op1.lExponent - bigTemp.lExponent)
                Op1.lExponent = bigTemp.lExponent
                Exponent = bigTemp.lExponent
                'Debug.Print "Op1: " & Op1.big2str
                'Debug.Print "Op2: " & Op2.big2str
                'Debug.Print "bigTemp: " & bigTemp.big2str
                'Debug.Print Chr(10) & Chr(13)
            End If
        End If
        'ensure exponent gets set
        '   in case they were already the same
        '   and skipped above, which makes them the same
        Exponent = Op1.lExponent
        
        'Debug.Print "bigTemp: " & bigTemp.big2str
        'Debug.Print "Op1: " & Op1.big2str
        
        'determine the number of "digit" addition operations
        If bigTemp.SymbolCollection.Count > Op1.SymbolCollection.Count Then
            subLength = bigTemp.SymbolCollection.Count
            'pad shorter number with zeros to be sure of value
            For i = Op1.SymbolCollection.Count To bigTemp.SymbolCollection.Count - 1
                Op1.setSymbol 0, i
                'doevents
            Next i
        Else
            subLength = Op1.SymbolCollection.Count
            'pad shorter number with zeros to be sure of value
            For i = bigTemp.SymbolCollection.Count To Op1.SymbolCollection.Count - 1
                bigTemp.setSymbol 0, i
                'doevents
            Next i
        End If
        'Debug.Print "bigTemp: " & bigTemp.big2str
        'Debug.Print "Op1: " & Op1.big2str
        
        'subtract symbol by symbol - don't forget to "borrow"
        borrowFrom = 0
        borrowTo = 0
        For i = 0 To subLength - 1
            borrowFrom = borrowTo
            borrowTo = 0
            If bigTemp.getSymbol(i) > (Op1.getSymbol(i) - borrowFrom) Then
                'borrow but don't actually change the number or operand
                borrowTo = 1
            End If
            setSymbol ((Op1.getSymbol(i) - borrowFrom + (borrowTo * Base)) - bigTemp.getSymbol(i)), i
            'doevents
        Next i
        'trim leading zeros and adjust length
        LeftTrim
    End If ' not done
    If Sign <> Me.iSign Then
        Me.iSign = Sign * Me.iSign
    End If
    Me.lExponent = Exponent
    Normalize
    'debug.Print "Op1: " & Op1.big2str
    'debug.Print "Op2: " & Op2.big2str
    'debug.Print "Me: " & big2str()
    
    Subtract = True
    
End Function

'convert base of operand to the new base
'   store result in public bigNumber object rebaseResult
'   (which must be declared in the code using the big number object module)
Public Function ReBase(Operand As bigNumber, newBase As Long, Optional Precision As Long) As Boolean
    Dim Result As New bigNumber     'temporary result variable
    Dim bigPart As New bigNumber    'temporary partial result variable
    Dim basePart As New bigNumber   'temp for handling of exponent
    Dim expPart As New bigNumber   'temp for handling of exponent
    Dim bigZero As New bigNumber
    Dim bigTemp As New bigNumber
    Dim n As Long 'loop counter
    Dim oldBase As Long
    Dim neuBase As Long     'hold to protect argument
    Dim Sign As Integer     'hold to protect operand
    Dim Exponent As Long    'hold exponent, to keep from changing operand
    
    'default boolean return is false - set true if rebase successful
    ReBase = False
    neuBase = newBase
    Me.lBase = neuBase
    Sign = Operand.iSign
    oldBase = Operand.lBase
    Exponent = Operand.lExponent
    
    bigZero.bigInitialize 1, 1, newBase, 0
    
    'Handle exponent of operand - convert number to a zero exponent
    bigPart.bigInitialize 1, 1, oldBase, 0
    expPart.bigInitialize 1, 1, newBase, 0
    basePart.bigInitialize 1, 1, newBase, 0
    
    'Debug.Print "Operand: " & Operand.big2str
    'Debug.Print "newBase: " & newBase
    'Debug.Print "Precision: " & Precision
    If Exponent <> 0 Then
        'positive exponent - integer, negative exponent - floating point
        '  handle by understanding that in any base the value of the base is "10"
        '  so raise the bigNumber "10" to the (absolute value of Exponent) power and
        '  convert to the new basethen either multiply or divide by the result
        '  depending on the sign of the exponent
        bigPart.setSymbol 1, 0
        'Debug.Print "bigPart pre exponent: " & bigPart.big2str
        'raise the base to the Abs(exponent) power Note that base = "10" in any base
        '   and base^abs(exponent) = pad right with abs(exponent)-1 zeros
        '   (actually by padding "1" with abs(exponent) zeros
        '   Note: cannot just left shift the oldbase bignumber because that only works for
        '   positive exponents - and we cannot right shift for negative exponents
        '   without losing significant symbols.  So this procedure sets us up to multiply or
        '   divide by the base^abs(exponent) value depending on sign of exponent
        bigPart.LeftShift Abs(Exponent)
        expPart.Assign bigPart
        'Debug.Print "expPart post exponent: " & expPart.big2str
        
        'initialize bigNumber Result variable
        Result.bigInitialize Sign, 1, neuBase, 0
        
        'basePart.ReBase expPart, neuBase
        'instead of recursion to rebase, use l2bigrebase to calculate the value of
        '  base to abs(exponent) in the new base, then either multiply or divide
        '  depending on sign of exponent
        For n = 0 To expPart.SymbolCollection.Count - 1
            'convert this symbol, for old base, of order n, to newbase
            
            'initialize bigNumber variable
            bigPart.bigInitialize Sign, 0, neuBase, 0
            oldBase = Operand.lBase
            'store long to big rebase(value, place, oldBase) in l2bigReBaseResult
            bigPart.l2bigReBase expPart.getSymbol(n), n, oldBase
            'Debug.Print "Partial basePart for symbol(" & n & "): " & bigPart.big2str
            'accumulate result
            basePart.Add Result, bigPart
            'Debug.Print "Cumulative basePart for symbol(" & n & "): " & basePart.big2str
            'doevents
        Next n
        'Debug.Print "basePart post l2bigRebase: " & basePart.big2str
        'keep this value for use at end to adjust conversion of bignumber
    Else
        'if exponent = zero - no action required
    End If
    
    'initialize bigNumber Result variable
    Result.bigInitialize Sign, 1, neuBase, 0
    bigTemp.bigInitialize Sign, 1, neuBase, 0
    
    'Algorithm: convert each symbol and accumulate it in a new number
    '   of new base by addition; must use the special sameBaseAdd method
    
    'Algorithm: convert each symbol to the new base
    'convert the corresponding base^exp to the new base
    'multiply by polynomial expansion to get symbols for
    '  the partial sum and add these to accumulate the result
    'Example: 678 base 10 = (6*10^0 + 7*10^1 + 8*10^2)
    '   convert each symbol to base 5 partial sum bigNumbers:
    '     8*10^0 = (1*5^1 + 3*5^0)*10^0   =   (1*5^1 + 3*5^0)*(1*5^0)
    '     Partial Sum 0:                  =   (1*5^1 + 3*5^0)
    '     7*10^1 = (1*5^1 + 2*5^0)*10^1   =   (1*5^1 + 2*5^0)*(2*5^1 + 0*5^0)
    '                                     =   (2*5^2 + 4*5^1 + 0*5^1 + 0*5^0)
    '     Partial Sum 1:                  =   (2*5^2 + 4*5^1 + 0*5^0)
    '     6*10^2 = (1*5^1 + 1*5^0)*10^2   =   (1*5^1 + 1*5^0)*(4*5^2 + 0*5^1 + 0*5^0)
    '                                     =   (4*5^3 + 4*5^2 + 0*5^2 + 0*5^1 + 0*5^1 + 0*5^0)
    '     Partial Sum 2:                  =   (4*5^3 + 4*5^2 + 0*5^1 + 0*5^0)
    '   So, sum of partial sums:          =   (4*5^3 + 6*5^2 + 5*5^1)
    '   but three of these symbols exceed the base (5), so propagate a "carry"
    '       sum of partial sums:          =   (4*5^3 + 7*5^2 + 0*5^1 + 3*5^0)
    '       sum of partial sums:          =   (5*5^3 + 2*5^2 + 0*5^1 + 3*5^0)
    '       sum of partial sums:          =   (1*5^4 + 0*5^3 + 2*5^2 + 0*5^1 + 3*5^0)
    '   Thus 678(base 10) = 10203(base 5)
    For n = 0 To Operand.SymbolCollection.Count - 1
        'convert this symbol, for old base, of order n, to newbase
        
        'initialize bigNumber variable
        bigPart.bigInitialize Sign, 1, neuBase, 0
        oldBase = Operand.lBase
        'store long to big rebase(value, place, oldBase) in l2bigReBaseResult
        bigPart.l2bigReBase Operand.getSymbol(n), n, oldBase
        'Debug.Print "Partial result for symbol(" & n & "): " & bigPart.big2str
        'accumulate result
        bigTemp.Add Result, bigPart
        Result.Assign bigTemp
        'Debug.Print "Cumulative result for symbol(" & n & "): " & Result.big2str
        'doevents
    Next n
    'adjust for non-zero exponent by multiplying or dividing by base part
    'store result in bigNumber invoking the method
    If Not basePart.Equals(bigZero) Then
        If Exponent > 0 Then
            Multiply Result, basePart
        Else
            If Exponent < 0 Then
                Divide Result, basePart, Precision
            End If
        End If
    Else
        Assign Result
    End If
    'Debug.Print "Result: " & Result.big2str, "basePart: " & basePart.big2str, "Assigned: " & big2str()
    ReBase = True
End Function

'Reset a bigNumber to zero value //*** this procedure no longer used ***//
Public Function Zero() As Boolean
    Dim i As Long       'loop counter
    Me.iSign = 1
    Me.lExponent = 0
    Me.lBase = 0
    For i = 0 To Me.SymbolCollection.Count - 1
        setSymbol 0, i
        'doevents
    Next i
End Function

'Assign the value of Operand to bigNumber
Public Function Assign(Operand As bigNumber) As Boolean
    Dim i As Long       'loop counter
    Dim Sign As Integer, Exponent As Long, Base As Long, Length As Long
    
    Sign = Operand.iSign
    Exponent = Operand.lExponent
    Base = Operand.lBase
    Length = Operand.SymbolCollection.Count
    
    Me.bigInitialize Sign, Length, Base, Exponent
    For i = 0 To Length - 1
        If i > Me.SymbolCollection.Count Then
            'add a new symbol position for this value
            Me.SymbolCollection.Add Operand.getSymbol(i)
        End If
        setSymbol Operand.getSymbol(i), i
        'doevents
    Next i
End Function

'Normalize a bigNumber by removing extraneous zeros and adjusting exponent
'   iFormat indicates:
'     0 or Null - minimize number of symbols used by increasing exponent to get rid of zeros
'     1 - disallow positive exponent, increase zero symbols
Public Function Normalize(Optional iFormat As Integer) As Boolean
    Dim i As Long, Exponent As Long, zeroFlag As Boolean
    
    'save properties of number invoking the method
    Exponent = Me.lExponent
    
    'trim "leading" zeros
    LeftTrim
    
    Select Case iFormat
        Case 0
            'look for and remove "trailing" zeros, and adjust exponent
            '   be careful using this parameter of the method with precision
            '   floating point procedures - a trailing zero is still a significant figure
            Do While getSymbol(0) = 0 And Me.SymbolCollection.Count > 1
                RightShift 1
                Me.lExponent = Me.lExponent + 1
            Loop
            
            'if the number is zero, set exponent to zero and sign to 1 (pos)
            '   note, ops above will reduce such a number to one symbol
            If getSymbol(0) = 0 Then
                Me.lExponent = 0
                Me.iSign = 1
            End If
        Case 1
            'For positive exponent:
            '   shift left to incorporate the value of the exponent
            '   make the exponent zero, and use least significant zeros instead
            'For negative exponent:
            '   right shift to eliminate trailing zeros and adjust the exponent
            '   (only adjusts exponent as far as trailing zeros allow,
            '    and only until exponent reaches zero - does not create positive exponent)
            
            'determine if number is equivalent to zero
            zeroFlag = True
            For i = 0 To Me.SymbolCollection.Count - 1
                If getSymbol(i) <> 0 Then
                    zeroFlag = False
                End If
            Next i
            'if the number is equivalent to zero, make it equal to zero
            If zeroFlag Then
                Me.iSign = 1
                Me.lExponent = 0
            Else
                If Exponent > 0 Then
                    'if not zero, then adjust the number
                    '   (recall from If above, we only do this for positive exponents)
                    Do Until Me.lExponent = 0
                        LeftShift 1
                        Me.lExponent = Me.lExponent - 1
                    Loop
                Else
                    If Exponent < 0 Then
                        '   right shift to eliminate trailing zeros and adjust the exponent
                        '   (only adjusts exponent as far as trailing zeros allow,
                        '    and only until exponent reaches zero - does not create positive exponent)
                        Do Until Me.getSymbol(0) <> 0 Or Me.lExponent = 0
                            Me.RightShift 1
                            Me.lExponent = Me.lExponent + 1
                        Loop
                    End If
                End If
            End If
    End Select
End Function

'shift the symbols of bigNumber to the left by "clicks" positions
'  Note this ammounts to multiplying bigNumber by its base
Public Function LeftShift(clicks As Long) As Boolean
    Dim i As Long   'loop counter
    
    LeftShift = False
    
    'shift "clicks" symbol positions, note that setSymbol will add symbol positions if needed
    If clicks > 0 Then
        i = Me.SymbolCollection.Count - 1
        Do While i >= 0
            setSymbol getSymbol(i), i + clicks
            i = i - 1
            'doevents
        Loop
        'pad the right with zeros
        i = clicks - 1
        Do While i >= 0
            setSymbol 0, i
            i = i - 1
            'doevents
        Loop
    End If
    'debug.Print "Shifted number: " & big2str()
    LeftShift = True
End Function
'shift the symbols of bigNumber to the right by "clicks" positions
'  Note this ammounts to dividing bigNumber by its base
'  Assumes exponent of floating point numbers will be adjusted externally
Public Function RightShift(clicks As Long) As Boolean
    Dim i As Long   'loop counter
    
    RightShift = False
    If clicks > 0 Then
        i = 0
        Do While i <= Me.SymbolCollection.Count - 1
            'just drop digits shifted out of range to the right
            If i - clicks >= 0 Then
                setSymbol getSymbol(i), i - clicks
            End If
            i = i + 1
            'doevents
        Loop
        
        'remove unused symbol positions
        For i = 1 To clicks
            'remove the highest indexed symbol position (no longer used)
            Me.SymbolCollection.Remove (Me.SymbolCollection.Count)
        Next i
    End If
    'Debug.Print "Shifted number: " & big2str()
    RightShift = True
End Function

'convert long integer x to base of the number using the method
'   and return in the bigNumber that calls the method
'   Used by ReBase(operand as bigNumber, NewBase as Long)
'   to convert one symbol of the operand
'   Therefor assumes that x is a single place symbol in the old base - passed
'    as the oldBase variable.
Public Function l2bigReBase(x As Long, place As Long, oldBase As Long) As Boolean
    Dim Exponent As Long, d As Long, quantity As Long
    Dim n As Long   'loop counter
    Dim bigPoly1 As New bigNumber, bigPoly2 As New bigNumber
    Dim bigTemp As New bigNumber
    Dim newBase As Long     'hold to protect argument
    Dim oleBase As Long     'hold to protect argument
    Dim Sign As Integer     'hold to protect operand
    'default return false, true if successful
    l2bigReBase = False
    
    'assign base and sign from bigNumber invoking method
    newBase = Me.lBase
    oleBase = oldBase
    Sign = Me.iSign
    
    'initialize big number variables
    bigPoly1.bigInitialize Sign, 0, newBase
    bigPoly2.bigInitialize Sign, 0, newBase
    
    'Algorithm:
    '  convert the symbol x
    '  convert the old base oldBase to bigNum
    '  raise converted oldBase to order (place)
    '  multiply converted x and oldBase

    'convert the symbol x, store result in bigPoly1
    If x = 0 Then
        bigPoly1.setSymbol 0, 0
    Else
        bigPoly1.lPart2bigReBase x
    End If
    'Debug.Print "bigPoly1: " & bigPoly1.big2str
    '  convert the old base, store in bigPoly2
    bigPoly2.lPart2bigReBase oleBase
    'Debug.Print "bigPoly2: " & bigPoly2.big2str
   
    '  raise converted oldBase to order (place)
    bigTemp.bigExponent bigPoly2, place
    'Debug.Print "bigPoly2 ^ " & place & " = " & bigTemp.big2str
    '  multiply converted x and oldBase, store result in number invoking this method
    Multiply bigPoly1, bigTemp
    'Debug.Print "bigPoly1 * bigPoly2^Place = " & big2str()
    
    l2bigReBase = True
End Function

'Multiply two bigNumbers by polynomial expansion and store result in bigNumber
'  that invoked this method
'Note: the same base add and multiply methods are necessary to enable the
'   generality of multiple base arithmetic - need to add and multiply in a
'   single base in order to convert a number from one base to another
Public Function sameBaseMultiply(Operand1 As bigNumber, Operand2 As bigNumber) As Boolean
    Dim i As Long, j As Long, k As Long         'loop counters
    Dim bigPart As New bigNumber, Result As New bigNumber
    Dim Base As Long
    
    'default boolean return is false - set true if successful
    sameBaseMultiply = False
    
    'take base from the first operand
    Base = Operand1.lBase
    Me.lBase = Base
    
    'initialize temporary result variable
    Result.bigInitialize 1, 1, Base, 0
    
    'debug.Print "Multiply: " & Operand1.big2str & " x " & Operand2.big2str
    
    For i = 0 To Operand1.SymbolCollection.Count - 1
        For j = 0 To Operand2.SymbolCollection.Count - 1
            'initialize partial result bigNumber variable
            bigPart.bigInitialize 1, 1, Base, 0
            'multiply the i,j term, note exp (place) for this term
            '  is (i + j) since b^i * b^j = b^(i+j)
            '  so we'll left shift that far after carrying
            '   * part -> symbol mod base
            '     carry -> int(symbol/base)
            '->Part
            'debug.Print "bigpart: " & bigPart.big2str
            bigPart.setSymbol _
                (Operand1.getSymbol(i) * Operand2.getSymbol(j)), 0
            'adjust part to base, and carry to more significant position(s) as necessary
            k = 0
            Do While Int(bigPart.getSymbol(k) / Base) > 0
                'look at symbol in part position k, if bigger than base,
                '   then spill over into the next higher position (k+1)
                '   and put remainder in position k
                '   (must do in this order or you reset the
                '    number you need for 2nd operation)
                bigPart.setSymbol Int(bigPart.getSymbol(k) / Base), k + 1
                bigPart.setSymbol bigPart.getSymbol(k) Mod Base, k
                k = k + 1
                'doevents
            Loop
            'shift left according to the position (exp) of number and operand
            '   (recall in these operations, the *b^exp is implied, the calculation
            '    determines the value of the symbol, and b^exp = b^i*b^j = b^(i+j)
            
            bigPart.LeftShift (i + j)
            'add this partial result to accumulate the result
            '   in the bigNumber that invoked this method
            'debug.Print "Part(" & i & "," & j & "): " & bigPart.big2str
            'debug.Print "Old Result: " & Result.big2str
            Result.sameBaseAdd Result, bigPart
            'debug.Print "Part(" & i & "," & j & "): " & bigPart.big2str
            'debug.Print "Mult Result: " & Result.big2str
            'doevents
        Next j
        'doevents
    Next i
    'trim any leading zeros and adjust length - recall most significant symbol is at
    '   symbolcollection.Count -1 since the least significant is at order zero
    Result.LeftTrim
    'Transfer the Result to bigNumber invoking method
    Assign Result
    
    sameBaseMultiply = True
End Function

'Trim leading zeros of bigNumber
Public Function LeftTrim() As Boolean
    Dim i As Long   'loop counter
    
    'default return false, return true if successful
    LeftTrim = False
    
    'trim any leading zeros - recall most significant symbol is at
    '   symbolcollection.Count -1 since the least significant is at order zero
    i = Me.SymbolCollection.Count - 1
    Do While getSymbol(i) = 0 And i > 0
        'remove the highest indexed symbol
        Me.SymbolCollection.Remove (Me.SymbolCollection.Count)
        i = i - 1
        'doevents
    Loop
    LeftTrim = True

End Function

'Initialize a bigNumber with provided values
Public Function bigInitialize(Sign As Integer, Length As Long, Base As Long, Optional Exponent As Long) As Boolean
    Dim i As Long   'loop counter for symbol position
    'default return false, true if successful
    bigInitialize = False
    
    'remove all symbols
    Do While Me.SymbolCollection.Count > 0
        'remove highest indexed symbol position
        Me.SymbolCollection.Remove (Me.SymbolCollection.Count)
    Loop
    
    'add the specified number of symbol positions with symbol value zero (0)
    For i = 0 To Length - 1
        Me.SymbolCollection.Add 0
    Next i
    
    Me.iSign = Sign
    Me.lBase = Base
    If Not IsNull(Exponent) Then
        Me.lExponent = Exponent
    End If
    
    bigInitialize = True
End Function

'convert long value to bigNumber, rebased
'stores result of conversion in the big number calling the method
Public Function lPart2bigReBase(x As Long) As Boolean
    Dim Exponent As Long
    Dim d As Long   'counter for symbol value
    Dim n As Long   'loop counter
    Dim Sign As Integer, newBase As Long     'temp to protect arguments
    Dim quantity As Long    'protect arguments
    
    quantity = x
    newBase = Me.lBase
    Sign = Me.iSign
    
    'initialize number invoking method
    bigInitialize Sign, 0, newBase
        
    Exponent = 0
    Do While newBase ^ Exponent <= quantity
        Exponent = Exponent + 1
        'doevents
    Loop
    'save value of exponent as the number of symbols required
    '  note that previous loop overshoots the highest exponent value
    '  by one -> that is the number of symbols, length of string
    '  (least significant is at the exponent zero position)
    Exponent = Exponent - 1     'correct for loop overshoot
    
    'determine the value of each symbol
    Do While Exponent >= 0
        'start with highest exponent, and fit as large a value
        '   of the symbol for that exp as possible
        d = 1
        Do While d * newBase ^ Exponent <= quantity And d < newBase
            d = d + 1
            'doevents
        Loop
        d = d - 1
        'symbol(exponent) = d
        setSymbol d, Exponent
        'subtract the order(exponent) quantity out
        '   and work on less significant symbols
        quantity = quantity - d * newBase ^ Exponent
        Exponent = Exponent - 1
        'doevents
    Loop
    'Debug.Print "Symbol: (" & x & ") in base: (" & newBase & ") = " & big2str()
    
End Function

'raise operand to exponent and store result in number calling method
Public Function bigExponent(Operand As bigNumber, Exponent As Long) As Boolean
    Dim bigPart As New bigNumber
    Dim bigTemp As New bigNumber    'temp to protect operand
    Dim Result As New bigNumber     'temp bigNumber result variable
    Dim Base As Long                'temp to protect operand

    'default return false, true if successful
    bigExponent = False
    
    bigTemp.Assign Operand
    
    If Exponent = 0 Then
        'anything to the zero = 1
        setSymbol 1, 0
        Me.iSign = Operand.iSign
        Me.lBase = Operand.lBase
        Me.lExponent = 0
    Else
        Result.Assign bigTemp
        'Debug.Print "Exponent Result progress ^1 :" & Result.big2str()
        'Debug.Print "Exponent Operand progress ^1 :" & Result.big2str()
        For i = 1 To Exponent - 1
            bigPart.Multiply Result, bigTemp
            Result.Assign bigPart
            'Debug.Print "Exponent progress ^" & i + 1 & " :" & Result.big2str
            'doevents
        Next i
        Assign Result
    End If
     'Debug.Print "Operand: ( " & Operand.big2str & " ) ^ " & Exponent & " = " & big2str()
    bigExponent = True
End Function

'raise operand to exponent and store result in number calling method
Public Function bigModExponent(Operand As bigNumber, Exponent As Long, Modulus As bigNumber) As Boolean
    Dim bigPart As New bigNumber
    Dim bigTemp As New bigNumber    'temp to protect operand
    Dim Result As New bigNumber     'temp bigNumber result variable
    Dim Base As Long                'temp to protect operand

    'default return false, true if successful
    bigModExponent = False
    
    bigTemp.Assign Operand
    
    If Exponent = 0 Then
        'anything to the zero = 1
        setSymbol 1, 0
        Me.iSign = Operand.iSign
        Me.lBase = Operand.lBase
        Me.lExponent = 0
    Else
        Result.Assign bigTemp
        'Debug.Print "Exponent Result progress ^1 :" & Result.big2str()
        'Debug.Print "Exponent Operand progress ^1 :" & Result.big2str()
        For i = 1 To Exponent - 1
            bigPart.Multiply Result, bigTemp
            Result.bigMod bigPart, Modulus
            'Debug.Print "Exponent progress ^" & i + 1 & " :" & Result.big2str
            'doevents
        Next i
        Assign Result
    End If
     'Debug.Print "Operand: ( " & Operand.big2str & " ) ^ " & Exponent & " = " & big2str()
    bigModExponent = True
End Function

