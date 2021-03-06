C*****************************************************************
C   --CURVY GRAPH PLOTTING PROGRAM PLOT84 VERSION
C     A.D. MCLACHLAN JUL 1984. LAST UPDATED 16 DEC 1991
C     U= format option changed such that U=blank give free-format input TSH
C     Dashed line option added PRE January 1986
C     Added option to draw special symbols (see Legend) PRE June 1986)
C     Added option Q for extra text, and font-changing in text PRE Jan 1987
C     Increased YSHIFT to 100.0 for larger legends ADMCL Feb 1988
C     Increased number of plots to 100 JMS Mar 25 1991
C-----------------------------------------------------------------
C   --INPUT CODES:
C     CONTROL CHARACTER IN COLUMN 1. COLS 3-80 ARE DATA
C     THE "!" IS USED AS A SEPARATOR IN LEGEND LINE (OPTIONAL IF NO <S,M,C>)
C       T=<TITLE FOR PLOT>         Start new page of graphs with TITLE
C                                    up to 60 characters
C       X=<XLABEL>                 Label for X axis. Up to 40 characters  
C       Y=<YLABEL>                 Label for Y axis  Up to 40 characters
C       Z=<NTEX>                   <NTEX>=1,0,-1Plot text or not. Default NTEX=1
C                                   If NTEX=0  switch off drawing of all labels
C                                     and numbers (but not plot symbols)
C                                   If NTEX=-1 do not plot legends under graph
C       L=<LEGEND>!<I>!<N>!<C>! Legend for a new graph
C                                    up to 30 characters
C                                    up to 100 graphs on one picture page
C                                    up to 50000 points on page
C                                  <I> is letter symbol on plotted points
C                                      or Sn to plot symbol n 
C                                      (usually n = 1 to 16)
C                                  <N> is mode 0...9 (-1 to -9 for dashed lines)
C                                  <C> is colour 1...9
C                                  1=black, 2=red, 3=green, 4=blue, 5=yellow, 
C                                  6=orange, 7=purple, 8-9=black
C       F= <FSIZX> <FSIZY>         Frame size of graph in mm
C                                    defaults (200.0,150.0) Max (209.0,295.0)  
C                                    minimum allowed (10.0,10.0)
C       G= <GSCALX> <GSCALY>       Graph unit scales in mm
C                                    allowed range each 5.0 to 280.0
C                                    defaults (50.0,25.0)
C                                    No number values plotted if GSCALE.LT.10.0.
C       A= <AXLENG> <AYLENG>       Axis lengths in graph units
C                                    defines a tick mark every 1.0 units
C                                    allowed range 1.001 to 200.0
C                                    defaults (5.5, 5.5)
C       B= <XLOW> <XHIGH> <YLOW> <YHIGH>
C                                  Boundary values to match the end tick marks
C                                  on each axis
C       C= <NFONT>                 Character fount selection.(Default=1)
C                                    0=plain,1=normal,2=italic,3=script,4=Greek 
C                                    Selection only applies to writing. Plot
C                                    symbols are always in Fount 0. 
C       U= <UFMT>                  Uniform instead of free input format for
C                                    X,Y values. If UFMT is blank then set
C                                    (2G14.6)
C       D= <REPEAT> <DASH>         Dash parameters, repeat length and dash
C                                    length in mm (default 5,2)
C       Q= <X> <Y>! text           Plot given text at point x,y (user units)
C
C	O=P                        Orientation = portrait (default)
C	O=L                        Orientation = landscape
C
C  Any text may contain cntrl/A - cntrl/D to change font to 1 - 4 for one
C  character.
C
C   --NO CONTROL CHARACTER THEN EXPECT COORDINATES
C       X,Y   (DECODED AS FREE G<POINT>.0 FORMAT)
C   --EACH GRAPH TERMINATED BY A "T" "L" OR "END FILE"
C   --MODES:  0=SYMBOLS AT EVERY POINT, NO LINES
C             1=SYMBOLS AT EVERY POINT AND LINES (DEFAULT)
C             n=SYMBOLS AT EVERY nTH POINT AND LINES n=2...9
C   --COLOURS 1=BLACK 2=RED 3=GREEN 4=BLUE 5=YELLOW 6=ORANGE 7=PURPLE 8,9=?
C-----------------------------------------------------------------------------
C
C
      PARAMETER (A4WIDTH_MM=209)
      PARAMETER (A4HEIGHT_MM=295)
      PARAMETER (NGRMAX=100,NQLBMX=30)
C
	common nfont,fontsize

      CHARACTER*1 ORIENTATION/'P'/
      CHARACTER*60 LEGND(NGRMAX),TITL,XLABL,YLABL
      DATA XLABL/'X'/,YLABL/'Y'/
      DATA IXCHR/1/,IYCHR/1/
      CHARACTER*1 CHSYMB(NGRMAX)
      DATA CHSYMB/NGRMAX*' '/
      CHARACTER*1 CHARL1,CHARX,CHARY,CHART,CHARL
C   --CHARACTER STRING FOR DECODING INPUT KEYS   
      CHARACTER*14 CHARIN/'TXYLFGABCUZDQO'/
      CHARACTER*10 CHRDIG/'0123456789'/
      CHARACTER*3 PATCH
C Q labels
      CHARACTER*40 QLABEL(NQLBMX)
      DIMENSION QXYLBL(2,NQLBMX)
C   --CHARACTER STRINGS FOR READING AN INPUT LINE
      CHARACTER*80 CHLINE
      CHARACTER*78 CLINE2
      EQUIVALENCE(CHLINE(3:3),CLINE2)
      EQUIVALENCE(CHLINE(1:1),CHARL1)
      CHARACTER*10 CFIELD
C--
      LOGICAL ITEST,NOFLND,NOTIT,NOBOUN,NOLEG
      DIMENSION X(50000),Y(50000),IPLT(NGRMAX+1),ILGCHR(NGRMAX),
     .   LSYMB(NGRMAX)
      DATA NPTMAX/50000/
      DIMENSION IMODE(NGRMAX),ICOLOR(NGRMAX)
      DATA ICOLOR/NGRMAX*4/
      DIMENSION FVALUE(20)
C-----
C   --NORMAL FRAME SIZE XEND1,YEND1
      DATA XSTART/0.0/,XEND1/190.001/,YSTART/0.0/,YEND1/280.001/
C   --MAX FRAME SIZE XFLIM,YFLIM
      DATA XFLIM/A4WIDTH_MM/,YFLIM/A4HEIGHT_MM/
C   --AXIS LENGTHS AND SCALE UNITS
      DATA XLEN1/5.5/,YLEN1/5.5/
      DATA GSCAL1/30.0/,GSCAL2/15.0/
C   --ORIGIN SHIFT
CCTSH      DATA XSHIFT/25.0/,YSHIFT/100.0/
      DATA XSHIFT/10.0/,YSHIFT/25.0/
      DATA XMIN1/1.E20/,YMIN1/1.E20/,
     1     XMAX1/-1.E20/,YMAX1/-1.E20/
      DATA MAXLEG/30/
C   --CHARACTER SIZES FOR LEGENDS ETC 
      DATA  SYSCL/3.0/,TISCL/5.0/,ALGSCL/4.0/
C   --FORMAT FOR UNIFORM INPUT
      CHARACTER*20 GFMT/'(2G14.6)'/
      CHARACTER*20 UFMT
      CHARACTER*78 BLNK78/' '/



C------------------------------------------------------------------
   20 FORMAT(' TOO MANY PLOTS!!! MAX IS ',I4,' PER PAGE!!')
   21 FORMAT(' TOO MANY POINTS!! MAX IS ',I8,' PER PAGE!!')
   22 FORMAT(A)
   23 FORMAT(1X,'CURVY84: Graph Plotting Program ')
   24 FORMAT(1X,' DATA READ: Frame Size     F= ',2F10.4)
   25 FORMAT(1X,' DATA READ: Graph Units    G= ',2F10.4)
   26 FORMAT(1X,' DATA READ: Axis Segments  A= ',2F10.4)
   27 FORMAT(1X,' DATA READ: Bound Values   B= ',
     1      /1X,'                   XLOW XHIGH ',2F12.4,
     2      /1X,'                   YLOW YHIGH ',2F12.4)
   28 FORMAT(1X,' !!DATA ERROR: Frame size too big/small. '/
     1     / 1X,' Reset as ',2F10.4)
   29 FORMAT(1X,' !!DATA ERROR: Graph scale units too big/small. '/
     1     / 1X,' Reset as ',2F10.4)
   30 FORMAT(1X,' !!DATA ERROR: Axis segments too big/small. '/
     1     / 1X,' Reset as ',2F10.4)
   31 FORMAT(1X,' !!SCALING ERROR: X graph scale too big '/
     1     / 1X,' Reset as ',F10.4)
   32 FORMAT(1X,' !!SCALING ERROR: Y graph scale too big '/
     1     / 1X,' Reset as ',F10.4)
   33 FORMAT(1X,' !!BOUNDS ERROR: Wrongly ordered or equal bounds '
     1     / 1X,' Ignored and automatic bounds used ')
   34 FORMAT(1X,' OUTPUT STATISTICS: Picture Number ',I5,' -- '
     1     / 1X,' Number of Graphs ',I3,' Points plotted ',I6,
     2     / 1X,' Axis Segments ',2F12.4,' Graph Scales  ',2F12.4,
     3     / 1X,' Sizes Used    ',2F12.4,
     4     / 1X,' Tick X Bounds ',2F12.4,' Tick Y Bounds ',2F12.4,
     5     / 1X,' Tick Steps X,Y',2F12.4,
     6     / 1X,' Data limits X:',2F12.4,' Data limits Y:',2F12.4)
   35 FORMAT(1X,' DATA READ: Fount          C= ',A)
   36 FORMAT(1X,' DATA READ: Uniform Format U= ',A) 
   37 FORMAT(1X,' !!FOUNT ERROR: Improper value replaced by NFONT=1')
   38 FORMAT(1X,' DATA READ: Uniform Format U= blank - set as *')
   39 FORMAT(2G14.6)
   40 FORMAT(1X,' DATA READ: NTEX           Z= ',I2)
   41 FORMAT(1X,' !!NTEX ERROR: Not +-1 or 0. Reset as 1')
   42 FORMAT(1X,' DATA READ: repeat, dash length (mm) =',2F10.4)
   43 FORMAT(1X,' Too many extra labels (Q), maximum =',I5)
