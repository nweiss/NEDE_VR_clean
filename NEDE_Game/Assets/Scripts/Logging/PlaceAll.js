// This script runs each session.  It is in charge of creating and destroying 
// objects, starting and stopping the eyetracker and logger, and sending various 
// object-related messages to the log and EEG (via the Logger/eyelink scripts).
//    Loads all assets in the "Resources/<Category>" folders, for each category that's
// turned on.  When a trial is started (through the variables reset and presentationType
// as set in GuiSpeed or in the Loader scene), this script places an object in each of 
// the locations designated by Location objects that are the children of Cubby objects.
//    It then picks a random object and places it according to the category and object 
// prevalences specified in the loader GUI.
//
// - Created ~5/2011 by DJ.
// - Updated 9/13/12 by DJ for v7.0 - removed Moving and Popup presentationType functionality 
//   (for code simplicity).
// - Updated 1/8/13 by DJ - Add GetScreenBounds_fast to every object (log approx positions w/o replay)
// - Updated 11/22/13 by DJ - updated options, switched to GetScreenBounds_cubby, cleaned up code.
// - Updated 12/18/13 by DJ - adjusted for GetScreenBounds_cubby
// - Updated 1/7/14 by DJ - log eye position (fixupdate) each frame
// - Updated 1/8/14 by DJ - route files in NedeConfig folder
// - Updated 7/29/14 by DJ - resources in NEDE subfolder, changed Numbers to Constants.

//---DECLARE GLOBAL VARIABLES
var subject = 0;
var session = 0;
var record_EDF_file = false; //set to true to tell the EyeLink to record an .edf file
var EDF_filename: String; //Filename of the EyeLink EDF file when it's transfered to Display (Unity) computer

//WHAT
var objectPrevalence = 1.0; //chance that an object placement will have no object
var categories : String[]; //the possible target/distractor categories
var categoryState : int[];
var categoryPrevalence : float[];
var nCategories = 0;
var nObjToSee = 20;
//WHERE
var locations = "Locations"; //the Tag that contains the available target locations
var objectSize = 2.0; //(Approximate) height of targets/distractors in meters
var distanceToLeader = 2.5; // How far away from the camera should the target pop up?
//WHEN
var trialTime = Mathf.Infinity;
var minBrakeDelay = 3.0; //min time between brake events
var maxBrakeDelay = 10.0; //max time between brake events
var objectMoveTime = 2.0; // how quickly should the moving objects move?
var recordObjBox = true; //send object bounding box to eyelink every frame
var syncDelay = 1.0; //time between Eye/EEG sync signals
//HOW
var presentationType = 0; //trial type: 0=stationary, 1=follow
var reset = false; //the GUI can use this to start a new trial

// PHOTODIODE variables
var isPhotodiodeUsed = true;
var photodiodeSize = 100;
private var WhiteSquare : Texture2D;
private var BlackSquare : Texture2D;

//To Dish Out to Other Scripts
var isActiveSession = 1; //use ArrowControl (1) or RobotWalk (0)?
var moveSpeed = 5.0; //for ArrowControl/RobotWalk
var spinSpeed = 50.0; //for ArrowControl
var offset_x = 50; //for eyelink calibration
var offset_y = 150; //for eyelink calibration
var gain_x = 1.0; //for eyelink calibration
var gain_y = 1.0; //for eyelink calibration

private var cubbies : GameObject[]; // loaded from <cubbies> tagged objects
private var positions : Array; //loaded from the <locations> tagged objects
private var rotations : Array; //loaded from the "Cubbies" tagged objects
private var prefabs : Array; //loaded from all target and distractor folders
private var categoryThresholds : float[]; //random number range for each category
private var is3dCategory: boolean[]; //does this category have 3d objects or 2d images?
private var objectsInPlay : Array; //The objects currently in the field
private var nObjects = 0; //how many objects have been created so far in the trial?
private var nextBrakeTime = Mathf.Infinity; //Time when a target should pop or move into view
private var trialEndTime = Mathf.Infinity; //Time when the current trial will end
private var syncTime = 0.0; //time of next Eye/EEG sync signal
private var eyelinkScript; //the script that passes messages to and receives eye positions from the eyetracker
private var portIsSync = false; //is parallel port sending Constants.SYNC?
private var walkScript; //the script that makes this object move
private var leaderWalkScript; //the script that makes a truck move
private var leaderFlashScript; //the script that makes a truck's lights turn on and off
private var brakeFactor = 0.2; // % of speed during braking
private var zoomFactor = 1.5;  // % of speed during acceleration

