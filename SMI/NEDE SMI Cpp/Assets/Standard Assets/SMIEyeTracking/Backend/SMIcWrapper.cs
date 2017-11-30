// -----------------------------------------------------------------------
//
// (c) Copyright 1997-2015, SensoMotoric Instruments GmbH
// 
// Permission  is  hereby granted,  free  of  charge,  to any  person  or
// organization  obtaining  a  copy  of  the  software  and  accompanying
// documentation  covered  by  this  license  (the  "Software")  to  use,
// reproduce,  display, distribute, execute,  and transmit  the Software,
// and  to  prepare derivative  works  of  the  Software, and  to  permit
// third-parties to whom the Software  is furnished to do so, all subject
// to the following:
// 
// The  copyright notices  in  the Software  and  this entire  statement,
// including the above license  grant, this restriction and the following
// disclaimer, must be  included in all copies of  the Software, in whole
// or  in part, and  all derivative  works of  the Software,  unless such
// copies   or   derivative   works   are   solely   in   the   form   of
// machine-executable  object   code  generated  by   a  source  language
// processor.
// 
// THE  SOFTWARE IS  PROVIDED  "AS  IS", WITHOUT  WARRANTY  OF ANY  KIND,
// EXPRESS OR  IMPLIED, INCLUDING  BUT NOT LIMITED  TO THE  WARRANTIES OF
// MERCHANTABILITY,   FITNESS  FOR  A   PARTICULAR  PURPOSE,   TITLE  AND
// NON-INFRINGEMENT. IN  NO EVENT SHALL  THE COPYRIGHT HOLDERS  OR ANYONE
// DISTRIBUTING  THE  SOFTWARE  BE   LIABLE  FOR  ANY  DAMAGES  OR  OTHER
// LIABILITY, WHETHER  IN CONTRACT, TORT OR OTHERWISE,  ARISING FROM, OUT
// OF OR IN CONNECTION WITH THE  SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// -----------------------------------------------------------------------

using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Text;
using UnityEngine;


namespace SMI
{
    public partial class SMIGazeController : MonoBehaviour
    {
        #region SMIcWrapper
        /// <summary>
        /// C Wrapper of the Functions of the SMI HMD SDK
        /// </summary>
        public class SMIcWrapper
        {
            const string dllName = "iViewHMDAPI.dll";

            #region public methods

            /// <summary>
            /// Converts the CalibrationStruct to an int
            /// </summary>
            /// <param name="t"></param>
            /// <returns></returns>
            public static int calibrationTypeToInt(smi_CalibrationType t)
            {
                switch (t)
                {
                    case smi_CalibrationType.OnePointCalibration:
                        return 1;

                    case smi_CalibrationType.ThreePointCalibration:
                        return 3;

                    case smi_CalibrationType.FivePointCalibration:
                        return 5;

					case smi_CalibrationType.NinePointCalibration:
						return 9;

                    case smi_CalibrationType.None:
                        return 0;

                    default:
                        return int.MaxValue;
                }
            }

            /// <summary>
            /// Start a quantitative Validation
            /// </summary>
            /// <param name="validationPointList"></param>
            /// <param name="fixationPointList"></param>
            /// <param name="showResultsOnOperatorScreen"></param>
            /// <param name="showResultsOnUserScreen"></param>
            /// <param name="durationResultWindow"></param>
            /// <returns></returns>
            public static unsafe int smi_quantitativeValidation(List<Vector2> validationPointList, List<Vector2> fixationPointList, bool showResultsOnOperatorScreen, bool showResultsOnUserScreen, int durationResultWindow)
            {
                //Check the Paramters 
                if (validationPointList == null || fixationPointList == null)
                {
                    GazeModel.ErrorID = 505;
                    Debug.LogError("Wrong parameters detected");
                }

                smi_Vec2d* pointerToValidationPointList = null;
                smi_Vec2d* pointerToFixationPointList = null;

                //Start the Validation
                int rc = smi_quantitativeValidation_c(ref pointerToValidationPointList, ref pointerToFixationPointList, showResultsOnOperatorScreen, showResultsOnUserScreen, durationResultWindow);

                //Write the Results into a List 
                for (int i = 0; i < 4; i++)
                {
                    validationPointList.Add(new Vector2((float)pointerToValidationPointList[i].x, (float)pointerToValidationPointList[i].y));
                    fixationPointList.Add(new Vector2((float)pointerToFixationPointList[i].x, (float)pointerToFixationPointList[i].y));
                }

                return rc;
            }