C----------------------------------------------------------------
C   --VARIABLE AND PLOT SET UP
      NPLMAX=0
      ICHAN = 1
      WRITE(6,23)
CCCCC      CALL CCPOPN(ICHAN,'CURVYIN','RO','F')
      CALL CCPOPN(ICHAN,'CURVYIN',5,1,512,IFAIL)
C   --NOFLND IS .TRUE. FOR DATA FILE STILL NOT ENDED
C   --NOTIT IS .TRUE. FOR NO TITLE LINE  FOUND
C   --NOLEG IS .TRUE. FOR NO LEGEND LINE FOUND
C   --NOBOUN IS .TRUE. FOR NO BOUND LINE FOUND
      NOFLND = .TRUE.
      NOLEG = .TRUE.
      NOTIT = .TRUE.
      NOBOUN = .TRUE.
      NFONT=1
      INFORM=3 
      NPICT = 0
      NPOINT = 0
      NGRAPH = 0
      NQLABL=0
      IPLT(1) = 1
      IMODE(1) = 1
      REPEAT = 5.0
      DASH = 2.0
      DOT = 0.0
C-----
C###      CALL PLOT84_INIT('PLOT')
	CALL P2K_OUTFILE('CURVYOUT',8)
	CALL P2K_LWIDTH(0.2)
      MCOLOR=1
C###      CALL PLOT84_MIXC(MCOLOR)
C-----
      FSIZX=XEND1
      FSIZY=YEND1
      XLEN=XLEN1
      YLEN=YLEN1
      GSCALX=GSCAL1
      GSCALY=GSCAL2 
C---------------------------------------------------------
C   --COLLECT ALL GRAPHS WHICH BELONG ON THE PICTURE PAGE BEFORE 
C   --DRAWING ANYTHING
C   --SCAN FOR CONTROL CHARACTERS
C---------------------------------------------------------
  100 CONTINUE
      READ(ICHAN,22,END=105,ERR=105) CHLINE
      GO TO 110
  105 CONTINUE
      NOFLND = .FALSE.
      GO TO 190
  110 CONTINUE
C   --DECODE THE FIRST CHARACTER
      NCODE=INDEX(CHARIN,CHARL1)
        IF(NCODE.EQ.0) THEN
          GO TO 112
        ELSE
          GO TO (115,130,140,158,151,
     1           152,153,154,155,156,157,1158,1159,159),NCODE
        END IF 
C   --"T" TITLE
C   --"X" LABEL
C   --"Y" LABEL
C   --"L" LEGEND
C   --"F" FRAME SIZE
C   --"G" GRAPH UNITS
C   --"A" AXIS LENGTHS IN GRAPH UNITS
C   --"B" BOUNDS FOR TICKS ON AXES 
C   --"C" CHARACTER FOUNT
C   --"U" UNIFORM COORDINATE FORMAT
c   --"Z" NTEX SWITCH
c   --"D" DASH PARAMETERS
C   --"Q" EXTRA TEXT LABELS
C   --"O" ORIENTATION
C   --COORDINATES ON LINE
  112 CONTINUE
      IF(NPOINT.GT.0) GO TO 180
C-------------------------------------------------------------
C   --THE FIRST COORDINATE LINE OF THE PICTURE TO SIGNALS
C   --THAT ALL CONTROL LINES ARE READ AND SO PICTURE SIZE ETC 
C   --CAN SAFELY BE SET. THE END OF DATA FOR A WHOLE PICTURE
C   --IS SIGNALLED BY EITHER: NEW TITLE, END FILE, DATA OVERFLOW. 
C-------------------------------------------------------------
  114 CONTINUE
C   --CHECK NUMBER OF PICTURES AND GRAPHS
      IF(NPICT.EQ.0) NPICT = 1
      IF(NGRAPH.EQ.0) NGRAPH = 1
      GO TO 180
C-----------------------------------------------------------------
C   --"T"  TITLE INFO AND NEW PLOT SET UP
C   --NEW TITLE MEANS NEW PICTURE PAGE WITH SERIES OF GRAPHS ON IT
C------------------------------------------------------------------
  115 CONTINUE
      NOTIT=.FALSE.
C   --IF NOT THE FIRST PICTURE THEN FINISH CURRENT GRAPH AND THEN COME BACK 
      IF(NPICT.NE.0) GO TO 190
  120 CONTINUE
      NPICT=NPICT+1
C   --SET DEFAULT SCALES AND SIZE FOR THIS PICTURE
      NOBOUN=.TRUE.
      XLEN=XLEN1
      YLEN=YLEN1
      FSIZX=XEND1
      FSIZY=YEND1
      GSCALX=GSCAL1
      GSCALY=GSCAL2
      NTEX=1
C   --RESET MAXIMA AND MINIMA OF OBSERVED DATA
      XMIN = XMIN1
      XMAX = XMAX1
      YMIN = YMIN1
      YMAX = YMAX1
C   --GRAPH AND POINT COUNTS, LABELS
      NGRAPH = 0
      NPOINT = 0
      NQLABL=0
      IPLT(1) = 1
      XLABL='X'
      YLABL='Y'
      IXCHR=1
      IYCHR=1
      NOLEG = .TRUE.
      DO 125 J = 1,NPLMAX
      CHSYMB(J) = ' '
  125 CONTINUE
C------------------
C   --COLLECT TITLE
C------------------
      CALL CURVY_CVLI(CLINE2,TITL,ITCHR)
      GO TO 100
C-----------------------------------
C   --"X"   X AXIS LABEL
C-----------------------------------
  130 CONTINUE
      CALL CURVY_CVLI(CLINE2,XLABL,IXCHR)
      IF (IXCHR.LT.0) IXCHR = 0
      IF(IXCHR.EQ.0) XLABL=' '
      GO TO 100
C-----------------------------------
C   --"Y"   Y  AXIS LABEL
C-----------------------------------
  140 CONTINUE
      CALL CURVY_CVLI(CLINE2,YLABL,IYCHR)
      IF (IYCHR.LT.0) IYCHR = 0
      IF(IYCHR.EQ.0) YLABL=' '
      GO TO 100
C----------------------------------------
C   --"F" GRAPH FRAME SIZE
C----------------------------------------
  151 CONTINUE
      CALL CURVY_CVLF(CLINE2,FVALUE,NFIELDS)
      FSIZX=FVALUE(1)
      FSIZY=FVALUE(2)
      WRITE(6,24) FSIZX,FSIZY
      IF((FSIZX.LE.XFLIM).AND.(FSIZX.GE.10.0).AND.
     1   (FSIZY.LE.YFLIM).AND.(FSIZY.GE.10.0)) GO TO 100
      FSIZX=XFLIM
      FSIZY=YFLIM
      WRITE(6,28) FSIZX,FSIZY
      GO TO 100
C-----------------------------------------
C   --"G" GRAPH SCALE UNITS
C-----------------------------------------
  152 CONTINUE
      CALL CURVY_CVLF(CLINE2,FVALUE,NFIELDS)
      GSCALX=FVALUE(1)
      GSCALY=FVALUE(2)
      WRITE(6,25) GSCALX,GSCALY
      IF((GSCALX.LE.280.0).AND.(GSCALX.GE.5.0).AND.
     1   (GSCALY.LE.280.0).AND.(GSCALY.GE.5.0)) GO TO 100
      GSCALX=50.0
      GSCALY=25.0
      WRITE(6,29) GSCALX,GSCALY   
      GO TO 100
