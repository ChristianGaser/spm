function [dat] = read_yokogawa_data(filename, hdr, begsample, endsample, chanindx)

% READ_YOKAGAWA_DATA reads continuous, epoched or averaged MEG data
% that has been generated by the Yokogawa MEG system and software
% and allows that data to be used in combination with FieldTrip.
%
% Use as
%   [dat] = read_yokogawa_data(filename, hdr, begsample, endsample, chanindx)
%
% This is a wrapper function around the functions
%   GetMeg160ContinuousRawDataM
%   GetMeg160EvokedAverageDataM
%   GetMeg160EvokedRawDataM
%
% See also READ_YOKOGAWA_HEADER, READ_YOKOGAWA_EVENT

% Copyright (C) 2005, Robert Oostenveld
%
% This file is part of FieldTrip, see http://www.ru.nl/neuroimaging/fieldtrip
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id: read_yokogawa_data.m 1113 2010-05-20 08:35:15Z tilsan $

if ~hasyokogawa('16bitBeta6')
    error('cannot determine whether Yokogawa toolbox is present');
end

% hdr = read_yokogawa_header(filename);
hdr = hdr.orig; % use the original Yokogawa header, not the FieldTrip header

% default is to select all channels
if nargin<5
  chanindx = 1:hdr.channel_count;
end

handles = definehandles;
fid = fopen(filename, 'rb', 'ieee-le');

switch hdr.acq_type
  case handles.AcqTypeEvokedAve
    % Data is returned by double.
    start_sample  = begsample - 1; % samples start at 0
    sample_length = endsample - begsample + 1;
    epoch_count   = 1;
    start_epoch   = 0;
    dat = double(GetMeg160EvokedAverageDataM( fid, start_sample, sample_length ));
    % the first extra sample is the channel number
    channum = dat(:,1);
    dat     = dat(:,2:end);

  case handles.AcqTypeContinuousRaw
    % Data is returned by int16.
    start_sample  = begsample - 1; % samples start at 0
    sample_length = endsample - begsample + 1;
    epoch_count   = 1;
    start_epoch   = 0;
    dat = double(GetMeg160ContinuousRawDataM( fid, start_sample, sample_length ));
    % the first extra sample is the channel number
    channum = dat(:,1);
    dat     = dat(:,2:end);

  case handles.AcqTypeEvokedRaw
    % Data is returned by int16.
    begtrial = ceil(begsample/hdr.sample_count);
    endtrial = ceil(endsample/hdr.sample_count);
    if begtrial<1
      error('cannot read before the begin of the file');
    elseif endtrial>hdr.actual_epoch_count
      error('cannot read beyond the end of the file');
    end
    epoch_count = endtrial-begtrial+1;
    start_epoch = begtrial-1;
    % read all the neccessary trials that contain the desired samples
    dat = double(GetMeg160EvokedRawDataM( fid, start_epoch, epoch_count ));
    % the first extra sample is the channel number
    channum = dat(:,1);
    dat     = dat(:,2:end);
    if size(dat,2)~=epoch_count*hdr.sample_count
      error('could not read all epochs');
    end
    rawbegsample = begsample - (begtrial-1)*hdr.sample_count;
    rawendsample = endsample - (begtrial-1)*hdr.sample_count;
    sample_length = rawendsample - rawbegsample + 1;
    % select the desired samples from the complete trials
    dat = dat(:,rawbegsample:rawendsample);

  otherwise
    error('unknown data type');
end

fclose(fid);

if size(dat,1)~=hdr.channel_count
  error('could not read all channels');
elseif size(dat,2)~=(endsample-begsample+1)
  error('could not read all samples');
end

% Count of AxialGradioMeter
ch_type = hdr.channel_info(:,2);
index = find(ch_type==[handles.AxialGradioMeter]);
axialgradiometer_index_tmp = index;
axialgradiometer_ch_count = length(index);

% Count of PlannerGradioMeter
ch_type = hdr.channel_info(:,2);
index = find(ch_type==[handles.PlannerGradioMeter]);
plannergradiometer_index_tmp = index;
plannergradiometer_ch_count = length(index);

