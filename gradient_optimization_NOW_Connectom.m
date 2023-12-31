% Scripted example of Numerical Optimization of gradient Waveforms (NOW)
clear
close all

addpath(genpath(fullfile('/cubric/collab/437_cardiac/Cardiac_waveform_design')))

% Change the parameters below to your liking. Those not
% specified are default-initialized as follows (see optimizationProblem for details):
%    Max gradient = 80 milliTesla/m
%    Max slew rate = 100 milliTesla/m/milliSecond = 100 T/m/s
%    Eta (heat dissipation parameter) = 1
%    Discretization points = 77
%    Target tensor = eye(3)
%    Initialguess = 'random'
%    zeroGradientAtIndex = [], i.e. only at start and end
%    enforceSymmetry = false;
%    redoIfFailed = true;
%    useMaxNorm = false;
%    doMaxwellComp = true;
%    MaxwellIndex = 100;
%    Motion compensation: disabled
%
% Written by Jens Sjölund and Filip Szczepankiewicz

%%  PREP
% First, set up the optimization problem. Do this first to create a
% structure where fields are pre-specified. Note that some fields are
% read-only and that new fields cannot be created.
problem = optimizationProblem;
problem.enforceSymmetry = false;
problem.doMaxwellComp = true;
% Define the hardware specifications of the gradient system
problem.gMax =  300; % Maximal gradient amplitude, in [mT/m]
problem.sMax = 80; % 80 Maximal gradient slew (per axis), in [T/(sm)]

% Request encoding and pause times based on sequence timing in [ms]
problem.durationFirstPartRequested    = 27.35;
problem.durationSecondPartRequested   = 14.33;
problem.durationZeroGradientRequested = 8.47; % minimum 8 ms for spiral

% Define the b-tensor shape in arbitrary units. This example uses an
% isotropic b-tensor that results in spherical tensor encoding (STE).
% problem.targetTensor = eye(3);
problem.targetTensor = [1, 0, 0; 0, 0, 0 ; 0, 0, 0];
% Define the number of sample points in time. More points take longer to
% optimize but provide a smoother waveform that can have steeper slopes.
problem.N = 77;

% Set the balance between energy consumption and efficacy
problem.eta = 0.9; %In interval (0,1]

% Set the threshold for concomitant gradients (Maxwell terms). 
% Please see https://doi.org/10.1002/mrm.27828 for more information on how 
% to set this parameter.
% problem.MaxwellIndex = 100; %In units of (mT/m)^2 ms
problem.MaxwellIndex = 100; %In units of (mT/m)^2 ms

% Set the desired orders of motion compensation and corresponding
% thresholds for allowed deviations. See Szczepankiewicz et al., MRM, 2020
% for details. maxMagnitude in units s^order / m.
problem.motionCompensation.order = [0, 1, 2];
problem.motionCompensation.maxMagnitude = [0, 0, 0];

% Make a new optimizationProblem object using the updated specifications.
% This explicit call is necessary to update all private variables.
problem = optimizationProblem(problem);

%% PRINT REQUESTED AND TRUE TIMES
% Note that due to the coarse raster, the requested and actual times may
% differ slightly.
clc
now_print_requested_and_real_times(problem);

%% RUN OPTIMIZATION
[result, problem] = NOW_RUN(problem);

%% PLOT RESULT
plot(0:problem.dt:problem.totalTimeActual,result.g)
xlabel('Time [ms]')
ylabel('Gradient amplitude [mT/m]')
measurementTensor = result.B
b_value = result.b

fn = now_write_wf(result, problem, pwd);
