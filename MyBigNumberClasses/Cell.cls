VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Cell"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Public leftWall As Integer

Public rightWall As Integer

Public topWall As Integer

Public bottomWall As Integer

Public color As Long
Public Sub draw()
Dim pic As PictureBox
Set pic = frmDrawingFrame.Picture1

pic.Line (leftWall, bottomWall)-(rightWall, topWall), color, BF

End Sub

Public Sub Initialize()
'nothing to do, for now

End Sub


Public Sub Update()
'recolor cell as the average of all of its neighbors
End Sub