            public static string[] smi_getAvailableCalibrations()
            {
                // StringBuilder builder = SMIcWrapper.smi_getAvailableCalibrations();
                string result = Marshal.PtrToStringAnsi(SMIcWrapper.smi_getAvailableCalibrations_c());
                return result.Split(',');
            }
            #endregion

            #region APICalls

            //Set the userFunction which should be calles asynchronously when a ne data sample is available
            [DllImport(dllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "smi_setCallback")]
            public static extern int smi_setCallback(Delegate callbackFunction);

            //Start the Data Streaming
            [DllImport(dllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "smi_startStreaming")]
            public static unsafe extern int smi_startStreaming(bool simulate, IntPtr trackingInformation);

            //Disconnect from the Eye Tracking Server
            [DllImport(dllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "smi_quit")]
            public static extern int smi_quit();

            //Setup the HMD CalibrationStructure
            [DllImport(dllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "smi_createCalibrationHMDStruct")]
            public static unsafe extern int smi_createCalibrationHMDStruct(ref IntPtr calibrationStruct);

            //Setup the Calibration
            [DllImport(dllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "smi_setupCalibration")]
            public static unsafe extern int smi_setupCalibration(IntPtr calibrationHMDStruct);

            //Start a Calibration
            [DllImport(dllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "smi_calibrate")]
            public static extern int smi_calibrate();

            // Use this when using a client side calibration (calibrationHMDStruct->client_visualization = true)
            // Precondition:	smi_setupCalibration(calibrationHMDStruct), smi_calibrate() have been successfully called
            [DllImport(dllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "smi_acceptCalibrationPoint")]
            public static extern int smi_acceptCalibrationPoint(smi_Vec2d vector);

            //Reset the Calibration
            [DllImport(dllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "smi_resetCalibration")]
            public static extern int smi_ResetCalibration();

            [DllImport(dllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "smi_startDetectingNewFixation")]
            public static extern void smi_startDetectingNewFixation();

            [DllImport(dllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "smi_checkForNewFixation")]
            public static extern bool smi_checkForNewFixation();

            //Abort the Calibration
            [DllImport(dllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "smi_abortCalibration")]
            public static extern int smi_AbortCalibration();

            //Start a Validation
            [DllImport(dllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "smi_validate")]
            public static extern int smi_validate();

            //Start a quantitative Validation
            [DllImport(dllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "smi_quantitativeValidation")]
            private static unsafe extern int smi_quantitativeValidation_c(ref smi_Vec2d* validationPointList, ref smi_Vec2d* validationFixationPointList, bool showResultsOnOpScreen, bool showResultsOnUserScreen, int durationResultWindow);

            //Returns SMI_RET_SUCCES if the calibration has been loaded
            //If not name is set, the current oculus user name will be loaded
            [DllImport(dllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "smi_loadCalibration")]
            public static unsafe extern int smi_loadCalibration([MarshalAs(UnmanagedType.LPStr)] string name);

            //Returns SMI_RET_SUCCES if the calibration has been saved.
            //Perform a calibration before 
            [DllImport(dllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "smi_saveCalibration")]
            public static unsafe extern int smi_saveCalibration([MarshalAs(UnmanagedType.LPStr)] string name);

            //Will list every calibration saved with smi_saveCalibration(char * name) before.
            //List is comma seperated
            [DllImport(dllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "smi_getAvailableCalibrations")]
            private static unsafe extern IntPtr smi_getAvailableCalibrations_c();

