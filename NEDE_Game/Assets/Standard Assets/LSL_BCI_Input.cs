using UnityEngine;
using System.Collections;
using System;
using System.Threading;
using LSL;
using System.Linq;

public class LSL_BCI_Input : MonoBehaviour {
	public liblsl.StreamOutlet Outlet  = null; //Unity wont recognize Outlet in the Update function unless it is declared globally
	private liblsl.StreamInlet Inlet = null;

	// Neil 12/07
	void Start(){

		// Create LSL stream outlet from Unity
		liblsl.StreamInfo UnityStream = new liblsl.StreamInfo ( "NEDE_Stream", "object_info", 17, 0, liblsl.channel_format_t.cf_float32, "NEDE_position" );
		Outlet = new liblsl.StreamOutlet(UnityStream);
		if (Outlet != null){
			Debug.Log("LSL Stream outlet created");
		}
		else{
			Debug.Log("Error creating LSL stream outlet");
		}

		// Create LSL stream inlet in Unity
		//liblsl.StreamInfo[] results = liblsl.resolve_stream("name", "Python");
		// Create LSL stream inlet from Matlab
		//liblsl.StreamInfo[] results = liblsl.resolve_stream("name", "NEDE_Stream_Response"); // 9/13/17

//		Inlet = new liblsl.StreamInlet(results[0]);
//		Debug.Log("Inlet Created: " + Inlet);
	}

	// pushLSL() function pushes data to the outlet
	// Outlet is the liblsl.StreamOutlet created above
	// LSLdata is an array of floats that you want to push
	public void pushLSL(float[] LSLdata) {
		Outlet.push_sample(LSLdata);
	}

	// receiveLSL() function receives data from the Inlet
	// Inlet is the liblsl.StreamInlet created above
	// sample is an array of floats that the function returns
	public float[] receiveLSL(){
		float[] sample = new float[3];
		double ts;
		ts = Inlet.pull_sample(sample, 0.0);
		//ts = Inlet.pull_sample(sample, .0133);
		return sample;
	}
}