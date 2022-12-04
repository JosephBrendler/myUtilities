VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "CartesianCoordinate"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Public x As Double

Public y As Double

Public r As Double

Public theta As Double

Public Function CartesianToPolar()

'correct for undefined point at x = 0
'If x = 0 Then x = 1.401E-45     'close to smallest positive single number

'convert to polar
'r is distance from origin to x,y
r = Sqr(x ^ 2 + y ^ 2)

'theta is defined differently in each quadrant
Select Case x
    Case Is > 0 '(x>0)
        Select Case y
            Case Is > 0     'First quadrant
                theta = Atn(Abs(y) / Abs(x))
            Case Is < 0     'Fourth quadrant
                theta = 2 * Pi - Atn(Abs(y) / Abs(x))
            Case 0
                theta = 0
        End Select 'y
    Case Is < 0 '(x<0)
        Select Case y
            Case Is > 0     'Second quadrant
                theta = Pi - Atn(Abs(y) / Abs(x))
            Case Is < 0     'Third quadrand
                theta = Pi + Atn(Abs(y) / Abs(x))
            Case 0
                theta = Pi
        End Select 'y
    Case 0      '(x=0)
        Select Case y
            Case Is > 0
                theta = Pi / 2
            Case Is < 0
                theta = -1 * Pi / 2
            Case 0
                theta = 0    'actually, this case undefined...
        End Select 'y
End Select 'x

End Function

