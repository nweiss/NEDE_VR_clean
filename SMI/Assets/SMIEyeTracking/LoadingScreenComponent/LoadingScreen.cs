
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
using UnityEngine.UI;
using SMI;

namespace SMI
{
    public class LoadingScreen : MonoBehaviour
    {

        public Text loadingScreenText;
        public Text calibrationInformationView;
        LoadingIcon loadingWheel;

        private MaskableGraphic[] loadingScreenElements;

        private bool isFinished = false;

        private Color fontColor;
        private Color destinationColorText;
        private Color destinationColorCalibrationView;

        private bool isDone = false;

        #region Unity Members

        /// <summary>
        /// Setup the LoadingScreen and set the Colors of the TextViews
        /// </summary>
        void Start()
        {
            Transform[] elements = gameObject.GetComponentsInChildren<Transform>(true);

            foreach (Transform element in elements)
            {
                element.gameObject.SetActive(true);
            }

            //Safe all Children
            loadingScreenElements = GetComponentsInChildren<MaskableGraphic>();
            //Get the TextComponent
            loadingScreenText = GetComponentInChildren<Text>();
            //Get the LoadingIcon
            loadingWheel = GetComponentInChildren<LoadingIcon>();
            //Safe the Color
            fontColor = loadingScreenText.color;

            //Setup the StartColors of the TextViews
            destinationColorText = fontColor;
            destinationColorCalibrationView = fontColor;

            //hide the CalibrationView per default
            calibrationInformationView.color = Color.clear;
        }

        /// <summary>
        /// Update the Colors and Change the DestinationColor of the Elements depending of the state of the Setup
        /// </summary>
        void Update()
        {
            updateTextColor();


            //Fade out the Screen
            if (isDone)
            {

                foreach (MaskableGraphic item in loadingScreenElements)
                {
                    item.color = Color.Lerp(item.color, Color.clear, Time.deltaTime * 8f);
                    destinationColorText = Color.clear;
                    destinationColorCalibrationView = Color.clear;
                    loadingWheel.FadeOut();
                }
            }

            //Write the Result of the Setup to the Screen
            if ((SMI.SMIGazeController.GazeModel.connectionRoutineDone) && !isFinished)
            {
                isFinished = true;
                setFinishedMode(SMI.SMIGazeController.GazeModel.ErrorID);
            }
        }
        #endregion

        #region private Members

        /// <summary>
        /// Set the Textcolor of the LoadingText
        /// </summary>
        private void updateTextColor()
        {
            //Fade the LoadingScreen
            if (loadingScreenText.color != destinationColorText)
            {
                loadingScreenText.color = Color.Lerp(loadingScreenText.color, destinationColorText, Time.deltaTime * 5);
            }

            //Fade the CalibrationView
            if (calibrationInformationView.color != destinationColorCalibrationView)
            {
                calibrationInformationView.color = Color.Lerp(calibrationInformationView.color, destinationColorCalibrationView, Time.deltaTime * 5);
            }
        }

        /// <summary>
        /// Start the Coroutine to enable the Fadeeffect
        /// </summary>
        /// <param name="errorID"></param>
        private void setFinishedMode(int errorID)
        {
            StartCoroutine(showResult(errorID));
        }

        /// <summary>
        /// Show the final Result of the attempt to connect
        /// </summary>
        /// <param name="errorID"></param>
        /// <returns></returns>
        private IEnumerator showResult(int errorID)
        {
            destinationColorText = Color.clear;
            yield return new WaitForSeconds(0.5f);
            destinationColorText = fontColor;

            if (errorID == 1)
            {
                loadingScreenText.text = "Finished!";
                loadingWheel.SetSucessIcon();
                yield return new WaitForSeconds(1f);
            }

            else
            {
                loadingScreenText.text = SMI.SMIGazeController.SMIcWrapper.errorIDContainer.getErrorMessage(errorID);
                loadingWheel.SetFailedIcon();
                yield return new WaitForSeconds(2f);
            }

            StartCoroutine("FadeInstructions");
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        private IEnumerator FadeInstructions()
        {

            Debug.Log("FadeInstruction");
            destinationColorCalibrationView = fontColor;

            yield return new WaitForSeconds(2);
            isDone = true;
            destinationColorCalibrationView = Color.clear;

            Debug.Log("FadeInstruction Finished");
        }
        #endregion
    }
}
