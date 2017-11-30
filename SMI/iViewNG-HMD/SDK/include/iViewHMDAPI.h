/**
 *
 * (c) Copyright 1997-2015, SensoMotoric Instruments Gesellschaft für 
 * innovative Sensorik mbH
 * 
 * Permission  is  hereby granted,  free  of  charge,  to any  person  or
 * organization  obtaining  a  copy  of  the  software  and  accompanying
 * documentation  covered  by  this  license  (the  "Software")  to  use,
 * reproduce,  display, distribute, execute,  and transmit  the Software,
 * and  to  prepare derivative  works  of  the  Software, and  to  permit
 * third-parties to whom the Software  is furnished to do so, all subject
 * to the following:
 * 
 * The  copyright notices  in  the Software  and  this entire  statement,
 * including the above license  grant, this restriction and the following
 * disclaimer, must be  included in all copies of  the Software, in whole
 * or  in part, and  all derivative  works of  the Software,  unless such
 * copies   or   derivative   works   are   solely   in   the   form   of
 * machine-executable  object   code  generated  by   a  source  language
 * processor.
 * 
 * THE  SOFTWARE IS  PROVIDED  "AS  IS", WITHOUT  WARRANTY  OF ANY  KIND,
 * EXPRESS OR  IMPLIED, INCLUDING  BUT NOT LIMITED  TO THE  WARRANTIES OF
 * MERCHANTABILITY,   FITNESS  FOR  A   PARTICULAR  PURPOSE,   TITLE  AND
 * NON-INFRINGEMENT. IN  NO EVENT SHALL  THE COPYRIGHT HOLDERS  OR ANYONE
 * DISTRIBUTING  THE  SOFTWARE  BE   LIABLE  FOR  ANY  DAMAGES  OR  OTHER
 * LIABILITY, WHETHER  IN CONTRACT, TORT OR OTHERWISE,  ARISING FROM, OUT
 * OF OR IN CONNECTION WITH THE  SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * @author SMI
*/

/**
* @file iViewHMDAPI.h
*
* @brief The file contains the prototype declarations for all supported
* functions and data structs the customer can use to interact with
* SMI eyetracking HMD devices.
**/

#pragma once

#ifndef CALLBACK
#	define CALLBACK __stdcall
#endif

// ----------------------------------------------------------------------------
//for ms vc++
#if defined(_MSC_VER)
#	define DEPRECATED __declspec(deprecated)
#	if defined(__cplusplus)
#		define DLL_DEC_PRE extern "C" __declspec(dllimport)
#	else
#		define DLL_DEC_PRE extern __declspec(dllimport)
#	endif
#	define DLL_DEC_POST __stdcall
#else
// for g++
#	define DLL_DEC_PRE extern "C" __stdcall
#	define DLL_DEC_POST
#endif

// ----------------------------------------------------------------------------

#ifndef DLL_DEFINITION
#ifdef _WINDOWS
#define DLL_DEFINITION __stdcall
#else
#define DLL_DEFINITION
#endif
#endif

// ----------------------------------------------------------------------------

/**
* @enum smi_ErrorReturnValue
*/
typedef enum  {
	SMI_RET_SUCCESS				=	1,
	SMI_ERROR_NO_CALLBACK_SET	=	500,
	SMI_ERROR_CONNECTING_TO_HMD	=	501,
	SMI_ERROR_HMD_NOT_SUPPORTED	=	502,
	SMI_ERROR_NOT_IMPLEMENTED	=	504,
	SMI_ERROR_INVALID_PARAMETER	=	505,
	SMI_ERROR_EYECAMERAS_NOT_AVAILABLE	=	506,
	SMI_ERROR_OCULUS_RUNTIME_NOT_SUPPORTED	=	507,
	SMI_ERROR_FILE_NOT_FOUND	= 508,
	SMI_ERROR_FILE_EMPTY		= 509,
	SMI_ERROR_SDK_NOT_INSTALLED	= 510,
	SMI_ERROR_NO_SMI_HARDWARE	= 511,
	SMI_ERROR_UNKNOWN			=	512
} smi_ErrorReturnValue;

/**
*  @enum smi_StreamTypeEnum
*/
typedef enum {
	SMI_SIMPLE_GAZE_SAMPLE,
	SMI_EYE_IMAGE_LEFT,
	SMI_EYE_IMAGE_RIGHT
} smi_StreamTypeEnum;

/**
*  @enum smi_CalibrationTypeEnum
*/
typedef enum {
	SMI_NONE, 
	SMI_ONE_POINT_CALIBRATION, 
	SMI_THREE_POINT_CALIBRATION,
	SMI_FIVE_POINT_CALIBRATION,
	SMI_NINE_POINT_CALIBRATION
} smi_CalibrationTypeEnum;

