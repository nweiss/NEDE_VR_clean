using UnityEngine;
using System.Collections;
using System;
using System.Threading;
using LSL;
using System.Linq;

public class LSL_BCI_Output : MonoBehaviour {
	public liblsl.StreamOutlet Outlet  = null;

	// Use this for initialization
	void Start(){

		// Create LSL stream outlet from Unity
		liblsl.StreamInfo UnityStream = new liblsl.StreamInfo ( "NEDE_Stream", "object_info", 15, 0, liblsl.channel_format_t.cf_float32, "NEDE_position" );
		Outlet = new liblsl.StreamOutlet(UnityStream);
		if (Outlet != null){
			Debug.Log("LSL Stream outlet created");
		}
		else{
			Debug.Log("Error creating LSL stream outlet");
		}
	}
	
	public void pushLSL(float[] LSLdata) {
		Outlet.push_sample(LSLdata);
	}
}