//========================================================
//Neil	
//private LSL_BCI_INPUT lsl_script;
var isTarget = 0.0;
var Outlet;
var oculusPixelWidth = 1920;
var oculusPixelHeight = 1080;
var empiricalPixelWidth;
var empiricalPixelHeight;
var isCamGoingUp = false;
var isObjOnRight = false;
var isBrakeLights = 0.0;
var isButtonPress = 0;
var Inlet = null;
var feedback_sphere : GameObject[];
var feedback_cube : GameObject[];
var feedback_object : GameObject;
var Startup_Object : GameObject;
Startup_Object = GameObject.Find("StartupObject");
var objectLocsFile : StreamWriter = new System.IO.StreamWriter("objectLocs.txt");
public var feedbackMaterials : Material[];
var Rend: Renderer;
public var closedLoop = false; // SETTING THAT TURNS ON AND OFF THE "FEEDBACK SPHERES" MARKING THE USERS INTEREST IN A BILLBOARD

//=========================================================

//---STARTUP SCRIPT
function Start () {
//=========================================================
	// Neil's Code
//    var camObject = GameObject.Find("Cams");
//	cam = camObject.GetComponent.<Camera>();
//
//    empiricalPixelWidth = cam.pixelWidth;
//    empiricalPixelHeight = cam.pixelHeight;

    //If you want to build the game and have it show on an oculus and have the overhead view on a screen 
//    Debug.Log("displays connected: " + Display.displays.Length);
//	if (Display.displays.Length > 1) {
//		Display.displays[1].Activate();
//		Debug.Log('Second monitor activated');
//	} else {
//		Debug.Log('Only one display detected');
//	}
	var LSLdata = [0.0,0.0,0.0,0.0,0.0,0.0,-1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0];
	Debug.Log("Start Cue Sent");
	Startup_Object.GetComponent(LSL_BCI_Input).pushLSL(LSLdata); //adjust data sent accordingly, sampleData vs LSLdata for online vs offline 

    //====================================

    Application.targetFrameRate = 90;
    		   		
	// Set up scripts
	this.enabled = false; // wait until this is done before we start updates
	gameObject.AddComponent(eyelink); // to interface with eye tracker
	gameObject.AddComponent(Constants); // to get constants
	var speedScript = gameObject.AddComponent(GuiSpeed); // to include GUI controls
	speedScript.placerScript = this;
	
	var i=0; //loop index
	var j=0; //loop index
	if (categories.length==0) {
		categories = Constants.CATEGORIES;		
		nCategories = categories.length;
		categoryState = new int[nCategories];
		categoryPrevalence = new float[nCategories];
		for(j=0;j<nCategories;j++) { categoryPrevalence[j] = 1/parseFloat(nCategories); }
	} 
	nCategories = categories.length;
	
	if (!isActiveSession) { //if the robot is driving
		trialTime = 999; //set this high to allow RobotWalk script to end the trial (whenever it finishes navigating.)
	}
 	//------- SCRIPTS
 	//Dish out variables to the other scripts (this one is in control!)	
	var startPoint = 0;
	if (isActiveSession) {
		var arrowScript = gameObject.AddComponent(ArrowControl); //moves the user actively from joystick input
		arrowScript.moveSpeed = moveSpeed;
		arrowScript.spinSpeed = spinSpeed; 	
	} else {
		walkScript = gameObject.AddComponent(RobotWalk); //moves the user passively on a predefined path
		yield walkScript.ParseRouteFile("NedeConfig/" + Application.loadedLevelName + ".txt"); //wait for this to finish before moving on
		walkScript.nObjToSee = nObjToSee;
		var lastOkStartPoint = walkScript.FindLastOkStartPoint();
		startPoint = Mathf.FloorToInt(Random.Range(0,lastOkStartPoint)); //choose starting point randomly between 0 and lastOkStartPt-1
		walkScript.moveSpeed = moveSpeed;
		walkScript.StartRoute(startPoint);
		if (presentationType==Constants.FOLLOW) {
			//If this is a "follow" trial, place object we are following
			var leaderLoc = Vector3(walkScript.points[startPoint+1].x, walkScript.points[startPoint+1].y, 0);
			//~ var leaderPrefab = Resources.Load("Truck/TruckPrefab"); //LOAD specified item from Resources folder
			var leaderObj = Instantiate(Resources.Load("NEDE/LeaderPrefab"));	//create object from prefab	
			leaderWalkScript = leaderObj.AddComponent(RobotWalk); //moves the user passively on a predefined path
			leaderWalkScript.moveSpeed = moveSpeed;
			leaderWalkScript.nObjToSee = 999; // make this number high so the camera's walkScript will end the level first
			leaderWalkScript.StartRoute(startPoint);
			leaderObj.transform.position = transform.position + transform.forward * distanceToLeader;
			leaderObj.transform.position.y = 0;
			//Save location of FlashLights script
			leaderFlashScript = leaderObj.GetComponentInChildren(FlashLights);			
		}
	}
	eyelinkScript = gameObject.GetComponent(eyelink); //gets eye position and records messages
	
	//------- EYELINK
	// Decide on filename
	var temp_filename;
	if (record_EDF_file) {
		temp_filename = "NEDElast.edf"; //temporary filename on EyeLink computer - must be <=8 characters (not counting .edf)!	
	} else {
		temp_filename = ""; //means "do not record an edf file"
		EDF_filename = ""; //means "do not transfer an edf file to this computer"
	}
	
	//Start eye tracker
	//print("--- subject: " + subject + "  session: " + session + " ---"); //print commands act as backup to eyelink logging/commands 
	var startOut = eyelinkScript.StartTracker(temp_filename); 
	eyelinkScript.SendToEEG(Constants.START_RECORDING);
	
	//Log experiment parameters
	eyelinkScript.write("----- SESSION PARAMETERS -----");
	eyelinkScript.write("subject: " + subject);
	eyelinkScript.write("session: " + session);
	eyelinkScript.write("Date: " + System.DateTime.Now);
	eyelinkScript.write("isActiveSession: " + isActiveSession);
	eyelinkScript.write("EDF_filename: " + EDF_filename);
	eyelinkScript.write("level: " + Application.loadedLevelName);
	eyelinkScript.write("trialTime: " + trialTime);
	eyelinkScript.write("presentationType: " + presentationType);
	eyelinkScript.write("locations: " + locations);
	eyelinkScript.write("objectSize: " + objectSize);
	eyelinkScript.write("distanceToLeader: " + distanceToLeader);
	eyelinkScript.write("objectPrevalence: " + objectPrevalence);
	eyelinkScript.write("minBrakeDelay: " + minBrakeDelay);
	eyelinkScript.write("maxBrakeDelay: " + maxBrakeDelay);
	eyelinkScript.write("objectMoveTime: " + objectMoveTime);
	eyelinkScript.write("recordObjBox: " + recordObjBox);
	eyelinkScript.write("isPhotodiodeUsed: " + isPhotodiodeUsed);
	eyelinkScript.write("photodiodeSize: " + photodiodeSize);
	eyelinkScript.write("syncDelay: " + syncDelay);
	eyelinkScript.write("nCategories: " + nCategories);
	for (i=0; i<nCategories; i++) {
		eyelinkScript.write("category: " + categories[i] + " state: " + Constants.CATEGORYSTATES[categoryState[i]] + " prevalence: " + categoryPrevalence[i]); 
	}
	eyelinkScript.write("startPoint: " + startPoint);
	eyelinkScript.write("nObjToSee: " + nObjToSee);
	eyelinkScript.write("moveSpeed: " + moveSpeed);
	eyelinkScript.write("spinSpeed: " + spinSpeed);
	eyelinkScript.write("screen.width: " + Screen.width);
	eyelinkScript.write("screen.height: " + Screen.height);
	eyelinkScript.write("eyelink.offset_x: " + offset_x);
	eyelinkScript.write("eyelink.offset_y: " + offset_y);
	eyelinkScript.write("eyelink.gain_x: " + gain_x);
	eyelinkScript.write("eyelink.gain_y: " + gain_y);
	eyelinkScript.write("----- END SESSION PARAMETERS -----");

 	//------- LOCATIONS
 	//Set up arrays
 	positions = new Array();
 	rotations = new Array();
 	objectsInPlay = new Array(); 	
 	var position_y = objectSize/2; // this puts tall objects on the ground, wide objects above it.

 	//Load all the possible positions for objects
 	//for each cubby, find the spheres that are its children, pick one of them, and add it to locations.

 	cubbies = GameObject.FindGameObjectsWithTag("Cubbies");
	var locsAll = GameObject.FindGameObjectsWithTag("Locations");
	var locsInCubby = new Array();
 	if (cubbies.Length>0) {
 		for (i=0;i<cubbies.Length;i++) {
 			//get sphere children
 			locsInCubby.Clear();
 			for (j=0;j<locsAll.Length;j++) {
 				if (locsAll[j].transform.IsChildOf(cubbies[i].transform)) {
 					locsAll[j].transform.position.y = position_y;
 					locsInCubby.Add(locsAll[j]);
 				}
 			} 				
 			//pick one randomly and add to array 
 			positions.Push(locsInCubby[Random.Range(0,locsInCubby.length)].transform.position);
 			rotations.Push(cubbies[i].transform.rotation);
 		}
 	} else {
 		eyelinkScript.write("WARNING: No cubbies found!  Make sure scene contains areas tagged Cubbies with children tagged Locations.");
 	}

	//------- OBJECTS	
	//Calculate thresholds for random number deciding the category
	categoryThresholds = new float[nCategories];
	categoryThresholds[0] = categoryPrevalence[0];
	for (i=1; i<nCategories; i++) {
		categoryThresholds[i] = categoryThresholds[i-1] + categoryPrevalence[i];			
	}
	//Load prefabs
	prefabs = new Array();
	is3dCategory = new boolean[nCategories];
	for (i=0; i<nCategories; i++) {
		if (categoryPrevalence[i]>0) {
			prefabs[i] = Resources.LoadAll(categories[i],GameObject);				
			if (prefabs[i].length==0) {
				prefabs[i] = Resources.LoadAll(categories[i],Texture2D);
				is3dCategory[i] = false;
			} else {
				is3dCategory[i] = true;
			}
		}
	}
	
	//Load Photodiode textures
	WhiteSquare = Resources.Load("NEDE/WHITESQUARE");
	BlackSquare = Resources.Load("NEDE/BLACKSQUARE");

	this.enabled = true;
	var prevObjNum = 1000;
}

