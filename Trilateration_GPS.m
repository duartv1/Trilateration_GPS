clc;clear;
%Initialize Beacon Locations
b1 = [0 0.5 0];
b2 = [3.5 0 1];
b3 = [0 1.5 0];
b4 = [4.5 0 0];
b5 = [0 2.5 3.5];
b6 = [1.5 2.5 0];
b7 = [3 0 2];
b8 = [4 4 4];
%8x3 array of beacon x,y,z pairs to calculate A
Barray = [b1; b2; b3; b4; b5; b6; b7; b8];

%Starting Data
origin = [0 0 0];
%velocities in km/s
velocity_x = 40/1000; %velocity in x-direction from [0, 100)
velocity_y = 20/1000; %velocity in y-direction from [100, 200]
velocity_z = 5/1000; %velocity in z-direction from [200, 300]

%%%%%%%%%%%%%%%%Part A: Actual distance%%%%%%%%%%%%%%%
%Calulcate x position for time 0 - 300 seconds
timeInterval = [0 : 20 : 100]'; % time interval for 100 seconds
x1 = velocity_x.*timeInterval; %x pos if going 40m/s for 100s
x2x3 = x1(6).*(ones([10 1])); %no longer moving in x direction for 200s so keep previous x position
xpos = vertcat(x1, x2x3); %concatenate all x vectors

%Calulcate y position for time 0 - 300 seconds
timeInterval = [0 : 20 : 100]'; %time interval for 100 seconds
y1 = zeros([5 1]); %no movement in y direction for first 100 seconds
y2 = velocity_y.*timeInterval; %y pos if going 20m/s for 100 seconds
y3 = y2(6).*(ones([5 1])); %no longer mvoing in y direction for next 100s so keep previous y position
ypos = vertcat(y1, y2, y3); %concatenate all y vectors

%Calulcate z position for time 0 - 300 seconds
timeInterval = [0 : 20 : 100]'; %time interval for 100 seconds
z12 = zeros([10 1]); %no movement in z direction for first 200 seconds
z3 = velocity_z.*timeInterval; %z pos if going 5m/s for last 100 seconds
zpos = vertcat(z12, z3); %concatenate all z vectors

%Concatenate final x, y and z vectors horizontally
positionXYZ = horzcat(xpos, ypos, zpos); %actual position of object from [0, 300]
r = []; %initialize radius array
for s = [1:1:16] %run for all time intervals in [0, 300]
    %get x,y,z pos at time interval n:
    posXArr = positionXYZ(s,1).*ones([8 1]); 
    posYArr = positionXYZ(s,2).*ones([8 1]);
    posZArr = positionXYZ(s,3).*ones([8 1]);
    %calculate distance, r, from all 8 beacons at time interval s
    rNew = sqrt((posXArr-Barray(1:8,1)).^2 + (posYArr-Barray(1:8,2)).^2 + (posZArr-Barray(1:8,3)).^2);
    %add new distance data array to final matrix
    r = vertcat(r, rNew');
end
r; %print final distance array

%%%%%%%%%%%%%%%%Part B: Measured distance%%%%%%%%%%%%%%%
%Calculate noise, delta i:
rng(44774477); %random seed
standardDev = 0.2/1000; %standard dev in km
mean = 0;
%initialize for loop variables:
position_arr = [];
r_i = 0;
for m = [1:1:16]
    %add "noise" to actual distance of beacon
    r_i = r(m, :) + standardDev.*randn(1,8) + mean;
    %concatenate this to our position array
    position_arr = vertcat(position_arr, r_i);
end

position_arr; %generated position array with noise

%%%%%%%%%%%%%%%%Part C: estimated co-ordinates %%%%%%%%%%%%%%%
%Initialize for loop variables/starting vals
J_Transpose_J = [0 0 0; 0 0 0; 0 0 0;];
J_Transpose_J_New = [];
R = [0; 0; 0;];
R_arr = [];
%Run for each time step between [0, 300] in 20s intervals
for timeStep = [1:1:16]
    %iterate over 100 times to achieve great accuracy
    for k = [1:1:100]
        %reset these values every iteration over the beacons
        J_Transpose_J = [0 0 0; 0 0 0; 0 0 0;];
        J_Transpose_J_New = [];
        J_Transpose_F = [0;0;0];
        %sum over 8 times (# of beacons)
        for i = [1:1:8]
            %calculate fi for the ith beacon
            fi = sqrt((R(1, 1)-Barray(i,1)).^2 + (R(2, 1)-Barray(i,2)).^2 + (R(3, 1)-Barray(i,3)).^2) - position_arr(timeStep, i);
            
            %form the JJ' matrix indices seperately
            JJ_11 = (R(1, 1)-Barray(i,1))^2 / (fi + position_arr(timeStep, i))^2;
            JJ_12 = ((R(1, 1)-Barray(i,1)) * (R(2, 1)-Barray(i,2))) / (fi + position_arr(timeStep, i))^2;
            JJ_13 = ((R(1, 1)-Barray(i,1)) * (R(3, 1)-Barray(i,3))) / (fi + position_arr(timeStep, i))^2;
            JJ_21 = ((R(1, 1)-Barray(i,1)) * (R(2, 1)-Barray(i,2))) / (fi + position_arr(timeStep, i))^2;
            JJ_22 = (R(2, 1)-Barray(i,2))^2 / (fi + position_arr(timeStep, i))^2;
            JJ_23 = ((R(2, 1)-Barray(i,2)) * (R(3, 1)-Barray(i,3))) / (fi + position_arr(timeStep, i))^2;
            JJ_31 = ((R(1, 1)-Barray(i,1)) * (R(3, 1)-Barray(i,3))) / (fi + position_arr(timeStep, i))^2;
            JJ_32 = ((R(2, 1)-Barray(i,2)) * (R(3, 1)-Barray(i,3))) / (fi + position_arr(timeStep, i))^2;
            JJ_33 = (R(3, 1)-Barray(i,3))^2 / (fi + position_arr(timeStep, i))^2;

            %take the individual matrix indices and concatenate
            J_Transpose_J_New = horzcat(JJ_11, JJ_12, JJ_13);
            J_Transpose_J_New = vertcat(J_Transpose_J_New, horzcat(JJ_21, JJ_22, JJ_23));
            J_Transpose_J_New = vertcat( J_Transpose_J_New, horzcat(JJ_31, JJ_32, JJ_33));
            J_Transpose_J = J_Transpose_J + J_Transpose_J_New;
            
            %individually calculate each J'F elelemnt
            JF_11 = ((R(1, 1)-Barray(i,1))*fi) / (fi + position_arr(timeStep, i));
            JF_21 = ((R(2, 1)-Barray(i,2))*fi) / (fi + position_arr(timeStep, i));
            JF_31 = ((R(3, 1)-Barray(i,3))*fi) / (fi + position_arr(timeStep, i));

            %form the J'F matrix
            J_Transpose_F = J_Transpose_F + vertcat(JF_11, JF_21, JF_31);
        end
        %update R value for next iteration
        R = vertcat(R - (inv(J_Transpose_J)) * J_Transpose_F);
    end
    %we now have estimated XYZ at this timestep
    %put the result into an array
    R_arr = vertcat(R_arr, R');
end
%print the final estinated xyz poistion form [0, 300]s
R_arr