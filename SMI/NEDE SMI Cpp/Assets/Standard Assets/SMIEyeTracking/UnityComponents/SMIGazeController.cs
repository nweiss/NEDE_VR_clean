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
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;
using System.Threading;
using UnityEngine;
using System.IO;

namespace SMI
{
    [AddComponentMenu("SMI/ SMI Gaze Controller")]
    public partial class SMIGazeController : MonoBehaviour
    {
        #region public member variables

        // Max Distance for the Raycasting
        public float maxRayCastDistance = 3500f;

        // Enable a fake Gazeinput. The Server will stream generated Data
        public bool isSimulationModeActive = false;

        // Disable the internal dataFilter of the HMD Data Streaming
        public bool isGazeFilterDisabled = true; 

        // Colorsetup for the Calibrationscreen
        public Color foregroundColor;
        public Color backgroundColor;

        #endregion

        #region private member variables

        // RaycastCamera: Default Use the Camera from the Central Anchor
        private Camera rayCastCam;

        // DataModel for the Status of the EyeTracker and the Sample
        private GazeModel gazeModel;

        // Thread for Starting the Server
        private Thread eyeThread;

        // Callback for dataStreaming 
        private unsafe delegate void getSample(SMIcWrapper.smi_CallbackDataStruct* result);
        private getSample m_SampleCallback;

        // Instance of the Gameobject
        private static SMIGazeController instance;

        #endregion

        #region inherited unity methods

        void Awake()
        {
            // Enable the Simulationmode if the App starts in the Editor 
#if UNITY_EDITOR
            isSimulationModeActive = true;
#endif

            // Create an ManagingGameObject Only in Windows/Editor
#if UNITY_EDITOR || UNITY_STANDALONE_WIN
            if (!instance)
            {
                instance = this;
                DontDestroyOnLoad(gameObject);

                // Instantiate The loadingScreen
                GameObject loadingScreen = Resources.Load("LoadingScreen") as GameObject;
                GameObject screen = GameObject.Instantiate(loadingScreen, Vector3.zero, transform.rotation) as GameObject;

                gazeModel = new GazeModel();

                // Parent the Screen to the Player
                screen.SetActive(true);
                screen.transform.parent = this.gameObject.transform;
                screen.transform.localPosition = new Vector3(0f, 0f, 0.5f);

                // Connect to the Device and Start the DataStreaming 
                eyeThread = new Thread(smi_initDevice);
                eyeThread.Start();
            }
#else
            Debug.LogError("You need an Windows Operation System");
#endif
        }

        void Start()
        {
            rayCastCam = GetComponentInParent<Camera>();
        }

        void OnApplicationQuit()
        {
            if(SMICalibrationVisualizer.stateOfTheCalibrationView.Equals(SMICalibrationVisualizer.VisualisationState.None))
            {
                smi_QuitApplication();
            }
        }

        #endregion

        #region public methods

        /// <summary>
        /// Access to the singleton instance
        /// </summary>
        public static SMIGazeController Instance
        {
            get
            {
                if (!instance)
                {
                    instance = (SMIGazeController)FindObjectOfType(typeof(SMIGazeController));

                    if (!instance)
                    {
                        GameObject gameObject = new GameObject();
                        gameObject.name = "EyeTrackingController";
                        instance = gameObject.AddComponent(typeof(SMIGazeController)) as SMIGazeController;
                    }
                }
                return instance;
            }
        }

        /// <summary>
        /// Calculate a ray based on the position and the averaged POR 
        /// </summary>
        /// <returns> A Ray based from the Gaze Direction</returns>
        public Ray smi_getRayFromGaze()
        {
            Matrix4x4 localToWorldMatrixCamera = rayCastCam.gameObject.transform.localToWorldMatrix;
            Matrix4x4 playerTransformMatrix = Matrix4x4.identity;

            Vector3 porAverageGaze = smi_getSample().por;
            Vector3 cameraPor3d = smi_transformGazePositionToWorldPosition(porAverageGaze);

            //Position of the GazePos
            Vector3 instancePosition = playerTransformMatrix.MultiplyPoint(localToWorldMatrixCamera.MultiplyPoint(cameraPor3d));

            //calulation the Direction of the Gaze
            Vector3 zeroPoint = playerTransformMatrix.MultiplyPoint(localToWorldMatrixCamera.MultiplyPoint(Vector3.zero));
            Vector3 gazeDirection = playerTransformMatrix.MultiplyPoint((instancePosition - zeroPoint));

            return new Ray(transform.position, gazeDirection);
        }