            //returns the current eyetracking server time in [ns] since start.
            //Precondition:	smi_startStreaming has been succesfully called
            [DllImport(dllName, CallingConvention = CallingConvention.StdCall, EntryPoint = "smi_getServerTime")]
            public static unsafe extern long smi_getServerTime();

            #endregion

            #region SMIcDataStructs

            /// <summary>
            /// StreamingTypes for the HMD
            /// </summary>
            public enum smi_StreamingType
            {
                SMI_SIMPLE_GAZE_SAMPLE,
                SMI_EYE_IMAGE_LEFT,
                SMI_EYE_IMAGE_RIGHT
            }

            /// <summary>
            /// Calibrationtype
            /// </summary>
            public enum smi_CalibrationType
            {
                None,
                OnePointCalibration,
                ThreePointCalibration,
                FivePointCalibration,
                NinePointCalibration
            }

            /// <summary>
            /// 3D Vector
            /// </summary>
            [StructLayout(LayoutKind.Sequential)]
            public struct smi_Vec3d
            {
                public double x;
                public double y;
                public double z;
            };

            /// <summary>
            /// 2D Vector
            /// </summary>
            [StructLayout(LayoutKind.Sequential)]
            public struct smi_Vec2d
            {
                public double x;
                public double y;
            };

            /// <summary>
            /// ColorStruct
            /// </summary>
            [StructLayout(LayoutKind.Sequential)]
            public struct smi_CalibrationColor
            {
                // red color part for customization of the calibration and validation visualization [0..1] 
                public double red;
                // green color part for customization of the calibration and validation visualization [0..1] 
                public double green;
                // blue color part for customization of the calibration and validation visualization [0..1] 
                public double blue;
            };

            /// <summary>
            /// Result struct holding data delivered via callback
            /// check the type and cast into the according struct
            /// </summary>
            [StructLayout(LayoutKind.Sequential)]
            public unsafe struct smi_CallbackDataStruct
            {
                // type of the result which gives a hint how to cast the result
                public smi_StreamingType type;

                // pointer to the data, cast using the type member
                public unsafe void* result;
            }

            [StructLayout(LayoutKind.Sequential)]
            public struct smi_TrackingParameterStruct
            {
                // distance of the Mapping plane for the 2d Point of Regard (mm), default distance is 1500 mm
                public double mappingDistance;

                // disable stabilization filter for the 2d Point of Regard is set to true
                public bool disableGazeFilter;
            }

            /// <summary>
            /// smi_EyeDataHMDStruct which holds information regarding gaze direction in space as well as in screen coordinate
            /// </summary>
            [StructLayout(LayoutKind.Sequential)]
            public struct smi_EyeDataHMDStruct
            {
                // coordinates of the gaze base point in a right handed coordinate system (x-left, y-up, z-forward) [mm]
                public smi_Vec3d gazeBasePoint;

                // normalized gaze direction
                public smi_Vec3d gazeDirection;

                // x, y mapped gaze coordinates [px]; (0, 0) represents the top left corner of the display
                public smi_Vec2d por;

                // pupil radius [mm]
                public double pupilRadius;

                // coordinates of pupil position [mm] (given in the same coordinate system as gazeBasePoint)
                public smi_Vec3d pupilPosition;

                // distance eye to lens [mm]
                public double eyeLensDistance;

                // distance eye to screen [mm]
                public double eyeScreenDistance;
            };

            /// <summary>
            /// smi_SampleHMDStruct holds information for both eyes as well as the averaged mapped POR
            /// </summary>
            [StructLayout(LayoutKind.Sequential)]
            public struct smi_SampleHMDStruct
            {
                // size of the Sample
                int sampleSize;

                // server time in ns
                public Int64 timestamp;

                // interocularDistance. meaning the Distance bezweeen the eye balls
                public double iod;

