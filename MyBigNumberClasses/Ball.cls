VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Ball"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Description = "ball used to play - bounces for elastic collisions with walls or paddles"
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"

Public x As Double
'horizontal location in mathematical coordinate system

Public y As Double
'horizontal location in mathematical coordinate system

Public PixelX As Integer
'horizontal location in pixel coordinate system

Public PixelY As Integer
'horizontal location in pixel coordinate system

Public vx As Double
'horizontal component of velocity in mathematical coordinate system

Public vy As Double
Attribute vy.VB_VarDescription = "vertical component of instantaneous velocity"
'horizontal component of velocity in mathematical coordinate system

Public speed As Double
'speed in pixel coordinate system - used to calculate velocity in mathematical coord system

Public extent As Double
Attribute extent.VB_VarDescription = "radius of ball"
'physical radius of ball

Public PixelExtent As Long
'pixel radius of ball

Public color As Long
'color of ball


Public Sub Initialize()
Dim pic As PictureBox
Set pic = frmDrawingFrame.Picture1

extent = BallSize
speed = BallSpeed

'pick random initial position
Randomize
x = Rnd * frameWidth
y = Rnd * frameHeight

'randomize initial velocity
Call setRandomVelocity

'convert mathematical position of ball to pixel location
'   results are returned in coordinates(0,1)
Call PointToPixel

'convert extent to pixels
PixelExtent = ExtentToPixels(extent)

color = Int(Rnd * White)

'Paint "ball"
pic.DrawWidth = PixelExtent
pic.PSet (PixelX, PixelY), color

End Sub

Public Sub move()
    Dim pic As PictureBox
    Dim paddle1 As Paddle
    Dim paddle2 As Paddle
    Dim i As Integer
    
    Set paddle1 = leftPaddle
    Set paddle2 = rightPaddle
    Set pic = frmDrawingFrame.Picture1

    'convert mathematical position of ball to pixel location
    '   results are returned in coordinates(0,1)
    Call PointToPixel
    
    'convert extent to pixels
    PixelExtent = ExtentToPixels(extent)
    
    'black out old ball location
    pic.DrawWidth = PixelExtent
    pic.PSet (PixelX, PixelY), Black

    'calculate ball's next position based on position and velocity
    x = x + vx
    y = y + vy

    'convert mathematical position of ball to pixel location
    '   results are returned in coordinates(0,1)
    Call PointToPixel
    
    'draw ball at new location
    pic.DrawWidth = PixelExtent
    pic.PSet (PixelX, PixelY), color
    
    'if the ball hit a wall, calculate the reflection
    If PixelX + PixelExtent >= pic.ScaleWidth Then
        'Hit right wall - reflect x and increment player 1 score
        vx = -1 * vx
        frmDrawingFrame.xPos = frmDrawingFrame.yPos + 1
            End If
    If PixelY + PixelExtent >= pic.ScaleHeight Then vy = -1 * vy
    If PixelX - PixelExtent <= 0 Then
        'Hit left wall - reflect y and increment player 2 score
        vx = -1 * vx
        frmDrawingFrame.yPos = frmDrawingFrame.yPos + 1

    End If
    If PixelY - PixelExtent <= 1 Then vy = -1 * vy
    
    'if the ball hit another ball, calculate reflection
    For i = 1 To balls.Count
        'if this ball is within "extent" distance, collide
        If distance(balls.Item(i).x, balls.Item(i).y) < Precision Then
            'assume only THIS ball could be at its own location
            ' so do nothing
        Else
            If distance(balls.Item(i).x, balls.Item(i).y) <= 2 * extent Then
                'collide with mass m = 1 for both balls
                Call collideElastic(i)
                Beep
            End If
        End If
    
    Next i
   
    'if the ball hit a paddle, calculate the reflection
    If (PixelX - PixelExtent = paddle1.rightWall + 1 And _
        PixelY + PixelExtent <= paddle1.topWall _
        And PixelY - PixelExtent >= paddle1.bottomWall) _
        Or _
        (PixelX - PixelExtent = paddle2.rightWall + 1 And _
        PixelY + PixelExtent <= paddle2.topWall And _
        PixelY - PixelExtent >= paddle2.bottomWall) _
        Or _
        (PixelX + PixelExtent = paddle1.leftWall - 1 And _
        PixelY - PixelExtent <= paddle1.topWall And _
        PixelY + PixelExtent >= paddle1.bottomWall) _
        Or _
        (PixelX + PixelExtent = paddle2.leftWall - 1 And _
        PixelY - PixelExtent <= paddle2.topWall And _
        PixelY + PixelExtent >= paddle2.bottomWall) _
        Then
        'collision with a vertical paddle wall (reflect horizontal)
        vx = -1 * vx
        Beep
    End If
    If (PixelY - PixelExtent = paddle1.topWall + 1 And _
        PixelX - PixelExtent <= paddle1.rightWall And _
        PixelX + PixelExtent >= paddle1.leftWall) _
        Or _
        (PixelY - PixelExtent = paddle2.topWall + 1 And _
        PixelX - PixelExtent <= paddle2.rightWall And _
        PixelX + PixelExtent >= paddle2.leftWall) _
        Or _
        (PixelY + PixelExtent = paddle1.bottomWall - 1 And _
        PixelX - PixelExtent <= paddle1.rightWall And _
        PixelX + PixelExtent >= paddle1.leftWall) _
        Or _
        (PixelY + PixelExtent = paddle2.bottomWall - 1 And _
        PixelX - PixelExtent <= paddle2.rightWall And _
        PixelX + PixelExtent >= paddle2.leftWall) _
        Then
        'collision with a horizontal paddle wall (reflect vertical)
        vy = -1 * vy
        Beep
    End If
    paddle1.color = White
    paddle1.draw
    paddle2.color = White
    paddle2.draw
    
