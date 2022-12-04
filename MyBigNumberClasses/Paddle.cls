VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Paddle"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Public hPos As Integer
Attribute hPos.VB_VarDescription = "horizontal position of center of paddle, measured in twips"

Public vPos As Integer
Attribute vPos.VB_VarDescription = "vertical position of center of paddle, measured in twips"

Public halfHeight As Integer
Attribute halfHeight.VB_VarDescription = "half height of paddle in twips, i.e. dist from center to top and bottom"

Public halfWidth As Integer
Attribute halfWidth.VB_VarDescription = "half width of paddle, i.e. dist from center of paddle to left and right"

Public leftWall As Integer

Public rightWall As Integer

Public topWall As Integer

Public bottomWall As Integer

Public color As Long

Public lineWidth As Integer

Public vStep As Integer


Public Sub Initialize(x As Integer, y As Integer)
Dim pic As PictureBox
Set pic = frmDrawingFrame.Picture1

lineWidth = 1
halfWidth = 3
halfHeight = 30
vStep = 20

hPos = x
vPos = y
leftWall = hPos - halfWidth
rightWall = hPos + halfWidth
topWall = vPos + halfHeight
bottomWall = vPos - halfHeight

pic.DrawWidth = lineWidth
pic.Line (leftWall, bottomWall)-(rightWall, topWall), White, BF

End Sub
Public Sub draw()
Attribute draw.VB_Description = "moves the paddle to location x (horizontal), y (vertical)"
Dim pic As PictureBox
Set pic = frmDrawingFrame.Picture1

pic.DrawWidth = lineWidth
pic.Line (leftWall, bottomWall)-(rightWall, topWall), color, BF

End Sub
Public Sub reWall()
'only the values of top and bottom wall change in movement
topWall = vPos + halfHeight
bottomWall = vPos - halfHeight

End Sub

