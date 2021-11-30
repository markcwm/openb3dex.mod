' particlecandy.bmx

' This software is a port of Martin Liedel's (Xaron) Particle Candy for Monkey-X
'
' BlitzMax OpenB3D Port by RonTek
' https://www.blitzcoder.org 
'
' ---------------------------------------------------------------------------------
'
' This software is a port of Mike Dogan's great ParticleCandy for BlitzBasic3d
' http://www.x-pressive.com
'
' Check his page if you're interested in his latest ParticleCandy Engine
' for Corona SDK!
'
' A BIG THANKS goes to him as he gave the permission to publish this as open source
' For any support or questions contact: martin.leidel@gmail.com

Strict

Rem
bbdoc: Particle Candy for Openb3d
End Rem
Module Openb3dex.Particlecandy

ModuleInfo "Version: 1.01"
ModuleInfo "License: zlib"
ModuleInfo "Copyright: - 2007-2021 Mike Dogan"

Import Openb3d.Openb3d

Include "particle.bmx"
Include "emitter.bmx"
Include "particletype.bmx"

Rem
bbdoc: TParticleCandy
EndRem
Type TParticleCandy
  Global DEBUG:Int  = False

  Field _gravity:Float
  Field _numParticleTypes:Int
  Field _maxNumParticleTypes:Int
  Field _useTriangles
  Field _entityFX:Int
  Field _emitterList:TList
  Field _particleTypes:TParticleCandyParticleType[]
  Field _particleTypeList:TList
  Field _numParticles:Int
  Field _particlesRendered:Int

  Field _camera:TCamera
  Field _screenW:Int
  Field _screenH:Int
  Field _mesh:TMesh[2]
  Field _surface:TSurface[2]
  Field _ptmsh:TMesh
  Field _ptsrf:TSurface
  Field _dummyPivot:TEntity
  Field _dummyMesh:TMesh
  Field _dummySurface:TSurface
  Field _particleTexture:TTexture
  Field _textureFrames:Int
  Field _textureFrameSize:Int
  Field _textureNumFrames:Int
  Field _uvUnit:Float
  Field _updatespeed:Int
  Field _wind:Float
  
  Field _cycles:Int
  Field _prev:Int = MilliSecs()   
  Field _now:Int  = MilliSecs()
  Field _diff:Float       ' MILLISEC-DIFFERENCE BETWEEN LAST TWO FRAMES

  Method Create:TParticleCandy( gravity:Float = 0.01, numParticleTypes:Int = 100, useTriangles = False, EntityFX:Int = 1+2+8+16+32 )
	 Local pc:TParticleCandy = New TParticleCandy
	 pc._gravity = gravity
    pc._maxNumParticleTypes = numParticleTypes
    pc._numParticleTypes = 0
    pc._useTriangles = useTriangles
    pc._entityFX = EntityFX
    pc._emitterList = New TList
    pc._particleTypes = New TParticleCandyParticleType[numParticleTypes]
    pc._particleTypeList = New TList
	 If TParticleCandy.DEBUG = True Then DebugLog "Creating Particle..."
	 Return pc
  End Method
  
  Method Init( cam:TCamera , texFile:String , texFrames:Int , viewportW:Int = 0 , viewportH:Int = 0 )
	  If TParticleCandy.DEBUG = True Then DebugLog "Init..."
    _camera = cam
    _screenW = viewportW
    _screenH = viewportH
    If( _screenW = 0 ) _screenW = GraphicsWidth()
    If( _screenH = 0 ) _screenH = GraphicsHeight()
    _mesh[0]    = CreateMesh()
    _surface[0] = CreateSurface( _mesh[0] )
    _mesh[1]    = CreateMesh()
    _surface[1] = CreateSurface( _mesh[1] )
    EntityBlend( _mesh[0], 1 )
    EntityBlend( _mesh[1], 3 )
    EntityFX   ( _mesh[0], _entityFX )
    EntityFX   ( _mesh[1], _entityFX )

    ' DUMMY PIVOT
    _dummyPivot = CreatePivot()
    
    ' DUMMY QUAD (CAMERA FACING + ROTATION)
    _dummyMesh    = CreateMesh()
    _dummySurface = CreateSurface( _dummyMesh )
    HideEntity( _dummyMesh )
    AddVertex ( _dummySurface, -1.0,  1.0, 0.0, 0.0, 0.0 )
    AddVertex ( _dummySurface,  1.0,  1.0, 0.0, 1.0, 0.0 )
    AddVertex ( _dummySurface, -1.0, -1.0, 0.0, 0.0, 1.0 )
    If( Not _useTriangles ) AddVertex( _dummySurface, 1.0, -1.0, 0.0, 1.0, 1.0 )
    If TParticleCandy.DEBUG = True Then DebugLog texFile
    loadParticleTexture( texFile, texFrames )
  End Method
  
  Method loadParticleTexture( texFile:String, texFrames:Int )
    If( _particleTexture ) FreeTexture( _particleTexture )
    _particleTexture = LoadTexture( texFile, 2+16+32 )
    If( Not _particleTexture ) RuntimeError "COULD NOT LOAD PARTICLE TEXTURE: " + texFile
    _textureFrames = texFrames
    _textureFrameSize = TextureWidth( _particleTexture ) / _textureFrames
    _textureNumFrames = TextureWidth( _particleTexture ) / _textureFrameSize
    _uvUnit = 1.0 / Float( _textureNumFrames )
    EntityTexture( _mesh[0], _particleTexture )
    EntityTexture( _mesh[1], _particleTexture )
  End Method
  
  Method changeParticleCamera( cam:TCamera, viewportW:Int, viewportH:Int )
    If( Not cam ) RuntimeError "changeParticleCamera(): INVALID CAMERA HANDLE."
    _camera = cam
    _screenW = viewportW
    _screenH = viewportH
  End Method

  Method setParticleUpdateCycle( i:Int )
    _updatespeed = i
  End Method

  Method setParticleWind( i:Float = 0.0 )
    _wind = i / 1000.0
  End Method

  Method CreateEmitter:TParticleCandyEmitter( parent:TEntity = Null, scale:Float = 1.0 )
    ' CAMERA SET?
    If( Not _camera ) RuntimeError "YOU DID NOT SET A REFERENCE TO YOUR CAMERA. USE InitParticles(...) FIRST !"
    ' TEXTURE LOADED?
    If( Not _particleTexture ) RuntimeError "YOU DID NOT SET A PARTICLE TEXTURE. USE InitParticles(...) FIRST !"
    
    Local emitter:TParticleCandyEmitter = New TParticleCandyEmitter.Create( parent, scale, _dummyPivot, _dummyMesh, _dummySurface )
    _emitterList.AddLast( emitter )
    Return emitter
  End Method

  Method stopEmitters()
    For Local emitter:TParticleCandyEmitter = EachIn _emitterList
      emitter._active = False
      'TODO If xChannelPlaying(TParticleCandyEmitter.Sch) xStopChannel TParticleCandyEmitter.Sch
    Next
  End Method

  Method freeEmitter( emitter:TParticleCandyEmitter )
    emitter.freeEmitter()
    _emitterList.Remove( emitter )
  End Method

  Method freeEmitters()
    For Local emitter:TParticleCandyEmitter = EachIn _emitterList
      freeEmitter( emitter )
    Next
  End Method

  Method clearParticles()
    stopEmitters()
    For Local emitter:TParticleCandyEmitter = EachIn _emitterList
      emitter.clearParticles()
    Next
	 If TParticleCandy.DEBUG = True Then DebugLog "clearing..."
  End Method

  Method Free()
    clearParticles()
    freeEmitters  ()
    For Local pt:TParticleCandyParticleType = EachIn _particleTypeList
        _particleTypeList.Remove( pt )
    Next
    _numParticleTypes = 0 
    FreeTexture( _particleTexture )
    FreeEntity  _dummyMesh
    FreeEntity  _dummyPivot
    FreeEntity  _mesh[0]
    FreeEntity  _mesh[1]
    _particleTexture = Null
    _mesh[0] = Null
    _mesh[1] = Null
    _dummyMesh   = Null
    _dummyPivot= Null
  End Method

  Method createParticleType:Int()
    _numParticleTypes = _numParticleTypes + 1
    
    If( _numParticleTypes > _maxNumParticleTypes ) RuntimeError "TOO MANY PARTICLE TYPES USED. SET '_maxNumParticleTypes' TO A HIGHER VALUE!"
    
    Local id:Int = _numParticleTypes
    
    _particleTypes[id] = New TParticleCandyParticleType
    
    ' SET Default VALUES WHEN CREATED
    setPTImage( id )
    setPTSpeed( id )
    setPTRandomSpeed( id )
    setPTSize( id )
    setPTAlpha( id )
    setPTWeight( id )
    setPTRotation( id )
    setPTColor( id )
    setPTEmissionAngle( id )
    setPTInnerAngle( id )
    setPTStartOffsets( id )
    setPTLifeTime( id )
    setPTBounce( id )
    setPTPulsation( id )
    horizontalPTAlign( id )
    setPTAddedBlend( id )
    setPTCircularMotion( id )
    setPTEmissionShape( id )

    _particleTypeList.AddLast( _particleTypes[id] )

    Return id
  End Method

  Method setPTNearCameraFade( id:Int, radius:Float )
    _particleTypes[id]._cfa = radius
  End Method

  Method setPTImage( id:Int, frm:Int = 1 )
    'VALID IMAGE FRAME?
    If( frm > _textureFrames * _textureFrames ) RuntimeError "COULD NOT SET PARTICLE IMAGE -IMAGE FRAME " + frm + " DOES NOT EXIST IN TEXTURE!"

  ' PARTICLE Type'S UV COORDS
    Local row:Int = 1
    While frm > _textureFrames
        frm = frm - _textureFrames
        row = row + 1
    Wend
    _particleTypes[id]._u = (frm-1) * _uvUnit
    _particleTypes[id]._v = (row-1) * _uvUnit
  End Method

  Method setPTSpeed( id:Int, spd:Float = 10.0, spv:Float = 1.0, slo:Float = 0.0 )
    _particleTypes[id]._spd = spd / 1000.0
    _particleTypes[id]._spv = spv / 1000.0
    _particleTypes[id]._slo = slo / 1000.0
  End Method

  Method setPTRandomSpeed( id:Int, srx:Float = 0.0, sry:Float = 0.0, srz:Float = 0.0 )
    _particleTypes[id]._srx = srx / 1000.0
    _particleTypes[id]._sry = sry / 1000.0
    _particleTypes[id]._srz = srz / 1000.0
  End Method

  Method setPTSize( id:Int, sze:Float = 1.0, szv:Float = 0.0, szc:Float = 0.0, szm:Float = 10.0 )
    If( _useTriangles )
      _particleTypes[id]._sze = sze * 1.5
      _particleTypes[id]._szv = szv * 1.5
      _particleTypes[id]._szc = ( szc / 1000.0 ) * 1.5
      _particleTypes[id]._szm = szm * 1.5
    Else
      _particleTypes[id]._sze = sze
      _particleTypes[id]._szv = szv
      _particleTypes[id]._szc = szc / 1000.0
      _particleTypes[id]._szm = szm
    End If
  End Method

  Method setPTAlpha( id:Int, alp:Float = 1.0, alv:Float = 0.0, alc:Float = 0.0 )
    _particleTypes[id]._alp = alp
    _particleTypes[id]._alv = alv
    _particleTypes[id]._alc = alc / 1000.0
  End Method

  Method setPTWeight( id:Int, wgt:Float = 1.0, wgv:Float = 0.0 )
    _particleTypes[id]._wgt = wgt / 1000.0
    _particleTypes[id]._wgv = wgv / 1000.0
  End Method

  Method setPTRotation( id:Int, rom:Int = 0, roc:Float = 0.0 )
    _particleTypes[id]._rom = rom
    If( rom = 1 )
      _particleTypes[id]._roc = roc / 1000.0
    Else
      _particleTypes[id]._roc = roc
    End If
  End Method

  Method setPTColor( id:Int, r:Int = 100, g:Int = 100, b:Int = 100, bv:Int = 0, rc:Float = 0.0, gc:Float = 0.0, bc:Float = 0.0 )
    _particleTypes[id]._r  = Float( r )
    _particleTypes[id]._g  = Float( g )
    _particleTypes[id]._b  = Float( b )
    _particleTypes[id]._bv = bv
    _particleTypes[id]._rc = rc / 1000.0
    _particleTypes[id]._gc = gc / 1000.0
    _particleTypes[id]._bc = bc / 1000.0
  End Method

  Method setPTBounce( id:Int, flh:Float = 0.0, bnc:Float = 0.0, bnm:Int = 0 )
    _particleTypes[id]._flh = flh
    _particleTypes[id]._bnc = bnc
    _particleTypes[id]._bnm = bnm
  End Method

  Method setPTInnerAngle( id:Int, ian:Float = 0.0 )
    If( ian < 0.0 ) ian = 0.0
    _particleTypes[id]._ian = ian / 2.0
  End Method

  Method setPTOuterAngle( id:Int, emr:Float = 0.0 )
    If( emr < _particleTypes[id]._ian ) emr = _particleTypes[id]._ian
    If( emr > 360.0 ) emr = 360.0
    _particleTypes[id]._emr = emr / 2.0
  End Method

  Method setPTEmissionAngle( id:Int, emx:Int = 3, emr:Float = 15.0 )
    If( emx < 0 Or emx > 3 ) RuntimeError "PARTICLE EMISSION ANGLE INVALID -USE AXIS VALUES 0-3 ONLY!"
    _particleTypes[id]._emr = emr / 2.0
    ' ParticleTypes[id].emx = emx
  End Method

  Method setPTStartOffsets( id:Int, ox1:Float = 0.0, ox2:Float = 0.0, oy1:Float = 0.0, oy2:Float = 0.0, oz1:Float = 0.0, oz2:Float = 0.0 )
    _particleTypes[id]._ox1 = ox1
    _particleTypes[id]._ox2 = ox2
    _particleTypes[id]._oy1 = oy1
    _particleTypes[id]._oy2 = oy2
    _particleTypes[id]._oz1 = oz1
    _particleTypes[id]._oz2 = oz2
  End Method

  Method setPTLifeTime( id:Int, lft:Int = 1000 )
    _particleTypes[id]._lft = lft
  End Method

  Method setPTPulsation( id:Int, pls:Float = 0.0 )
    _particleTypes[id]._pls = pls
  End Method

  Method horizontalPTAlign( id:Int, hor:Int = 0 )
    _particleTypes[id]._hor = hor
  End Method

  Method setPTAddedBlend( id:Int, msh:Int = 0 )
    If( msh > 1 ) RuntimeError "SET PARTICLE BLEND MODE FAILED: USE ONLY 0 (NORMAL) OR 1 (ADDED BLEND)!"
    _particleTypes[id]._msh = msh
  End Method

  Method setPTTrail( id:Int, trl:Int, tst:Int = 0, tlt:Int = 1000, ter:Float = 15.0 )
    If( trl = 0 ) RuntimeError "SET PARTICLE TRAIL FAILED. YOU DID NOT SPECIFY A TRAIL PARTICLE ID."
    If( trl > _maxNumParticleTypes ) RuntimeError "SET PARTICLE TRAIL FAILED. THE SPECIFIED PARTICLE TYPE DOES NOT EXIST."
    
    _particleTypes[id]._trl = trl
    _particleTypes[id]._tst = tst
    _particleTypes[id]._tlt = tlt
    _particleTypes[id]._ter = ter / 1000.0
  End Method

  Method removePTTrail( id:Int )
    _particleTypes[id]._trl = 0
    _particleTypes[id]._tst = 0
    _particleTypes[id]._tlt = 0
    _particleTypes[id]._ter = 0
  End Method

  Method setPTCircularMotion( id:Int, cms:Float = 0.0 )
    _particleTypes[id]._cms = cms / 1000.0
  End Method

  Method setPTEmissionShape( id:Int, esh:Int = 0 )
    _particleTypes[id]._esh = esh
  End Method

  Method copyParticleType:Int( id2:Int )
    _numParticleTypes = _numParticleTypes + 1
    
    If( _numParticleTypes > _maxNumParticleTypes ) RuntimeError "TOO MANY PARTICLE TYPES USED. SET '_maxNumParticleTypes' TO A HIGHER VALUE!"
    
    Local id:Int = _numParticleTypes
    
    _particleTypes[id] = New TParticleCandyParticleType
    
    ' COPY VALUES FROM SOURCE Type
    _particleTypes[id]._u   = _particleTypes[id2]._u
    _particleTypes[id]._v   = _particleTypes[id2]._v
    _particleTypes[id]._spd = _particleTypes[id2]._spd
    _particleTypes[id]._spv = _particleTypes[id2]._spv
    _particleTypes[id]._slo = _particleTypes[id2]._slo
    _particleTypes[id]._srx = _particleTypes[id2]._srx
    _particleTypes[id]._sry = _particleTypes[id2]._sry
    _particleTypes[id]._srz = _particleTypes[id2]._srz
    _particleTypes[id]._sze = _particleTypes[id2]._sze
    _particleTypes[id]._szv = _particleTypes[id2]._szv
    _particleTypes[id]._szc = _particleTypes[id2]._szc
    _particleTypes[id]._szm = _particleTypes[id2]._szm
    _particleTypes[id]._alp = _particleTypes[id2]._alp
    _particleTypes[id]._alv = _particleTypes[id2]._alv
    _particleTypes[id]._alc = _particleTypes[id2]._alc
    _particleTypes[id]._wgt = _particleTypes[id2]._wgt
    _particleTypes[id]._wgv = _particleTypes[id2]._wgv
    _particleTypes[id]._rom = _particleTypes[id2]._rom
    _particleTypes[id]._hor = _particleTypes[id2]._hor
    _particleTypes[id]._roc = _particleTypes[id2]._roc
    _particleTypes[id]._ian = _particleTypes[id2]._ian
    _particleTypes[id]._emr = _particleTypes[id2]._emr
    _particleTypes[id]._flh = _particleTypes[id2]._flh
    _particleTypes[id]._bnc = _particleTypes[id2]._bnc
    _particleTypes[id]._bnm = _particleTypes[id2]._bnm
    _particleTypes[id]._pls = _particleTypes[id2]._pls
    _particleTypes[id]._ox1 = _particleTypes[id2]._ox1
    _particleTypes[id]._ox2 = _particleTypes[id2]._ox2
    _particleTypes[id]._oy1 = _particleTypes[id2]._oy1
    _particleTypes[id]._oy2 = _particleTypes[id2]._oy2
    _particleTypes[id]._oz1 = _particleTypes[id2]._oz1
    _particleTypes[id]._oz2 = _particleTypes[id2]._oz2
    _particleTypes[id]._r   = _particleTypes[id2]._r
    _particleTypes[id]._g   = _particleTypes[id2]._g
    _particleTypes[id]._b   = _particleTypes[id2]._b
    _particleTypes[id]._bv  = _particleTypes[id2]._bv
    _particleTypes[id]._rc  = _particleTypes[id2]._rc
    _particleTypes[id]._gc  = _particleTypes[id2]._gc
    _particleTypes[id]._bc  = _particleTypes[id2]._bc
    _particleTypes[id]._lft = _particleTypes[id2]._lft
    _particleTypes[id]._msh = _particleTypes[id2]._msh
    _particleTypes[id]._trl = _particleTypes[id2]._trl
    _particleTypes[id]._tst = _particleTypes[id2]._tst
    _particleTypes[id]._tlt = _particleTypes[id2]._tlt
    _particleTypes[id]._ter = _particleTypes[id2]._ter
    _particleTypes[id]._cms = _particleTypes[id2]._cms
    _particleTypes[id]._esh = _particleTypes[id2]._esh

    _particleTypeList.AddLast( _particleTypes[id] )

    Return id
  End Method

  Method render()
    Local r1:Float, r2:Float, i:Int, j:Int, k:Int, typ:Int, typ2:Int
    ' UPDATE EVERY ..th CYCLE ONLY
    _cycles = _cycles + 1
    If( _cycles < _updatespeed ) Return
    _cycles = 0

    ' CALCULATE TIME CHANGE
    _now  = MilliSecs()
    _diff  = _now - _prev
    If( _diff > 500 ) _diff = 500
    _prev = _now

    _numParticles      = 0
    _particlesRendered = 0
  
    _surface[0].ClearSurface()
    _surface[1].ClearSurface()

    For Local emitter:TParticleCandyEmitter = EachIn _emitterList
      ' EMITTER ACTIVE?
      If( emitter._active )
        Local x:Float  = EntityX    ( emitter.piv, True )
        Local y:Float  = EntityY    ( emitter.piv, True )
        Local z:Float  = EntityZ    ( emitter.piv, True )
        Local xr:Float = EntityPitch( emitter.piv, True )
        Local yr:Float = EntityYaw  ( emitter.piv, True )
        Local zr:Float = EntityRoll ( emitter.piv, True )
        
        ' LOOP THROUGH EMITTER'S PARTICLE TYPES
        For Local i:Int = 1 To emitter._npt
          typ  = emitter._pty[i]
          Local spv:Float = _particleTypes[typ]._spv
          Local emr:Float = _particleTypes[typ]._emr
          Local ian:Float = _particleTypes[typ]._ian
          ' EMITTER FINISHED?
          If( _now - emitter._est > emitter._mlt )
            emitter._active = False
            'TODO If TParticleCandyEmitter.slp And xChannelPlaying(TParticleCandyEmitter.Sch) xStopChannel TParticleCandyEmitter.Sch

            ' EMIT THIS PARTICLE Type?
          Else If( _now - emitter._est > emitter._pst[i] And _now - emitter._est < emitter._plt[i] And emitter._pta[i] = True )
            
            emitter._pea[i] = emitter._pea[i] + _diff * emitter._per[i]
            While emitter._pea[i] > 1.0

              Local particle:TParticleCandyParticle = New TParticleCandyParticle
              particle._typ = typ
              particle.piv = emitter.piv

              ' PARTICLE ANGLE
              RotateEntity  ( emitter.piv, xr, yr, zr, True )
              PositionEntity( emitter.piv, x, y, z, True )
              ' START POSITION
              If( _particleTypes[typ]._esh = 0 )
                ' EMISSION SHAPE AREA
                TurnEntity( emitter.piv, Rnd( ian, emr ), Rnd( 0, 359 ), Rnd( ian, emr ), False )
                MoveEntity( emitter.piv, ( _particleTypes[typ]._ox1 + Rnd( 0, _particleTypes[typ]._ox2 ) ) * emitter._scl, ( _particleTypes[typ]._oy1 + Rnd( 0, _particleTypes[typ]._oy2 ) ) * emitter._scl, ( _particleTypes[typ]._oz1 + Rnd( 0, _particleTypes[typ]._oz2) ) * emitter._scl )
              Else If( _particleTypes[typ]._esh = 1 )
                ' EMISSION SHAPE POINT  
                TurnEntity( emitter.piv, Rnd( ian, emr ), Rnd( 0, 359 ), Rnd( ian, emr ), False )
              Else If( _particleTypes[typ]._esh = 2 )
                ' EMISSION SHAPE RING
                TurnEntity( emitter.piv, Rnd( ian, emr ), Rnd( 0, 359 ), Rnd( ian, emr ), False )
                MoveEntity( emitter.piv, ( _particleTypes[typ]._ox1 + _particleTypes[typ]._ox2) * emitter._scl, ( _particleTypes[typ]._oy1 + Rnd( 0, _particleTypes[typ]._oy2 ) ) * emitter._scl, ( _particleTypes[typ]._oz1 + _particleTypes[typ]._oz2 ) * emitter._scl )
              Else If( _particleTypes[typ]._esh = 3 )
                ' EMISSION SHAPE xLine
                MoveEntity( emitter.piv, ( _particleTypes[typ]._ox1 + Rnd( 0, _particleTypes[typ]._ox2 ) ) * emitter._scl, ( _particleTypes[typ]._oy1 + Rnd( 0, _particleTypes[typ]._oy2 ) ) * emitter._scl, ( _particleTypes[typ]._oz1 + Rnd( 0, _particleTypes[typ]._oz2 ) ) * emitter._scl )
              End If
              
              particle._x  = EntityX( emitter.piv, True )
              particle._y  = EntityY( emitter.piv, True )
              particle._z  = EntityZ( emitter.piv, True )
              particle._lx = x
              particle._ly = y
              particle._lz = z

              ' SET SPEED
              TFormVector( 0,( _particleTypes[typ]._spd + Rnd( -spv, spv ) ) * emitter._scl, 0, emitter.piv, Null )
              particle._vx = TFormedX()
              particle._vy = TFormedY()
              particle._vz = TFormedZ()
                    
              ' RANDOM PARTICLE ROTATION?
              If( _particleTypes[typ]._rom = 1 )
                particle._rot = Rnd( 0.0, 359.0 )
              Else If( _particleTypes[typ]._rom = 0 )
              ' FIXED PARTICLE ROTATION?
                particle._rot = _particleTypes[typ]._roc
              End If
        
              particle._scl = emitter._scl
              particle._sze = ( _particleTypes[typ]._sze + Rnd( -_particleTypes[typ]._szv, _particleTypes[typ]._szv ) ) * emitter._scl
              particle._alp = _particleTypes[typ]._alp  + Rnd( -_particleTypes[typ]._alv, _particleTypes[typ]._alv )
              k = Rnd( -_particleTypes[typ]._bv, _particleTypes[typ]._bv )
              particle._r   = _particleTypes[typ]._r + k
              particle._g   = _particleTypes[typ]._g + k
              particle._b   = _particleTypes[typ]._b + k
              particle._stt = _now

              emitter._particleList.AddLast( particle )

              emitter._pea[i] = emitter._pea[i] - 1.0
            Wend
                
            ' CHANGE PARTICLE'S EMISSION RATE
            emitter._per[i] = emitter._per[i] + emitter._pec[i]
                
          End If ' End If EMIT THIS PARTICLE Type
        Next
        
        ' RESTORE EMITTER'S POSITION
        RotateEntity  ( emitter.piv, xr, yr, zr, True )
        PositionEntity( emitter.piv, x, y, z, True )
        
      End If

      ' UPDATE ALL PARTICLES
      For Local particle:TParticleCandyParticle = EachIn emitter._particleList
    
        ' COUNT  PARTICLE
        _numParticles = _numParticles + 1
        ' UPDATE  PARTICLE
        typ   = particle._typ
        _ptmsh = _mesh[_particleTypes[typ]._msh]
        _ptsrf = _surface[_particleTypes[typ]._msh]
        particle._lx = particle._x

        particle._ly = particle._y
        particle._lz = particle._z
        particle._x  = particle._x  + ( _diff * particle._vx ) + ( _diff * _wind )
        particle._y  = particle._y  + _diff * particle._vy
        particle._z  = particle._z  + _diff * particle._vz
        particle._vx = particle._vx + _diff * Rnd( -_particleTypes[typ]._srx, _particleTypes[typ]._srx )
        particle._vy = particle._vy + _diff * Rnd( -_particleTypes[typ]._sry, _particleTypes[typ]._sry )
        particle._vz = particle._vz + _diff * Rnd( -_particleTypes[typ]._srz, _particleTypes[typ]._srz )
        ' SLOW DOWN
        particle._vx = particle._vx + _diff * ( particle._vx * _particleTypes[typ]._slo )
        particle._vy = particle._vy + _diff * ( particle._vy * _particleTypes[typ]._slo )
        particle._vz = particle._vz + _diff * ( particle._vz * _particleTypes[typ]._slo )
        '
        particle._vy  = particle._vy  - _diff * ( ( ( particle._scl * _particleTypes[typ]._wgt ) + Rnd( -_particleTypes[typ]._wgv, _particleTypes[typ]._wgv ) ) * _gravity )
        particle._alp = particle._alp + _diff * _particleTypes[typ]._alc
        particle._r   = particle._r   + _diff * _particleTypes[typ]._rc
        particle._g   = particle._g   + _diff * _particleTypes[typ]._gc
        particle._b   = particle._b   + _diff * _particleTypes[typ]._bc
        particle._sze = particle._sze + _diff * ( _particleTypes[typ]._szc * particle._scl )
        ' SIZE CHANGE
        If( particle._sze > _particleTypes[typ]._szm * particle._scl ) particle._sze = _particleTypes[typ]._szm * particle._scl
        ' ROTATION
        If( _particleTypes[typ]._rom = 1 )
          If( particle._vx > 0 )
            particle._rot = particle._rot + _diff * _particleTypes[typ]._roc
          Else
            particle._rot = particle._rot - _diff * _particleTypes[typ]._roc
          End If
        End If
        ' Floor BOUNCE?
        If( _particleTypes[typ]._flh <> 0.0 )
          If( particle._y < _particleTypes[typ]._flh )
            particle._bnc = particle._bnc + 1
            particle._y   = _particleTypes[typ]._flh
            particle._vy  = -( particle._vy * _particleTypes[typ]._bnc )
          End If
        End If
        ' EMIT TRAIL PARTICLE?
        If( _particleTypes[typ]._trl )
          If( _now - particle._stt > _particleTypes[typ]._tst And _now - particle._stt < _particleTypes[typ]._tlt )
            particle._tea = particle._tea + _diff * _particleTypes[typ]._ter
            While particle._tea > 1.0
              typ2 = _particleTypes[typ]._trl
              Local trail:TParticleCandyParticle = New TParticleCandyParticle
              trail._typ = typ2
              trail._x   = particle._x
              trail._y   = particle._y
              trail._z   = particle._z
              trail._rot = Rnd( 0.0, 359.0 )
              trail._scl = particle._scl
              trail._sze = ( particle._sze + Rnd( -_particleTypes[typ2]._szv, _particleTypes[typ2]._szv ) ) * particle._scl
              trail._alp = _particleTypes[typ2]._alp + Rnd( -_particleTypes[typ2]._alv, _particleTypes[typ2]._alv )
              k = Rnd( -_particleTypes[typ2]._bv, _particleTypes[typ2]._bv )
              trail._r   = _particleTypes[typ2]._r + k
              trail._g   = _particleTypes[typ2]._g + k
              trail._b   = _particleTypes[typ2]._b + k
              trail._stt = _now
              emitter._particleList.AddLast( trail )
              particle._tea = particle._tea - 1.0
            Wend
          End If
        End If
            
    	' CIRCULAR MOTION
        If( _particleTypes[particle._typ]._cms <> 0.0 )
          EntityParent( _dummyPivot, particle.piv, False )
          PositionEntity( _dummyMesh, particle._x, particle._y, particle._z, True )
          EntityParent( _dummyMesh, _dummyPivot, True )
          TurnEntity( _dummyPivot, 0, _particleTypes[particle._typ]._cms * _diff, 0.0 )
          particle._x = EntityX( _dummyMesh, True )
          particle._y = EntityY( _dummyMesh, True )
          particle._z = EntityZ( _dummyMesh, True )
    	End If
        
        ' Delete PARTICLE?
        If( _now - _particleTypes[typ]._lft > particle._stt )
          If( GetParent( _dummyPivot ) = particle.piv ) EntityParent( _dummyPivot, Null, False )
          emitter._particleList.Remove( particle )
        Else If( particle._sze < 0 )
          If( GetParent( _dummyPivot ) = particle.piv ) EntityParent( _dummyPivot, Null, False )
          emitter._particleList.Remove( particle )
        Else If( particle._alp < 0 )
          If( GetParent( _dummyPivot ) = particle.piv ) EntityParent( _dummyPivot, Null, False )
          emitter._particleList.Remove( particle )
        Else If( particle._bnc > _particleTypes[typ]._bnm )
          If( GetParent( _dummyPivot ) = particle.piv ) EntityParent( _dummyPivot, Null, False )
          emitter._particleList.Remove( particle )
        'Else If  Particle.r + Particle.g + Particle.b < 1 ' <-- Delete If PARTICLE xColor BECOMES BLACK
        'Delete Particle
        Else
        ' DRAW PARTICLE?
          If( inView( particle._x, particle._y, particle._z, particle._sze ) )
            draw( particle )
            _particlesRendered = _particlesRendered + 1
          End If
        End If
        
      Next' PARTICLES LOOP
    Next
  End Method

  Method inView( x:Float, y:Float, z:Float, size:Float )
    TFormPoint( x, y, z, _ptmsh, Null )
    CameraProject( _camera, TFormedX(), TFormedY(), TFormedZ() )
    If( ProjectedZ() > 0 )
      If( ProjectedX() > -size And ProjectedX() < _screenW + size )
        If( ProjectedY() > -size And ProjectedY() < _screenH + size )
          Return True
        End If
      End If
    End If
    Return False
  End Method

  Method draw( particle:TParticleCandyParticle )
    Local sz:Float, x:Float, y:Float, z:Float, u1:Float, u2:Float, v1:Float, v2:Float, r:Int, g:Int, b:Int, v:Int, rom:Int
    x   = particle._x
    y   = particle._y
    z   = particle._z
    r   = Int( particle._r )
    g   = Int( particle._g )
    b   = Int( particle._b )
    u1  = _particleTypes[particle._typ]._u
    v1  = _particleTypes[particle._typ]._v
    u2  = u1 + _uvUnit
    v2  = v1 + _uvUnit
    sz  = ( particle._sze + Rnd( -_particleTypes[particle._typ]._pls, _particleTypes[particle._typ]._pls) ) * particle._scl

    ' ADJUST DUMMY QUAD
    ScaleEntity   ( _dummyMesh, sz, sz, 0, True )
    PositionEntity( _dummyMesh, x, y, z, True )
    
    If( _particleTypes[particle._typ]._rom = 2 )
      ' FACE CAMERA
      PointEntity( _dummyMesh, _camera )
      ' ALIGN ROTATION To MOVEMENT
		 AlignToVector( _dummyMesh, x-particle._lx, y-particle._ly, z-particle._lz, 1 )
      'AlignToVector( _dummyMesh, x-particle._lx, y-particle._ly, z-particle._lz, 1 )
    Else If( _particleTypes[particle._typ]._hor > 0 )
      ' ALIGN HORIZONTALLY
      RotateEntity( _dummyMesh, -90, 0, particle._rot, True )
    Else
      ' FACE CAMERA & ROTATE
      PointEntity( _dummyMesh, _camera, particle._rot )
    End If
    
    ' GET DUMMY VERTEX-COORDS
    TFormPoint( VertexX( _dummySurface, 0 ), VertexY( _dummySurface, 0 ), VertexZ( _dummySurface, 0 ), _dummyMesh, Null )
    x = TFormedX()
    y = TFormedY()
    z = TFormedZ()
    v  = AddVertex( _ptsrf, x, y, z, u1, v1 )
    TFormPoint( VertexX( _dummySurface, 1 ), VertexY( _dummySurface, 1 ), VertexZ( _dummySurface, 1 ), _dummyMesh, Null )
    x = TFormedX()
    y = TFormedY()
    z = TFormedZ()
    AddVertex( _ptsrf, x, y, z, u2, v1 )
    TFormPoint( VertexX( _dummySurface, 2 ), VertexY( _dummySurface, 2 ), VertexZ(_dummySurface, 2 ), _dummyMesh, Null )
    x = TFormedX()
    y = TFormedY()
    z = TFormedZ()
    AddVertex( _ptsrf, x, y, z, u1, v2 )
    
    If( Not _useTriangles )
      TFormPoint( VertexX( _dummySurface, 3 ), VertexY( _dummySurface, 3 ), VertexZ( _dummySurface, 3 ), _dummyMesh, Null )
      x = TFormedX()
      y = TFormedY()
      z = TFormedZ()
      AddVertex( _ptsrf, x, y, z, u2, v2 )
      AddTriangle( _ptsrf, v+1, v+3, v+2 )
    End If

    AddTriangle( _ptsrf, v, v+1, v+2 )

    ' FADE NEAR CAMERA
    Local d:Float = 1.0
    If( _particleTypes[particle._typ]._cfa > 0.0 )
      Local d:Float = EntityDistance( _camera, _dummyMesh ) / _particleTypes[particle._typ]._cfa
      If( d > 1.0  )
        d = 1.0
      Else If( d < 0.0 )
        d = 0.0
      End If
    End If

    VertexColor( _ptsrf, v  , r, g, b, d * particle._alp )
    VertexColor( _ptsrf, v+1, r, g, b, d * particle._alp )
    VertexColor( _ptsrf, v+2, r, g, b, d * particle._alp )
    VertexColor( _ptsrf, v+3, r, g, b, d * particle._alp )
  End Method
End Type