C-----------------------------------------
C   --"A" AXIS LENGTHS IN GRAPH UNITS
C-----------------------------------------
  153 CONTINUE
      CALL CURVY_CVLF(CLINE2,FVALUE,NFIELDS)
      XLEN=FVALUE(1)
      YLEN=FVALUE(2)
      WRITE(6,26) XLEN,YLEN
      IF((XLEN.GE.1.001).AND.(XLEN.LE.200.0).AND.
     1   (YLEN.GE.1.001).AND.(YLEN.LE.200.0)) GO TO 100
      IF(XLEN.LT.1.001) XLEN=1.001
      IF(XLEN.GT.200.0) XLEN=200.0
      IF(YLEN.LT.1.001) YLEN=1.001
      IF(YLEN.GT.200.0) YLEN=200.0
      WRITE(6,30) XLEN,YLEN
      GO TO 100
C-------------------------------------------------------
C   --"B" BOUNDARY VALUES OF X,Y ON GRAPH EXTREME TICKS
C-------------------------------------------------------
  154 CONTINUE
      NOBOUN=.FALSE.
      CALL CURVY_CVLF(CLINE2,FVALUE,NFIELDS)
      XLOW= FVALUE(1)
      XHIGH=FVALUE(2)
      YLOW= FVALUE(3)
      YHIGH=FVALUE(4)
      WRITE(6,27) XLOW,XHIGH,YLOW,YHIGH
      IF((XHIGH.GT.XLOW).AND.(YHIGH.GT.YLOW)) GO TO 100
      WRITE(6,33)
      NOBOUN=.TRUE.
      GO TO 100
C---------------------------------------
C   --"C" CHARACTER FOUNT
C---------------------------------------
  155 CONTINUE
C   --DECODE THE NUMBER
      WRITE(6,35) CLINE2(1:1)
      IDIG=INDEX(CHRDIG,CLINE2(1:1))
      NFONT=IDIG-1
        IF((NFONT.LT.0).OR.(NFONT.GT.4)) THEN
          WRITE(6,37)
          NFONT=1
        END IF
C###      CALL PLOT84_FONT(NFONT)
      GO TO 100
C---------------------------------------
C   --"U" UNIFORM FORMAT
C---------------------------------------
  156 CONTINUE
        IF(INDEX(CLINE2,BLNK78).EQ.1) THEN
          WRITE(6,38)
          UFMT=GFMT        
C  --TSH 16-dec-91
          INFORM=4
        ELSE
          UFMT=CLINE2
          WRITE(6,36) UFMT
          INFORM=2
        END IF
      GO TO 100
C-----------------------------------------
C   --"Z" NTEX OPTION
C-----------------------------------------
  157 CONTINUE
      CALL CURVY_CVLF(CLINE2,FVALUE,NFIELDS)
      NTEX=NINT(FVALUE(1))
      WRITE(6,40) NTEX
        IF((NTEX.LT.-1).OR.(NTEX.GT.1)) THEN
          WRITE(6,41)
          NTEX=1
        END IF
      GO TO 100
C-----------------------------------------
C   --"D" dash parameters, REPEAT DASH
C-----------------------------------------
 1158 CONTINUE
      CALL CURVY_CVLF(CLINE2,FVALUE,NFIELDS)
      IF(NFIELDS.GE.1) REPEAT = FVALUE(1)
      IF(NFIELDS.GE.2) DASH = FVALUE(2)
      WRITE(6,42) REPEAT,DASH
      GO TO 100
C---------------------------------------
C   --"Q" read x,y coordinates and text for labels
C---------------------------------------
 1159 IF(NQLABL.GE.NQLBMX) THEN
	    WRITE(6,43) NQLBMX
	    GO TO 100
      ENDIF
      NQLABL=NQLABL+1
      CALL CURVY_CVLI(CLINE2,CFIELD,N)
      CALL CURVY_CVLF(CFIELD(1:N),QXYLBL(1,NQLABL),NFIELDS)
      CALL CURVY_CVLI(CLINE2(N+2:),QLABEL(NQLABL),NC)
      GO TO 100
C---------------------------------------
C   --"L"   LEGEND,SYMBOL,MODE
C     NEW LEGEND MEANS START COLLECTING DATA FOR
C     A NEW GRAPH
C---------------------------------------
  158 CONTINUE
      NGRAPH = NGRAPH + 1
      NOLEG = .FALSE.
      IF(NGRAPH.LE.NGRMAX) GO TO 160
C   --TOO MANY GRAPHS ON PAGE - DRAW AND FINISH PAGE
      WRITE(6,20) NGRMAX
      NOFLND = .FALSE.
      GO TO 190
  159 CONTINUE
      CALL CURVY_CVLI(CLINE2,ORIENTATION,I)
      IF (ORIENTATION.NE.'L'.AND.
     .    ORIENTATION.NE.'P') THEN
        WRITE(6,*) 'Error. O(rientation) must be P or L. P forced.'
        ORIENTATION='P'
      ENDIF
      GOTO 100
C-------------------------------------------------------
C   --COLLECT LEGEND,SYMBOL,MODE,COLOUR
C-------------------------------------------------------
C   --START POINT FOR THIS GRAPH
  160 CONTINUE
      IPLT(NGRAPH) = NPOINT + 1
      CALL CURVY_CVLI(CLINE2,LEGND(NGRAPH),JLGCHR)
      IPOS=JLGCHR+2
C
C Search for symbol field    CCC PRE June 1986
      CALL CURVY_CVLI(CLINE2(IPOS:),CFIELD,J)
      IF(J.LE.0.OR.CFIELD(1:1).EQ.' ') THEN
C No symbol
	    CHSYMB(NGRAPH)=' '
	    LSYMB(NGRAPH)=0
      ELSEIF(J.EQ.1) THEN
C 1 character, use as plotting symbol
	    CHSYMB(NGRAPH)=CFIELD(1:1)
	    LSYMB(NGRAPH)=-1
      ELSE
C More than one character, try to read all but first as number to 
C define symbol
	    CFIELD(1:1)=' '
	    CFIELD(J+1:J+1)=','
	    READ(CFIELD,161,ERR=162) LSYMB(NGRAPH)
	    GO TO 163
C Error in read, default to symbol 1
162	    WRITE(6,164) CFIELD
164	    FORMAT(' Illegal symbol number ',A,', default to 1')
	    LSYMB(NGRAPH)=1
163         CHSYMB(NGRAPH)=' '
      ENDIF
      IPOS=IPOS+J+1
C
CCC      CHSYMB(NGRAPH) = CLINE2(IPOS:IPOS)
CCC      IPOS=IPOS+2
C
      CALL CURVY_CVLI(CLINE2(IPOS:),CFIELD,J)
      IF(J.LE.0) THEN
        IM=1
      ELSE
        J=J+1
        CFIELD(J:J)=','
        READ(CFIELD,161) IM
161     FORMAT(I5)
      ENDIF
      IMODE(NGRAPH) = IM
      IPOS=IPOS+J
C   --UP TO MAXLEG CHARACTERS ALLOWED FOR LEGEND
      ILGCHR(NGRAPH) = MIN0(MAXLEG,JLGCHR)
      IC=INDEX(CHRDIG,CLINE2(IPOS:IPOS))
      IF(IC.NE.0) GO TO 175
C   --DEFAULT COLOUR IS BLUE(=4)
      IC = 5			
  175 CONTINUE
      ICOLOR(NGRAPH) = IC - 1
      GO TO 100
C-----------------------------------------------
C     X,Y COORDINATE DATA (NO CONTROL CHARACTER)
C-----------------------------------------------
  180 CONTINUE
C   --NPOINT IS NUMBER OF POINTS ON PAGE
C   --IPLT(NGRAPH) IS TOTAL NUMBER OF POINTS IN FIRST (NGRAPH) GRAPHS
      NPOINT = NPOINT + 1
      IF (NPOINT.LT.NPTMAX) GO TO 185
C   --TOO MANY POINTS - STOP READING AND DRAW
      WRITE(6,21) NPTMAX
      NOFLND = .FALSE.
      GO TO 190
C--
  185 CONTINUE
C   --INTERPRET COORDINATES
      GO TO (186,187,188,1881), INFORM
C   --STANDARD (2G14.6) FORMAT
  186 CONTINUE
      READ(CHLINE,39) A,B
      GO TO 189
C   --UNIFORM INPUT FORMAT
  187 CONTINUE      
      READ(CHLINE,UFMT) A,B
      GO TO 189
C   --FREE INPUT FORMAT
  188 CONTINUE
C   --DECODE FREE FORMAT DECIMAL FIELDS
      CALL CURVY_CVLF(CHLINE,FVALUE,NFIELDS)
      A = FVALUE(1)
      B = FVALUE(2)
      GOTO 189
C  --* FORMAT added TSH 16-dec-91
 1881 READ(CHLINE,*) A,B
  189 CONTINUE
C   --UPDATE LIMITS
      IF (A.LT.XMIN) XMIN = A
      IF (A.GT.XMAX) XMAX = A
      IF (B.LT.YMIN) YMIN = B
      IF (B.GT.YMAX) YMAX = B
      X(NPOINT) = A
      Y(NPOINT) = B
      GO TO 100
C========================================================================
C   --DO ACTUAL PLOTTING OF ALL GRAPHS IN THIS PICTURE
C========================================================================
  190 CONTINUE