// Place photodiode square in upper right corner
function OnGUI () {
	if (isPhotodiodeUsed) {
		if (portIsSync) {
			GUI.DrawTexture(Rect(Screen.width-photodiodeSize,-3,photodiodeSize,photodiodeSize), WhiteSquare, ScaleMode.ScaleToFit, false);
		} else {
			GUI.DrawTexture(Rect(Screen.width-photodiodeSize,-3,photodiodeSize,photodiodeSize), BlackSquare, ScaleMode.ScaleToFit, false);
		}
	}
}


//---NEW TRIAL SCRIPT
function Update () {
	isButtonPress = 0;

	//UPDATE TIME FOR THIS FRAME
	var t = eyelinkScript.getTime();
	//-------
	// When the specified trial time has elapsed, end the trial.
	if (t > trialEndTime) {
		EndLevel();
		Application.LoadLevel("Loader"); //Go back to the Loader Scene
		return; //stop executing Update (to avoid, e.g., destroying things twice)
	}

//	SYNC EYELINK AND EEG
//	if (t>syncTime) {
//		//toggle parallel port output
//		portIsSync = !portIsSync; 
//		if (portIsSync) {
//			eyelinkScript.SendToEEG(Constants.SYNC);
//		} else {
//			//eyelinkScript.SendToEEG(0);
//		}
//		//get next sync time
//		syncTime = t + syncDelay;
//		}
	
	
	
	//-------
	//When it's time for a new trial, place targets and distractors.
	if (reset) {		
		reset = false;

		//If there exists a current trial, end it and destroy all the objects
		if (objectsInPlay.length>0) {
			eyelinkScript.write("----- END TRIAL -----");
			//Destroy all objects in the scene to start anew
			DestroyAll();
		}

		//log what we're doing
//		eyelinkScript.write("----- LOAD TRIAL -----");
		//Place distractors in the specified locations
		PlaceObjects(objectLocsFile);		 

		// Place the feedback spheres
		if (closedLoop) {
			for (var i=0; i<positions.length; i++) {
				CreateFeedback(i, 0.0);
			}
		}
		 
		//Determine times when the moving or pop-up object should be placed
		//Makes the leading car break
		if (presentationType==Constants.STATIONARY) {
			nextBrakeTime = Mathf.Infinity; //No pop-ups
		} else if (presentationType==Constants.FOLLOW) {
			nextBrakeTime = t + Random.Range(minBrakeDelay,maxBrakeDelay);
		}
		
		//Start the trial
//		eyelinkScript.FlushBuffer(); //Disregard the saccades that took place during loading;
//		eyelinkScript.write("----- START TRIAL -----");
		trialEndTime = t + trialTime;
	}
	

	//-------
	//Truck-handling code for "Follow" trials
	if (presentationType==Constants.FOLLOW) { 
		if (t > nextBrakeTime) { //nextBrakeTime was set during the reset cycle
			nextBrakeTime = Mathf.Infinity; //so we only run this code once
			leaderFlashScript.LightsOn();
			isBrakeLights = 1.0;
			leaderWalkScript.moveSpeed = moveSpeed * brakeFactor;
//			eyelinkScript.write("Leader Slow");
		}
		//If the subject presses a key and the brakes are on, turn the brakes off
		if (eyelinkScript.UpdateButton()==Constants.BRAKEBUTTON) {
			isButtonPress = 1;
			if (leaderWalkScript.moveSpeed < moveSpeed) { //but only if we're braking
				leaderFlashScript.LightsOff(); //turn the lights off
				isBrakeLights = 0.0;
				isButtonPress = 1;
				leaderWalkScript.moveSpeed = moveSpeed * zoomFactor; //have truck speed up until it's at desired distance.
//				eyelinkScript.write("Leader Fast"); //inform the data log
			}
		}
		// If the truck is speeding and has reached the desired distance, make it stop speeding
		if (leaderWalkScript.moveSpeed > moveSpeed && leaderWalkScript.distanceTraveled >= walkScript.distanceTraveled) {
			leaderWalkScript.moveSpeed = moveSpeed; //set back to normal speed
//			eyelinkScript.write("Leader Normal"); //inform the data log
			nextBrakeTime = t + Random.Range(minBrakeDelay,maxBrakeDelay); //set next brake time
		}
	}
}

