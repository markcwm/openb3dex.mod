' emitter.bmx

Rem
bbdoc: TParticleCandyEmitter
EndRem
Type TParticleCandyEmitter
  Field _active:Int
  Field piv:TEntity   ' PIVOT HANDLE
  Field _est:Int       ' TIME EMISSION STARTED
  Field _pty:Int[11]   ' UP To 10 PARTICLE TYPES PER EMITTER  
  Field _pta:Int[11]  ' PARTICLE Type ENABLED? (True/False)
  Field _pst:Int[11]   ' PARTICLE Type START TIMES
  Field _plt:Int[11]   ' PARTICLE Type LIFE  TIMES
  Field _per:Float[11]   ' PARTICLE Type EMISSION RATE (PER SECOND)
  Field _peo:Float[11]   ' PARTICLE Type EMISSION RATE REMEMBER
  Field _pec:Float[11]   ' PARTICLE Type EMISSION RATE CHANGE
  Field _pea:Float[11]   ' INCREASE, EMIT PARTICLE If ABOVE 1
  Field _scl:Float = 1   ' EMITTER'S SCALE
  Field _snd:Int       ' EMITTER SOUND
  Field _sch:Int       ' REMEMBER SOUND CHANNEL HANDLE
  Field _slp:Int      ' LOOP SOUND (1) Or Not (0)
  Field _mlt:Int       ' EMITTER'S MAXIMAL LIFE-TIME (LONGEST PARTICLE TYPE)
  Field _npt:Int       ' NUMBER OF ASSIGNED PARTICLE TYPES

  Field _particleList:TList
  Field _dummyPivot:TEntity
  Field _dummyMesh:TMesh
  Field _dummySurface:TSurface

  Method Create:TParticleCandyEmitter( parent:TEntity = Null, scale:Float = 1.0, dummyPivot:TEntity = Null, dummyMesh:TMesh = Null, dummySurface:TSurface = Null )
    Local n:TParticleCandyEmitter = New TParticleCandyEmitter
	  n._active       = False
    n._scl          = scale
    n._dummyPivot   = dummyPivot
    n._dummyMesh    = dummyMesh
    n._dummySurface = dummySurface

    n.piv = CreateCube( parent )
    Local marker:TEntity = CreateCube( n.piv )
    ScaleEntity   ( marker, 1.0, 0.2, 1.0 )
    PositionEntity( marker, 0.0, 1.0, 0.0 )
    EntityColor   ( marker, 255, 0, 0 )
    HideEntity    ( n.piv )

    n._particleList = New TList
	 Return n
  End Method

  Method addParticleType:Int( pid:Int, pst:Int = 0, plt:Int = 1000, per:Float = 10.0, pec:Float = 0.0 )
    _npt = _npt + 1
    _pty[_npt] = pid		    ' PARTICLE TYPES ID
    _pst[_npt] = pst		    ' PARTICLE Type START TIME 
    _plt[_npt] = pst + plt	' PARTICLE Type LIFE  TIME
    _per[_npt] = per / 1000	' PARTICLE Type EMISSION RATE (PER SECOND)
    _peo[_npt] = per / 1000	' PARTICLE Type EMISSION RATE REMEMBER
    _pec[_npt] = pec / 1000	' PARTICLE Type EMISSION RATE CHANGE
    _pta[_npt] = True		    ' PARTICLE Type ENABLED? (True/False)
    ' EMITTER'S MAXIMAL LIFE-TIME (LONGEST LASTING PARTICLE TYPE)
    If( pst + plt > _mlt ) _mlt = pst + plt
    Return _npt
  End Method

  Method updateSlot( slotNum:Int, pst:Int = 0, plt:Int = 1000, per:Float = 10.0, pec:Float = 0.0 )
    _pst[slotNum]  = pst		    ' PARTICLE Type START TIME 
    _plt[slotNum]  = pst + plt	' PARTICLE Type LIFE  TIME
    _per[slotNum]  = per / 1000	' PARTICLE Type EMISSION RATE (PER SECOND)
    _peo[slotNum]  = per / 1000	' PARTICLE Type EMISSION RATE REMEMBER
    _pec[slotNum]  = pec / 1000	' PARTICLE Type EMISSION RATE CHANGE
    ' EMITTER'S MAXIMAL LIFE-TIME (LONGEST LASTING PARTICLE TYPE)
    If( pst + plt > _mlt ) _mlt = pst + plt
  End Method

  Method start()
	 If TParticleCandy.DEBUG = True Then DebugLog "starting..."
    _active = True
    _est    = MilliSecs()
    For Local i:Int = 1 To _npt
      _per[i] = _peo[i]
    Next
    ' ALSO START ATTACHED SOUND?
    If( _snd )
      'TODO If xChannelPlaying(TParticleCandyEmitter.Sch) xStopChannel TParticleCandyEmitter.Sch
      'TParticleCandyEmitter.Sch = xEmitSound(TParticleCandyEmitter.Snd,TParticleCandyEmitter.Piv)
    End If
  End Method

  Method stop()
    _active = False
    'TODO If xChannelPlaying(TParticleCandyEmitter.Sch) xStopChannel TParticleCandyEmitter.Sch
  End Method

	Rem
  Method setSound:Void( sndFile:String, slp:Int = 0 )
    _slp = slp
    'TODO TParticleCandyEmitter.Snd  = xLoad3DSound(sndFile)
    'If TParticleCandyEmitter.Snd < 1 Then RuntimeError "COULD NOT LOAD SOUND: " + sndFile
    'If TParticleCandyEmitter.slp Then xLoopSound TParticleCandyEmitter.Snd
  End Method
  End Rem

  Method SetScale( scl:Float = 1.0 )
    _scl = scl
    ScaleEntity( piv, scl, scl, scl, True )
  End Method

  Method GetScale:Float()
    Return _scl
  End Method
  
  Method isActive()
    Return _active
  End Method

  Method hasFinished()
    For Local i:Int = 1 To _npt
      If( MilliSecs() - _est < _plt[i] )
         Return False
      End If
    Next
    Return True
  End Method

  Method getParticleType:Int( slot:Int )
    Return _pty[slot]
  End Method

  Method getSlot:Int( pid:Int )
    For Local i:Int = 1 To _npt
      If( _pty[i] = pid ) Return i
    Next
    Return -1
  End Method

  Method slotEnabled( slot:Int )
    Return _pta[slot]
  End Method

  Method disableSlot( slot:Int )
    _pta[slot] = False
  End Method

  Method enableSlot( slot:Int )
    _pta[slot] = True
  End Method

  Method freeParticleTypes()
    stop()
    _npt    = 0
    _active = False
  End Method

  Method freeEmitter()
    stop()

    For Local particle:TParticleCandyParticle = EachIn _particleList
      If( GetParent( _dummyPivot ) = particle.piv ) EntityParent( _dummyPivot, Null, False )
      If( GetParent( _dummyMesh )  = particle.piv ) EntityParent( _dummyMesh , Null, False )
      _particleList.Remove( particle )
    Next

    _npt    = 0
    _active = False
    'TODO If TParticleCandyEmitter.Snd > 0 xFreeSound TParticleCandyEmitter.Snd
    FreeEntity( piv )
  End Method

  Method clearParticles()
    For Local particle:TParticleCandyParticle = EachIn _particleList
      If( GetParent( _dummyPivot ) = particle.piv ) EntityParent( _dummyPivot, Null, False )
      If( GetParent( _dummyMesh )  = particle.piv ) EntityParent( _dummyMesh , Null, False )
      _particleList.Remove( particle )
    Next
  End Method

End Type
