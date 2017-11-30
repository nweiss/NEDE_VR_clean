function [headRotation] = processHeadRotation(oculusRotation, carRotation)

% This function takes in the oculus rotation and the car rotation from 
% unity and outputs the head rotation

HR_rel = oculusRotation - carRotation;
headRotation = HR_rel;

% Instead of using negative angles, unity gives very high angles (ie 
% instead of giving an angle of -5 degrees, it will use 355 degrees).
% Correct for that.
wraparoundInd = HR_rel > 180;
headRotation(wraparoundInd) = HR_rel(wraparoundInd)-360;