using UnityEngine;
using System.Collections;
using UnityEngine.UI;

public class SetupOverlay : MonoBehaviour {

	public RawImage VRViewImage;
	public RawImage BirdsEyeViewImage;

	public Camera firstPersonCamera;

	// Use this for initialization
	void Start () {

	}

	// Update is called once per frame
	void Update () {
		scaleOverlaysToGameSize ();
	}

	void scaleOverlaysToGameSize(){
		int w = firstPersonCamera.pixelWidth;
		int h = firstPersonCamera.pixelHeight;



		VRViewImage.rectTransform.sizeDelta = new Vector2 (w/2, h/2);
		BirdsEyeViewImage.rectTransform.sizeDelta = new Vector2 (w/2, h/2);
	}
}