                // interPupillary distance, distance between left and right pupil-center
                public double ipd;

                // X, Y coordinates of the mapped combined (averaged) point of regard on the display [px]
                public smi_Vec2d por;

                // normalized direction of the averaged ("cyclops") gaze
                public smi_Vec3d gazeDirection;

                public smi_Vec3d gazeBasePoint;

                // left Eye Data
                public smi_EyeDataHMDStruct left;
                // right Eye Data
                public smi_EyeDataHMDStruct right;

                [MarshalAs(UnmanagedType.Bool)]
                public bool isValid;
            }

            /// <summary>
            /// WrapperClass for the CalibrationClass
            /// Use this Class to initialize a Calibration
            /// </summary>
            public class smi_CalibrationClass
            {
                // Type of the Calibration
                public smi_CalibrationType type;

                //Points to use for the Calibration, have to be set in full display resolution (1920 x 1080)
                public List<Vector2> calibrationPointList = new List<Vector2>();

                // Background of the calibration visualisation
                public Color backgroundColor = Color.gray;

                // Color of the targetpoints
                public Color foregroundColor = Color.white;

                // Disable default calibration visualisation if this is set to true
                //[MarshalAs(UnmanagedType.I1)]
                public bool client_visualisation = false;

                //! Set a timeout timer for calibration in [ms]. Disabled if set to 0
                public int calibrationTimer = 0;
                /// <summary>
                /// For marshalling to c++; Do not use directly; use parent class instead
                /// </summary>
                /// 
                [Serializable]
                [StructLayout(LayoutKind.Sequential)]
                public unsafe struct smi_CalibrationStruct
                {
                    // Type of the Calibration
                    public smi_CalibrationType type;

                    //Points to use for the Calibration, have to be set in full display resolution (1920 x 1080)
                    public unsafe SMIcWrapper.smi_Vec2d* calibrationPointList;

                    // Background of the calibration visualisation
                    public unsafe smi_CalibrationColor* backgroundColor;

                    // Color of the targetpoints
                    public unsafe smi_CalibrationColor* foregroundColor;

                    // Disable default calibration visualisation if this is set to true
                    [MarshalAs(UnmanagedType.Bool)]
                    public bool client_visualisation;

                    //! Set a timeout timer for calibration in [ms]. Disabled if set to 0
                    public int calibrationTimer;
                };
            }

            #endregion

            #region HelperClasses

            /// <summary>
            /// Container for Constants
            /// </summary>
            public class Constants
            {

                public const float FOV_GazeMapping = 84;
                public const float planeDistance = 1500f;
            }

            /// <summary>
            /// Position of the Targets in the DefaultCalibrations
            /// </summary>
            public class DefaultCalibrationInformations
            {
                private static Vector2[] defaultOnePointCalibration = 
                { 
                    new Vector2(960, 540)
				};

                private static Vector2[] defaultThreePointCalibration = 
                { 
					new Vector2(780.8f, 453.6f),
					new Vector2(960f, 626.4f),
                    new Vector2(1139.2f, 453.6f)
				};

                private static Vector2[] defaultFivePointCalibration = 
                { 
					new Vector2(780.8f, 453.6f), 
					new Vector2(1139.2f, 626.4f), 
					new Vector2(1139.2f, 453.6f), 
					new Vector2(780.8f, 626.4f), 
					new Vector2(960.0f, 540.0f)
				};

                public static Vector2[] defaultNinePointCalibration = 
                {  
					new Vector2(750.8f, 423.6f), 
					new Vector2(1169.2f, 656.4f), 
					new Vector2(1169.2f, 423.6f), 
					new Vector2(750.8f, 656.4f),
					new Vector2(960.0f, 540.0f),
					new Vector2(1169.2f, 540.0f),
					new Vector2(960.0f, 423.6f),
					new Vector2(750.8f, 540.0f),
					new Vector2(960.0f, 656.4f)
				};