C   --CHECK COMPATIBILITY OF THE LIMITS AS SET
C   --FSIZX,FSIZY ARE ALREADY CHECKED
C   --NOW CHECK ON ACTUAL SIZE REQUIRED FOR THE GRAPH
      GSIZX=XLEN*GSCALX
        IF(GSIZX.GT.FSIZX) THEN
          GBIGX=FSIZX/XLEN
          GSCALX=GBIGX
          WRITE(6,31) GSCALX          
        END IF
      GSIZY=YLEN*GSCALY
        IF(GSIZY.GT.FSIZY) THEN
          GBIGY=FSIZY/YLEN
          GSCALY=GBIGY
          WRITE(6,32) GSCALY
        END IF
      XSIZE=XLEN*GSCALX
      YSIZE=YLEN*GSCALY
C   --COORDINATE SCALES BASED ON GRAPH UNITS
        NXLEN=XLEN
        ANX=NXLEN
        NYLEN=YLEN
        ANY=NYLEN
C       --AUTOMATIC OPTION
        IF(NOBOUN) THEN
          CALL CURVY_CVSC(XMIN,XMAX,XLEN,VXMIN,DVX)
          CALL CURVY_CVSC(YMIN,YMAX,YLEN,VYMIN,DVY)
          XLOW=VXMIN
          XHIGH=XLOW+DVX*ANX
          YLOW=VYMIN
          YHIGH=YLOW+DVY*ANY
C       --AS READ FROM BOUNDS LINE
        ELSE
          VXMIN=XLOW
          DVX=(XHIGH-XLOW)/ANX            
          VYMIN=YLOW
          DVY=(YHIGH-YLOW)/ANY
        END IF
      DVXFAC=DVX/GSCALX
      DVYFAC=DVY/GSCALY
C-----------------------------------------------------
C   --START NEW PICTURE ON THE PLOTTER WITH NEW WINDOW
C-----------------------------------------------------
C###      CALL PLOT84_XENV
      XEND=FSIZX
      YEND=FSIZY
C   --ALLOW 25MM AT TOP AND RIGHT EDGE FOR LABEL AND TITLE LETTERING
      DWLIMX=XEND+XSHIFT+25.0
      DWLIMY=YEND+YSHIFT+25.0
C###      CALL PLOT84_BSIZ(DWLIMX,DWLIMY) 
C###      CALL PLOT84_WNDB(XSTART,DWLIMX,YSTART,DWLIMY)
C###      CALL PLOT84_PICT
C   --NEW PAGE OF GRAPHS: SET SCALES ON NEW SHEET OF PAPER
C   --CENTRED CHARACTERS WITH UNIFORM SPACING
C   --TITLE LETTERING TOTAL WIDTH MUST NOT EXCEED 0.8*XSIZE
      TITLEN=ITCHR+1
      SPACET=0.8*XSIZE
      TSIZL=SPACET/TITLEN
      TSIZE=TISCL
      IF(TSIZE.GT.TSIZL) TSIZE=TSIZL
      IF(TSIZE.LT.2.0) TSIZE=2.0   
	CALL P2K_HOME
C shift origin to bottom l.h. corner
	  IF (ORIENTATION.EQ.'P') THEN
	    CALL P2K_MOVE(-0.9, -1.2, 0.0)
	  ELSE
	    CALL P2K_MOVE(0.9, -1.2, 0.0)
	    CALL P2K_TWIST(90.0, 180.0, 0.0)
	  ENDIF
	  CALL P2K_HERE
C###      CALL PLOT84_SCLC(TSIZE,TSIZE)
C###      CALL PLOT84_FONT(NFONT)
C###      CALL PLOT84_CENC(1)
C###      CALL PLOT84_CSPU(1)
C   --GRAPH SCALE 1 UNIT = GSCALX OR GSCALY MM
C   --DRAWING BOARD ORIGIN IN MM
C###      CALL PLOT84_ORGD(XSHIFT,YSHIFT)

C select drawing-board scale. mm.
	CALL P2K_GRID(A4WIDTH_MM/2, A4WIDTH_MM/2, 1.0)

C  and set an origin for the graph
	CALL P2K_MOVE(XSHIFT, YSHIFT, 0.0)
	CALL P2K_HERE


C--------------------------------------------
C   --PRINT STATISTICS FOR THIS PICTURE
C--------------------------------------------
      WRITE(6,34) NPICT,  NGRAPH,NPOINT,
     1    XLEN,YLEN,  GSCALX,GSCALY,
     2    XSIZE,YSIZE,
     3    XLOW,XHIGH,  YLOW,YHIGH,
     4    DVX,DVY,
     5    XMIN,XMAX,  YMIN,YMAX 
C-------------------------------------------- 
C   --START DRAWING (TITLE IN BLACK)
C###      IF (MCOLOR .EQ. 1) CALL PLOT84_COLR(4)
C---------------
C   --DRAW TITLE
C---------------
      IF(NTEX.EQ.0) GO TO 192
      IF(NOTIT.OR.(ITCHR.LE.0)) GO TO 192
C   --TITLE: FOUNT(1) 5MM HIGH PLACED TO RIGHT OF Y AXIS LINE 
C###      IF(MCOLOR.EQ.1) CALL PLOT84_COLR(4)
      AX = 0.5*XSIZE + TISCL
      AY = YSIZE + TISCL
C###      CALL PLOT84_ANCU(AX,AY)
	IF (MCOLOR.EQ.1) CALL C2KCOLOUR(4)
      CALL P2K_MOVE(AX, AY, 0.0)
	CALL C2KFONT(5.0)
      CALL P2K_CSTRING(TITL(1:ITCHR), ITCHR, 0.0)
  192 CONTINUE
C--------------------------------
C   --DRAW AXES AND XLABEL,YLABEL
C--------------------------------
	CALL P2K_MOVE(0.0, 0.0, 0.0)
      NSIDE= -1
C###    CALL PLOT84_CVAX(0.0,0.0,XLABL(1:40),NSIDE,NTEX,
C###   1              XLEN,GSCALX,0.0 ,VXMIN,DVX)
      CALL C2KCVAX(0.0,0.0,XLABL(1:40),NSIDE,NTEX,
     1              XLEN,GSCALX,0.0 ,VXMIN,DVX)
      NSIDE=1
C###      CALL PLOT84_CVAX(0.0,0.0,YLABL(1:40),NSIDE,NTEX,
C###     1             YLEN,GSCALY,90.0,VYMIN,DVY)
      CALL C2KCVAX(0.0,0.0,YLABL(1:40),NSIDE,NTEX,
     1             YLEN,GSCALY,90.0,VYMIN,DVY)
cc	CALL P2K_HERE
cc	CALL P2K_GRID(XLEN/2, YLEN/2, 1.0)


C------------------------------------------------
C   SCALE UP DATA FOR ALL THE GRAPHS ON THIS PAGE
C------------------------------------------------
  195 CONTINUE
      IPLT(NGRAPH + 1) = NPOINT + 1
      DO 200 J = 1,NPOINT
      X(J) = (X(J) - VXMIN)/DVXFAC
      Y(J) = (Y(J) - VYMIN)/DVYFAC
  200 CONTINUE
C   --SET CHAR SIZE FOR PLOT SYMBOLS
C   --FONT(0) 3 MM HIGH
C###      CALL PLOT84_FONT(0)
C###      CALL PLOT84_SCLC(SYSCL,SYSCL)
	NFONT=0
	CALL C2KFONT(SYSCL)
      DO 300 J = 1,NGRAPH
C###      IF(MCOLOR .EQ. 1) CALL PLOT84_COLR(ICOLOR(J))
	IF (MCOLOR.EQ.1) CALL C2KCOLOUR(ICOLOR(J))
      JX = IPLT(J)
      N = IPLT(J+1) - JX
      IFREQ = 1
      IF(IABS(IMODE(J)).GT.1) IFREQ = IABS(IMODE(J))
C---------------
C   --DRAW LINES
C---------------
      IF(IABS(IMODE(J)).GT.0) THEN
	    IF(IMODE(J).GT.0) THEN
C  Solid lines
		  CALL DASHED(0,REPEAT,DASH,DOT)
	    ELSE
C  Dashed lines
		  CALL DASHED(1,REPEAT,DASH,DOT)
	    ENDIF
	    CALL LINES(X(JX),Y(JX),N)
      ENDIF
      IF(INDEX(CHSYMB(J),' ').EQ.1.AND.LSYMB(J).EQ.0) GO TO 300
C-----------------
C   --DRAW SYMBOLS   (either characters or special symbols)
C------------------
      NJUST=2
      DO 290 K = 1,N,IFREQ
      L = JX + K - 1
C###      CALL PLOT84_ANCU(X(L),Y(L))
	CALL P2K_MOVE(X(L),Y(L)-0.5*SYSCL,0.0)
      IF(LSYMB(J).LT.0) THEN
C###	    CALL PLOT84_CETX(CHSYMB(J),NJUST)
	  CALL P2K_CSTRING(CHSYMB(J),1,0.0)
      ELSE
C###	    CALL PLOT84_GSYM(LSYMB(J),1)
	  CALL C2KSYMBOL(LSYMB(J),1)
      ENDIF
  290 CONTINUE
  300 CONTINUE
