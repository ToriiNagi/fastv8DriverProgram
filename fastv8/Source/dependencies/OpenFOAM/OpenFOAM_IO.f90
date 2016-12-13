!**********************************************************************************************************************************
! LICENSING
! Copyright (C) 2015-2016  National Renewable Energy Laboratory
!
!    This file is part of AeroDyn.
!
! Licensed under the Apache License, Version 2.0 (the "License");
! you may not use this file except in compliance with the License.
! You may obtain a copy of the License at
!
!     http://www.apache.org/licenses/LICENSE-2.0
!
! Unless required by applicable law or agreed to in writing, software
! distributed under the License is distributed on an "AS IS" BASIS,
! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
! See the License for the specific language governing permissions and
! limitations under the License.
!
!**********************************************************************************************************************************
! File last committed: $Date$
! (File) Revision #: $Rev$
! URL: $HeadURL$
!**********************************************************************************************************************************
MODULE OpenFOAM_IO
 
   use NWTC_Library
   use OpenFOAM_Types

   implicit none

   INTEGER(IntKi), PARAMETER        :: MaxBl    =  3                                   ! Maximum number of blades allowed in simulation
   
contains
   
!----------------------------------------------------------------------------------------------------------------------------------
SUBROUTINE ReadInputFiles( InputFileName, m_OpFM, NumBlades, ErrStat, ErrMsg )
! This subroutine reads the AeroDyn input file and stores all the blade properties data in the OpFM_MiscVar data structure.
! It does not perform data validation. Since AeroDyn reads this file first, the data should be valid when the OpenFOAM module reads it.
!..................................................................................................................................

      ! Passed variables
   CHARACTER(*),            INTENT(IN)    :: InputFileName   ! Name of the input file
   TYPE(OpFM_MiscVarType),  INTENT(INOUT) :: m_OpFM          ! This contains the variable to store the blade properties
   INTEGER(IntKi),          INTENT(IN)    :: NumBlades       ! Number of blades for this model
   INTEGER(IntKi),          INTENT(OUT)   :: ErrStat         ! The error status code
   CHARACTER(*),            INTENT(OUT)   :: ErrMsg          ! The error message, if an error occurred

      ! local variables

   INTEGER(IntKi)                         :: I
   INTEGER(IntKi)                         :: ErrStat2        ! The error status code
   CHARACTER(ErrMsgLen)                   :: ErrMsg2         ! The error message, if an error occurred

   CHARACTER(1024)                        :: ADBlFile(MaxBl) ! File that contains the blade information (specified in the primary input file)
   CHARACTER(*), PARAMETER                :: RoutineName = 'ReadInputFiles'
   
   
      ! initialize values:

   ErrStat = ErrID_None
   ErrMsg  = ''

      ! get the  ADBlFile info from the primary/platform input-file data
   
   CALL ReadPrimaryFile( InputFileName, NumBlades, ADBlFile, ErrStat2, ErrMsg2 )
      CALL SetErrStat(ErrStat2,ErrMsg2, ErrStat, ErrMsg, RoutineName)
      IF ( ErrStat >= AbortErrLev ) THEN
         CALL Cleanup()
         RETURN
      END IF
      

      ! get the blade input-file data
      
   ALLOCATE( m_OpFM%BladeProps( NumBlades ), STAT = ErrStat2 )
   IF (ErrStat2 /= 0) THEN
      CALL SetErrStat(ErrID_Fatal,"Error allocating memory for BladeProps.", ErrStat, ErrMsg, RoutineName)
      CALL Cleanup()
      RETURN
   END IF
      
   DO I=1,NumBlades
      CALL ReadBladeInputs ( ADBlFile(I), m_OpFM%BladeProps(I), -1, ErrStat2, ErrMsg2 )
         CALL SetErrStat(ErrStat2,ErrMsg2, ErrStat, ErrMsg, RoutineName//TRIM(':Blade')//TRIM(Num2LStr(I)))
         IF ( ErrStat >= AbortErrLev ) THEN
            CALL Cleanup()
            RETURN
         END IF
   END DO
   
      

   CALL Cleanup ( )


CONTAINS
   !...............................................................................................................................
   SUBROUTINE Cleanup()
   ! This subroutine cleans up before exiting this subroutine
   !...............................................................................................................................

   END SUBROUTINE Cleanup

END SUBROUTINE ReadInputFiles
!----------------------------------------------------------------------------------------------------------------------------------
SUBROUTINE ReadPrimaryFile( InputFile, NumBlades, ADBlFile, ErrStat, ErrMsg )
! This routine reads in the primary AeroDyn input file and fills in the name of the blade properties file for each blade in ADBlFile
!..................................................................................................................................


   implicit                        none

      ! Passed variables
   integer(IntKi),     intent(out)     :: ErrStat                             ! Error status

   character(*),       intent(out)     :: ADBlFile(MaxBl)                     ! name of the files containing blade inputs
   character(*),       intent(in)      :: InputFile                           ! Name of the file containing the primary input data
   INTEGER(IntKi),     intent(in)      :: NumBlades                           ! Number of blades for this model

   character(*),       intent(out)     :: ErrMsg                              ! Error message
   
      ! Local variables:
   integer(IntKi)                :: I                                         ! loop counter
   integer(IntKi)                :: UnIn                                      ! Unit number for reading file
   integer(IntKi)                :: nAFfiles                                  ! number of airfoil files
     
   integer(IntKi)                :: ErrStat2, IOS                             ! Temporary Error status
   logical                       :: Echo                                      ! Determines if an echo file should be written
   character(ErrMsgLen)          :: ErrMsg2                                   ! Temporary Error message
   character(1024)               :: PriPath                                   ! Path name of the primary file
   character(*), parameter       :: RoutineName = 'ReadPrimaryFile'
   
   
      ! Initialize some variables:
   ErrStat = ErrID_None
   ErrMsg  = ""
      
   CALL GetPath( InputFile, PriPath )     ! Input files will be relative to the path where the primary input file is located.
   
      ! Get an available unit number for the file.

   CALL GetNewUnit( UnIn, ErrStat2, ErrMsg2 )
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )

      ! Open the Primary input file.

   CALL OpenFInpFile ( UnIn, InputFile, ErrStat2, ErrMsg2 )
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
      IF ( ErrStat >= AbortErrLev ) THEN
         CALL Cleanup()
         RETURN
      END IF
      
   ! Read the lines up/including to the "Echo" simulation control variable
   ! If echo is FALSE, don't write these lines to the echo file. 
   ! If Echo is TRUE, rewind and write on the second try.
   
   !----------- HEADER -------------------------------------------------------------
   
   READ(UnIn,*)
   
   READ(UnIn,*)
  
   
   !----------- GENERAL OPTIONS ----------------------------------------------------
   
   READ(UnIn,*)
   
   
   READ(UnIn,*)
   
      ! DTAero - Time interval for aerodynamic calculations {or default} (s):
   READ(UnIn,*)
      
      ! WakeMod - Type of wake/induction model {0=none, 1=BEMT} (-):
   READ(UnIn,*)

      ! AFAeroMod - Type of airfoil aerodynamics model {1=steady model, 2=Beddoes-Leishman unsteady model} (-):
   READ(UnIn,*)

      ! TwrPotent - Type tower influence on wind based on potential flow around the tower {0=none, 1=baseline potential flow, 2=potential flow with Bak correction} (switch) :
   READ(UnIn,*)

      ! TwrShadow - Calculate tower influence on wind based on downstream tower shadow? (flag) :
   READ(UnIn,*)
      
      ! TwrAero - Calculate tower aerodynamic loads? (flag):
   READ(UnIn,*)
      
      ! FrozenWake - Assume frozen wake during linearization? (flag):
   READ(UnIn,*)
      
   !----------- ENVIRONMENTAL CONDITIONS -------------------------------------------
   READ(UnIn,*)
      
      ! AirDens - Air density (kg/m^3):
   READ(UnIn,*)

      ! KinVisc - Kinematic air viscosity (m^2/s):
   READ(UnIn,*)

      ! SpdSound - Speed of sound (m/s):
   READ(UnIn,*)
      
   !----------- BLADE-ELEMENT/MOMENTUM THEORY OPTIONS ------------------------------
   READ(UnIn,*)

      ! SkewMod - Type of skewed-wake correction model {1=uncoupled, 2=Pitt/Peters, 3=coupled} [used only when WakeMod=1] (-):
   READ(UnIn,*)

      ! TipLoss - Use the Prandtl tip-loss model? [used only when WakeMod=1] (flag):
   READ(UnIn,*)

      ! HubLoss - Use the Prandtl hub-loss model? [used only when WakeMod=1] (flag):
   READ(UnIn,*)

      ! TanInd - Include tangential induction in BEMT calculations? [used only when WakeMod=1] (flag):
   READ(UnIn,*)

      ! AIDrag - Include the drag term in the axial-induction calculation? [used only when WakeMod=1] (flag):
   READ(UnIn,*)

      ! TIDrag - Include the drag term in the tangential-induction calculation? [used only when WakeMod=1 and TanInd=TRUE] (flag):
   READ(UnIn,*)

      ! IndToler - Convergence tolerance for BEM induction factors (or "default"] [used only when WakeMod=1] (-):
   READ(UnIn,*)
         
      ! MaxIter - Maximum number of iteration steps [used only when WakeMod=1] (-):
   READ(UnIn,*)
      
   !----------- BEDDOES-LEISHMAN UNSTEADY AIRFOIL AERODYNAMICS OPTIONS -------------
   READ(UnIn,*)
      
      ! UAMod - Unsteady Aero Model Switch (switch) {1=Baseline model (Original), 2=Gonzalez�s variant (changes in Cn,Cc,Cm), 3=Minemma/Pierce variant (changes in Cc and Cm)} [used only when AFAreoMod=2] (-):
   READ(UnIn,*)

      ! FLookup - Flag to indicate whether a lookup for f� will be calculated (TRUE) or whether best-fit exponential equations will be used (FALSE); if FALSE S1-S4 must be provided in airfoil input files [used only when AFAreoMod=2] (flag):
   READ(UnIn,*)
      
   !----------- AIRFOIL INFORMATION ------------------------------------------------
   READ(UnIn,*)


      ! InCol_Alfa - The column in the airfoil tables that contains the angle of attack (-):
   READ(UnIn,*)

      ! InCol_Cl - The column in the airfoil tables that contains the lift coefficient (-):
   READ(UnIn,*)

      ! InCol_Cd - The column in the airfoil tables that contains the drag coefficient (-):
   READ(UnIn,*)

      ! InCol_Cm - The column in the airfoil tables that contains the pitching-moment coefficient; use zero if there is no Cm column (-):
   READ(UnIn,*)

      ! InCol_Cpmin - The column in the airfoil tables that contains the drag coefficient; use zero if there is no Cpmin column (-):
   READ(UnIn,*)

      ! NumAFfiles - Number of airfoil files used (-):
   CALL ReadVar( UnIn, InputFile, nAFfiles, "NumAFfiles", "Number of airfoil files used (-)", ErrStat2, ErrMsg2, -1)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
               
      ! AFNames - Airfoil file names (NumAFfiles lines) (quoted strings):
   DO I = 1,nAFfiles
      READ(UnIn,*)
   END DO      
             
   !----------- ROTOR/BLADE PROPERTIES  --------------------------------------------
