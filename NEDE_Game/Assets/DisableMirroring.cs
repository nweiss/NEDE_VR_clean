using UnityEngine;
using System.Collections;

public class DisableMirroring : MonoBehaviour {

	// Use this for initialization
//	IEnumerator Start ()
//	{
//		yield return new WaitForEndOfFrame ();
//		UnityEngine.VR.VRSettings.showDeviceView = false;
//		Debug.Log ("VR view disabled for Birds eye camera");
//	}
//	

	void Start() {
		Camera birdsEyeCam = GetComponent<Camera> ();
		birdsEyeCam.targetDisplay = 1;
	}


	// Update is called once per frame
	void Update () {
	
	}
}
