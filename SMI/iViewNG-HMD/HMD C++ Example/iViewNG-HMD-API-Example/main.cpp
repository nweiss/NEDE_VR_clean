#include <iostream>
#include <string>
#include <conio.h>
#include <windows.h>
#include <stdlib.h>
#include <fstream>

#include "iViewHMDAPI.h"

using namespace std;

// forward declaration
bool get();
bool streamEyeData = true;
// define a list to get validation points/fixations respectively
smi_Vec2d * validationPointList;
smi_Vec2d * fixationPointList;

void apiCallRC(int rc){
	cout << endl << smi_rcToString(rc) << endl;
}

void outputHelp(){
	cout << endl;
	cout << " q ... quit application" << endl;
	cout << endl;
	cout << " 1 ... start one point calibration" << endl;
	cout << " 3 ... start three point calibration" << endl;
	cout << " 5 ... start five point calibration" << endl;
	cout << " 9 ... start nine point calibration" << endl;
	cout << " n ... reset calibration" << endl;
	cout << endl;
	cout << " h ... save the current calibration" << endl;
	cout << " j ... list available calibrations" << endl;
	cout << " k ... load a calibration" << endl;
	cout << endl;
	cout << " e ... show/hide eye image monitor" << endl;
	cout << " v ... show verification visualization" << endl;
	cout << " b ... show quantitative validation" << endl;
	cout << " ESC . close verification visualization" << endl;
	cout << endl;
	cout << " s ... start eye image streaming" << endl;
	cout << " u ... stop eye image streaming" << endl;
	cout << endl;
}
//
// some information is commented out just because it will spam the command line
//
void sampleToString(smi_SampleHMDStruct * sample){
	if (streamEyeData) {cout<< " timestamp " << sample->timestamp 
		<< " PORx: " << sample->por.x
		<< " PORy: " << sample->por.y
		//<< " iod: " << sample->iod
		//<< " ipd: " << sample->ipd
		//<< " gazeDirection.x: " << sample->gazeDirection.x
		//<< " gazeDirection.y: " << sample->gazeDirection.y 
		//<< " gazeDirection.z: " << sample->gazeDirection.z
		//<< " isValid: "			<< sample->isValid

		//<< " Left PORx: " << sample->left.por.x
		//<< " Left PORy: " << sample->left.por.y
		//<< " left.eyeballCenter.x: " << sample->left.gazeBasePoint.x
		//<< " left.eyeballCenter.y: " << sample->left.gazeBasePoint.y 
		//<< " left.eyeballCenter.z: " << sample->left.gazeBasePoint.z 
		//<< " left.gazeDirection.x: " << sample->left.gazeDirection.x
		//<< " left.gazeDirection.y: " << sample->left.gazeDirection.y
		//<< " left.gazeDirection.z: " << sample->left.gazeDirection.z
		//<< " left.eyeLensDistance: " << sample->left.eyeLensDistance
		//<< " left.eyeScreenDistance: " << sample->left.eyeScreenDistance
		//<< " left.pupilPosition.x: " << sample->left.pupilPosition.x
		//<< " left.pupilPosition.y: " << sample->left.pupilPosition.y
		//<< " left.pupilPosition.z: " << sample->left.pupilPosition.z
		//<< " left.pupilRadius: " << sample->left.pupilRadius

		//<< " Right PORx: " << sample->right.por.x 
		//<< " Right PORy: " << sample->right.por.y
		//<< " right.eyeballCenter.x: " << sample->right.gazeBasePoint.x
		//<< " right.eyeballCenter.y: " << sample->right.gazeBasePoint.y
		//<< " right.eyeballCenter.z: " << sample->right.gazeBasePoint.z
		//<< " right.gazeDirection.x: " << sample->right.gazeDirection.x
		//<< " right.gazeDirection.y: " << sample->right.gazeDirection.y
		//<< " right.gazeDirection.z: " << sample->right.gazeDirection.z
		//<< " right.eyeLensDistance: " << sample->right.eyeLensDistance
		//<< " right.eyeScreenDistance: " << sample->right.eyeScreenDistance
		//<< " right.pupilPosition.x: " << sample->right.pupilPosition.x
		//<< " right.pupilPosition.y: " << sample->right.pupilPosition.y
		//<< " right.pupilPosition.z: " << sample->right.pupilPosition.z
		//<< " right.pupilRadius: " << sample->right.pupilRadius
		<< "       \r";
	cout.flush();
	}
}

