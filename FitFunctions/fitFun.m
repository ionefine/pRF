function [err] = fitFun(var, funName, params, freeList, origVarargin)
% [err] = fitFun(var, funName, params, freeList, origVarargin)
%
% Support function for 'fitcon.m'
%
% Inputs:
%   var                  New values to be stored in the 'params' structure
%                        under field names (in order) from 'freeList'
%   funName              Function to be optimized
%   params               Structure of parameter values for 'funName'
%   freeList             Cell array containing list of parameter names
%                        (strings)
%   origVarargin         Extra varables to be sent into 'funName' after
%                        'params'
%
% Output:
%   err                  Error value at minimum

% Adapted from 'fitFunction.m' written by gmb - Summer 2000
% Edited by Kelly Chang for pRF package - June 21, 2016

%% Calling Specified Function to be Fitted

% store values of 'var' into 'params'
params = var2params(var, params, freeList);

if ~isempty(origVarargin)
    tmp = arrayfun(@(x) ['origVarargin{' num2str(x) '}'], 1:length(origVarargin), ...
        'UniformOutput', false); % organize evaluation string and origVarargin
    err = eval(sprintf('%s(params,%s);', funName, strjoin(tmp, ','))); % evaluate the function
else
    err = eval(sprintf('%s(params);', funName));
end