using UnityEngine;
using System.Collections;

public class NoMirror : MonoBehaviour {

	// Use this for initialization
	void Start () {
		UnityEngine.VR.VRSettings.showDeviceView = false;
	}
	
	// Update is called once per frame
	void Update () {
		UnityEngine.VR.VRSettings.showDeviceView = false;
	}
}