C------------------------------------------------
C  Plot extra labels
C------------------------------------------------
      IF(NQLABL.GT.0) THEN
C###	    CALL PLOT84_FONT(NFONT)
	    DO 310,I=1,NQLABL
	    XX=(QXYLBL(1,I)-VXMIN)/DVXFAC
	    YY=(QXYLBL(2,I)-VYMIN)/DVYFAC
C###	    CALL PLOT84_ANCU(XX,YY)
	    CALL P2K_MOVE(XX, YY, 0.0)
	    CALL PLTTXT(QLABEL(I))
310	    CONTINUE
      ENDIF
      IF (NOLEG.OR.NTEX.LT.0) GO TO 410
C------------------------------------------------
C   --PLOT LEGENDS -- IN TWO COLUMNS IF NECESSARY
C------------------------------------------------
C   --FIRST LEGEND CENTRED 21MM BELOW X AXIS
C   --VERTICAL SPACING 6MM LETTER HEIGHT 4MM
C   --ROOM FOR UP TO 30 CHARS APPROX
C   --ADJUST LETTER SIZE OF LEGENDS TO FIT SPACE XSIZE/2.0
C   --IN TWO COLUMNS IF 4 OR MORE GRAPHS
      LGLENX=0
      DO 320 JPLOT=1,NGRAPH
      LGLEN=ILGCHR(JPLOT)
      IF(LGLEN.GT.LGLENX) LGLENX=LGLEN
  320 CONTINUE
C   --5 SPACES FOR THE SYMBOL
      LGLENX=LGLENX+5
      ALGLEN=LGLENX
      XSIZE=XLEN*GSCALX
C   --ONE OR TWO COLUMNS USED
      SPACEL=0.5*XSIZE
      IF(NGRAPH.LT.4) SPACEL=2.0*SPACEL
      SIZLEG=SPACEL/ALGLEN
      IF(SIZLEG.GT.ALGSCL) SIZLEG=ALGSCL
      IF(SIZLEG.LT.2.0) SIZLEG=2.0
C###      CALL PLOT84_SCLC(SIZLEG,SIZLEG)
C###      CALL PLOT84_FONT(NFONT)
	CALL C2KFONT(SIZLEG)
C   --START DRAWING
      NSW = (NGRAPH + 1)/2
      ANSW=NSW
      IF (NGRAPH.LT.4) NSW = 4
      IF(NTEX.EQ.0) GO TO 405
      DO 400 JPLOT = 1,NGRAPH
      XSIZE=XLEN*GSCALX
      YSIZE=YLEN*GSCALY
      AJPLOT=JPLOT
C###      IF (MCOLOR .EQ. 1) CALL PLOT84_COLR(ICOLOR(JPLOT))
	IF (MCOLOR .EQ. 1) CALL C2KCOLOUR(ICOLOR(JPLOT))
      A = 0.0
      B = -(11.0 + 7.0*AJPLOT)
      IF (JPLOT .LE. NSW) GO TO 390
      A = XSIZE/2.0
      B = -(11.0 + 7.0*(AJPLOT-ANSW))
  390 CONTINUE
C###      CALL PLOT84_ANCU(A,B)
	CALL P2K_MOVE(A, B, 0.0)
CCC
      IF(LSYMB(JPLOT).LE.0) THEN
C   --SYMBOL DRAWN BETWEEN '- -' 
	    PATCH= '-'//CHSYMB(JPLOT)//'-'
C###	    CALL PLOT84_STRC(PATCH)
	CALL PLTTXT(PATCH(1:3))
C???	CALL P2K_STRING(PATCH, 3, 0.0)
      ELSE
C###	    CALL PLOT84_STRC('-')
C###	    CALL PLOT84_GSYM(LSYMB(JPLOT),1)
C###	    CALL PLOT84_SCUR(1.)
C###	    CALL PLOT84_STRC('-')
      ENDIF
CCC
      LGLEN=ILGCHR(JPLOT)
      IF (LGLEN.LE.0) GO TO 400
C###      CALL PLOT84_ANCU((A + 5.0*SIZLEG),B)
	CALL P2K_MOVE((A + 5.0*SIZLEG), B, 0.0)
      CALL PLTTXT(LEGND(JPLOT)(1:LGLEN))
  400 CONTINUE
  405 CONTINUE
C-----
  410 CONTINUE
C   --FINISH PICTURE
C###      CALL PLOT84_ENDP
	CALL P2K_PAGE
      IF(NOFLND) GO TO 120
C------------------------
C   --FINISH ALL PLOTTING
C------------------------
C###      CALL PLOT84_STOP
      STOP
      END
C***************************************************************
      SUBROUTINE CURVY_CVLI(CHLINE,CHOUT,NCHAR)
C---------------------------------------------------------------
C     A.D. MCLACHLAN JUL 1984 . LAST UPDATED 9 OCT 1984
C   --SUBROUTINE TO SCAN THROUGH INPUT (CHLINE) LOOK FOR "!"
C     ADAPTED FROM D.A. AGARD "CURVY"
C     RETURN PORTION UP TO ! IN CHOUT AND CHARACTER COUNT IN NCHAR
C     IF NO "!" FOUND THEN RETURN UP TO LEN(CHOUT) CHARACTERS     
C     AND TRIM TRAILING BLANKS
C     IF "!" THEN DO NOT TRIM 
C     NOTE!! BOTH INPUT/OUTPUT VARIABLES ARE CHARACTER VARIABLES
C-----------------------------------------------------------------
      CHARACTER*1 EXCL/'!'/
      CHARACTER*(*) CHLINE
      CHARACTER*(*) CHOUT
C-----------------------------------------------------------------
   20 FORMAT(1X,A)
   21 FORMAT(1X,I5)
C-----------------------------------------------------------------
      MAXCHR=LEN(CHOUT)
      NCHAR=0
C   --SEARCH FOR "!" IN FIRST MAXCHR+1  POSITIONS
      NBEFOR=INDEX(CHLINE,EXCL)-1
      IF(NBEFOR.GT.MAXCHR) NBEFOR=MAXCHR
C   --WHEN NO "!" 
        IF(NBEFOR.LT.0) THEN
C   --TRIM TRAILING BLANKS
          L=LENSTR(CHLINE)
          NBEFOR=MIN(L,MAXCHR)
        END IF
C   --WHEN FIRST CHARACTER IS "!" OR STRING IS BLANK RETURN NCHAR=0
      IF(NBEFOR.EQ.0) GO TO 100
C   --COPY INTO CHOUT
      CHOUT=CHLINE(1:NBEFOR)   
      NCHAR=NBEFOR
  100 CONTINUE
      RETURN
      END
C***********************************************************
      SUBROUTINE CURVY_CVSC( AMIN, AMAX, AXLEN, XLOW, DX )
C------------------------------------------------------------
C   --PLOT SCALING ROUTINE FOR DATA RANGING FROM AMIN TO AMAX
C     A.D. MCLACHLAN JULY 1984. LAST UPDATED 5 SEP 1984
C------------------------------------------------------------
C     ADAPTED FROM D.A. AGARD "CURVY" 1982
C     CURVY_CVSC SELECTS THE 'NICEST?' POSSIBLE XLOW & DX FOR AXIS
C     LENGTH AXLEN, USING INTEGER PART OF AXLEN TO DRAW ON
C     THIS ROUTINE USES THE GREATEST INTEGER ROUTINE CURVY_CFIX(R,I)
C-----------------------------------------------------------
      DATA NDM/11/
      REAL DMC(11)/1.0,1.25,1.5,2.0,2.5,3.0,
     1             4.0,5.0,6.0,8.0,10.0/
C---------------------------------------------------------------
   20 FORMAT(1X,' !!!CURVY_CVSC ARGUMENT ERROR:'
     1    /1X,' AMIN=',E14.5,' AMAX= ',E14.5,' AXLEN= ',F10.4)
C---------------------------------------------------------------
      IF (AXLEN.EQ.0) GO TO 100
C   --THE PLOT AXIS IS OF LENGTH "AXLEN" GRAPH UNITS
C   --"NXLEN" IS THE NUMBER OF COMPLETE SEGMENTS ALONG THE AXIS 
C   --"(NXLEN+1)" TICK MARKS WILL BE DRAWN
      NXLEN=AXLEN
      AXL = NXLEN
C   --"DEL" IS THE RANGE OF "X" COVERED BY ONE SEGMENT
      DEL = 0.99*(AMAX - AMIN)/AXL
      IF (DEL .GT. 0.0) GO TO 150
  100 CONTINUE
      WRITE(6,20) AMIN,AMAX,AXLEN
      XLOW = 0.0
      DX = 1.0
      GO TO 500
C----------------------------
  150 CONTINUE
      DL = ALOG10(DEL)
      CALL CURVY_CFIX(DL,IPOW10)
      POW10 = IPOW10
      DECFAC = 10.0**POW10
      DM = DEL/DECFAC
C   --"DM" IS A NUMBER BETWEEN 1.0 AND 9.99 GOT BY SCALING OFF
C   --"POW10" POWERS OF 10.0 FROM "DEL"
C   --"DX" IS A NICE VALUE FOR THE RANGE, JUST ABOVE "DM" IN SIZE
C   --SELECT NICE DX
      JD = 1
