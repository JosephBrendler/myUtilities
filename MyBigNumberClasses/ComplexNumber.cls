VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "ComplexNumber"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Public Real As Double

Public Imaginary As Double

Public realSqr As Double

Public imagSqr

Public Function ComplexSquare()
'square the complex number z = z.real + i*z.imaginary
'    recall i^2 = -1
'    Derivation:
'    z^2 = (Re + i*Im)(Re + i*Im)
'    z^2 = Re^2 + Re*i*Im +i*IM*Re + (i*Im)^2
'    z^2 = Re^2 + 2*(i*Re*Im) + i^2*Im^2
'    z^2 = (Re^2 - Im^2) + i*(2*Re*Im)
realSqr = Real ^ 2 - Imaginary ^ 2
imagSqr = 2 * Real * Imaginary

End Function


