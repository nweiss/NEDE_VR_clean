// GetScreenBounds_cubby.js
//
// This script identifies a rectangular bounding box around the object the script is attached to
// (in screen coordinates).
//    The coordinates of this bounding box can be accessed or written to a text file by other fns.
//    The box is used in analysis to detect which object a subject is looking at.
//    NOTE: This script assumes that the object is inside specifically designed cubbies
// (prefabs named "DoubleCubby") and that the environment only involves hallways
// in the x and z directions.  We also assume that the subject does not go into these cubbies.
// These assumptions save computation time.
//
// - Created ~5/2011 by DJ.
// - Updated 3/13/12 by DJ - got rid of mainMesh
// - Updated 9/13/12 by DJ for v7.0: removed Moving and Popup surpriseLevel functionality 
//   (for code simplicity).
// - Updated 1/8/13 by DJ (_fast): Get screen bounds without screenshots (less accurate, much faster)
// - Updated 2/26/13 by DJ - raycast is transform.right, not transform.forward (since we rotated 90deg).
// - Updated 11/22/13 by DJ - removed moving & popup support
// - Updated 12/17/13 by DJ - Changed name to _cubby. Raycast -transform.up (to point at floor). 
//   Also cleanup, comments
// - Updated 12/18/13 by DJ - calculate dir using objBounds.center, not transform.position
// - Updated 7/29/14 by DJ - Changed Numbers to Constants.
//
//---------------------------------------------------------------
// Copyright (C) 2014 David Jangraw, <www.nede-neuro.org>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//    
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.
//---------------------------------------------------------------

//DECLARE GLOBAL VARIABLES
var objNumber; //this object's unique number in the current scene.
private var cam: Camera;
//private var MainCam: Camera;
private var vertices: Vector3[]; // corners of bounding box
var fractionVisible = 0.0; // fraction of object not occluded by cubby or screen edge
var boundsRect = Rect(0,0,0,0); // bounds (left,top,width,height) of unoccluded object on screen (in pixels)
//The position of the cubby corners, where the two walls that might obscure an object stop.
var cubby: Transform;
var wall1: Vector3;
var wall2: Vector3;
var highlight = false;
var highlightTexture: Texture2D;
var oculusScreenWidth = 1920;
var oculusScreenHeight = 800;
var VRRotation: Vector3;

//Get the eight corners of the object in the world	
function GetVertices() {
	//Get the renderer's bounds (visible part of object)
	objBounds = ObjectInfo.ObjectBounds(gameObject);
	var mins = objBounds.min;
	var maxes = objBounds.max;

	//Get the eight corners of this cube
	vertices[0] = mins;
	vertices[1] = Vector3(mins.x,mins.y,maxes.z);
	vertices[2] = Vector3(mins.x,maxes.y,mins.z);
	vertices[3] = Vector3(mins.x,maxes.y,maxes.z);
	vertices[4] = Vector3(maxes.x,mins.y,mins.z);
	vertices[5] = Vector3(maxes.x,mins.y,maxes.z);
	vertices[6] = Vector3(maxes.x,maxes.y,mins.z);
	vertices[7] = maxes;
}

// Get object edges ("vertices") and find locations of cubby walls
function StartObject() {
	//get camera
	var camObject = GameObject.Find("VRCamera");
	cam = camObject.GetComponent.<Camera>();

//	var camObjectA = GameObject.Find("VRCamera");
//	MainCam = camObjectA.GetComponent.<Camera>();


	//Initialize global variables
	vertices = new Vector3[8];
	//Get the position of the object in the world
	GetVertices();

	//Find cubby walls
//	var hitInfo: RaycastHit;
	var objBounds = ObjectInfo.ObjectBounds(gameObject);
//	Physics.Raycast(objBounds.center , -transform.up, hitInfo); // send ray down; the floor it hits will be the cubby we're interested in
//	cubby = hitInfo.transform.parent; //We assume that the floor hit is one of the prefabs "DoubleCubby", "CubbyL" or "CubbyR".	
	var dir = objBounds.center - cubby.transform.position;
	if (Vector3.Dot(dir,cubby.right)>0) { // dir is on the side cubby.right (usually to the subject's left)
		dir = cubby.right; 
	} else { // dir is on the side -cubby.right (usually to the subject's right)
		dir = -cubby.right;
	}
	wall1 = cubby.position + cubby.forward*Constants.CUBBYSIZE/2 + dir*Constants.CUBBYSIZE/2; //The corners of CubbyL and CubbyR are here, if the prefab hasn't been changed.
	wall2 = cubby.position - cubby.forward*Constants.CUBBYSIZE/2 + dir*Constants.CUBBYSIZE/2; //We don't determine L or R, since they could switch if the subject's view changes.	
		
}