C   --SEARCH FOR DEMARCATION VALUE JUST ABOVE DM
  200 CONTINUE
      IF (DM .LE. DMC(JD)) GO TO 300
      JD = JD + 1
      GO TO 200
C   --COMPUTE NICE XLOW
C   --"XLOW" IS A MULTIPLE OF "DX" JUST BELOW THE OBSERVED "AMIN" AND IS
C   --THE VALUE OF "X" TO ALIGN WITH THE ORIGIN TICK MARK
C   --"XHIGH" IS THE VALUE OF "X" TO PLOT AT THE LAST TICK MARK
C   --AND WE SHOULD HAVE "XHIGH" .GE. "AMAX"
  300 CONTINUE
      DX = DMC(JD)*DECFAC
      CALL CURVY_CFIX((AMIN/DX),ILOW)
      XLOW = FLOAT(ILOW)*DX
      XHIGH= FLOAT(ILOW+NXLEN)*DX
      XREM = XHIGH - AMAX 
      CALL CURVY_CFIX((XREM/DX),IREM)
C   --MUST INCREASE DX & REDO XLOW?
      IF (XREM .GE. (-DEL*.01)) GO TO 400
C   --INCREASE DX. IF AT END OF RANGE GO TO NEXT POWER OF 10.0
      JD = JD + 1
      IF (JD .LE. NDM) GO TO 300
      JD = 2
      DECFAC = DECFAC*10.0
      GO TO 300
C   --CENTRE PLOT ON AXIS
  400 CONTINUE
      XLOW = XLOW - FLOAT(IREM/2)*DX
      IF ((AMIN .GT.0.5*DX).OR.
     1    (AMIN .LT.-0.1*DX)) GO TO 500
      XLOW = 0.0
  500 CONTINUE
      RETURN
      END
C****************************************************
      SUBROUTINE CURVY_CFIX(REEL,IFIXI)
C----------------------------------------------------
C   --GREATEST INTEGER FUNCTION
      IFIXI = IFIX(REEL)
      IF((REEL - FLOAT(IFIXI)).LT.0.0) IFIXI=IFIXI - 1
      RETURN
      END
C************************************************
      SUBROUTINE CURVY_CVLF(CARD,XNUM,NFIELDS)
C-----------------------------------------------
C   --SUBROUTINE TO DO FREE-FORMAT CONVERSION
C     A.D. MCLACHLAN JULY 1984. REVISED 4 SEP 1984.
C-----------------------------------------------
      CHARACTER*1 ASTER,BLANK
      CHARACTER*(*) CARD
      DIMENSION XNUM(*)
      DATA ASTER,BLANK/'*',' '/
C-----------------------------------------------
C*al   20 FORMAT(G<NPOINT>.0)
   20 FORMAT(G10.0)
C-----------------------------------------------
      NCHAR=LEN(CARD)
      DO 100 I=1,20
      XNUM(I)=0.0
  100 CONTINUE
      NFIELDS=0
C   --SEARCH FOR STARTING POINT
      ISTART = 1
        DO WHILE ((CARD(ISTART:ISTART).EQ.BLANK)
     1            .AND.(ISTART.LT.NCHAR))
          ISTART=ISTART+1
        END DO
C   --DECODE FIELDS IN G FORMAT
        DO WHILE (ISTART.LT.NCHAR)
          NFIELDS=NFIELDS+1
          NPOINT=INDEX(CARD(ISTART:),BLANK)-1
	  IF(NPOINT.LT.0) NPOINT=NCHAR-ISTART+1
          IEND=ISTART+NPOINT-1
CTSH          DECODE(NPOINT,20,CARD(ISTART:IEND)) XNUM(NFIELDS)
CTSH++
          READ(CARD(ISTART:IEND),20) XNUM(NFIELDS)
CTSH--
          ISTART=IEND+2
C   --SKIP OVER REPEATED BLANKS
          DO WHILE ((CARD(ISTART:ISTART).EQ.BLANK).
     1               AND.(ISTART.LT.NCHAR))
            ISTART=ISTART+1
          END DO
        END DO
C---
      RETURN
      END
C
C
C***************************************************************************
      SUBROUTINE DASHED(M,R,D,T)
C     ===========================
C  MODE =0 SOLID LINE
C   MODE=1 DASHED LINE (DOT DUMMY PARAMETER)
C   MODE=2  CHAINED LINE
C  REPEAT DASH DOT  ARE IN CURRENT UNITS  DEFAULT IS MMS.
      COMMON /DASH/ LPT,MODE,REPEAT,DASH,DOT,A1,B1
C
      MODE=M
      REPEAT=R
      DASH=D
      DOT=T
      LPT=0
      RETURN
      END
C
C*********************************************************************
C
      SUBROUTINE LINES(X,Y,NPT)
C     =========================
C
C DRAW LINES TO JOIN NPT POINTS X,Y
      DIMENSION X(NPT),Y(NPT)
C
      COMMON /DASH/ LPT,MODE,REPEAT,DASH,DOT,A1,B1
      DATA SMALL/0.001/
C
C MODE =0 FOR SOLID LINES
      IF(NPT.LE.1) RETURN
      IF(MODE.GT.0) GO TO 10
C
C SOLID
C###      CALL PLOT84_MVTO(X(1),Y(1))
	CALL P2K_MOVE(X(1),Y(1), 0.0)
      DO 1 I=2,NPT
C###1     CALL PLOT84_DWTO(X(I),Y(I))
	CALL P2K_DRAW(X(I),Y(I), 0.0)
1     CONTINUE
      RETURN
C
C
C DASHED LINES, REPEAT IS REPEAT LENGTH, DASH IS DASH LENGTH
C DOT IS DUMMY (NO CHAIN LINES)
10    GAP=REPEAT-DASH
      A=DASH
      B=GAP
C LPT=0 IF 1ST CALL SINCE CALL TO S/R DASHED, OTHERWISE KEEP DASHES IN PHASE
      IF(LPT.EQ.0) GO TO 11
      A=A1
      B=B1
C
11    LPT=1
      X1=X(1)
      Y1=Y(1)
      I=2
C###      CALL PLOT84_MVTO(X1,Y1)
	CALL P2K_MOVE(X(1),Y(1), 0.0)
C
C COME HERE FOR NEW LINE
15    X2=X(I)
      Y2=Y(I)
      DX=X2-X1
      DY=Y2-Y1
      D=SQRT(DX*DX+DY*DY)
      IF(D.LT.SMALL) GO TO 30
      DX=DX/D
      DY=DY/D
      R=D
      A1=0.
      B1=0.
      J=-1
C
C R IS REMAINING LINE LENGTH
C COME HERE FOR EACH DASH REPEAT
20    IF(R.LT.(A+B)) GO TO 25
      IF(J) 26,26,27
C
C LAST BIT, GET REMAINING DASH LENGTH
25    IF(R.LT.A) GO TO 21
C LAST PART IS IN GAP
      A1=0.
      B1=B-R+A
      B=R-A
      GO TO 22
C LAST PART IS IN DASH
21    A1=A-R
      B1=GAP
      A=R
      B=0.
22    J=-2
C
26    J=J+1
      XD=A*DX
      YD=A*DY
      XG=B*DX
      YG=B*DY
C
27    CONTINUE
C###27    IF(A.GT.SMALL) CALL PLOT84_DWBY(XD,YD)
C###C<<<<<PLOT84 CALL>>>>>>
C###      IF(B.GT.SMALL) CALL PLOT84_MVBY(XG,YG)
      R=R-A-B
      IF(J) 30,28,20
C RESET DASH LENGTH AFTER 1ST REPEAT
28    A=DASH
      B=GAP
      J=0
      GO TO 20
C
C END OF LINE, RESTORE UNUSED DASH LENGTH
30    I=I+1
      IF(I.GT.NPT) RETURN
      X1=X2
      Y1=Y2
      A=A1
      B=B1
      GO TO 15
C
      END
C
C
      SUBROUTINE PLTTXT(TEXT)
C     =====================================
C
C Plot TEXT at current position, character size CXSIZE,CYSIZE
C Process string for control characters  cntrlA to cntrlD, these change
C to font 1 - 4 for one character, then revert to current font
C
	common nfont,fontsize

      CHARACTER*(*) TEXT
C
      NC=LENSTR(TEXT)
      I1=1
      I=I1
C
10    JC=ICHAR(TEXT(I:I))
      IF(JC.GE.1.AND.JC.LE.4) THEN
C Control character found, draw text up to here
	    IF(I.GT.I1) THEN
	      CALL P2K_STRING(TEXT(I1:I), I-I1+1, 0.0)
C###		  CALL PLOT84_STRS(TEXT(I1:I),CXSIZE,CYSIZE)
	    ENDIF
C  Plot next character in new font (seems to be all Greek to me... tsh)
	    I=I+1
	    IF(I.GT.NC) RETURN
	      ITEMPFONT=NFONT
	      NFONT=4
	      CALL C2KFONT(FONTSIZE)
	      CALL P2K_STRING(TEXT(I:I), 1, 0.0)
