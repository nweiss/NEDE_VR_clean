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
using UnityEngine.EventSystems;

namespace SMI
{
    public class SMILoadAndSaveCalibration : MonoBehaviour
    {

        public static bool isCalibrationMenuOpen = false; 

        private InputField nameField;
        private MaskableGraphic[] items;
        private Text headline;

        private CalibrationMenuMode selectedMode;
        public enum CalibrationMenuMode
        {
            SaveCalibration, 
            LoadCalibration
        }

        void Start()
        {
            headline = GetComponentInChildren<Text>();
            items = GetComponentsInChildren<MaskableGraphic>();
            nameField = GetComponentInChildren<InputField>();
            nameField.onEndEdit.AddListener((value) => ReactOnEnter(value));
            SetViewsActive(false);
        }

        public void ShowLoadCalibrationScreen()
        {
            SetViewsActive(true);
            nameField.text = "";
            headline.text = "Load Calibration";
            SetCalibrationMenuMode(CalibrationMenuMode.LoadCalibration);
            EventSystem.current.SetSelectedGameObject(nameField.gameObject);
			nameField.Select ();
			nameField.ActivateInputField ();
        }
        
        public void ShowSaveCalibrationScreen()
        {
            SetViewsActive(true);
            nameField.text = "";
            headline.text = "Save Calibration";
            SetCalibrationMenuMode(CalibrationMenuMode.SaveCalibration);
            EventSystem.current.SetSelectedGameObject(nameField.gameObject);
			nameField.Select ();
			nameField.ActivateInputField ();
        }


        private void SetViewsActive(bool isActive)
        {
            foreach (MaskableGraphic item in items)
            {
				item.transform.localRotation = Quaternion.Euler(Vector3.zero);
                item.gameObject.SetActive(isActive);
            }
            SMILoadAndSaveCalibration.isCalibrationMenuOpen = isActive;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="mode"></param>
        private void SetCalibrationMenuMode(CalibrationMenuMode mode)
        {
            selectedMode = mode; 
        }
        
        private void ReactOnEnter(string input)
        {
            int result = 0;

            //Load
            if (selectedMode == CalibrationMenuMode.LoadCalibration)
            {
                result = SMI.SMIGazeController.SMIcWrapper.smi_loadCalibration(input);
            }

            //Save
            else
            {
                result = SMI.SMIGazeController.SMIcWrapper.smi_saveCalibration(input);
                
            }

            reactOnLoading(result);
        }


        private void reactOnLoading(int result)
        {
            nameField.gameObject.SetActive(false);
            //Sucess
            if(result == 1)
            {
                switch(selectedMode)
                {
                    case CalibrationMenuMode.SaveCalibration:
                        headline.text = "Calibration sucessful saved";
						SMILoadAndSaveCalibration.isCalibrationMenuOpen = false;
                        break;

                    case CalibrationMenuMode.LoadCalibration:
                        headline.text = "Calibration sucessful loaded";
						SMILoadAndSaveCalibration.isCalibrationMenuOpen = false;
						break;
                }
            }
                //No Sucess
            else
            {

                switch (selectedMode)
                {
                    case CalibrationMenuMode.SaveCalibration:
                        headline.text = "Saving failed";
                        break;

                    case CalibrationMenuMode.LoadCalibration:
                        headline.text = "Loading failed";
                        break;
                }
            }

            StartCoroutine(CloseMenuAfterTime());
        }
		
		
		public string[] GetAvailabeCalibrationyByName()
		{
			return SMI.SMIGazeController.SMIcWrapper.smi_getAvailableCalibrations();
		}
		
		IEnumerator CloseMenuAfterTime()
		{
			yield return new WaitForSeconds(2);
            SetViewsActive(false);

        }

    }
}