                public static Vector2[] validationPoints = 
                {
                    new Vector2(760.0f, 433), 
                    new Vector2(1160.0f, 433), 
                    new Vector2(1160.0f, 646), 
                    new Vector2(760.0f,646)
                };

                public static Vector2[] validationGrid =
                {
                    new Vector2(711.111f, 396f),
                    new Vector2(877.037f, 396f),
                    new Vector2(1042.96f, 396f),
                    new Vector2(1208.89f, 396f), 
  
                    new Vector2(711.111f, 486),
                    new Vector2(877.037f, 486),
                    new Vector2(1042.96f, 486),
                    new Vector2(1208.89f, 486),
  
                    new Vector2(711.111f, 576),
                    new Vector2(877.037f, 576),
                    new Vector2(1042.96f, 576),
                    new Vector2(1208.89f, 576),
  
                    new Vector2(711.111f, 666),
                    new Vector2(877.037f, 666),
                    new Vector2(1042.96f, 666),
                    new Vector2(1208.89f, 666)
                };

                public static Vector2[] selectDefaultCalibration(smi_CalibrationType type)
                {
                    switch (type)
                    {
                        case smi_CalibrationType.OnePointCalibration:
                            return defaultOnePointCalibration;
                        case smi_CalibrationType.ThreePointCalibration:
                            return defaultThreePointCalibration;
                        case smi_CalibrationType.FivePointCalibration:
                            return defaultFivePointCalibration;
                        case smi_CalibrationType.NinePointCalibration:
                            return defaultNinePointCalibration;

                        //Wrong Parameter Detected etc
                        default:
                            return defaultThreePointCalibration;
                    }
                }
            }

            /// <summary>
            /// Class for Errorhandling
            /// </summary>
            public class errorIDContainer
            {

                /// <summary>
                /// container for the ErrorIDs and States of the Eye Tracker Controller
                /// </summary>
                private static Dictionary<int, string> ErrorId = new Dictionary<int, string>()
                    {
                        {1, "SMI_RET_SUCCESS"},
                        {500, "SMI_ERROR_NO_CALLBACK_SET"},
                        {501, "SMI_ERROR_CONNECTING_TO_HMD"},
                        {502, "SMI_ERROR_HMD_NOT_SUPPORTED"},
                        {504, "SMI_ERROR_NOT_IMPLEMENTED"},
                        {505, "SMI_ERROR_INVALID_PARAMETER"},
						{506, "SMI_ERROR_EYECAMERAS_NOT_AVAILABLE"},
						{507, "SMI_ERROR_OCULUS_RUNTIME_NOT_SUPPORTED"},
						{508, "SMI_ERROR_FILE_NOT_FOUND"},
						{509, "SMI_ERROR_FILE_EMPTY"},
						{510, "SMI_ERROR_SDK_NOT_INSTALLED"},
						{511, "SMI_ERROR_NO_SMI_HARDWARE"},
                        {512,"SMI_ERROR_UNKNOWN"}
                    };


                /// <summary>
                /// Convert the ErrorID into a readable Message
                /// </summary>
                /// <param name="id"></param>
                /// <returns></returns>
                public static string getErrorMessage(int id)
                {
                    return ErrorId[id];
                }
            }

            #endregion
        }
        #endregion

        #region UnityStructs
        /// <summary>
        /// DataStorage of the GazeData
        /// </summary>
        public class GazeModel
        {
            //Static Data about the status. Use this for the loadingScreen
            public static int ErrorID = -1;
            public static bool connectionRoutineDone = false;

            public unity_SampleHMD dataSample { get; set; }
            public List<Vector2> validationPointList { get; set; }
            public List<Vector2> fixationPointList { get; set; }

            public GazeModel()
            {
                dataSample = new unity_SampleHMD();
            }
        }

        /// <summary>
        /// The Unitysample of the Eye
        /// </summary>
        public class unity_EyeDataHMDStruct
        {
            public Vector3 pupilPosition;
            public Vector3 gazeDirection;
            public Vector3 gazeBasePoint;

