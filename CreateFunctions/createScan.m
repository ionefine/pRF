function [scan] = createScan(scanOpt, opt)
% [scan] = createScan(scanOpt, opt)
%
% Creates a structure 'scan' containing information about the scan(s) given
% by the corresponding 'scanOpt.vtcPath' and 'scanOpt.paradigmPath'
%
% Inputs:
%   scanOpt                  A structure containing option to create the
%                            'scan' structure with fields:
%       vtcPath              Path(s) to all .vtc files, string
%       paradigmPath         Path(s) to all .mat paradigm files, string
%       paradigm             A structure containg the variable name(s) of
%                            paradigm sequence(s) located within paradigm
%                            files (i.e., [scanOpt.paradgim.<var>])
%       voiPath              Path to .voi file, string
%   opt                      A structure containing option for pRF model
%                            fitting containing fields:
%       model                Model name, also the function name to be
%                            fitted string
%       roi                  Name of the .voi if fitting a within a ROI,
%                            string
%       upSample             Desired up-sampling factor for the resolution
%                            of the stimulus image, numeric
%
% Output:
%   scan                     A structure with length 1xN where N is the
%                            length of 'scanOpt.vtcPath' containing the
%                            .vtc and scan's information with fields:
%       paradigmFile         Name of paradigm file , string
%                            (i.e., 'Subj1_Paradigm_Set1.mat')
%       paradigm             A structure containing the paradigm sequences 
%                            for each stimulus dimension given as fields:
%           <funcOf          Stimulus paradigm sequence, should be given in
%             parameters>    units that are to be estimated for each
%                            stimulus dimension, blanks should be coded as
%                            NaNs, numeric
%       k                    A structure containing the unique stimulus 
%                            values for each stimulus dimension given as
%                            fields:
%           <funcOf          Unique stimukus values for each stimulus 
%             parameters>    dimension, excludes NaNs
%                            (i.e., unique(scan.paradigm))
%       vtcFile              Name of the .vtc file, string
%                            (i.e., 'Subj1_Set1.vtc')
%       vtcSize              Size of the vtc data
%       nVols                Number of volumes in the scan
%       TR                   TR of the scan, seconds
%       dur                  Total scan duration, seconds
%       t                    Time vector of the scan in TRs, seconds
%       vtc                  A structure containing .vtc data with fields:
%           id               Voxel index number
%           tc               Time course of the indexed voxel
%       <model funcOf>       Upsampled (or not) unique units of the given
%                            stimulus
%       stimImg              A MxNix...xNn matrix where M is the number of
%                            volumes of the scan and Ni through Nn is the 
%                            length(scan.<funcOf>) or the desired 
%                            resolution of the stimulus image for each
%                            stimulus dimension
%
% Notes:
% - Dependencies: <a href="matlab: web('http://support.brainvoyager.com/available-tools/52-matlab-tools-bvxqtools/232-getting-started.html')">BVQXTools/NeuroElf</a>

% Written by Kelly Chang - June 23, 2016

%% Input Control

if ~isfield(scanOpt, 'voiPath')
    scanOpt.voiPath = '';
end

%% Error Check

if isempty(scanOpt.vtcPath)
    error('No .vtc files selected');
elseif isempty(scanOpt.paradigmPath)
    error('No paradigm files selected');
end

if ischar(scanOpt.vtcPath)
    scanOpt.vtcPath = {scanOpt.vtcPath};
end

if ischar(scanOpt.paradigmPath);
    scanOpt.paradigmPath = {scanOpt.paradigmPath};
end

if length(scanOpt.vtcPath) ~= length(scanOpt.paradigmPath)
    error('All vtc files must have corresponding paradigm files');
end

if ~isfield(scanOpt, 'paradigm') || isempty(scanOpt.paradigm)
    error('Must specify ''scanOpt.paradigm''');
end

paramNames = eval(opt.model);
if ~all(ismember(fieldnames(scanOpt.paradigm), paramNames.funcOf))
    errFlds = setdiff(paramNames.funcOf, fieldnames(scanOpt.paradigm));
    error('Must specify paradigm for variable: %s', strjoin(errFlds, ', '));
end

if ~isempty(opt.roi) && isempty(scanOpt.voiPath)
    error('No ''scanOpt.voiPath'' when ''opt.roi'' is specified');
end

if iscell(scanOpt.voiPath) && length(scanOpt.voiPath) > 1
    error('Too many .voi files specified');
end

if ~isempty(scanOpt.voiPath) && isempty(opt.roi)
    [~,opt.roi] = fileparts(scanOpt.voiPath);
    opt.roi = [opt.roi '.voi'];
end

if ischar(scanOpt.vtcPath)
    scanOpt.vtcPath = {scanOpt.vtcPath};
end

if ischar(scanOpt.paradigmPath)
    scanOpt.paradigmPath = {scanOpt.paradigmPath};
end

%% .vtc File Name(s)

[~,tmp] = cellfun(@fileparts, scanOpt.vtcPath, 'UniformOutput', false);
vtcFile = strcat(tmp, '.vtc');

%% Paradigm File Name(s)

[~,tmp,ext] = cellfun(@fileparts, scanOpt.paradigmPath, 'UniformOutput', false);
paradigmFile = strcat(tmp, ext);

%% Creating 'scan' Structure

for i = 1:length(scanOpt.vtcPath)
    if ~opt.quiet
        disp(['Loading: ' vtcFile{i}]);
    end
    
    bc = BVQXfile(scanOpt.vtcPath{i}); % load .vtc file
    if ~isempty(opt.roi)
        voi = BVQXfile(scanOpt.voiPath);
        vtc = unpackROI(VTCinVOI(bc, voi));
    else
        vtc = fullVTC(bc);
    end
    
    load(scanOpt.paradigmPath{i}); % load paradigm file
    
    tmpScan.paradigmFile = paradigmFile{i}; % paradigm file name
    for i2 = 1:length(paramNames.funcOf)
        tmpScan.paradigm.(paramNames.funcOf{i2}) = eval(['[' scanOpt.paradigm.(paramNames.funcOf{i2}) '];']);
        tmpScan.k.(paramNames.funcOf{i2}) = unique(tmpScan.paradigm.(paramNames.funcOf{i2})(~isnan(tmpScan.paradigm.(paramNames.funcOf{i2}))));
    end    
    
    % error check
    if length(unique(structfun(@length, tmpScan.paradigm))) > 1
        error('Given paradigm sequences mismatch in length');
    end
    
    tmpScan.vtcFile = vtcFile{i}; % name of the .vtc file
    tmpScan.vtcSize = size(bc.VTCData); % size of the .vtc data
    tmpScan.nVols = bc.NrOfVolumes; % number of volumes in the scan
    tmpScan.TR = bc.TR/1000; % seconds
    tmpScan.dur = tmpScan.nVols*tmpScan.TR; % scan duration, seconds
    tmpScan.t = 0:tmpScan.TR:(tmpScan.dur-tmpScan.TR); % time vector, seconds
    tmpScan.vtc = vtc; % voxel time course
    scan(i) = createStimImg(tmpScan, opt); % collect into one 'scan' stucture
end