        /// <summary>
        /// Doing a Raycast and write the output into the RaycastHit hitinfo
        /// </summary>
        /// <param name="hitInfo"> Write the informations about the Raycast into the RaycastHit Object</param>
        /// <returns> Returns true, when the raycast was sucessful</returns>
        public bool smi_getRaycastHitFromGaze(out RaycastHit hitInfo)
        {
            return Physics.Raycast(smi_getRayFromGaze(), out hitInfo, maxRayCastDistance);
        }



        /// <summary>
        /// Doing a Raycast and write the output into the RaycastHit hitinfo and a LayerMask
        /// </summary>
        /// <param name="hitInfo"> Write the informations about the Raycast into the RaycastHit Object</param>
        /// <param name="layerMask"> Defines which layers are used for the raycast</param>
        /// <returns> Returns true, when the raycast was sucessful</returns>
        public bool smi_getRaycastHitFromGaze(out RaycastHit hitInfo, int layerMask)
        {
            return Physics.Raycast(smi_getRayFromGaze(), out hitInfo, maxRayCastDistance, layerMask);
        }

        /// <summary>
        ///  Returns the Object in Focus of the Raycast from the Gaze
        /// </summary>
        /// <returns> The focused Gameobject</returns>
        public GameObject smi_getGameObjectInFocus()
        {
            RaycastHit hitInfo;
            if (smi_getRaycastHitFromGaze(out hitInfo))
            {
                return hitInfo.collider.gameObject;
            }

            return null;
        }

        /// <summary>
        /// Customize the calibration procedure, call is *optional* and will override the default settings for the runtime
        /// Precondition: smi_setCallback, smi_startStreaming have been successfully called
        /// </summary>
        /// <param name="calibrationClass"> The Calibration Class provides the Informations for a custom Calibration</param>
        public unsafe void smi_setupCalibration(SMIcWrapper.smi_CalibrationClass calibrationClass)
        {   
            //Init a pointer
            IntPtr newPtr = IntPtr.Zero;
            SMIcWrapper.smi_createCalibrationHMDStruct(ref newPtr);
            SMIcWrapper.smi_CalibrationClass.smi_CalibrationStruct* pointerToCalibrationStruct = (SMIcWrapper.smi_CalibrationClass.smi_CalibrationStruct*) newPtr;

            //Create the Calibrationinformationstruct
            pointerToCalibrationStruct->type = calibrationClass.type;

            // Set the Colors of the Calibration
            pointerToCalibrationStruct->backgroundColor->blue = calibrationClass.backgroundColor.b;
            pointerToCalibrationStruct->backgroundColor->red = calibrationClass.backgroundColor.r;
            pointerToCalibrationStruct->backgroundColor->green = calibrationClass.backgroundColor.g;

            pointerToCalibrationStruct->foregroundColor->blue = calibrationClass.foregroundColor.b;
            pointerToCalibrationStruct->foregroundColor->red = calibrationClass.foregroundColor.r;
            pointerToCalibrationStruct->foregroundColor->green = calibrationClass.foregroundColor.g;

            // Set the Custom CalibrationPoints only if the List has custom points
            if (calibrationClass.calibrationPointList.Count != 0)
            {
                if (SMIcWrapper.calibrationTypeToInt(calibrationClass.type) == calibrationClass.calibrationPointList.Count)
                {
                    for (int i = 0; i < calibrationClass.calibrationPointList.Count; i++)
                    {
                        pointerToCalibrationStruct->calibrationPointList[i].x = calibrationClass.calibrationPointList[i].x;
                        pointerToCalibrationStruct->calibrationPointList[i].y = calibrationClass.calibrationPointList[i].y;
                    }
                }

                // Handle an Error and print it into the Console/Logfile
                else
                {
                    GazeModel.ErrorID = 505;
                    Debug.LogError("Wrong Parameters detected");
                }
            }

            // Activate the calibration visualisation; per default it is false -> the iInternal calibration visualisation will be used
            pointerToCalibrationStruct->client_visualisation = calibrationClass.client_visualisation;

            // TimeOut
            pointerToCalibrationStruct->calibrationTimer = calibrationClass.calibrationTimer;

            // Setup the Calibration
            GazeModel.ErrorID = SMIcWrapper.smi_setupCalibration((IntPtr)pointerToCalibrationStruct);
        }

