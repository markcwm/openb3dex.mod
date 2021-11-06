' particletype.bmx

Rem
bbdoc: TParticleCandyParticleType
EndRem
Type TParticleCandyParticleType
  Field _u:Float, _v:Float  ' PARTICLE TEXTURE COORDS
  Field _spd:Float          ' SPEED
  Field _spv:Float          ' SPEED VARIATION
  Field _slo:Float		      ' SPEED SLOW DOWN FACTOR
  Field _srx:Float          ' RANDOM X-SPEED FACTOR
  Field _sry:Float          ' RANDOM X-SPEED FACTOR
  Field _srz:Float          ' RANDOM X-SPEED FACTOR
  Field _sze:Float          ' SIZE
  Field _szv:Float          ' SIZE VARIATION
  Field _szc:Float          ' SIZE CHANGE
  Field _szm:Float          ' Max. SIZE
  Field _alp:Float          ' ALPHA
  Field _alv:Float          ' ALPHA VARIATION
  Field _alc:Float          ' ALPHA CHANGE
  Field _wgt:Float          ' WEIGHT
  Field _wgv:Float          ' WEIGHT VARIATION
  Field _rom:Int            ' ROTATION MODE (0=STATIC, 1=RANDOM, 2=ALIGN To MOVEMENT)
  Field _hor:Int            ' ALIGN HORIZONTAL (0 = False, > 0 = True)
  Field _roc:Float          ' ROTATION CHANGE
  Field _ian:Float          ' EMISSION INNER RADIUS     
  Field _emr:Float          ' EMISSION OUTER RADIUS
  Field _flh:Float          ' Floor HEIGHT (To BOUNCE)
  Field _bnc:Float          ' BOUNCE FACTOR
  Field _bnm:Int            ' Max. NUMBER OF BOUNCES
  Field _pls:Float          ' PULSATION VALUE
  Field _ox1:Float, _ox2:Float     ' START X-OFFSET Min And Max
  Field _oy1:Float, _oy2:Float     ' START Y-OFFSET Min And Max
  Field _oz1:Float, _oz2:Float     ' START Z-OFFSET Min And Max
  Field _r:Int, _g:Int, _b:Int     ' xColor RGB
  Field _bv:Int             ' xColor BRIGHTNESS VARIATION
  Field _rc:Float, _gc:Float, _bc:Float   ' xColor RGB CHANGE
  Field _lft:Int            ' LIFE TIME (MilliSecs)
  Field _msh:Int            ' MESH NUMBER (0 / 1)
  Field _trl:Int            ' TRAIL PARTICLE ID
  Field _tst:Int            ' TRAIL EMISSION START TIME
  Field _tlt:Int            ' TRAIL PARTICLE LIFE TIME (MilliSecs)
  Field _ter:Float          ' TRAIL EMISSION RATE (PER SECOND)
  Field _cms:Float          ' CIRCULAR MOVEMENT SPEED
  Field _esh:Int            ' EMISSION SHAPE (0 = AREA, 1 = RING)
  Field _cfa:Float          ' NEAR CAMERA FADE DISTANCE
End Type