/**
* @struct smi_Vec3d
*/
typedef struct {
	double x;
	double y;
	double z;
} smi_Vec3d;

/**
* @struct smi_Vec2d
*/
typedef struct {
	double x;
	double y;
} smi_Vec2d;

/**
* @struct smi_ColorStruct
*/
typedef struct {
	//! red color part for customization of the calibration and validation visualization [0..1] 
	double red;

	//! green color part for customization of the calibration and validation visualization [0..1] 
	double green;

	//! blue color part for customization of the calibration and validation visualization [0..1] 
	double blue;
} smi_ColorStruct;


/**
* @struct smi_CallbackDataStruct
*
* @brief Result struct holding data delivered via callback
* check the type and cast into the according struct
*
*/
typedef struct {
	//! type of the result which gives a hint how to cast the result
	smi_StreamTypeEnum type;		

	//! pointer to the data, cast using the type member
	void * result;				
} smi_CallbackDataStruct;



/**
* @struct smi_CalibrationHMDStruct
* 
* @brief set up calibration parameters
*/
typedef struct {
	//! Type of the Calibration
	smi_CalibrationTypeEnum type;

	//! Points to use for the Calibration, have to be set in full display resolution (1920 x 1080)
	//! Fill the array according to calibration type
	//!	Only fill if you want to change the position of the SMI default calibration
	//! 1 Point calibration set calibrationPointList[0]
	//! 3 Point calibration set calibrationPointList[0], calibrationPointList[1], calibrationPointList[2]
	//! 5 Point calibration set calibrationPointList[0], calibrationPointList[1], calibrationPointList[2], calibrationPointList[3], calibrationPointList[4]
	smi_Vec2d * calibrationPointList;

	//! Determines the background color of the calibration visualization during the calibration process
	smi_ColorStruct * backgroundColor;

	//! Determines the calibration point color of the calibration visualization during the calibration process
	smi_ColorStruct * foregroundColor;
	
	//! Disable default calibration visualization if this is set to true
	bool client_visualization;

	//! Set a timeout timer for the default SMI calibration in [ms]. Disabled if set to 0 / not set
	int calibrationTimer;

} smi_CalibrationHMDStruct; 

/**
* @struct smi_TrackingParameterStruct
* 
* @brief settings which affect the output data
*/
typedef struct {
	//! Distance of the mapping plane for the 2D Point of Regard [mm], default distance is 1500 mm
	//! Value of DBL_MAX will result in a dynamic mapping distance at the vergence depth of the monocular gaze rays, note that this may result in noisier data
	double mappingDistance;

	//! Disable stabilization filter for the 2D Point of Regard if this is set to true
	bool disableGazeFilter;
	
} smi_TrackingParameterStruct; 

/**
* @struct smi_EyeDataHMDStruct
*
* @brief smi_EyeDataHMDStruct which holds information regarding gaze direction in space as well as in screen coordinates
*/
typedef struct {
	//! coordinates of the gaze base point in a right handed coordinate system (x-left, y-up, z-forward) [mm]
	smi_Vec3d	gazeBasePoint;

	//! normalized gaze direction
	smi_Vec3d	gazeDirection;		 

	//! x, y mapped gaze coordinates [px]; (0, 0) represents the top left corner of the display
	smi_Vec2d	por;

	//! pupil radius [mm]
	double	pupilRadius;

	//! coordinates of pupil position [mm] (given in the same coordinate system as gazeBasePoint)
	smi_Vec3d   pupilPosition;

	//! distance eye to lens [mm]
	double eyeLensDistance;

	//! distance eye to screen [mm]
	double eyeScreenDistance;

} smi_EyeDataHMDStruct;

/*
 * The following definitions (until #endif)
 * is an extract from IPL headers.
 * Copyright (c) 1995 Intel Corporation.
 */
#define IPL_DEPTH_SIGN 0x80000000

#define IPL_DEPTH_1U     1
#define IPL_DEPTH_8U     8
#define IPL_DEPTH_16U   16
#define IPL_DEPTH_32F   32

#define IPL_DEPTH_8S  (IPL_DEPTH_SIGN| 8)
#define IPL_DEPTH_16S (IPL_DEPTH_SIGN|16)
#define IPL_DEPTH_32S (IPL_DEPTH_SIGN|32)

#define IPL_DATA_ORDER_PIXEL  0
#define IPL_DATA_ORDER_PLANE  1

#define IPL_ORIGIN_TL 0
#define IPL_ORIGIN_BL 1