        /// <summary>
        ///  Shows a calibration window on the HMD screen, default calibration method is 3-Point. 
        ///  Accept calibration points by hitting the 'space bar' 
        ///  Precondition: smi_setCallback, smi_startStreaming have been successfully called
        /// </summary>
        public void smi_calibrate()
        {
            if (GazeModel.ErrorID == 1) // no error
            {
                GazeModel.ErrorID = SMIcWrapper.smi_calibrate();
            }
            else
            {
                GazeModel.ErrorID = 506;
                Debug.LogError("Calibration Failed");
            }
        }

        /// <summary>
        /// Abort the Calibration
        /// </summary>
        public void smi_abortCalibration()
        {
            GazeModel.ErrorID = SMIcWrapper.smi_AbortCalibration();
        }

        /// <summary>
        /// Reset the Calibration to 0-point
        /// </summary>
        public void smi_resetCalibration()
        {
            GazeModel.ErrorID = SMIcWrapper.smi_ResetCalibration();
        }

        /// <summary>
        /// Display of 4x4 validation grid with gaze overlay, press ESC to exit the window
        /// The color scheme is always consistend with the last executed calibration.
        /// Precondition: smi_setCallback, smi_startStreaming have been successfully called
        /// </summary>
        public void smi_startValidation()
        {
            GazeModel.ErrorID = SMIcWrapper.smi_validate();
        }

        /// <summary>
        ///  Display a validation which shows multiple points and computes a accuracy and precision per point, press ESC to exit the window
        ///  The color scheme is always consistend with the last executed calibration.
        ///  Precondition: smi_setCallback, smi_startStreaming have been successfully called
        /// </summary>
        /// <param name="validationPointList">fills Array with x,y positions of the validation points</param>
        /// <param name="fixationPointList">fills Array with x,y positions of the fixations</param>
        /// <param name="showResultsOnOperatorScreen">show window on operator screen</param>
        /// <param name="showResultsOnUserScreen">show window on user screen (HMD)</param>
        /// <param name="durationResultWindow">duration in [ms] to show the validation window on user and operator if enabled
        /// if set to 0 operator window has to be closed manually whereas the user window will be closed after 4 [s]  </param>
        public void smi_quantitativeValidation(List<Vector2> validationPointList, List<Vector2> fixationPointList, bool showResultsOnOperatorScreen, bool showResultsOnUserScreen, int durationResultWindow)
        {
            GazeModel.ErrorID = SMIcWrapper.smi_quantitativeValidation(validationPointList, fixationPointList, showResultsOnOperatorScreen, showResultsOnUserScreen, durationResultWindow);
        }

        /// <summary>
        /// Stop the datastreaming and disconnect from the server
        /// </summary>
        public void smi_QuitApplication()
        {
            GazeModel.ErrorID = SMIcWrapper.smi_quit();
        }

        /// <summary>
        /// Returns the Sample from the GazeModel. Use this for your own advanced gazeInteraction
        /// </summary>
        /// <returns>The saved Sample Data from the HMD </returns>
        public unity_SampleHMD smi_getSample()
        {
            return gazeModel.dataSample;
        }