C###	    CALL PLOT84_GCHS(TEXT(I:I),-0.5,-0.5,CXSIZE,CYSIZE,JC)
	    I1=I+1
      ENDIF
      I=I+1
      IF(I.LE.NC) GO TO 10
C
c  put font back
	NFONT=ITEMPFONT
	CALL C2KFONT(FONTSIZE)
C Plot last string
C###      IF(I1.LE.NC)CALL PLOT84_STRS(TEXT(I1:NC),CXSIZE,CYSIZE)
	CALL P2K_STRING(TEXT(I1:NC), NC-I1+1, 0.0)
      RETURN
      END
C
C
C
C***********************************************************************
      SUBROUTINE GSCVAX(X,Y,LABEL,NSIDE,NTEX,
     1    AXLEN,GSCALE,ANGLE,FVAL,DV)
C-----------------------------------------------------------------------
C   --DRAW AXES WITH LABELS FOR GRAPHS
C     A.D. MCLACHLAN SEPT 1984. LAST UPDATED 12 NOV 1984.
C     ADAPTED FROM D.A. AGARD PLOT82
C----------------------------------------------------------------------- 
C             (X,Y) = STARTING COORDINATES FOR AXIS GENERATION (REAL)
C             LABEL = CHARACTER TEXT STRING FOR LABELING THE AXIS
C             NSIDE = +1 OR -1
C                   = + = ANNOTATIONS GENERATED ABOVE AXIS
C                   = - = ANNOTATIONS GENERATED BELOW AXIS
C             NTEX  = 0 DO NOT, ELSE DO PLOT LABELS AND TIC NUMBERS ALONG AXIS
C             AXLEN = AXIS LENGTH IN GRAPH UNITS (REAL)
C                     AXIS IS MARKED EVERY 1.0 GRAPH UNITS 
C             GSCALE= VALUE OF 1 GRAPH UNIT IN USER UNITS (EXPECTED TO BE MM) 
C                     NO VALUE NUMBERS DRAWN IF GSCALE.LT.10.0
C             ANGLE = ANGLE IN DEGREES AT WHICH AXIS IS DRAWN (REAL)
C             FVAL = FIRST ANNOTATION VALUE (REAL)
C             DV = DELTA ANNOTATION VALUE (REAL)
C
C	CHARACTER HEIGHT IS AUTOMATICALLY SET TO BE INDEPENDENT OF GLOBAL
C       SCALE UNLESS IT IS TOO LARGE TO GO ON AXES
C       CHARACTER FOUNT IS NOT SET HERE
C------------------------------------------------------------------------
      DIMENSION NTRSAV(48)
C------------------------------------------------------------------------
      CHARACTER*(*) LABEL
C------------------------------------------------------------------------
C   --REMOVE TRAILING BLANKS FROM LABEL
C   --MAX 40 CHARACTERS TO PLOT 5MM WIDE
      LABLEN=LEN(LABEL)
        DO WHILE(INDEX(LABEL(LABLEN:LABLEN),' ').EQ.1)
          LABLEN=LABLEN-1
        END DO
      IF(LABLEN.GT.40) LABLEN=40
C-----        
  100 CONTINUE
      PI=4.0*ATAN2(1.0,1.0)
      ANGFAC=PI/180.0
C   --SAVE CURRENT CHARACTER AND USER SCALING
C###      CALL PLOT84_TSAV(NTRSAV)
C   --DECOUPLE CHARACTER SCALING FROM USER SCALE
C   --SET UP SCALE FOR CHARACTERS
C   --THIS SCALING RESULTS IN  A UNIT HGT=1.0 MM
C   --FOR LETTER SIZES INDEPENDENT OF USER SCALE "USCALY" . 
      HGT = 1.0
C###      CALL PLOT84_TLNK(0)
C###      CALL PLOT84_ORGC(0.0,0.0)
C###      CALL PLOT84_SCLC(HGT,HGT)
      THETA=ANGLE*ANGFAC
C###      CALL PLOT84_CROT(THETA,THETA+PI/2.0)
C   --CENTRED CHARACTERS WITH UNIFORM SPACING
C###      CALL PLOT84_CENC(1)
C###      CALL PLOT84_CSPU(1)
C   --CHOOSE WHICH SIDE OF AXIS TO ANNOTATE AND LABEL
      SIDE = +1.0
      IF(NSIDE.LT.0) SIDE= -1.0
C--------------------------------------------------------------------
C   --THIS SECTION TRIES TO RESCALE DV INTO A RANGE FROM 0.01 TO 99.0
C--------------------------------------------------------------------
C   --DETERMINE VALUE OF 'DV' EXPONENT
  110 CONTINUE
      EXPDV = 0.0
      ADV = ABS (DV)
C   --ZERO DELTA ANNOTATION VALUE?
      IF (ADV.EQ.0.) GO TO 500
C   --'DV' EXPONENT CALCULATION COMPLETED?
  200 CONTINUE
C   --DIVIDE BY 10.0 TILL LT. 99.0 
      IF(ADV.LT.99.) GO TO 400
      ADV = ADV/10.
      EXPDV = EXPDV + 1.
      GO TO 200
C   --MULTIPLY BY 10.0 TILL GE. 0.01
  300 CONTINUE
      ADV = ADV*10.
      EXPDV = EXPDV - 1.
C   --'DV' EXPONENT CALCULATION COMPLETED?
  400 CONTINUE
      IF(ADV.LT.0.01) GO TO 300
C--
C   --COMPUTE NORMALIZED 'FVAL' AND 'DV' SCALED BY (10**-EXPDV)
  500 CONTINUE
      VAL = FVAL*(10.**(-EXPDV))
      ADV = DV*(10.**(-EXPDV))
      EXABS=ABS(EXPDV)+0.5
      IEXPDV=EXABS
      IF(EXPDV.LT.0) IEXPDV=-IEXPDV
C   --CHECK NUMBER OF DIGITS AFTER DECIMAL POINT
      NTIC = AXLEN + 1.0
      JDIG = 2
      QMAX = (NTIC-1)*ADV + VAL
      IF (QMAX.GT.99.99) JDIG = 1
      IADV = ADV
      IVAL = VAL
      IF ((ADV.EQ.IADV).AND.(IVAL.EQ.VAL)) JDIG = 0
C-----------------------------------------
C   --SET UP POSITIONING CONSTANTS FOR NUMBERS
C-----------------------------------------
      SINA = SIN (THETA)
      COSA = COS (THETA)
C   --NUMBERS LEFT JUSTIFIED AND 7.0 MM ABOVE/BELOW AXIS SIZE 4MM
C   --NUMBERS OFFSET BY 4MM TO LEFT
      DX = -4.0*HGT
      DY = 7.0*SIDE*HGT
      XX = X + DX*COSA - DY*SINA
      YY = Y + DY*COSA + DX*SINA
C   --ANNOTATE AXIS IN GRAPH UNITS 1.0 UNITS AT A STEP
      NJUST=1
      NAFTER=JDIG
      NDIGIT=JDIG   
      SIZE=4.0
C   --ADJUST SIZE IF NECESSARY TO ALLOW 5 DIGITS AND A SPACE TO EACH SEGMENT
C   --BUT DO NOT GO BELOW 2.0MM
C   --NO VALUES DRAWN IF GSCALE.LT.10.0
      SZMAX=GSCALE/6.0
      SZMIN=2.0
      IF(SIZE.GT.SZMAX)SIZE=SZMAX
      IF(SIZE.LT.SZMIN)SIZE=SZMIN
C###C%%   CALL PLOT84_FONT(1)
      IF(GSCALE.LT.10.0) GO TO 610
      IF(NTEX.EQ.0) GO TO 610
      DO 600 I=1,NTIC
C###      CALL PLOT84_ANCU(XX,YY)
C###      CALL PLOT84_FNUM(VAL,NDIGIT,NAFTER,SIZE,SIZE,NJUST)
      VAL = VAL + ADV
      XX = XX + COSA*GSCALE
      YY = YY + SINA*GSCALE
  600 CONTINUE
  610 CONTINUE 
      IF(NTEX.EQ.0) GO TO 700
      IF(LABLEN.LE.0) GO TO 700
C   --LABEL AXIS WITH LABLEN CHARACTERS AND POSSIBLY THE EXPDV VALUE
      ANL = LABLEN
C   --DOES 'DV' EXPONENT EXIST?
      IF (IEXPDV.NE.0) ANL = LABLEN + 5
C   --CENTRE THE LABEL
C   --LETTERS 5MM HIGH  CENTRED 14MM ABOVE/BELOW AXIS
      SIZE=5.0
C   --SHRINK LETTERS IF TOO BIG TO FIT ALLOWED SPACE
C   --ALLOW SPACE OF 80% AXIS LENGTH
      SPACL=0.8*AXLEN*GSCALE
      SIZL=SPACL/ANL
      IF(SIZL.LT.5.0) SIZE=SIZL
      IF(SIZE.LT.2.0) SIZE=2.0
      WIDL=SIZE*ANL
      DX = 0.5*(AXLEN*GSCALE) -0.5*WIDL*HGT 
      DY = 14.0*SIDE*HGT
      XX = X + DX*COSA - DY*SINA
      YY = Y + DY*COSA + DX*SINA