#define IPL_ALIGN_4BYTES   4
#define IPL_ALIGN_8BYTES   8
#define IPL_ALIGN_16BYTES 16
#define IPL_ALIGN_32BYTES 32

#define IPL_ALIGN_DWORD   IPL_ALIGN_4BYTES
#define IPL_ALIGN_QWORD   IPL_ALIGN_8BYTES

#define IPL_BORDER_CONSTANT   0
#define IPL_BORDER_REPLICATE  1
#define IPL_BORDER_REFLECT    2
#define IPL_BORDER_WRAP       3

/**
 * When subscribing to #IVIEWDATASTREAM_GAZE_INFORMATION, the subscription ticket returns instances of this
 * data structure. It contains all extracted information concerning a person's gaze at the specified moment
 * in time.
 * This is a subset of an IplImage structure from the IPL headers (Copyright (c) 1995 Intel Corporation)
 * so you can cast it directly to IplImage.
 */
typedef struct {
    int  nSize;						// sizeof(IplImage)
    int  ID;						// version (=0)
    int  nChannels;					// Most of OpenCV functions support 1,2,3 or 4 channels
    int  alphaChannel;				// Ignored by OpenCV
    int  depth;						// Pixel depth in bits: IPL_DEPTH_8U, IPL_DEPTH_8S, IPL_DEPTH_16S,
									// IPL_DEPTH_32S, IPL_DEPTH_32F and IPL_DEPTH_64F are supported.
    char colorModel[4];				// Ignored by OpenCV
    char channelSeq[4];				// ditto
    int  dataOrder;					// 0 - interleaved color channels, 1 - separate color channels.
									// cvCreateImage can only create interleaved images
    int  origin;					// 0 - top-left origin,
									// 1 - bottom-left origin (Windows bitmaps style).
    int  align;						// Alignment of image rows (4 or 8).
									// OpenCV ignores it and uses widthStep instead.
    int  width;						// Image width in pixels.
    int  height;					// Image height in pixels.
    struct _IplROI *roi;			// Image ROI. If NULL, the whole image is selected.
    struct _EyeImage *maskROI;		// Must be NULL.
    void  *imageId;					// Must be NULL.
    struct _IplTileInfo *tileInfo;	// Must be NULL.
    int  imageSize;					// Image data size in bytes
									// (==image->height*image->widthStep
									// in case of interleaved data)
    char *imageData;				// Pointer to aligned image data.
    int  widthStep;					// Size of aligned image row in bytes.
    int  BorderMode[4];				// Ignored by OpenCV.
    int  BorderConst[4];			// Ditto.
    char *imageDataOrigin;			// Pointer to very origin of image data
									// (not necessarily aligned) -
									// needed for correct deallocation
}smi_EyeImageStruct;

/**
* @struct smi_SampleHMDStruct
*
* @brief smi_SampleHMDStruct holds information for both eyes as well as the averaged mapped POR
*
*/
typedef struct {
	//! size of the struct
	size_t	size;
	
	//! server time [ns]
	unsigned long long timestamp;

	//! interocular distance, i.e. distance between left and right gaze base point [mm] 
	double	iod;	

	//! inter pupillary distance, i.e. distance between left and right pupil center [mm] 
	double ipd;

	//! x, y coordinates of the mapped combined (averaged) point of regard on the display [px]
	smi_Vec2d	por;
	
	//! normalized direction of the averaged ("cyclops") gaze
	smi_Vec3d	gazeDirection;

    //! base point of the averaged ("cyclops") gaze
	smi_Vec3d	gazeBasePoint;

	//! left eye data
	smi_EyeDataHMDStruct left;

	//! right eye data
	smi_EyeDataHMDStruct right;	

	//! validity of gaze sample
	bool isValid;

} smi_SampleHMDStruct;

// user callback for handling new gaze data
typedef void (CALLBACK * smi_userCallback)(smi_CallbackDataStruct * result);