//Find the object's position in screen coordinates and see if the subject's
//eyes are on or near it.
function UpdateObject (isCamGoingUp: boolean, objNum: int) {

	var isInView = false;
	var rayCastHitBillboard = false;
	var camPos = cam.transform.position;
	var objPos = transform.position;
	var objDir = objPos - camPos;
	var distance = Vector3.Distance(camPos, objPos);
	var hitInfo: RaycastHit;
	var hitSomething = false;
	var cornerDirection: Vector3;
	var vertices_screenA: Vector3;
	var isObjOnRight = false; // in world space (x-axis)
	var isObjOnRightFloat = 0.0;

	if (distance < 25)
	{

		if (objPos[0] > camPos[0]) // object is on the right in world space
		{
			isObjOnRight = true;
			isObjOnRightFloat = 1.0;
		}
		//Debug.Log("objPos: " + objPos);
		//Debug.Log("camPos: " + camPos);

		//Debug.Log("Going up in world space: " + isCamGoingUp);
		//Debug.Log("Billboard on right in world space: " + isObjOnRight);

		// for a given billboard, find the inside upper corner. Create a point "corner" that is the coordinates just inside the corner. 
		// This will allow a raycast from the camera in the direction of corner to make contact with the billboard.
		var k = 0;
		var temp;
		var corner: Vector3;
		var leftWS; //the x-coordinate of the leftmost point in world coordinates
		var rightWS;
		var topWS;

		if (isObjOnRight && isCamGoingUp)
		{
			temp = vertices[0][0];
			for (k=1; k<vertices.Length; k++)
			{
				temp = Mathf.Min(temp, vertices[k][0]);
			}
			leftWS = temp;

			temp = vertices[0][1];
			for (k=1; k<vertices.Length; k++)
			{
				temp = Mathf.Max(temp, vertices[k][1]);
			}
			topWS = temp;
			corner[0] = leftWS+.1;
			corner[1] = topWS-.1;	
			corner[2] = vertices[0][2];						
			//Debug.Log("objPos: " + objPos);	
			//Debug.Log("corner for UR billboard: " + corner);
		}

		if (!isObjOnRight && isCamGoingUp)
		{
			temp = vertices[0][0];
			for (k=1; k<vertices.Length; k++) 
			{
				temp = Mathf.Max(temp, vertices[k][0]);
			}
			rightWS = temp;

			temp = vertices[0][1];
			for (k=1; k<vertices.Length; k++)
			{
				temp = Mathf.Max(temp, vertices[k][1]);
			}
			topWS = temp;
			corner[0] = rightWS-.1;
			corner[1] = topWS-.1;	
			corner[2] = vertices[0][2];
			//Debug.Log("objPos: " + objPos);								
			//Debug.Log("corner for UL billboard: " + corner);
		}

		if (isObjOnRight && !isCamGoingUp)
		{
			temp = vertices[0][0];
			for (k=1; k<vertices.Length; k++)
			{
				temp = Mathf.Min(temp, vertices[k][0]);
			}
			leftWS = temp;

			temp = vertices[0][1];
			for (k=1; k<vertices.Length; k++)
			{
				temp = Mathf.Max(temp, vertices[k][1]);
			}
			topWS = temp;
			corner[0] = leftWS+.1;
			corner[1] = topWS-.1;	
			corner[2] = vertices[0][2];
			//Debug.Log("objPos: " + objPos);								
			//Debug.Log("corner for DR billboard: " + corner);
		}

		if (!isObjOnRight && !isCamGoingUp)
		{
			temp = vertices[0][0];
			for (k=1; k<vertices.Length; k++) 
			{
				temp = Mathf.Max(temp, vertices[k][0]);
			}
			rightWS = temp;

			temp = vertices[0][1];
			for (k=1; k<vertices.Length; k++)
			{
				temp = Mathf.Max(temp, vertices[k][1]);
			}
			topWS = temp;
			corner[0] = rightWS-.1;
			corner[1] = topWS-.1;	
			corner[2] = vertices[0][2];
			//Debug.Log("objPos: " + objPos);								
			//Debug.Log("corner for DL billboard: " + corner);
		}

		cornerDirection = corner - camPos; //WHICH WAY???
		hitSomething = Physics.Raycast(camPos, cornerDirection, hitInfo, distance);
		//Debug.Log("hitSomething: " + hitSomething);
		//Debug.Log("object hit: " + hitInfo.collider.gameObject.name);
		if (hitSomething == true) 
			{
				if (hitInfo.collider.gameObject.name == "Cube") 
				{
					rayCastHitBillboard = true;
				}
			}
		}

	// If the raycast is not hitting a billboard, return fractionVisible = 0
	if (!rayCastHitBillboard) 
	{
		fractionVisible = 0;
		return fractionVisible;
	}



	// If the camera is not pointing in the direction of the object, return fractionVisible = 0
	if (Vector3.Dot(cam.transform.forward, cornerDirection) < 1)
	{
		fractionVisible = 0;
		return fractionVisible;
	}

	
	//---IF raycast is hitting a billboard
	//---Find the bounding box of the object if there were nothing in the way
	//Reset the bounding box variables
	var bottom = Mathf.Infinity;
	var top = -Mathf.Infinity;
	var left = Mathf.Infinity;
	var right = -Mathf.Infinity;
	
	//Get the four corners of the object on the screen	
	var vertices_screen: Vector3;
	for (var i=0; i<vertices.Length; i++) {
		vertices_screen = cam.WorldToScreenPoint(vertices[i]);
		if (vertices_screen.x < left) {
			left = vertices_screen.x;
		}
		if (vertices_screen.x > right) {
			right = vertices_screen.x;
		}
		if (vertices_screen.y < bottom) {
			bottom = vertices_screen.y;
		}
		if (vertices_screen.y > top) {
			top = vertices_screen.y;
		}
	}
	
	//---Find the bounding box of the object given that things are in the way
	//Get the screen positions of the neighboring walls and decide which is on the left
	var leftWall = cam.WorldToScreenPoint(wall1);		
	var rightWall = cam.WorldToScreenPoint(wall2);
	if (rightWall.x<leftWall.x) { //if wall 1 is to the right of wall 2, switch the labels!
		var oldLeftWall = leftWall;
		leftWall = rightWall;	
		rightWall = oldLeftWall;
	}
	
	//Round everything
	//~ left = Mathf.Round(left);
	//~ right = Mathf.Round(right);
	//~ top = Mathf.Round(top);
	//~ bottom = Mathf.Round(bottom);

	//Check if the object is occluded (blocked)
	if (left > Screen.width || right < 0 || left > rightWall.x || right < leftWall.x) { //if the object is offscreen or occluded
		//boundsRect = Rect(0,0,0,0);		
		fractionVisible = 0;
//		if (objNum+1==8) {
//			Debug.Log("left" + left);
//			Debug.Log("rightwallx" + rightWall.x);
//			Debug.Log("right" + right);
//			Debug.Log("leftWall.x" + leftWall.x);
//				for (var ii=0; ii<vertices.Length; ii++) {
//					vertices_screen = cam.WorldToScreenPoint(vertices[ii]);
//					Debug.Log("vertices_screen x: " + vertices_screen.x);
//				}
//			Debug.Log("return3");
//		}
		return fractionVisible;
	}
	
	//Find the bounding box
	var leftmost_visible = Mathf.Max(Mathf.Max(left, leftWall.x), 0); //the left-most point at which the object is visible
	var rightmost_visible = Mathf.Min(Mathf.Min(right, rightWall.x), Screen.width); //the left-most point at which the object is visible
	
	//Set final bounds
	// Dave's Version
	//boundsRect = Rect(leftmost_visible-50,Screen.height-top-50, rightmost_visible-leftmost_visible+100,top-bottom+100); //HACK!!!!
	//Neil's 2D version
	//boundsRect = Rect(leftmost_visible, top, rightmost_visible-leftmost_visible,top-bottom);
	//Neil's 3D version
	top = (top-140)*oculusScreenHeight/210;
	bottom = (bottom-140)*oculusScreenHeight/210;
	left = left*oculusScreenWidth/Screen.width;
	right = right*oculusScreenWidth/Screen.width;
	leftmost_visible = leftmost_visible*oculusScreenWidth/Screen.width;
	rightmost_visible = rightmost_visible*oculusScreenWidth/Screen.width;
	boundsRect = Rect(leftmost_visible, top, rightmost_visible-leftmost_visible,top-bottom);
	fractionVisible = (rightmost_visible-leftmost_visible)/(right-left);

//	if (objNum + 1 == 8) {
//		Debug.Log("bounds rect: " + boundsRect);
//		Debug.Log(Time.time);
//
//	}

	return fractionVisible;
}

//To run when the object is destroyed
function StopObject() { 

}


//Draw the saccade box around the object on-screen (only if this script is enabled)
function OnGUI () {
	if (fractionVisible>0) {
		if (highlight) {
			GUI.DrawTexture(boundsRect, highlightTexture, ScaleMode.StretchToFill);
		} else {
			GUI.Box(boundsRect, "#" + objNumber); //Draws a translucent box around the object with "#2" on it (for object number 2)
		}
	}
}