//===================================================================================
// LSL and VR Updates

function LateUpdate() {

	var LSLdata = [0.0,0.0,0.0,0.0,0.0,0.0,-1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0];

	var camObject = GameObject.Find("Cams"); // Track the direction that MainCamera is moving in
	var VRcamObject = GameObject.Find("VRCamera");
	VRcam = VRcamObject.GetComponent.<Camera>();
	var VRRotation: Vector3;
	VRRotation = VRcam.transform.rotation.eulerAngles;
	var carRotation = camObject.transform.rotation.eulerAngles;

	if (camObject.transform.forward[2] > 0)
		isCamGoingUp = true;
	else
		isCamGoingUp = false;
	//Debug.Log("isCamGoingUp: " + isCamGoingUp);

	//Update object screen bounds
	if (recordObjBox) {
		var thisObj; var boundsScript; 
		var fractionVisible = 0.0;
		var isObjectOnRight = 0.0;
		var isObjInView = false;
		var updateArgs;
		for (var i=0; i<objectsInPlay.length; i++) {		
			thisObj = objectsInPlay[i];
			if (thisObj != null) {
				//Get the bounding script
				boundsScript = thisObj.GetComponent(GetScreenBounds_cubby);
				fractionVisible = boundsScript.UpdateObject(isCamGoingUp, i);

				//Record visibility
				if (fractionVisible > .01) {
					Debug.Log("OBJECT IN VIEW: " + Time.time);
					isObjInView = true;               
                    if(thisObj.tag == "TargetObject") {
                    	isTarget = 1;
                    }
                    if(thisObj.tag == "DistractorObject") {
                    	isTarget = 2;
                    }

                    ret = parseBillboardName(thisObj.name);
                    objCategory = ret[0];
                    imageNo = ret[1];

					LSLdata[0] = boundsScript.boundsRect.x; //*oculusPixelWidth/empiricalPixelWidth; // Hack to solve the problem of the units being off
					LSLdata[1] = boundsScript.boundsRect.y; //*oculusPixelHeight/empiricalPixelHeight;
					LSLdata[2] = boundsScript.boundsRect.width; //*oculusPixelWidth/empiricalPixelWidth;
					LSLdata[3] = boundsScript.boundsRect.height; //*oculusPixelHeight/empiricalPixelHeight;
					LSLdata[4] = isTarget;
					LSLdata[5] = objCategory;
					LSLdata[6] = i;
					LSLdata[7] = VRRotation[0];
					LSLdata[8] = VRRotation[1];
					LSLdata[9] = VRRotation[2];
					LSLdata[10] = carRotation[0];
					LSLdata[11] = carRotation[1];
					LSLdata[12] = carRotation[2];
					LSLdata[13] = isButtonPress;
					LSLdata[14] = isBrakeLights;
					LSLdata[15] = imageNo;
				}
			}
		}
		if (isObjInView == false) {
			LSLdata[6] = -1.0; // Use -1 as the Billboard ID when no billboard is present because Billboard ID can take a value of 0.
			LSLdata[7] = VRRotation[0];
			LSLdata[8] = VRRotation[1];
			LSLdata[9] = VRRotation[2];
			LSLdata[10] = carRotation[0];
			LSLdata[11] = carRotation[1];
			LSLdata[12] = carRotation[2];
			LSLdata[13] = isButtonPress;
			LSLdata[14] = isBrakeLights;
		}

		/* ONLNINE STREAMING */
		
		//01/09/2017
		Startup_Object.GetComponent(LSL_BCI_Input).pushLSL(LSLdata); //adjust data sent accordingly, sampleData vs LSLdata for online vs offline 

		//GameObject.Find("StartupObject").GetComponent("LSL_BCI_Output").pushLSL(LSLdata);

		/***** Comment this section if running without online data streaming ******/
		// The variable unity_from_matlab has three values for each billboard
			// unity_from_matlab[0] is the index of the billboard (0-indexed. 1 less than the objnumber unity assigns to each billboard)
			// unity_from_matlab[1] is the classification of the billboard 
			// unity_from_matlab[0] is the confidence of the classification for the given billboard
//		unity_from_matlab = Startup_Object.GetComponent(LSL_BCI_Input).receiveLSL();
//		//if Python has pushed a sample
//		if (unity_from_matlab[2] != 0){
//			Debug.Log("Billboard #: " + unity_from_matlab[0] +1 + "\t classified as: " + unity_from_matlab[1] + "\t confidence: " + unity_from_matlab[2]);
//			//create graphic to show the classification of a billboard
//			CreateFeedback(unity_from_matlab);			
//		}

		
	}

	// Update colors of feedback spheres based on interest scores
	if (closedLoop) {
		if (Time.frameCount == 375) {
			updateFeedback();
		}
	}
	//===================================================================================

	//Log Camera Position
	//eyelinkScript.write("Camera at (" + transform.position.x + ", " + transform.position.y + ", " + transform.position.z + ")  rotation (" + transform.rotation.x + ", " + transform.rotation.y + ", " + transform.rotation.z +", " + transform.rotation.w + ")");	
	
	//Log Eye Position
	//eyelinkScript.UpdateEye_fixupdate();	
	//eyelinkScript.write("Eye at (" + eyelinkScript.x + ", " + eyelinkScript.y + ")");
}

