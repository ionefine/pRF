function [err,pred] = fitHDR(fitParams, vN, scan, opt)
% [err,pred] = fitHDR(fitParams, vN, scan, opt)
% 
% Calcuates the average correlation error (negative) for a given voxel
% across all scans BUT fitting for subject's HDR
%
% Inputs: 
%   fitParams           A structure of parameter values for fitted function
%   vN                  Voxel number
%   scan                A structure containing information about the 
%                       scan(s) 
%   opt                 A structure containing options for pRF fitting
% 
% Outputs:
%   err                 Mean (negative) cross correlation across all scans
%   pred                Predicted time course for each scan with the given
%                       'fitParams'
%
% Note:
% - This funciton is trying to maximizing the cross-correlation, but 
%   because 'fminsearchcon' is a MINIZATION function, we add a - sign in 
%   front of the cross-correlation to make it negative

% Written by Jessica Thomas - October 20, 2014
% Edited by Kelly Chang for pRF fitting - July 11, 2016

%% Fit HDR 

corr = 0;
for i = 1:length(scan)
    scan(i).convStim = createConvStim(scan(i), fitParams); % convolve convStim again with hdr
    
    pred(i).tc = eval(['scan(i).convStim*' opt.model '(fitParams,scan(i));']);
    pred(i).tc = pred(i).tc .^ fitParams.exp; 
       
    tc = [scan(i).vtc.tc];
    tmp = eval([opt.corr '(tc(:,vN),pred(i).tc);']);
    corr = corr + tmp;
end
err = -corr/length(scan); % mean (negative) cross correlation across all scans