            public Vector2 por;
            public double pupilRadius;

            public double eyeLensDistance;
            public double eyeScreenDistance;


            /// <summary>
            /// Init a empty Sample
            /// </summary>
            public unity_EyeDataHMDStruct()
            {
                pupilRadius = 0;
                pupilPosition = Vector3.zero;
                por = Vector2.zero;
                gazeDirection = Vector3.zero;
                gazeBasePoint = Vector3.zero;
                eyeScreenDistance = 0;
                eyeLensDistance = 0;
            }

        }

        /// <summary>
        /// The complete Unitysample from the HMD
        /// </summary>
        public class unity_SampleHMD
        {
            //TimeStamp of the Sample
            public double timeStamp;
            //Interpupillary Distance
            public double ipd;
            //Interocular Distance
            public double iod;

            public bool isValid;

            //Samples
            public unity_EyeDataHMDStruct left;
            public unity_EyeDataHMDStruct right;

            //Average Data
            public Vector2 por;
            public Vector3 gazeDirection;
            public Vector3 gazeBasePoint;

            #region public Members
            /// <summary>
            /// Init a Sample and write it into the gazeModel
            /// </summary>
            /// <param name="sample"></param>
            public unsafe unity_SampleHMD(SMI.SMIGazeController.SMIcWrapper.smi_SampleHMDStruct* sample)
            {
                // Timestamp
                timeStamp = System.Convert.ToDouble(sample->timestamp);

                // Safe the IOD & IPD
                iod = (float)sample->iod;
                ipd = (float)sample->ipd;

                // POI, GazeDirection and GazeBasePoint ("Of The cyclonEye")
                por = new Vector2((float)sample->por.x, (float)sample->por.y);
                gazeDirection = new Vector3((float)sample->gazeDirection.x, (float)sample->gazeDirection.y, (float)sample->gazeDirection.z);
                gazeBasePoint = new Vector3((float)sample->gazeBasePoint.x, (float)sample->gazeBasePoint.y, (float)sample->gazeBasePoint.z);

                // Safe the EyeSample
                left = convertSMIToUnityEyeSample(sample->left);
                right = convertSMIToUnityEyeSample(sample->right);

                isValid = sample->isValid;
            }

            /// <summary>
            /// Init an empty Sample
            /// </summary>
            public unity_SampleHMD()
            {
                left = new unity_EyeDataHMDStruct();
                right = new unity_EyeDataHMDStruct();
                timeStamp = 0;
                por = Vector2.zero;
                gazeDirection = Vector3.zero;
                ipd = 0;
                iod = 0;
            }
            #endregion

            #region private Members
            /// <summary>
            /// Convert the SMI Sample into a Unitysample
            /// </summary>
            /// <param name="sample"></param>
            /// <returns></returns>
            private unity_EyeDataHMDStruct convertSMIToUnityEyeSample(SMIcWrapper.smi_EyeDataHMDStruct sample)
            {

                unity_EyeDataHMDStruct unitySample = new unity_EyeDataHMDStruct();
                unitySample.eyeLensDistance = sample.eyeLensDistance;
                unitySample.eyeScreenDistance = sample.eyeScreenDistance;

                unitySample.gazeBasePoint = new Vector3((float)sample.gazeBasePoint.x, (float)sample.gazeBasePoint.y, (float)sample.gazeBasePoint.z);
                unitySample.gazeDirection = new Vector3((float)sample.gazeDirection.x, (float)sample.gazeDirection.y, (float)sample.gazeDirection.z);

                unitySample.por = new Vector2((float)sample.por.x, (float)sample.por.y);
                unitySample.pupilPosition = new Vector3((float)sample.pupilPosition.x, (float)sample.pupilPosition.y, (float)sample.pupilPosition.z);
                unitySample.pupilRadius = sample.pupilRadius;

                return unitySample;
            }

            #endregion
        }

        #endregion
    }
}