//---DESTROY ALL TARGETS AND DISTRACTORS
function DestroyAll() {
	var thisObject: Object;
	//Pick all objects out of the objectsInPlay array and destroy them
	while (objectsInPlay != null && objectsInPlay.length>0) { //until we clear the list
		thisObject = objectsInPlay.Pop();
		Destroy(thisObject); //destroy object and remove it from the list
	}
	eyelinkScript.write("Destroyed All Objects");
	nObjects = 0;
}


//---PLACE A SINGLE OBJECT AT THE GIVEN LOCATION, CHOSEN RANDOMLY
function PlaceObject(location: Vector3, newrotation: Quaternion, parentcubby: GameObject, objType: String, objectLocsFile: StreamWriter, objInd: int) {
	//Set up
	var i; //category number
	var newTexture : Texture2D; //To be set multiple times in loop	
	var newMaterial : Material;
	var newObject : GameObject;
	var mesh1 : Transform; //type depends on 3D-ness
	var mainMesh : GameObject;
	
	// Determine the object category
	var categoryRand = Random.value;
	for (i=0; i<nCategories; i++) { //category index
		if (categoryRand<categoryThresholds[i]) { //first category whose threshold is above the random value will be chosen
			break; //leave the loop with the selected category remaining in i
		}
	}
	
	// Create the object
	j = Random.Range(0, prefabs[i].Length); //object index
	if (is3dCategory[i]) {
		//Instantiate the object		
		newObject = Instantiate(prefabs[i][j],location,newrotation);	//create object from prefab	(NEW in v6.5: IN SPECIFIED ROTATION)
		newObject.name = ReadLog.substring(newObject.name,0,newObject.name.length-7); // get rid of (Clone) part of name
		newObject.tag = Constants.CATEGORYSTATES[categoryState[i]] + "Object"; //TargetObject or DistractorObject
		
		//Scale and position new object    
		var objBounds = ObjectInfo.ObjectBounds(newObject);
		var objLength = ObjectInfo.BoundLength(objBounds);
		newObject.transform.localScale *= (objectSize/objLength); //Resize object (standard size is ~1m)
		objBounds = ObjectInfo.ObjectBounds(newObject); // update given new center
		newObject.transform.Translate(location-objBounds.center, Space.World); //Adjust to center of mesh!				
		newObject.transform.Translate(Vector3(0,-location.y+objBounds.extents.y,0)); // shift so object is sitting on the ground
			
	} else {
		//Create the object				
		newTexture = prefabs[i][j]; //select the distractor randomly (w/ replacement)				
		newMaterial = new Material (Shader.Find ("Diffuse"));
		newObject = new GameObject("square");
		mainMesh = GameObject.CreatePrimitive(PrimitiveType.Cube); //Mesh1 of object we just created		
		newObject.tag = Constants.CATEGORYSTATES[categoryState[i]] + "Object"; //TargetObject or DistractorObject

		//Assemble the object
		newMaterial.mainTexture = newTexture;
		mainMesh.GetComponent.<Renderer>().material = newMaterial;
		mainMesh.transform.parent = newObject.transform;
		
		//transform object
		newObject.transform.position = location;
		newObject.transform.localScale = Vector3(0.1,objectSize,objectSize); // to use 90deg rotation
		newObject.transform.rotation = newrotation*Quaternion.AngleAxis(90,Vector3.up); // rotate 90deg so pic is not upside-down from either side
		newObject.name = newTexture.name;

		objectLocsFile.WriteLine(location[0] + "," + location[2] + "," + i + "," + j + "," + objInd);
	}

	//Log object
	nObjects++; //increment number of objects in the trial so far
	//Add a script to the object we just created
	var posScript = newObject.AddComponent(LogPosition);
	posScript.objType = objType;
	posScript.eyelinkScript = eyelinkScript; // for writing info to file
	if (objType=="Stationary") posScript.enabled = false; //No need to update stationary objects every frame.
	posScript.objNumber = nObjects;			
	posScript.StartObject(); //runs the "StartObject" function
	
	//Add GetScreenBounds_cubby script
	if (recordObjBox) {
		var boundsScript = newObject.AddComponent(GetScreenBounds_cubby);
		boundsScript.objNumber = nObjects;
		boundsScript.cubby = parentcubby.transform;
		boundsScript.enabled = false; // if true -> draw a box around the object
//		boundsScript.objType = objType;
		boundsScript.StartObject();
	}
	
	//Log new object in array
	objectsInPlay.Push(newObject);
	//Return the object we created
	return newObject;
}


