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

using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Threading;
using UnityEngine.UI;


namespace SMI
{
    [System.Serializable]
    [RequireComponent(typeof(SMIGazeController))]
    public class SMICalibrationVisualizer : MonoBehaviour
    {

        #region public member variables
        public bool pauseGameWhileCalibration = true;

        //state of the Element
        public enum VisualisationState
        {
            calibration,
            gridValidation,
            quantitativeValidation,
            None
        }

        public static VisualisationState stateOfTheCalibrationView = VisualisationState.None;

        public KeyCode abortCalibrationKey = KeyCode.Escape;
        public KeyCode acceptCalibrationKey = KeyCode.Space;
        #endregion

        #region private member variables

        private GameObject calibrationTarget;
        private GameObject gazePositionTarget;
        private GameObject anchorValidationGrid;
        private GameObject anchorValidationView;
        private GameObject[] gazeTargetValidationViewItems;
        private GameObject[] gazeTargetsOfQuantiativeValidation;


        private Thread calibrationThread;
        private CalibrationJob job;
        private Vector2[] positionsOfPORForQuantiativeValidation;
        private Vector2[] targetPositions;

        private LayerMask calibrationLayer;
        private Camera rayCam;
        private SMIRenderCamera[] renderCameras;

        private int targetID = 0;

        private float[] validationItems;
        private SMItextView TextViewValidation;
        #endregion

        #region inherited unity methods
        public float ganzemappingDistanceValidation = 1.5f;
        void Start()
        {
            renderCameras = transform.parent.parent.GetComponentsInChildren<SMIRenderCamera>();
            rayCam = transform.parent.GetComponent<Camera>();
            calibrationLayer = LayerMask.NameToLayer("CalibrationView");

            smi_InitCalibrationView();
            smi_InitValidationView();

        }

        /// <summary>
        /// Cancel the Quit if the User is in the CalibrationMode
        /// </summary>
        void OnApplicationQuit()
        {
            switch(stateOfTheCalibrationView)
            {
                case VisualisationState.calibration:
                    Application.CancelQuit();
                    smi_AbortCalibation(); 
                    break; 

                case VisualisationState.gridValidation:
                    Application.CancelQuit();
                    smi_FinishValidation();
                    break; 
				
                case VisualisationState.quantitativeValidation:
                    Application.CancelQuit();
                    smi_AbortValidation();
                    break; 
            }
        }

        void Update()
        {
            #region CalibrationMode

//			if (stateOfTheCalibrationView.Equals(VisualisationState.gridValidation)) {
//				smi_FinishValidation();
//			}
//			if (stateOfTheCalibrationView.Equals(VisualisationState.quantitativeValidation)){
//				smi_AbortValidation();
//			}

            //AcceptPoint only when the Application is in the CalibrationMode
            if (stateOfTheCalibrationView.Equals(VisualisationState.calibration))
            {
                smi_SetStatusOfCalibrationModeOfCameras(true);

                //Accept the Point and start the Detection for a new Fixation
                if (Input.GetKeyDown(acceptCalibrationKey) || SMIGazeController.SMIcWrapper.smi_checkForNewFixation())
                {
                    smi_UpdateTargetPosition();
                }

                if (targetPositions != null)
                {
                    //Set the CalibrationTarget float planeDistForMapping = 1.5f;
                    calibrationTarget.transform.position = smi_CalculatePositionOnGazeMappingPlane(targetPositions[targetID],1.5f);
                }
            }


            #endregion

            #region ValidationMode

            //AcceptPoint the ValidationPoints only if the Application is in the ValidationMode

            else if (stateOfTheCalibrationView.Equals(VisualisationState.quantitativeValidation))
            {
                smi_SetStatusOfCalibrationModeOfCameras(true);
				
                //Accept the Point and start the Detection for a new Fixation
                if (Input.GetKeyDown(acceptCalibrationKey) || SMIGazeController.SMIcWrapper.smi_checkForNewFixation())
                {
                    smi_UpdateTargetPosition();
                }

                if (targetPositions != null)
                {
                    calibrationTarget.transform.position = smi_CalculatePositionOnGazeMappingPlane(targetPositions[targetID], ganzemappingDistanceValidation);
                }
            }

            else if (stateOfTheCalibrationView.Equals(VisualisationState.gridValidation))
            {
                smi_SetStatusOfCalibrationModeOfCameras(true);
                gazePositionTarget.transform.position = smi_CalculatePositionOnGazeMappingPlane(SMI.SMIGazeController.Instance.smi_getSample().por, ganzemappingDistanceValidation);
            }

            #endregion

            #region NormalMode
            else
            {
                smi_SetStatusOfCalibrationModeOfCameras(false);
            }

            //ThreadJoining
            if (stateOfTheCalibrationView.Equals(VisualisationState.None) && calibrationThread.IsAlive)
            {
                calibrationThread.Join();
            }

            #endregion
        }
        #endregion