// helper function to convert return code into human readable text string
inline char * smi_rcToString(int rc) {
	switch (rc) {
	case SMI_RET_SUCCESS:
		return "SMI_SUCCESS";
	case SMI_ERROR_NO_CALLBACK_SET:
		return "SMI_ERROR_NO_CALLBACK_SET";
	case SMI_ERROR_CONNECTING_TO_HMD:
		return "SMI_ERROR_CONNECTING_TO_HMD";
	case SMI_ERROR_HMD_NOT_SUPPORTED:
		return "SMI_ERROR_HMD_NOT_SUPPORTED";
	case SMI_ERROR_NOT_IMPLEMENTED:
		return "SMI_ERROR_NOT_IMPLEMENTED";
	case SMI_ERROR_INVALID_PARAMETER:
		return "SMI_ERROR_INVALID_PARAMETER";
	case SMI_ERROR_EYECAMERAS_NOT_AVAILABLE:
		return "SMI_ERROR_EYECAMERAS_NOT_AVAILABLE";
	case SMI_ERROR_OCULUS_RUNTIME_NOT_SUPPORTED:
		return "SMI_ERROR_OCULUS_RUNTIME_NOT_SUPPORTED";
	case SMI_ERROR_FILE_NOT_FOUND:
		return "SMI_ERROR_FILE_NOT_FOUND";
	case SMI_ERROR_FILE_EMPTY:
		return "SMI_ERROR_FILE_EMPTY";
	case SMI_ERROR_SDK_NOT_INSTALLED:
		return "SMI_ERROR_SDK_NOT_INSTALLED";
	case SMI_ERROR_NO_SMI_HARDWARE:
		return "SMI_ERROR_NO_SMI_HARDWARE";
	default:
	case SMI_ERROR_UNKNOWN:
		return "SMI_ERROR_UNKNOWN";
	}
};


/**
 * @brief Set the user callback function which is called asynchronously when new gaze data is available
 * Precondition:	none
 * 
 * @param func		Function Pointer to the user function
 */
DLL_DEC_PRE int DLL_DEC_POST  smi_setCallback(smi_userCallback func);


/**
 * @brief Starts streaming of gaze samples and eye images
 * In the background eye tracking is initialized and started (this can take a moment)
 * This function is blocking
 * Precondition:	smi_setCallback, have been called successfully
 *
 * @param simulate						Activates a testing mode, which will send mock data in a loop
 * @param trackingParameterStruct		Optional parameter for altering the behaviour of the produced data
 */ 
DLL_DEC_PRE int DLL_DEC_POST  smi_startStreaming(bool simulate = false, smi_TrackingParameterStruct * trackingParameterStruct = NULL);

/**
 * @brief Starts streaming of eye images 
 * In order to identify possible tracking problems it can help to look at the eye images, both eyes are
 * available via registered callback
 * Precondition:	smi_SetCallback, smi_StartStreaming have been successfully called
 *                  and gaze streaming is not in simulation mode
 */
DLL_DEC_PRE int DLL_DEC_POST   smi_startEyeImageStreaming();
		
/**
 * @brief Stops eye image streaming 
 * Precondition:	smi_ShowEyeImages has been successfully called
 */
DLL_DEC_PRE int DLL_DEC_POST   smi_stopEyeImageStreaming();


/** 
 * @brief Terminates the eyetracking server and stops data streaming
 * Precondition:	smi_setCallback, smi_startStreaming have been called successfully
 */
DLL_DEC_PRE int DLL_DEC_POST  smi_quit();


/**
 * @brief creates and allocates the memory of calibrationHMDStruct used for the calibration, call is *optional*
 * Fills block of memory for backgroundcolor, foregroundcolor and calibrationpoints[5].
 * If you want to define your own calibration grid (color and position), this function has to be called beforehand.
 * 
 * @param calibrationHMDStruct		pointer to the pointer of the calibration struct used for smi_setupCalibration 
 */
DLL_DEC_PRE int DLL_DEC_POST  smi_createCalibrationHMDStruct(smi_CalibrationHMDStruct **calibrationHMDStruct);


/**
* @brief customize the calibration procedure, call is *optional* and will override the default settings for the runtime 
* Precondition:	smi_setCallback, smi_startStreaming, smi_createCalibrationHMDStruct have been successfully called
*
* @param calibrationHMDStruct		struct which holds the parameters for custom calibration, created by smi_createCalibrationHMDStruct 
*/
DLL_DEC_PRE int DLL_DEC_POST  smi_setupCalibration(smi_CalibrationHMDStruct *calibrationHMDStruct);


/**
 * @brief Run a calibration
 * Shows a calibration window on the HMD screen, default calibration method is 3-Point
 * Accept calibration points by hitting the 'space bar'
 * Precondition:	smi_setCallback, smi_startStreaming have been successfully called
 *
 */ 
DLL_DEC_PRE int DLL_DEC_POST  smi_calibrate();


/**
 * @brief Accept the current calibration point
 * Use this when using a client side calibration (calibrationHMDStruct->client_visualization = true)
 * Precondition:	smi_setupCalibration(calibrationHMDStruct), smi_calibrate() have been successfully called
 *
 * @param	smi_Vec2d calibrationPoint	x,y Position of the currently shown calibration point
 */