//---INSTANTIATE AN OBJECT IN EACH LOCATION
function PlaceObjects(objectLocsFile: StreamWriter) {
	//Set up
	var newObject : Object; //object we just created
	
	//Main loop: creates a randomly chosen target or distractor at each location
	for (var i=0; i<positions.length; i++) {		
		//Decide if there will be an object at this location
		var isObject = (Random.value < objectPrevalence); //There is an objectPrevalence*100% chance that each location will contain an object
		if (isObject) {
			//Place a target or distractor
			newObject = PlaceObject(positions[i],rotations[i],cubbies[i],"Stationary", objectLocsFile, i);
		}
	}
	objectLocsFile.Close();
}

//---CREATE OBJECTS FOR CLOSED LOOP FEEDBACK
function CreateFeedback(objInd : int, interestScore : float) {
	// Map the confidence from 0-1 to an int between 0-5 
	sphere_num = Mathf.Round(5*interestScore);
	feedback_object = Instantiate(feedback_sphere[sphere_num], objectsInPlay[objInd].transform.position + Vector3(0, 2, 0), transform.rotation);
	feedback_object.layer = LayerMask.NameToLayer("UI");
	feedback_object.name = "feedback_obj" + objInd;
}

//---UPDATE OBJECTS IN CLOSED LOOP FEEDBACK
function updateFeedback() {
	try{
		sr = new StreamReader("interestScores.txt");
		line = sr.ReadLine();
		objInd = 0;
		while (line != null) {
			line = sr.ReadLine();
			objInd = objInd + 1;
			interestScore = float.Parse(line);
			materialNo = Mathf.Round(5*interestScore);
			feedbackObj = GameObject.Find("feedback_obj" + objInd);
			rend = feedbackObj.GetComponent.<Renderer>();
			rend.sharedMaterial = feedbackMaterials[materialNo];
		}
		sr.Close();
	}
	catch (e) {
		print("The interest score file could not be read.");
		print(e.Message);
	}
}