% Count of EegChannel
ch_type = hdr.channel_info(:,2);
index = find(ch_type==[handles.EegChannel]);
eegchannel_index_tmp = index;
eegchannel_ch_count = length(index);

% Count of NullChannel
ch_type = hdr.channel_info(:,2);
index = find(ch_type==[handles.NullChannel]);
nullchannel_index_tmp = index;
nullchannel_ch_count = length(index);

%%% Pulling out AxialGradioMeter and value conversion to physical units.
if ~isempty(axialgradiometer_index_tmp)
    % Acquisition of channel information
    axialgradiometer_index = axialgradiometer_index_tmp;
    ch_info = hdr.channel_info;
    axialgradiometer_ch_info = ch_info(axialgradiometer_index, :);

    % Value conversion
    % B = ( ADValue * VoltRange / ADRange - Offset ) * Sensitivity / FLLGain
    calib = hdr.calib_info;
    amp_gain = hdr.amp_gain(1);
    tmp_ch_no = channum(axialgradiometer_index, 1);
    tmp_data = dat(axialgradiometer_index, 1:sample_length);
    tmp_offset = calib(axialgradiometer_index, 3) * ones(1,sample_length);
    ad_range = 5/2^(hdr.ad_bit-1);
    tmp_data = ( tmp_data * ad_range - tmp_offset );
    clear tmp_offset;
    tmp_gain = calib(axialgradiometer_index, 2) * ones(1,sample_length);
    tmp_data = tmp_data .* tmp_gain / amp_gain;
    dat(axialgradiometer_index, 1:sample_length) = tmp_data;
    clear tmp_gain;

    % Deletion of Inf row
    index = find(axialgradiometer_ch_info(1,:) == Inf);
    axialgradiometer_ch_info(:,index) = [];

    % Deletion of channel_type row
    axialgradiometer_ch_info(:,2) = [];

    % Outputs to the global variable
    handles.sqd.axialgradiometer_ch_info = axialgradiometer_ch_info;
    handles.sqd.axialgradiometer_ch_no = tmp_ch_no;
    handles.sqd.axialgradiometer_data = [ tmp_ch_no tmp_data];
    clear tmp_data;
end

%%% Pulling out PlannerGradioMeter and value conversion to physical units.
if ~isempty(plannergradiometer_index_tmp)
    % Acquisition of channel information
    plannergradiometer_index = plannergradiometer_index_tmp;
    ch_info = hdr.channel_info;
    plannergradiometer_ch_info = ch_info(plannergradiometer_index, :);

    % Value conversion
    % B = ( ADValue * VoltRange / ADRange - Offset ) * Sensitivity / FLLGain
    calib = hdr.calib_info;
    amp_gain = hdr.amp_gain(1);
    tmp_ch_no = channum(plannergradiometer_index, 1);
    tmp_data = dat(plannergradiometer_index, 1:sample_length);
    tmp_offset = calib(plannergradiometer_index, 3) * ones(1,sample_length);
    ad_range = 5/2^(hdr.ad_bit-1);
    tmp_data = ( tmp_data * ad_range - tmp_offset );
    clear tmp_offset;
    tmp_gain = calib(plannergradiometer_index, 2) * ones(1,sample_length);
    tmp_data = tmp_data .* tmp_gain / amp_gain;
    dat(plannergradiometer_index, 1:sample_length) = tmp_data;
    clear tmp_gain;

    % Deletion of Inf row
    index = find(plannergradiometer_ch_info(1,:) == Inf);
    plannergradiometer_ch_info(:,index) = [];

    % Deletion of channel_type row
    plannergradiometer_ch_info(:,2) = [];

    % Outputs to the global variable
    handles.sqd.plannergradiometer_ch_info = plannergradiometer_ch_info;
    handles.sqd.plannergradiometer_ch_no = tmp_ch_no;
    handles.sqd.plannergradiometer_data = [ tmp_ch_no tmp_data];
    clear tmp_data;
end