C###      CALL PLOT84_ANCU(XX,YY)
      CALL PLTTXT(LABEL)
C   --NO 'DV' EXPONENT TO PLOT?
      
      IF((GSCALE.LT.10.0).OR.(IEXPDV.EQ.0)) GO TO 700
C   --PLOT EXPONENT LABEL '  *10'
C###      CALL PLOT84_STRS('  *10',SIZE,SIZE)
C   --PLOT VALUE OF EXPONENT AS SUPERSCRIPT 13MM ABOVE/BELOW AXIS SIZE 3MM
      XX = XX + (WIDL*COSA - 1.0*SINA)*HGT
      YY = YY + (WIDL*SINA + 1.0*COSA)*HGT
C   --PLOT -IEXPDV  
C   --LABEL VALUES MULTIPLIED BY 10.0**-IEXPDV GIVE TRUE VALUES
C###      CALL PLOT84_ANCU(XX,YY)
      NJUST=1
      NDIGIT=1
      SIZE=SIZE*0.6
      IF(SIZE.LT.2.0)SIZE=2.0
C###      CALL PLOT84_INUM(-IEXPDV,NDIGIT,SIZE,SIZE,NJUST)
C   --DRAW AXIS AND TIC MARKS NORMALLY 3MM LONG
  700 CONTINUE
      DX = -3.0*SIDE*SINA*HGT
      DY = +3.0*SIDE*COSA*HGT
      XX = X - COSA*GSCALE
      YY = Y - SINA*GSCALE
C###      CALL PLOT84_MVTO(X,Y)
      DO 800 I=1,NTIC
      XX = XX + COSA*GSCALE
      YY = YY + SINA*GSCALE
C###      CALL PLOT84_DWTO(XX,YY)
C###      CALL PLOT84_MVTO(XX+DX,YY+DY)
C###      CALL PLOT84_DWTO(XX,YY)
  800 CONTINUE
C   --DRAW LAST BIT OF AXIS IF REQUIRED
      XX=X+(AXLEN*GSCALE)*COSA
      YY=Y+(AXLEN*GSCALE)*SINA
C###      CALL PLOT84_DWTO(XX,YY)
C   --RESTORE CHARACTER SCALE
C###      CALL PLOT84_TRES(NTRSAV)
      RETURN
      END

	SUBROUTINE C2KFONT(SIZE)
	common nfont,fontsize
C  Base size for text = 5mm high
	DATA BASE_SIZE/1/
	FONTSIZE=SIZE
C  select font
C  font 0 = caps-only
C	IF (NFONT.EQ.0)
	IF(NFONT.EQ.0) then
	  CALL P2K_FONT('Helvetica'//CHAR(0),SIZE*BASE_SIZE)
	ENDIF
C  font 1 = normal
	IF(NFONT.EQ.1) then
	  CALL P2K_FONT('Helvetica'//CHAR(0),SIZE*BASE_SIZE)
	ENDIF
C  font 2 = italic
	IF(NFONT.EQ.2) then
	  CALL P2K_FONT('Helvetica-Oblique'//CHAR(0),SIZE*BASE_SIZE)
	ENDIF
C  font 3 = script (not available in postscript. use italic)
	IF(NFONT.EQ.3) then
	  CALL P2K_FONT('Helvetica-Oblique'//CHAR(0),SIZE*BASE_SIZE)
	ENDIF
C  font 4 = greek
	IF(NFONT.EQ.4) then
	  CALL P2K_FONT('Symbol'//CHAR(0),SIZE*BASE_SIZE)
	ENDIF
	RETURN
	END


      SUBROUTINE C2KCVAX(X0,Y0,LABEL,NSIDE,NTEX,
     1                       AXLEN,GSCALX,ANGLE,FVAL,DV)
	CHARACTER*(*)	LABEL
	CHARACTER	TEMPSTR*80
	CHARACTER	TEMPEXP*10
	A4WIDTH_IN_MM=209
	AXLEN_MM=A4WIDTH_IN_MM/2

	CALL P2K_MOVE(X0,Y0,0.0)
	CALL P2K_HERE
	CALL P2K_TWIST(ANGLE, ANGLE+90, 0.0)
C  set the scales so that one user unit = GSCAL mm
	CALL P2K_GRID(0.5*A4WIDTH_IN_MM/GSCALX, 1.0, 1.0)
	CALL P2K_LWIDTH(0.4)
	CALL P2K_DRAW(AXLEN, 0.0, 0.0)
	X=0.0
	XVAL=FVAL
c	type *,xval,dv
C  Scale tick-label abs values to range .01 - 99
	IEXP=0
	ABSDV=ABS(DV)
	DO WHILE (ABSDV .LT. 0.01)
	  ABSDV=ABSDV*10.
	  IEXP=IEXP-1
	END DO
	DO WHILE (ABSDV .GT. 99.0)
	  ABSDV=ABSDV/10.0
	  IEXP=IEXP+1
	END DO
	DV=DV/(10.0**IEXP)
	XVAL=XVAL/(10.0**IEXP)
C  tick font is 4.0 mm
	CALL C2KFONT(4.0)
C  Draw tick-marks
	DO I=1,AXLEN+1
	  CALL P2K_MOVE(X, 0.0, 0.0)
C  set grid to mm.
	  CALL P2K_GRID(1.0, A4WIDTH_IN_MM/2, 1.0)
	  CALL P2K_HERE
	  CALL P2K_DRAW(0.0, 2.0*NSIDE, 0.0)
C  write tick label if necessary
	  IF (GSCALX.GE.10.0 .AND. NTEX.NE.0) THEN
	    IF (NSIDE.GT.0) CALL P2K_MOVE(0.0, 2.0, 0.0)
	    IF (NSIDE.LT.0) CALL P2K_MOVE(0.0, -5.0, 0.0)
c	type *,xval,dv,iexp
	    IF (ABS(XVAL).GT.9.) THEN
	      WRITE(TEMPSTR,FMT='(F5.1)') XVAL
	    ELSE IF (ABS(XVAL).GT.0.9) THEN
	      WRITE(TEMPSTR,FMT='(F5.2)') XVAL
	    ELSE
	      WRITE(TEMPSTR,FMT='(F5.3)') XVAL
	    END IF
	    J=1
	    DO WHILE (TEMPSTR(J:J).EQ.' ')
	      J=J+1
	    END DO
CCC  drop any leading zero
CC	  IF (TEMPSTR(J:J+1).EQ.'0.') J=J+1
	  CALL P2K_STRING(TEMPSTR(J:8), 8-J+1, 0.0)
	  END IF
	  CALL P2K_ROR
	  CALL P2K_RGR
cc	  X=X+GSCALX
	  X=X+1.0
	  XVAL=XVAL+DV
	END DO	  
C  Draw axis label centred on axis centre
	IF (NTEX.NE.0) THEN
	  CALL C2KFONT(5.0)
cc	  CALL P2K_MOVE(GSCALX*AXLEN/2, 0.0, 0.0)
	  CALL P2K_MOVE(AXLEN/2, 0.0, 0.0)
	  CALL P2K_HERE
          CALL P2K_GRID(1.0, A4WIDTH_IN_MM/2, 1.0)
C  leave space for the tick labels
	  X=9.0*NSIDE
C  If the text is below the axis, add a bit of extra
C  space for the height of the font (5 mm)
	  IF (NSIDE.LT.0) X=X-3
	  CALL P2K_MOVE(0.0, X, 0.0)
	  TEMPSTR=LABEL
C  append any exponent expression to the label
	  IF (IEXP.NE.0) THEN
	    WRITE(TEMPEXP,FMT='(I3)') IEXP
C  strip leading spaces from exponent string
	     I=1
	     DO WHILE (TEMPEXP(I:I).EQ.' ')
	       I=I+1
	     END DO
	     TEMPSTR=TEMPSTR(1:MYLNBLNK(TEMPSTR))//' (* by 10**'//TEMPEXP(I:3)//')'
	  END IF
	  CALL P2K_CSTRING(TEMPSTR, MYLNBLNK(TEMPSTR), 0.0)
	  CALL P2K_RGR
	  CALL P2K_ROR
	END IF

	CALL P2K_ROR
	CALL P2K_RTW
	CALL P2K_RGR
	RETURN
	END

	INTEGER FUNCTION MYLNBLNK(STRING)
	CHARACTER	STRING*(*)
	DO I=LEN(STRING),1,-1
	  IF (STRING(I:I).NE.' ') GOTO 10
	END DO
10	MYLNBLNK=I
	RETURN
	END

	SUBROUTINE C2KCOLOUR(ICOLOUR)
C  map curvy colours on to P2K colours
	INTEGER C2KCOLOURS(9)
	DATA C2KCOLOURS/0,2,5,6,4,3,7,0,0/
	CALL P2K_COLOUR(C2KCOLOURS(ICOLOUR))
	RETURN
	END

	SUBROUTINE C2KSYMBOL(NSYMB,ISIZE)
	RETURN
	END