        #region public methods

        /// <summary>
        /// Setup a Calibrationview
        /// </summary>
        /// <param name="calibrationInformation">Parameterclass for the paramter of the Calibration</param>
        public void smi_SetupCalibrationInClient(SMIGazeController.SMIcWrapper.smi_CalibrationClass calibrationInformation)
        {
            if (stateOfTheCalibrationView.Equals(VisualisationState.None))
            {
                //Save the Position of the Target
                targetPositions = calibrationInformation.calibrationPointList.ToArray();

                //No Custom Parameter Detected
                if (targetPositions.Length == 0)
                {
                    targetPositions = SMIGazeController.SMIcWrapper.DefaultCalibrationInformations.selectDefaultCalibration(calibrationInformation.type);
                }

                //Setup the informations for the ServerApp
                SMIGazeController.Instance.smi_setupCalibration(calibrationInformation);
            }
        }

        /// <summary>
        /// Reset the ValidationValues and the position of the Gaze in the validationmode
        /// </summary>
        public void smi_SetupQuantitativeValidation()
        {
            if (stateOfTheCalibrationView.Equals(VisualisationState.None))
            {
                SMIGazeController.SMIcWrapper.smi_startDetectingNewFixation();
                targetID = 0;

                validationItems = new float[4];
                positionsOfPORForQuantiativeValidation = new Vector2[4];
                calibrationTarget.SetActive(true);

                targetPositions = SMIGazeController.SMIcWrapper.DefaultCalibrationInformations.validationPoints;
                stateOfTheCalibrationView = VisualisationState.quantitativeValidation;

            }
        }

        /// <summary>
        /// Show the GridValidation 
        /// </summary>
        public void smi_ShowGridValidation()
        {
            calibrationTarget.SetActive(false);

            if (stateOfTheCalibrationView.Equals(VisualisationState.None))
            {
                anchorValidationGrid.SetActive(true);
                gazePositionTarget.SetActive(true);

                stateOfTheCalibrationView = VisualisationState.gridValidation;

                if (pauseGameWhileCalibration)
                {
                    Time.timeScale = 0;
                }
            }
        }

        /// <summary>
        /// Start the Calibration
        /// </summary>
        public void smi_CalibrateInClient()
        {
            targetID = 0;
            stateOfTheCalibrationView = VisualisationState.calibration;
            calibrationTarget.SetActive(true);

            calibrationThread = new Thread(job.DoWork);
            calibrationThread.Start();

            if (pauseGameWhileCalibration)
            {
                Time.timeScale = 0;
            }
        }

        /// <summary>
        /// Abort the Calibration
        /// </summary>
        public void smi_AbortCalibation()
        {
            targetID = 0;
            SMIGazeController.Instance.smi_abortCalibration();
            calibrationThread.Abort();
            stateOfTheCalibrationView = VisualisationState.None;
        }