void CALLBACK myCallback (smi_CallbackDataStruct * result){
	switch (result->type){
		case SMI_SIMPLE_GAZE_SAMPLE:
			{ // check the type
				smi_SampleHMDStruct * sample = (smi_SampleHMDStruct*)result->result; // cast the result
				sampleToString(sample);
				break;
			}
		case SMI_EYE_IMAGE_LEFT:
			{
				cout << endl << "got left eye image" << endl;
				break;
			}
		case SMI_EYE_IMAGE_RIGHT:
			{
				cout << endl << "got right eye image" << endl;
				break;
			}
	}
}

int main( int argc, const char* argv[] ){
	
	int rc; 

	cout << "smi_SetCallback: ";
	apiCallRC(rc = smi_setCallback(myCallback));

	outputHelp();

	smi_TrackingParameterStruct params;
	memset(&params, 0, sizeof(smi_TrackingParameterStruct));
	params.mappingDistance = 1500; // map to vergence distance

	bool simulateData = false;

	cout << "smi_StartStreaming" << (simulateData ? "(simulated)" : "") << ": " << endl;
	
	apiCallRC(rc = smi_startStreaming(simulateData, &params)); 
	if(rc != SMI_RET_SUCCESS)
	{
		if(!simulateData && (rc == SMI_ERROR_CONNECTING_TO_HMD || rc == SMI_ERROR_EYECAMERAS_NOT_AVAILABLE)){
			simulateData = true;
			cout << "No " << (rc==SMI_ERROR_CONNECTING_TO_HMD ? "HMD connected" : "Eye Tracker connected") <<" - starting simulation mode instead" << endl;
			cout << "smi_StartStreaming" << (simulateData ? "(simulated)" : "") << ": " << endl;
			apiCallRC(rc = smi_startStreaming(simulateData, &params)); 
		} else {
			getchar();
			return 0;
		}
	}

	// start listening for keyboard input
	get();

    return 0;
}

