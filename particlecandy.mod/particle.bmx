' particle.bmx

Rem
bbdoc: TParticleCandyParticle
EndRem
Type TParticleCandyParticle
  Field _x:Float, _y:Float, _z:Float    ' PARTICLE'S CENTER COORDS
  Field _lx:Float, _ly:Float, _lz:Float ' PARTICLE'S PREVIOUS POSITION
  Field _vx:Float, _vy:Float, _vz:Float ' PARTICLE'S SPEED
  Field _bnc:Int        ' BOUNCE COUNT
  Field _typ:Int        ' PARTICLE'S TYPE
  Field _scl:Float      ' PARTICLE'S SCALE FACTOR
  Field _sze:Float      ' SIZE
  Field _alp:Float      ' ALPHA
  Field _rot:Float      ' ROTATION
  Field _r:Float, _g:Float, _b:Float    ' xColor RGB
  Field _stt:Int        ' START TIME (MILLI-SECS)
  Field _tea:Float      ' INCREASE, EMIT TRAIL If ABOVE 1
  Field piv:TEntity    ' HANDLE To PARTICLE'S EMITTER
  Field _id:Int
End Type