        /// <summary>
        /// Abort the Validation 
        /// </summary>
        public void smi_AbortValidation()
        {
            targetID = 0;
            stateOfTheCalibrationView = VisualisationState.None;
            gazePositionTarget.SetActive(false);
            if (pauseGameWhileCalibration)
            {
                Time.timeScale = 1;
            }
        }
        #endregion

        #region private methods

        /// <summary>
        /// Activate the extra CalibrationLayer and set the Backgroundcolor for the Background.
        /// </summary>
        /// <param name="status"> which status should be used</param>
        private void smi_SetStatusOfCalibrationModeOfCameras(bool status)
        {
            for (int i = 0; i < renderCameras.Length; i++)
            {
                renderCameras[i].EnableCalibrationMode(status);
            }
        }

        /// <summary>
        /// Setup the CalibrationView
        /// </summary>
        private void smi_InitCalibrationView()
        {
            //Instanciate the Targets
            calibrationTarget = Instantiate(Resources.Load("CalibrationTarget", typeof(GameObject)), transform.position, Quaternion.identity) as GameObject;
            calibrationTarget.layer = calibrationLayer;
            calibrationTarget.SetActive(false);



            foreach (Transform child in calibrationTarget.transform)
            {
                child.gameObject.layer = calibrationLayer;
            }
            calibrationTarget.layer = calibrationLayer;

            //Setup the Thread
            job = new CalibrationJob();
            calibrationThread = new Thread(job.DoWork);

            for (int i = 0; i < renderCameras.Length; i++)
            {
                renderCameras[i].calibrationLayer = LayerMask.LayerToName(calibrationLayer);
            }
        }

        /// <summary>
        /// Add the Components to the SMI Visualizer
        /// </summary>
        private void smi_InitValidationView()
        {

            //ValidationGrid;
            anchorValidationGrid = Instantiate(Resources.Load("ValidationGrid", typeof(GameObject)), transform.position, Quaternion.identity) as GameObject;
            anchorValidationGrid.name = "ValidationGrid";
            anchorValidationGrid.transform.parent = gameObject.transform;
            anchorValidationGrid.layer = calibrationLayer;
            anchorValidationGrid.transform.localRotation = Quaternion.identity;
            anchorValidationGrid.SetActive(false);

            //gazeTarget for the Grid Validation
            gazePositionTarget = Instantiate(Resources.Load("GazeTarget", typeof(GameObject)), transform.position, Quaternion.identity) as GameObject;
            gazePositionTarget.name = "GazeTarget";
            gazePositionTarget.transform.parent = anchorValidationGrid.transform.parent;
            gazePositionTarget.layer = calibrationLayer;
            gazePositionTarget.SetActive(false);

            //ValidationView
            anchorValidationView = Instantiate(Resources.Load("ValidationView", typeof(GameObject)), transform.position, Quaternion.identity) as GameObject;
            anchorValidationView.name = "ValidationView";
            anchorValidationView.transform.parent = gameObject.transform;
            anchorValidationView.transform.localRotation = Quaternion.identity;
            anchorValidationView.layer = calibrationLayer;

            TextViewValidation = gameObject.GetComponentInChildren<SMItextView>();
            anchorValidationView.SetActive(false);

            //GazeTargets to visualize the position of the Gaze in for the ValidationScreen 
            gazeTargetsOfQuantiativeValidation = new GameObject[4];
            for (int i = 0; i < 4; i++)
            {
                gazeTargetsOfQuantiativeValidation[i] = Instantiate(Resources.Load("GazeTarget", typeof(GameObject)), transform.position, Quaternion.identity) as GameObject;
                gazeTargetsOfQuantiativeValidation[i].transform.parent = anchorValidationView.transform;
                gazeTargetsOfQuantiativeValidation[i].name = "GazeTarget";
                gazeTargetsOfQuantiativeValidation[i].SetActive(false);
                gazeTargetsOfQuantiativeValidation[i].layer = calibrationLayer;
            }
        }