bool get()
{
    char c;
    while (true)
    {
        c = _getch(); // waiting for keyboard input
        
		if (c== 'q') {
			cout<< endl << "smi_Quit: ";
			apiCallRC(smi_quit());
            return true; // terminate the application
        }
		if (c == 'v'){
			cout<< endl << "smi_Validate: ";
			apiCallRC(smi_validation());
		}
		if (c == 'b'){
			cout<< endl <<  "smi_quantitativeValidation: ";
			apiCallRC(smi_quantitativeValidation(&validationPointList, &fixationPointList, true, true, 0));
		}
		if (c == '1'){
			smi_CalibrationHMDStruct * calibrationHMDStruct;
			smi_createCalibrationHMDStruct(&calibrationHMDStruct);
			calibrationHMDStruct->type = SMI_ONE_POINT_CALIBRATION;
			calibrationHMDStruct->backgroundColor->blue = 0.5;
			calibrationHMDStruct->backgroundColor->green = 0.5;
			calibrationHMDStruct->backgroundColor->red = 0.5;
			calibrationHMDStruct->foregroundColor->blue = 1.0;
			calibrationHMDStruct->foregroundColor->green = 1.0;
			calibrationHMDStruct->foregroundColor->red = 1.0;

			cout << endl << "smi_Calibrate (1 point): ";
			apiCallRC(smi_setupCalibration(calibrationHMDStruct));
			apiCallRC(smi_calibrate());
		}
		if (c == '3'){
			smi_CalibrationHMDStruct * calibrationHMDStruct;
			smi_createCalibrationHMDStruct(&calibrationHMDStruct);
			calibrationHMDStruct->type = SMI_THREE_POINT_CALIBRATION;
			calibrationHMDStruct->backgroundColor->blue = 0.5;
			calibrationHMDStruct->backgroundColor->green = 0.5;
			calibrationHMDStruct->backgroundColor->red = 0.5;
			calibrationHMDStruct->foregroundColor->blue = 1.0;
			calibrationHMDStruct->foregroundColor->green = 1.0;
			calibrationHMDStruct->foregroundColor->red = 1.0;

			cout << endl << "smi_Calibrate (3 points): ";
			apiCallRC(smi_setupCalibration(calibrationHMDStruct));
			apiCallRC(smi_calibrate());
		}
		if (c == '5'){
			smi_CalibrationHMDStruct * calibrationHMDStruct;
			smi_createCalibrationHMDStruct(&calibrationHMDStruct);
			calibrationHMDStruct->type = SMI_FIVE_POINT_CALIBRATION;
			calibrationHMDStruct->backgroundColor->blue = 0.5;
			calibrationHMDStruct->backgroundColor->green = 0.5;
			calibrationHMDStruct->backgroundColor->red = 0.5;	
			calibrationHMDStruct->foregroundColor->blue = 1.0;
			calibrationHMDStruct->foregroundColor->green = 1.0;
			calibrationHMDStruct->foregroundColor->red = 1.0;

			cout << endl << "smi_Calibrate (5 points): ";
			apiCallRC(smi_setupCalibration(calibrationHMDStruct));
			apiCallRC(smi_calibrate());
		}

		if (c == '9') {
			smi_CalibrationHMDStruct * calibrationHMDStruct;
			smi_createCalibrationHMDStruct(&calibrationHMDStruct);
			calibrationHMDStruct->type = SMI_NINE_POINT_CALIBRATION;
			calibrationHMDStruct->backgroundColor->blue = 0.5;
			calibrationHMDStruct->backgroundColor->green = 0.5;
			calibrationHMDStruct->backgroundColor->red = 0.5;	
			calibrationHMDStruct->foregroundColor->blue = 1.0;
			calibrationHMDStruct->foregroundColor->green = 1.0;
			calibrationHMDStruct->foregroundColor->red = 1.0;

			cout << endl << "smi_Calibration (9 points): ";
			apiCallRC(smi_setupCalibration(calibrationHMDStruct));
			apiCallRC(smi_calibrate());
		}
		if (c == 'n'){
			cout << endl << "smi_ResetCalibration: ";
			apiCallRC(smi_resetCalibration());
		}
		if (c == 'e'){
			static bool showeyeImages = false;
			showeyeImages = !showeyeImages;
			if(showeyeImages){
				cout << endl << "smi_ShowEyeImageMonitor: " << endl;
				smi_showEyeImageMonitor();
			}else{
				cout << endl << "smi_HideEyeImageMonitor: " << endl;
				smi_hideEyeImageMonitor();
			}
		}
		if (c == 's'){
			cout << endl << "smi_startEyeImageStreaming: " << endl;
			apiCallRC(smi_startEyeImageStreaming());
		}
		if (c == 'u'){
			cout << endl << "smi_stopEyeImageStreaming: " << endl;
			apiCallRC(smi_stopEyeImageStreaming());
		}
		if (c == 'h') {
			streamEyeData = false;
			cout << endl;
			cout << endl << "smi_saveCalibration" << endl;
			std::string name;
			getline(cin, name);
			char * _name = new char[name.length() + 1];
			strcpy(_name, name.c_str());
			apiCallRC(smi_saveCalibration(_name));
			delete [] _name;
			streamEyeData = true;
		}
		if (c == 'j') {
			cout << endl << "smi_getAvailableCalibrations" << endl;
			char * avCalibrations;
			avCalibrations = smi_getAvailableCalibrations();
			cout << endl << avCalibrations<< endl;
		}
		if (c == 'k') {
			streamEyeData = false;
			cout << endl;
			cout << endl << "smi_loadCalibration" << endl;
			std::string name;
			getline(cin, name);
			char *_name = new char[name.length() + 1];
			strcpy(_name, name.c_str());			
			apiCallRC(smi_loadCalibration(_name));
			delete [] _name;
			streamEyeData = true;
		}
		if (c == 'm') {
			cout << endl << "smi_getServerTime" << endl;
			long long ts = smi_getServerTime();
			cout << endl << ts << endl;
		}
    }
}