//---END THE LEVEL AND DO CLEANUP
//This function is called during the Update function, or by GuiSpeed script.
function EndLevel() {
	VR.VRSettings.enabled = false;

	var LSLdata = [0.0,0.0,0.0,0.0,0.0,0.0,-1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,2.0];
	Debug.Log("Exit Cue Sent");
	Startup_Object.GetComponent(LSL_BCI_Input).pushLSL(LSLdata); //adjust data sent accordingly, sampleData vs LSLdata for online vs offline 


	//disable updates
	this.enabled=false;
	//Log what we're doing
	eyelinkScript.write("----- END TRIAL -----");
	eyelinkScript.SendToEEG(Constants.END_RECORDING);
	DestroyAll(); //Clean up objects
	// Close the tracker and log files (important for saving!)
	eyelinkScript.StopTracker(EDF_filename); //transfer file to current directory with given filename
}

//---END THE LEVEL MANUALLY
//This program is called if the user ends the level by pressing the play button or closing the window
function OnApplicationQuit() { 
	EndLevel(); //Still do cleanup/exit script so our data is saved properly.
}

function parseBillboardName(name: String) : int[] {
	//Find the object category
    if (name.Contains("car")){ //car_side
    	objCategory = 1;
    }
    if (name.Contains("gra")){ //grand_piano
    	objCategory = 2;
    }
    if (name.Contains("lap")){ //laptop
    	objCategory = 3;
    }
    if (name.Contains("sch")){ //schooner
    	objCategory = 4;
    }

    //Find the image number (ie 32 for the image car_side_32.jpg)
    // For a two digit image name (ie car_side_32)
    if (name[name.Length-3] == "-") {
    	imageNo = parseInt(name[name.Length-2:name.Length]);
    }
	// For a one digit image name (ie car_side_2)
    else {
    	imageNo = parseInt(name[name.Length-1].ToString());
    }
    ret = [objCategory,imageNo];
    return ret;
}

function mapBillboardLocsToPathLocs(billboardLocs: Vector2[]){
	// This function maps a location from (x,z) in world space in unity to the space in validDrivingMap.csv
	// Will have to update to find the desired driving location for a given desired billboard location.
	for (var i=0; i<billboardLocs.length; i++) {
				
		x = (5 + 5*Mathf.round(billboardLocs[i][0]/5))/5;
		y = (5*Mathf.round(billboardLocs[i][0]/5))/5;
	}
};