        /// <summary>
        /// Set the Position of the Target to the next position of the targetPositionArray or finish the Calibrationview after the last Point
        /// </summary>
        private void smi_UpdateTargetPosition()
        {

            SMIGazeController.SMIcWrapper.smi_startDetectingNewFixation();

            if (stateOfTheCalibrationView.Equals(VisualisationState.calibration) && (targetID < targetPositions.Length))
            {

                job.AcceptCalibrationPoint(targetPositions[targetID]);
                ++targetID;
            }
            else if (stateOfTheCalibrationView.Equals(VisualisationState.quantitativeValidation) && (targetID < targetPositions.Length))
            {
                positionsOfPORForQuantiativeValidation[targetID] = SMI.SMIGazeController.Instance.smi_getSample().por;
                smi_SaveAngleBetweenPORAndTarget(targetPositions[targetID]);

                ++targetID;
            }

            if(targetID == targetPositions.Length)
            {
                //Calibration
                if (stateOfTheCalibrationView.Equals(VisualisationState.calibration))
                {
                    smi_FinishCalibration();
                }

                //Validation
                else
                {
                    smi_FinishValidation();
                }
            }
        }

        /// <summary>
        /// Calculates the Angle between the POR and the 
        /// </summary>
        /// <param name="targetPosition"></param>
        private void smi_SaveAngleBetweenPORAndTarget(Vector2 targetPosition)
        {
            Vector2 position = SMI.SMIGazeController.Instance.smi_getSample().por;
            positionsOfPORForQuantiativeValidation[targetID] = position;
            validationItems[targetID] = Mathf.Sqrt(Mathf.Pow(position.x - targetPosition.x, 2) + Mathf.Pow(position.y - targetPosition.y, 2)) * (float)(1f / 18f);
        }

        /// <summary>
        /// Finishe the Validation Screen: 
        /// - Close the Grid Validation
        /// - Opens the Final State of the Quantitative Validation
        /// </summary>
        public void smi_FinishValidation()
        {
            //Grid Validation: Instead Quit the View
            if (stateOfTheCalibrationView.Equals(VisualisationState.gridValidation))
            {

                gazePositionTarget.SetActive(false);
                anchorValidationGrid.SetActive(false);

                stateOfTheCalibrationView = VisualisationState.None;

                if (pauseGameWhileCalibration)
                {
                    Time.timeScale = 1;
                }
            }

            else if (stateOfTheCalibrationView.Equals(VisualisationState.quantitativeValidation))
            {
                StartCoroutine(ResumeAfterTimeout());
            }
        }

        /// <summary>
        /// Close the Calibrationview
        /// </summary>
        public void smi_FinishCalibration()
        {
            calibrationTarget.SetActive(false);
			gazePositionTarget.SetActive (false);
			anchorValidationGrid.SetActive (false);

            targetID = 0;
            stateOfTheCalibrationView = VisualisationState.None;

            try
            {
                calibrationThread.Join();
            }
            catch (System.Exception e)
            {
                Debug.LogException(e);
            }


            if (pauseGameWhileCalibration)
            {
                Time.timeScale = 1;
            }
        }

        private Vector3 smi_CalculatePositionOnGazeMappingPlane(Vector2 Position, float planeDistForMapping)
        {
            Matrix4x4 localToWorldMatrixCamera = rayCam.gameObject.transform.localToWorldMatrix;
            Matrix4x4 playerTransformMatrix = Matrix4x4.identity;

            Vector3 porAverageGaze = Position;
            Vector3 cameraPor3d = smi_TransformGazePositionToWorldPosition(porAverageGaze,planeDistForMapping);

            //Position of the GazePos
            Vector3 instancePosition = playerTransformMatrix.MultiplyPoint(localToWorldMatrixCamera.MultiplyPoint(cameraPor3d));

            return instancePosition;
        }

