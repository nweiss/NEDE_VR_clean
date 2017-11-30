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

namespace SMI
{
    /// <summary>
    /// Textcomponent for the VisualisationScreen
    /// </summary>
    public class SMItextView : MonoBehaviour
    {

        public Text textView;

        private string text;
        private bool isVisible = false;

        public bool IsVisible
        {
            get
            {
                return isVisible;
            }
            set
            {
                textView.gameObject.SetActive(value);
                isVisible = value;
            }
        }

        public string Text
        {
            get
            {
                return text;
            }
            set
            {
                textView.text = value;
                text = value;
            }
        }

        /// <summary>
        /// Set the string of the text
        /// </summary>
        /// <param name="text"></param>
        public void SetText(string text)
        {
            this.text = text;
            textView.text = text;
        }

        /// <summary>
        /// Show the TextComponent
        /// </summary>
        /// <param name="isVisible"></param>
        public void SetTextVisible(bool isVisible)
        {
            this.isVisible = isVisible;
            textView.gameObject.SetActive(this.isVisible);
        }

        /// <summary>
        /// Create A reference to the TextComponent
        /// </summary>
        void Awake()
        {

            textView = GetComponentInChildren<Text>();
        }
    }
}