%%% Pulling out EegChannel Channel and value conversion to Volt units.
if ~isempty(eegchannel_index_tmp)
    % Acquisition of channel information
    eegchannel_index = eegchannel_index_tmp;

    % Value conversion
    % B = ADValue * VoltRange / ADRange
    tmp_ch_no = channum(eegchannel_index, 1);
    tmp_data = dat(eegchannel_index, 1:sample_length);
    ad_range = 5/2^(hdr.ad_bit-1);
    tmp_data = tmp_data * ad_range;
    dat(eegchannel_index, 1:sample_length) = tmp_data;

    % Outputs to the global variable
    handles.sqd.eegchannel_ch_no = tmp_ch_no;
    handles.sqd.eegchannel_data = [ tmp_ch_no tmp_data];
    clear tmp_data;
end

%%% Pulling out Null Channel and value conversion to Volt units.
if ~isempty(nullchannel_index_tmp)
    % Acquisition of channel information
    nullchannel_index = nullchannel_index_tmp;

    % Value conversion
    % B = ADValue * VoltRange / ADRange
    tmp_ch_no = channum(nullchannel_index, 1);
    tmp_data = dat(nullchannel_index, 1:sample_length);
    ad_range = 5/2^(hdr.ad_bit-1);
    tmp_data = tmp_data * ad_range;
    dat(nullchannel_index, 1:sample_length) = tmp_data;

    % Outputs to the global variable
    handles.sqd.nullchannel_ch_no = tmp_ch_no;
    handles.sqd.nullchannel_data = [ tmp_ch_no tmp_data];
    clear tmp_data;
end

% select only the desired channels
dat = dat(chanindx,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this defines some usefull constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function handles = definehandles
handles.output = [];
handles.sqd_load_flag = false;
handles.mri_load_flag = false;
handles.NullChannel         = 0;
handles.MagnetoMeter        = 1;
handles.AxialGradioMeter    = 2;
handles.PlannerGradioMeter  = 3;
handles.RefferenceChannelMark = hex2dec('0100');
handles.RefferenceMagnetoMeter       = bitor( handles.RefferenceChannelMark, handles.MagnetoMeter );
handles.RefferenceAxialGradioMeter   = bitor( handles.RefferenceChannelMark, handles.AxialGradioMeter );
handles.RefferencePlannerGradioMeter = bitor( handles.RefferenceChannelMark, handles.PlannerGradioMeter );
handles.TriggerChannel      = -1;
handles.EegChannel          = -2;
handles.EcgChannel          = -3;
handles.EtcChannel          = -4;
handles.NonMegChannelNameLength = 32;
handles.DefaultMagnetometerSize       = (4.0/1000.0);       % Square of 4.0mm in length
handles.DefaultAxialGradioMeterSize   = (15.5/1000.0);      % Circle of 15.5mm in diameter
handles.DefaultPlannerGradioMeterSize = (12.0/1000.0);      % Square of 12.0mm in length
handles.AcqTypeContinuousRaw = 1;
handles.AcqTypeEvokedAve     = 2;
handles.AcqTypeEvokedRaw     = 3;
handles.sqd = [];
handles.sqd.selected_start  = [];
handles.sqd.selected_end    = [];
handles.sqd.axialgradiometer_ch_no      = [];
handles.sqd.axialgradiometer_ch_info    = [];
handles.sqd.axialgradiometer_data       = [];
handles.sqd.plannergradiometer_ch_no    = [];
handles.sqd.plannergradiometer_ch_info  = [];
handles.sqd.plannergradiometer_data     = [];
handles.sqd.eegchannel_ch_no   = [];
handles.sqd.eegchannel_data    = [];
handles.sqd.nullchannel_ch_no   = [];
handles.sqd.nullchannel_data    = [];
handles.sqd.selected_time       = [];
handles.sqd.sample_rate         = [];
handles.sqd.sample_count        = [];
handles.sqd.pretrigger_length   = [];
handles.sqd.matching_info   = [];
handles.sqd.source_info     = [];
handles.sqd.mri_info        = [];
handles.mri                 = [];