        private Vector3 smi_TransformGazePositionToWorldPosition(Vector2 gazePos,float planeDistForMapping)
        {
            
            float gazeScreenWidth = 1920f;
            float gazeScreenHeight = 1080f;
            float horizFieldOfView = 87f * Mathf.Deg2Rad;
            float vertFieldOfView = horizFieldOfView;

            float xOff = planeDistForMapping * Mathf.Tan(horizFieldOfView / 2f);
            float yOff = planeDistForMapping * Mathf.Tan(vertFieldOfView / 2f);
            float zOff = planeDistForMapping;

            Vector3 gazePosInWorldSpace = new Vector3(smi_CalculateGazeOffset(gazePos.x, gazeScreenWidth, xOff), -smi_CalculateGazeOffset(gazePos.y, gazeScreenHeight, yOff), zOff);

            return gazePosInWorldSpace;
        }

        private float smi_CalculateGazeOffset(float xin, float gazeScreenWidth, float offset)
        {
            return (xin * 2f * offset) / gazeScreenWidth - offset;
        }

        /// <summary>
        /// Prints the final Accuracy in the TextView
        /// </summary>
        private void smi_ShowValidationText()
        {
            float Accuracy = 0f;

            for (int i = 0; i < validationItems.Length; i++)
            {
                Accuracy += validationItems[i];
            }

            Accuracy /= validationItems.Length;
            TextViewValidation.SetText("Average Accuracy: " + System.Math.Round(Accuracy,3) + "°");
        }

        /// <summary>
        /// Resumes to the game after a short waitingtime
        /// </summary>
        /// <returns></returns>
        IEnumerator ResumeAfterTimeout()
        {
            anchorValidationView.SetActive(true);

            calibrationTarget.SetActive(false);
            gazePositionTarget.SetActive(false);

            smi_ShowValidationText();

            for (int i = 0; i < gazeTargetsOfQuantiativeValidation.Length; i++)
            {
                gazeTargetsOfQuantiativeValidation[i].transform.position = smi_CalculatePositionOnGazeMappingPlane(positionsOfPORForQuantiativeValidation[i], ganzemappingDistanceValidation);
                gazeTargetsOfQuantiativeValidation[i].SetActive(true);
            }

            anchorValidationView.SetActive(true);
            TextViewValidation.SetTextVisible(true);

            yield return new WaitForSeconds(5);

            targetID = 0;
            stateOfTheCalibrationView = VisualisationState.None;

            anchorValidationView.SetActive(false);
            TextViewValidation.SetTextVisible(false);

            //Remove the Targets from the Scene
            for (int i = 0; i < gazeTargetsOfQuantiativeValidation.Length; i++)
            {
                gazeTargetsOfQuantiativeValidation[i].SetActive(false);
            }

            if (pauseGameWhileCalibration)
            {
                Time.timeScale = 1;
            }
        }
    }
        #endregion

    /// <summary>
    /// Task for the CalibrationThread
    /// </summary>
    public class CalibrationJob
    {
        /// <summary>
        /// Start the Calibrationmode of the System; Note that this Thread will be bocked from the Server and waits for the Selected TargetCount (AcceptCalibrationPoint)
        /// </summary>
        public void DoWork()
        {
            SMIGazeController.SMIcWrapper.smi_startDetectingNewFixation();
            SMIGazeController.SMIcWrapper.smi_calibrate();
        }

        /// <summary>
        /// Accept manually the current target
        /// </summary>
        public void AcceptCalibrationPoint(Vector2 targetPos)
        {
            SMI.SMIGazeController.SMIcWrapper.smi_Vec2d targetPoint = new SMIGazeController.SMIcWrapper.smi_Vec2d();
            targetPoint.x = (double)targetPos.x;
            targetPoint.y = (double)targetPos.y;
            SMIGazeController.SMIcWrapper.smi_acceptCalibrationPoint(targetPoint);
        }

        /// <summary>
        /// Stop of the Calibration. Stops the calibrationMode of the server and reset the calibration
        /// </summary>
        public void RequestStop()
        {
            SMIGazeController.SMIcWrapper.smi_AbortCalibration();
        }
    }
}