End Sub
Public Sub setRandomVelocity()
Dim hScaleFactor As Double, vScaleFactor As Double
Dim quadrant As Integer
Dim pic As PictureBox

Set pic = frmDrawingFrame.Picture1

hScaleFactor = frameWidth / pic.ScaleWidth
vScaleFactor = frameHeight / pic.ScaleHeight

vx = Rnd * speed * hScaleFactor
vy = Rnd * speed * vScaleFactor
'Note: above produces first quadrant velocities only, so randomize
Randomize
quadrant = 1 + Int(Rnd * 3)
Select Case quadrant
Case 1
    'do nothing else
Case 2
    'negate horizontal component
    vx = -1 * vx
Case 3
    'negate both components
    vx = -1 * vx
    vy = -1 * vy
Case 4
    'negate vertical component
    vy = -1 * vy
End Select
End Sub
Public Sub PointToPixel()
Dim hScaleFactor As Double, vScaleFactor As Double
Dim pic As PictureBox

Set pic = frmDrawingFrame.Picture1

'set coordinates(0,1) to converted values of x and y (invert y)
PixelX = Int(x * pic.ScaleWidth / frameWidth)
PixelY = Int(pic.ScaleHeight - y * pic.ScaleHeight / frameHeight)
End Sub

Public Function distance(x2 As Double, y2 As Double) As Double
    distance = Sqr((x - x2) ^ 2 + (y - y2) ^ 2)
End Function

Public Sub collideElastic(i As Integer)
    Dim crtV1 As New CartesianCoordinate, crtV2 As New CartesianCoordinate
    Dim plrV1 As New PolarCoordinate, plrV2 As New PolarCoordinate
    Dim Gamma As Double
    'i is the index of other ball involved in collision
    '   in the balls collection
    '   Collision is perfectly elastic
    '   Mass of every ball = 1 (simplifies calculation
    '   of conservation of momentum and energy)
    '   Balls reflect with angle of reflection equal
    '   to angle of incedence to the tangent to their
    '   point of contact (a line tangent to both balls
    '   thru the point of contact; also perpendicular to
    '   the line between the two balls, which makes angle
    '   gamma with the horizontal
    crtV1.x = vx
    crtV1.y = vy
    crtV2.x = balls.Item(i).vx
    crtV2.y = balls.Item(i).vy
    crtV1.CartesianToPolar
    crtV2.CartesianToPolar
    
    plrV1.r = crtV1.r
    plrV1.theta = crtV1.theta
    plrV2.r = crtV2.r
    plrV2.theta = crtV2.theta
    
    'determine angle Gamma made by line between two balls,
    '   at instant of contact, with the horizontal
    Gamma = Atn(Abs(y - balls.Item(i).y) / Abs(x - balls.Item(i).x))
    'correct for quadrant, since Atn() is only defined -Pi/2 to Pi/2
    If y - balls.Item(i).y < 0 And x - balls.Item(i).x < 0 Then
        'quadrant 1 - no correction necessary
    Else
        If y - balls.Item(i).y < 0 And x - balls.Item(i).x >= 0 Then
            'quadrant 2
            Gamma = Pi - Gamma
        Else
            If y - balls.Item(i).y >= 0 And x - balls.Item(i).x >= 0 Then
                'quadrant 3
                Gamma = Pi + Gamma
            Else
                If y - balls.Item(i).y >= 0 And x - balls.Item(i).x < 0 Then
                    'quadrant 4
                    Gamma = (2 * Pi) - Gamma
                End If
            End If
        End If
    End If
        
    'calculate angles of reflection
    If plrV1.theta <= Pi Then
        plrV1.theta = plrV1.theta + Pi + 2 * (Gamma - plrV1.theta)
    Else    'theta > Pi
        plrV1.theta = plrV1.theta - Pi - 2 * (Gamma - plrV1.theta)
    End If
    plrV1.PolarToCartesian
    vx = plrV1.x
    vy = plrV1.y
    
    If plrV2.theta <= Pi Then
        plrV2.theta = plrV2.theta + Pi + 2 * (Gamma - plrV2.theta)
    Else    'theta > Pi
        plrV2.theta = plrV2.theta - Pi - 2 * (Gamma - plrV2.theta)
    End If
    plrV2.PolarToCartesian
    balls.Item(i).vx = plrV2.x
    balls.Item(i).vy = plrV2.y
End Sub
Public Function ExtentToPixels(d As Double) As Long
Dim pic As PictureBox
Set pic = frmDrawingFrame.Picture1
ExtentToPixels = Int(d * pic.ScaleWidth / frameWidth)

End Function