!   CALL ReadCom( UnIn, InputFile, 'Section Header: Rotor/Blade Properties', ErrStat2, ErrMsg2, UnEc )
   READ(UnIn,*)
      
      ! UseBlCm - Include aerodynamic pitching moment in calculations? (flag):
   READ(UnIn,*)

      ! ADBlFile - Names of files containing distributed aerodynamic properties for each blade (see AD_BladeInputFile type):
   DO I = 1,NumBlades
      CALL ReadVar ( UnIn, InputFile, ADBlFile(I), 'ADBlFile('//TRIM(Num2Lstr(I))//')', 'Name of file containing distributed aerodynamic properties for blade '//TRIM(Num2Lstr(I)), ErrStat2, ErrMsg2, -1 )
         CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
      IF ( PathIsRelative( ADBlFile(I) ) ) ADBlFile(I) = TRIM(PriPath)//TRIM(ADBlFile(I))
   END DO      
      
   !---------------------- END OF FILE -----------------------------------------
      
   CALL Cleanup( )
   RETURN


CONTAINS
   !...............................................................................................................................
   SUBROUTINE Cleanup()
   ! This subroutine cleans up any local variables and closes input files
   !...............................................................................................................................

   IF (UnIn > 0) CLOSE ( UnIn )

   END SUBROUTINE Cleanup
   !...............................................................................................................................
END SUBROUTINE ReadPrimaryFile      
!----------------------------------------------------------------------------------------------------------------------------------
SUBROUTINE ReadBladeInputs ( ADBlFile, BladeKInputFileData, UnEc, ErrStat, ErrMsg )
! This routine reads a blade input file.
!..................................................................................................................................


      ! Passed variables:

   TYPE(OpFM_BladePropsType),  INTENT(INOUT)  :: BladeKInputFileData               ! Data for Blade K stored in the module's input file
   CHARACTER(*),             INTENT(IN)     :: ADBlFile                            ! Name of the blade input file data
   INTEGER(IntKi),           INTENT(IN)     :: UnEc                                ! I/O unit for echo file. If present and > 0, write to UnEc

   INTEGER(IntKi),           INTENT(OUT)    :: ErrStat                             ! Error status
   CHARACTER(*),             INTENT(OUT)    :: ErrMsg                              ! Error message


      ! Local variables:

   INTEGER(IntKi)               :: I                                               ! A generic DO index.
   INTEGER( IntKi )             :: UnIn                                            ! Unit number for reading file
   INTEGER(IntKi)               :: ErrStat2 , IOS                                  ! Temporary Error status
   CHARACTER(ErrMsgLen)         :: ErrMsg2                                         ! Temporary Err msg
   CHARACTER(*), PARAMETER      :: RoutineName = 'ReadBladeInputs'

   ErrStat = ErrID_None
   ErrMsg  = ""
   UnIn = -1
      
   ! Allocate space for these variables
   
   
   
   
   CALL GetNewUnit( UnIn, ErrStat2, ErrMsg2 )
      CALL SetErrStat(ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName)


      ! Open the input file for blade K.

   CALL OpenFInpFile ( UnIn, ADBlFile, ErrStat2, ErrMsg2 )
      CALL SetErrStat(ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName)
      IF ( ErrStat >= AbortErrLev ) RETURN


   !  -------------- HEADER -------------------------------------------------------

      ! Skip the header.

   CALL ReadCom ( UnIn, ADBlFile, 'unused blade file header line 1', ErrStat2, ErrMsg2, UnEc )
      CALL SetErrStat(ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName)

   CALL ReadCom ( UnIn, ADBlFile, 'unused blade file header line 2', ErrStat2, ErrMsg2, UnEc )
      CALL SetErrStat(ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName)
      
   !  -------------- Blade properties table ------------------------------------------                                    
   CALL ReadCom ( UnIn, ADBlFile, 'Section header: Blade Properties', ErrStat2, ErrMsg2, UnEc )
      CALL SetErrStat(ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName)

      ! NumBlNds - Number of blade nodes used in the analysis (-):
   CALL ReadVar( UnIn, ADBlFile, BladeKInputFileData%NumBlNds, "NumBlNds", "Number of blade nodes used in the analysis (-)", ErrStat2, ErrMsg2, UnEc)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
      IF ( ErrStat >= AbortErrLev ) RETURN

   CALL ReadCom ( UnIn, ADBlFile, 'Table header: names', ErrStat2, ErrMsg2, UnEc )
      CALL SetErrStat(ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName)

   CALL ReadCom ( UnIn, ADBlFile, 'Table header: units', ErrStat2, ErrMsg2, UnEc )
      CALL SetErrStat(ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName)
      
   IF ( ErrStat>= AbortErrLev ) THEN 
      CALL Cleanup()
      RETURN
   END IF
   
      
      ! allocate space for blade inputs:
   CALL AllocAry( BladeKInputFileData%BlSpn,   BladeKInputFileData%NumBlNds, 'BlSpn',   ErrStat2, ErrMsg2)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   CALL AllocAry( BladeKInputFileData%BlCrvAC, BladeKInputFileData%NumBlNds, 'BlCrvAC', ErrStat2, ErrMsg2)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   CALL AllocAry( BladeKInputFileData%BlSwpAC, BladeKInputFileData%NumBlNds, 'BlSwpAC', ErrStat2, ErrMsg2)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   CALL AllocAry( BladeKInputFileData%BlCrvAng,BladeKInputFileData%NumBlNds, 'BlCrvAng',ErrStat2, ErrMsg2)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   CALL AllocAry( BladeKInputFileData%BlTwist, BladeKInputFileData%NumBlNds, 'BlTwist', ErrStat2, ErrMsg2)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   CALL AllocAry( BladeKInputFileData%BlChord, BladeKInputFileData%NumBlNds, 'BlChord', ErrStat2, ErrMsg2)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
   CALL AllocAry( BladeKInputFileData%BlAFID,  BladeKInputFileData%NumBlNds, 'BlAFID',  ErrStat2, ErrMsg2)
      CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
      
      ! Return on error if we didn't allocate space for the next inputs
   IF ( ErrStat >= AbortErrLev ) THEN
      CALL Cleanup()
      RETURN
   END IF
            
   DO I=1,BladeKInputFileData%NumBlNds
      READ( UnIn, *, IOStat=IOS ) BladeKInputFileData%BlSpn(I), BladeKInputFileData%BlCrvAC(I), BladeKInputFileData%BlSwpAC(I), &
                                  BladeKInputFileData%BlCrvAng(I), BladeKInputFileData%BlTwist(I), BladeKInputFileData%BlChord(I), &
                                  BladeKInputFileData%BlAFID(I)  
         CALL CheckIOS( IOS, ADBlFile, 'Blade properties row '//TRIM(Num2LStr(I)), NumType, ErrStat2, ErrMsg2 )
         CALL SetErrStat( ErrStat2, ErrMsg2, ErrStat, ErrMsg, RoutineName )
               ! Return on error if we couldn't read this line
            IF ( ErrStat >= AbortErrLev ) THEN
               CALL Cleanup()
               RETURN
            END IF
         
         IF (UnEc > 0) THEN
            WRITE( UnEc, "(6(F9.4,1x),I9)", IOStat=IOS) BladeKInputFileData%BlSpn(I), BladeKInputFileData%BlCrvAC(I), BladeKInputFileData%BlSwpAC(I), &
                                  BladeKInputFileData%BlCrvAng(I), BladeKInputFileData%BlTwist(I), BladeKInputFileData%BlChord(I), &
                                  BladeKInputFileData%BlAFID(I)
         END IF         
   END DO
   BladeKInputFileData%BlCrvAng = BladeKInputFileData%BlCrvAng*D2R
   BladeKInputFileData%BlTwist  = BladeKInputFileData%BlTwist*D2R
                  
   !  -------------- END OF FILE --------------------------------------------

   CALL Cleanup()
   RETURN


CONTAINS
   !...............................................................................................................................
   SUBROUTINE Cleanup()
   ! This subroutine cleans up local variables and closes files
   !...............................................................................................................................

      IF (UnIn > 0) CLOSE(UnIn)

   END SUBROUTINE Cleanup

END SUBROUTINE ReadBladeInputs      


END MODULE OpenFOAM_IO