DLL_DEC_PRE int DLL_DEC_POST smi_acceptCalibrationPoint(smi_Vec2d calibrationPoint);


/** 
 * @brief Reset the current calibration
 * Precondition:	smi_setCallback, smi_startStreaming have been successfully called
 */
DLL_DEC_PRE int DLL_DEC_POST  smi_resetCalibration();


/**
 * @brief Cancel the currently running calibration method
 * Use this when using a client side calibration
 * Calibration will be aborted and gaze will be resetted to 0-point calibration
 * Precondition:	smi_setCallback, smi_startStreaming, smi_calibrate have been successfully called
 */
DLL_DEC_PRE int DLL_DEC_POST  smi_abortCalibration();


/**
 * @brief Display of 4x4 validation grid with gaze overlay, press ESC to exit the window
 * The color scheme is always consistend with the last executed calibration.
 * Precondition:	smi_setCallback, smi_startStreaming have been successfully called
 */
DLL_DEC_PRE int DLL_DEC_POST  smi_validation();


/**
* @brief Display a validation which shows multiple points and computes a accuracy and precision per point, press ESC to exit the window
* The color scheme is always consistend with the last executed calibration.
* Precondition:	smi_setCallback, smi_startStreaming have been successfully called
*
* @param &validationPointList			fills Array with x,y positions of the validation points
* @param &validationFixationList		fills Array with x,y positions of the fixations
* @param showResultsOnOperatorScreen	show window on operator screen
* @param showResultsOnUserScreen		show window on user screen (HMD)
* @param durationResultWindow			duration in [ms] to show the validation window on user- and operatorscreen if enabled
										if set to 0 operator window has to be closed manually whereas the user window will be closed after 4 [s]  
*/
DLL_DEC_PRE int DLL_DEC_POST smi_quantitativeValidation(smi_Vec2d ** validationPointList, smi_Vec2d ** validationFixationPointList,
	bool showResultsOnOperatorScreen = true, bool showResultsOnUserScreen = true, int durationResultWindow = 4000);


/**
 * @brief Creates 2 eye image monitors using OpenCV windowed visualization
 * In order to indentify possible tracking problems it can help to look at the eye images.
 * Both eyes should be centered in the image to ensure best possible trackability			
 * Precondition:	smi_setCallback, smi_startStreaming have been successfully called		
 *
 * @param xl x Position of the left eye window [px]
 * @param yl y Position of the left eye window [px]
 * @param xr x Position of the right eye window [px]
 * @param yr y Position of the right eye window [px]
 */
DLL_DEC_PRE int DLL_DEC_POST  smi_showEyeImageMonitor(int xl=0, int yl=0, int xr=320, int yr=0);


/**
 * @brief Closes both eye image windows
 * Precondition:	smi_setCallback, smi_startStreaming, smi_showEyeImageMonitor have been successfully called
 */
DLL_DEC_PRE int DLL_DEC_POST  smi_hideEyeImageMonitor();


/**
 * @brief Starts a new fixation detection. 
 * Precondition:	smi_setCallback, smi_startStreaming have been succesfully called
 */
DLL_DEC_PRE void DLL_DEC_POST smi_startDetectingNewFixation();


/**
 * @brief Checks for a new fixation
 * Returns true if a fixation has been found.
 * Precondition:	smi_startDetectingNewFixation has been succesfully called
 */
DLL_DEC_PRE bool DLL_DEC_POST smi_checkForNewFixation();


/**
 * @brief Loads a previously saved calibration
 * Returns SMI_RET_SUCCES if the calibration has been loaded.
 * If not name is set, the current oculus user name will be loaded
 */
DLL_DEC_PRE int DLL_DEC_POST smi_loadCalibration(char * name = "");


/**
 * @brief saves the current calibration under a given name.
 * Returns SMI_RET_SUCCES if the calibration has been saved.
 * Perform a calibration before 
 */
DLL_DEC_PRE int DLL_DEC_POST smi_saveCalibration(char * name = "");


/**
 * @brief returns a list of available calibrations.
 * Will list every calibration saved with smi_saveCalibration(char * name) before.
 * List is comma seperated.
 */
DLL_DEC_PRE char* DLL_DEC_POST smi_getAvailableCalibrations();


/**
 * @brief returns the current eyetracking server time in [ns] since start.
 * Precondition:	smi_startStreaming has been succesfully called
 */
DLL_DEC_PRE long long DLL_DEC_POST smi_getServerTime();

/**
 * @brief Checks if our SDK is installed, our Hardware is available 
 * and the correct Oculus Runtime is installed.
 */
DLL_DEC_PRE int DLL_DEC_POST smi_checkHardware();