        #endregion

        #region private methods

        /// <summary>
        /// Set the Callback and start the datastreaming.
        /// </summary>
        private void smi_initDevice()
        {
            smi_setCallback();
            smi_startStreaming();
        }

        /// <summary>
        /// Set the Datastream Callback 
        /// </summary>
        private unsafe void smi_setCallback()
        {
            m_SampleCallback = smi_callBackGetData;
            try
            {
                GazeModel.ErrorID = SMIcWrapper.smi_setCallback(m_SampleCallback);
            }
            catch (System.Exception e)
            {
                Debug.LogException(e);
            }
        }

        /// <summary>
        /// Start the Datastreaming
        /// </summary>
        private unsafe void smi_startStreaming()
        {
            SMIcWrapper.smi_TrackingParameterStruct parameter;
            parameter.mappingDistance = SMIcWrapper.Constants.planeDistance;
            parameter.disableGazeFilter = isGazeFilterDisabled;

            int iSizeOfTrackingParameterStruct = Marshal.SizeOf(parameter);
            IntPtr ptrParameterStruct = Marshal.AllocHGlobal(iSizeOfTrackingParameterStruct);
            Marshal.StructureToPtr(parameter, ptrParameterStruct, false);

            try
            {
                GazeModel.ErrorID = SMIcWrapper.smi_startStreaming(isSimulationModeActive, ptrParameterStruct);
            }
            catch (SystemException e)
            {
                Debug.LogException(e);
            }

            Marshal.FreeHGlobal(ptrParameterStruct);
            ptrParameterStruct = IntPtr.Zero;

            GazeModel.connectionRoutineDone = true;
        }

        /// <summary>
        /// Write the Data from the Sample into the GazeModel
        /// </summary>
        /// <param name="result"> Pointer to a smi_CallbackDataStruct</param>
        private unsafe void smi_callBackGetData(SMIcWrapper.smi_CallbackDataStruct* result)
        {
            if (result->type == SMIcWrapper.smi_StreamingType.SMI_SIMPLE_GAZE_SAMPLE)
            {
                SMIcWrapper.smi_SampleHMDStruct* sample = (SMIcWrapper.smi_SampleHMDStruct*)result->result;

                // Write the EyeSamples of the Eyes into the gazeModel
                gazeModel.dataSample = new unity_SampleHMD(sample);
            }
        }

        /// <summary>
        /// Transform the raw-Gazeposition into the WorldPosition of the 3D-World of Unity
        /// </summary>
        /// <param name="gazePos">the raw-GazePosition</param>
        /// <returns>Transformed GazePosition in the World Space</returns>
        private Vector3 smi_transformGazePositionToWorldPosition(Vector2 gazePos)
        {
            float planeDistForMapping = 1.5f;
            float gazeScreenWidth = 1920f;
            float gazeScreenHeight = 1080f;
            float horizFieldOfView = 87f * Mathf.Deg2Rad;
            float vertFieldOfView = horizFieldOfView;

            float xOff = planeDistForMapping * Mathf.Tan(horizFieldOfView / 2f);
            float yOff = planeDistForMapping * Mathf.Tan(vertFieldOfView / 2f);
            float zOff = planeDistForMapping;

            Vector3 gazePosInWorldSpace = new Vector3(smi_calculateGazeOffset(gazePos.x, gazeScreenWidth, xOff), -smi_calculateGazeOffset(gazePos.y, gazeScreenHeight, yOff), zOff);

            return gazePosInWorldSpace;
        }

        /// <summary>
        /// Calculate the gaze offset to the screen width per vector component
        /// </summary>
        /// <param name="xin"></param>
        /// <param name="gazeScreenWidth"></param>
        /// <param name="offset"></param>
        /// <returns></returns>
        private float smi_calculateGazeOffset(float xin, float gazeScreenWidth, float offset)
        {
            return (xin * 2f * offset) / gazeScreenWidth - offset;
        }
        #endregion

    }


}

