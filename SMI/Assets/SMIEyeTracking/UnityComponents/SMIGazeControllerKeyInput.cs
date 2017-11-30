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
using SMI;
using System.Collections.Generic;

namespace SMI
{
    [AddComponentMenu("SMI/ SMI Default Keyboard Manager")]
    public class SMIGazeControllerKeyInput : MonoBehaviour
    {
        public bool useCalibrationMenuExample = true;

        [SerializeField]
        private KeyCode startOnePointCalibration = KeyCode.Alpha1;

        [SerializeField]
        private KeyCode startThreePointCalibration = KeyCode.Alpha3;

        [SerializeField]
        private KeyCode startFivePointCalibration = KeyCode.Alpha5;

        [SerializeField]
        private KeyCode startNinePointCalibration = KeyCode.Alpha9;

        [SerializeField]
        private KeyCode resetCalibration = KeyCode.N;

        [SerializeField]
        private KeyCode startQuantitativeValidation = KeyCode.B;

        [SerializeField]
        private KeyCode startGridValidation = KeyCode.V;

        [SerializeField]
        private KeyCode loadCalibration = KeyCode.K;

        [SerializeField]
        private KeyCode saveCalibration = KeyCode.J;


        private SMICalibrationVisualizer calibVis;
        private SMILoadAndSaveCalibration loadAndSaveCalibration;


        void Start()
        {
            calibVis = GetComponent<SMICalibrationVisualizer>();

            if (useCalibrationMenuExample)
            {
                GameObject obj = Instantiate(Resources.Load("CalibrationMenu")) as GameObject;
                obj.transform.parent = gameObject.transform;
                obj.name = "CalibrationMenu";
                loadAndSaveCalibration = obj.GetComponent<SMILoadAndSaveCalibration>();
            }
        }

        void Update()
        {
            smi_manageStandardKeyInput();
        }


        /// <summary>
        /// Start Calibrations inside of the Unityapplication
        /// </summary>
        private void smi_manageStandardKeyInput()
        {
            if (!SMILoadAndSaveCalibration.isCalibrationMenuOpen)
            {
                //Setup a CalibrationClass
                SMI.SMIGazeController.SMIcWrapper.smi_CalibrationClass calibrationInformation = new
                SMI.SMIGazeController.SMIcWrapper.smi_CalibrationClass();

                calibrationInformation.client_visualisation = true;

                //Set the Colors of the background and the foreground
                calibrationInformation.backgroundColor = SMIGazeController.Instance.backgroundColor;
                calibrationInformation.foregroundColor = SMIGazeController.Instance.foregroundColor;

                calibrationInformation.calibrationPointList = new List<Vector2>();

                #region Set the Type and Start the Calibration
                if (Input.GetKeyDown(startOnePointCalibration))
                {
					if (SMICalibrationVisualizer.stateOfTheCalibrationView.Equals(SMICalibrationVisualizer.VisualisationState.gridValidation)){
						calibVis.smi_FinishValidation();
					}
					if (SMICalibrationVisualizer.stateOfTheCalibrationView.Equals(SMICalibrationVisualizer.VisualisationState.quantitativeValidation)){
						calibVis.smi_AbortValidation();
					}
                    calibrationInformation.type = SMIGazeController.SMIcWrapper.smi_CalibrationType.OnePointCalibration;
                    calibVis.smi_SetupCalibrationInClient(calibrationInformation);
                    calibVis.smi_CalibrateInClient();
                }

                else if (Input.GetKeyDown(startThreePointCalibration))
                {
					if (SMICalibrationVisualizer.stateOfTheCalibrationView.Equals(SMICalibrationVisualizer.VisualisationState.gridValidation)){
						calibVis.smi_FinishValidation();
					}
					if (SMICalibrationVisualizer.stateOfTheCalibrationView.Equals(SMICalibrationVisualizer.VisualisationState.quantitativeValidation)){
						calibVis.smi_AbortValidation();
					}
                    calibrationInformation.type = SMIGazeController.SMIcWrapper.smi_CalibrationType.ThreePointCalibration;

                    // define a custom calibration grid (which is actually the default one) 
                    //calibrationInformation.calibrationPointList.Add(new Vector2(780, 453));
                    //calibrationInformation.calibrationPointList.Add(new Vector2(1139, 453));
                    //calibrationInformation.calibrationPointList.Add(new Vector2(960, 626));

                    calibVis.smi_SetupCalibrationInClient(calibrationInformation);
                    calibVis.smi_CalibrateInClient();
                }

                else if (Input.GetKeyDown(startFivePointCalibration))
                {
					if (SMICalibrationVisualizer.stateOfTheCalibrationView.Equals(SMICalibrationVisualizer.VisualisationState.gridValidation)){
						calibVis.smi_FinishValidation();
					}
					if (SMICalibrationVisualizer.stateOfTheCalibrationView.Equals(SMICalibrationVisualizer.VisualisationState.quantitativeValidation)){
						calibVis.smi_AbortValidation();
					}
                    calibrationInformation.type = SMIGazeController.SMIcWrapper.smi_CalibrationType.FivePointCalibration;
                    calibVis.smi_SetupCalibrationInClient(calibrationInformation);
                    calibVis.smi_CalibrateInClient();
                }

                else if (Input.GetKeyDown(startNinePointCalibration))
                {
					if (SMICalibrationVisualizer.stateOfTheCalibrationView.Equals(SMICalibrationVisualizer.VisualisationState.gridValidation)){
						calibVis.smi_FinishValidation();
					}
					if (SMICalibrationVisualizer.stateOfTheCalibrationView.Equals(SMICalibrationVisualizer.VisualisationState.quantitativeValidation)){
						calibVis.smi_AbortValidation();
					}
                    calibrationInformation.type = SMIGazeController.SMIcWrapper.smi_CalibrationType.NinePointCalibration;
                    calibVis.smi_SetupCalibrationInClient(calibrationInformation);
                    calibVis.smi_CalibrateInClient();
                }
                #endregion

                //Reset Calibration
                else if (Input.GetKeyDown(resetCalibration))
                {
                    SMIGazeController.Instance.smi_resetCalibration();
                }

                    //Show Quantitative Validation Screen
                else if (Input.GetKeyDown(startQuantitativeValidation))
                {
                    calibVis.smi_SetupQuantitativeValidation();
                }
                //Show ValidationGrid
                else if (Input.GetKeyDown(startGridValidation))
                {
                    calibVis.smi_ShowGridValidation();
                }

                else if (Input.GetKeyDown(saveCalibration))
                {
                    loadAndSaveCalibration.ShowSaveCalibrationScreen();
                }
                else if (Input.GetKeyDown(loadCalibration))
                {
                    loadAndSaveCalibration.ShowLoadCalibrationScreen(); 
                }
            }
        }
    }

}
