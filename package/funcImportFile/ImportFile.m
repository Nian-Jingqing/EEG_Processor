function [ArgOut, Next, Warnings] = ImportFile(Import)
% Initialize warnings
Warnings = {};
% -------------------------------------------------------------------------
% Check if files exist
disp('>> BIDS: Checking validity of paths')
if exist(Import.DataFile.Path) == 0 %#ok<EXIST>
    error('Data file not found:\n''%s''.', Import.DataFile.Path)
end
if strcmpi(Import.Channels.Type, 'Geoscan') && exist(Import.Channels.Path) == 0 %#ok<EXIST>
    error('Geoscan file not found:\n''%s''.', Import.Channels.Path)
end
if ~isempty(Import.Events.HypnoPath) && exist(Import.Events.HypnoPath) == 0 %#ok<EXIST>
    error('Compumedics Hypnogram file not found:\n''%s''.', Import.Events.HypnoPath)
end
if ~isempty(Import.Events.EventsPath) && exist(Import.Events.EventsPath) == 0 %#ok<EXIST>
    error('Compumedics Hypnogram file not found:\n''%s''.', Import.Events.HypnoPath)
end
if ~isempty(Import.Events.WonambiXMLPath) && exist(Import.Events.WonambiXMLPath) == 0 %#ok<EXIST>
    error('Wonambi XML file not found:\n''%s''.', Import.Events.WonambiXMLPath)
end
% -------------------------------------------------------------------------
% CREATE EEGLAB STRUCTURE
disp('>> BIDS: Creating EEGLAB structure')
[EEG, MFF] = Import_EmptySet(Import.DataFile.Type, Import.DataFile.Path);
% -------------------------------------------------------------------------
% SETTING THE SUBJECT ID
EEG.subject = Import.Subject;
% -------------------------------------------------------------------------
% IMPORTING EEG CHANNEL LOCATIONS
[EEG, urpibchanlocs, urpibdata] = Import_ChannelLocations(EEG, Import.Channels.Type, Import.Channels.Path, Import.DataFile.Type);
% -------------------------------------------------------------------------
% ONLY KEEP THOSE EEG CHANNELS THE USER SPECIFIED TO LOAD
if Import.SaveAs.Type == 12
    EEG = Import_SelectTenTwentyChans(EEG, Import.DataFile.Type);
end
% -------------------------------------------------------------------------
% LOAD THE EEG DATA
disp('>> BIDS: Loading EEG data')
switch Import.DataFile.Type
    case 'MFF'
        EEG = mff_import_eeg_data(EEG, MFF);
    case {'SET', 'COMPU257', 'TENTWENTY'}
        disp('>> BIDS: Keeping only the EEG channels')
        EEG = pop_select(EEG, 'channel', {EEG.chanlocs.labels});
end
% -------------------------------------------------------------------------
% Check that the number of channels in the data is the same as in Chanlocs
if size(EEG.data, 1) ~= length(EEG.chanlocs)
    error('%s: The number of rows in the matrix ''EEG.data'' (%i) is not equal to the length of ''EEG.chanlocs'' (%i).', EEG.filename, size(EEG.data, 1), length(EEG.chanlocs))
end
% -------------------------------------------------------------------------
% Force reference to single electrode
if strcmpi(Import.DataFile.Type, 'MFF') || strcmpi(Import.DataFile.Type, 'COMPU257')
    if strcmpi(Import.DataFile.Type, 'COMPU257')
        RefChan = 'REF';
    else
        RefChan = 'Cz';
    end
    EEG = pop_reref(EEG, strcmpi({EEG.chanlocs.labels}, RefChan), 'keepref', 'on');
    EEG = pop_chanedit(EEG, 'setref', {'1:257', RefChan});
    EEG.ref = 'common';
    % Or in case of the TEN-TWENTY type, set the reference channels
elseif strcmpi(Import.DataFile.Type, 'TENTWENTY')
    for i = 1:EEG.nbchan
        if strcmpi(EEG.chanlocs(i).type, 'PNS')
            continue
        else
            switch EEG.chanlocs(i).labels(end)
                case {'1', '3'}
                    EEG.chanlocs(i).ref = 'M2';
                case {'2', '4'}
                    EEG.chanlocs(i).ref = 'M1';
                case 'z'
                    EEG.chanlocs(i).ref = {'M1', 'M2'};
            end
        end
    end
    EEG.ref = 'mixed';
end
% -------------------------------------------------------------------------
% LOAD ALL PHYSIOLOGY DATA
switch Import.DataFile.Type
    case 'MFF'
        disp('>> BIDS: Loading PNS data')
        EEG = mff_import_pib_data(EEG, MFF);
        EEG = mff_import_piblocs(EEG, Import.DataFile.Path);
    case {'SET', 'COMPU257', 'TENTWENTY'}
        % All physiology data should have been loaded originally.
        % Can not do it here.
        disp('>> BIDS: Adding back the original PNS channels')
        EEG.data = [EEG.data; urpibdata];
        EEG.nbchan = size(EEG.data, 1);
        fnames = fieldnames(urpibchanlocs);
        for i = 1:length(urpibchanlocs)
            k = length(EEG.chanlocs)+1;
            for j = 1:length(fnames)
                EEG.chanlocs(k).(fnames{j}) = urpibchanlocs(i).(fnames{j});
            end
        end
end
% -------------------------------------------------------------------------
% CALCULATE EOG CHANNELS, BUT ONLY IF NOT EXISTENT
idx = regexpIdx({EEG.chanlocs.labels}, 'EOG') | strcmpi({EEG.chanlocs.type}, 'EOG') | strcmpi({EEG.chanlocs.labels}, 'VEOG') | strcmpi({EEG.chanlocs.labels}, 'HEOG') | strcmpi({EEG.chanlocs.labels}, 'VEOU') | strcmpi({EEG.chanlocs.labels}, 'HEOR');
if ~any(idx)
    EEG = mff_calc_eog(EEG);
end
% Check that all channel labels are Matlab valid variable names
for ci = 1:length(EEG.chanlocs)
    EEG.chanlocs(ci).labels = matlab.lang.makeValidName(EEG.chanlocs(ci).labels);
end
% Store the original channel locations in case we delete any channels
EEG.urchanlocs = EEG.chanlocs;
% -------------------------------------------------------------------------
% LOAD ALL EVENTS FROM THE MFF FILE
switch Import.DataFile.Type
    case 'MFF'
        disp('>> BIDS: Importing events from MFF file')
        T = now;
        EEG = mff_import_events(EEG, Import.DataFile.Path);
        fprintf(' - Finished in %s\n', datestr(now-T, 'HH:MM:SS'))
    otherwise
        % All Events should have been loaded the first time.
        % If not, the user should re-import the MFF file
end
% -------------------------------------------------------------------------
% LOAD THE HYPNOGRAM AND SLEEP EVENTS
if ~isempty(Import.Events.HypnoPath)
    [EEG, warnmsg] = compumed_import_sleep_scores(EEG, Import.Events.HypnoPath);
    if ~isempty(warnmsg)
        warnmsg = sprintf('%s: %s', EEG.filename, warnmsg);
        Warnings = [Warnings, {warnmsg; '-----'}];
    end
end
if ~isempty(Import.Events.EventsPath)
    switch Import.DataFile.Type
        case 'MFF'
            [EEG, warnmsg] = compumed_import_sleep_events(EEG, Import.Events.EventsPath, Import.DataFile.Path);
        case {'SET', 'COMPU257'}
            [EEG, warnmsg] = compumed_import_sleep_events(EEG, Import.Events.EventsPath);
    end
    if ~isempty(warnmsg)
        warnmsg = sprintf('%s: %s', EEG.filename, warnmsg);
        Warnings = [Warnings, {warnmsg; '-----'}];
    end
end
if ~isempty(Import.Events.WonambiXMLPath)
    [EEG, warnmsg] = wonambi_import_xml(EEG, Import.Events.WonambiXMLPath);
    if ~isempty(warnmsg)
        warnmsg = sprintf('%s: %s', EEG.filename, warnmsg);
        Warnings = [Warnings, {warnmsg; '-----'}];
    end
end
% Make sure there is a 'duration' field
if ~isfield(EEG.event, 'duration')
    for ei = 1:length(EEG.event)
        EEG.event(ei).duration = 0;
    end
end
% -------------------------------------------------------------------------
% Check if filtering is set, if so, do filter, otherwise update JSON
EEG = Proc_TemporalFilter(EEG, Import.Processing);
% -------------------------------------------------------------------------
% FILTER THE PNS DATA
if Import.Processing.DoFilter
    EEG = Import_PhysioFilter(EEG);
end
% -------------------------------------------------------------------------
% Check if resampling is set, if so, do resample, otherwise update JSON
if Import.Processing.DoResample
    EEG = Proc_Resample(EEG, Import.Processing);
end
% -------------------------------------------------------------------------
% CALCULATE FASTER STATISTICS
if Import.SaveAs.Type ~= 12
    EEG.etc.faster = Proc_FasterStats(EEG, ifelse(strcmpi(Import.DataFile.Type, 'TENTWENTY'), true, false));
end
% -------------------------------------------------------------------------
% CALCULATE SPECTROGRAM
[EEG, Warnings] = Analysis_Spectrogram(EEG, Import.Processing, [], Warnings);
% -------------------------------------------------------------------------
% CALCULATE ICA
[EEG, Warnings] = Analysis_ICA(EEG, Import.Processing, [], Warnings);
% -------------------------------------------------------------------------
% CHECK THE DATA AND EVENT CONSISTENCY
if size(EEG.data, 1) ~= EEG.nbchan
    error('%s: The number of rows in the matrix ''EEG.data'' (%i) is not equal to the value of ''EEG.nbchan'' (%i).', EEG.filename, size(EEG.data, 1), EEG.nbchan)
end
if size(EEG.data, 1) ~= length(EEG.chanlocs)
    error('%s: The number of rows in the matrix ''EEG.data'' (%i) is not equal to the length of ''EEG.chanlocs'' (%i).', EEG.filename, size(EEG.data, 1), length(EEG.chanlocs))
end
if length(EEG.chanlocs) ~= EEG.nbchan
    error('%s: The length of ''EEG.chanlocs'' (%i) is not equal to the value of ''EEG.nbchan'' (%i).', EEG.filename, length(EEG.chanlocs), EEG.nbchan)
end
% check the eeg for consistency
EEG = eeg_checkset(EEG, 'eventconsistency');
% Check that all event labels are Matlab valid variable names
for ei = 1:length(EEG.event)
    if ~ischar(EEG.event(ei).type)
        EEG.event(ei).type = num2str(EEG.event(ei).type);
    end
    EEG.event(ei).type = matlab.lang.makeValidName(EEG.event(ei).type);
end
% Store the original events in case we modify any of the events
EEG.urevent = EEG.event;
% -------------------------------------------------------------------------
% Set the name and path of this dataset
[EEG.filepath, EEG.setname] = fileparts(Import.SaveAs.Path);
if Import.SaveAs.Type == 12
    EEG.filename = [EEG.setname, '.edf'];
    EEG.datfile = '';
elseif Import.SaveAs.Type == 256
    EEG.filename = [EEG.setname, '.set'];
    EEG.datfile = [EEG.setname, '.fdt'];
end
% -------------------------------------------------------------------------
% Set the JSON structure
KeysValues = filename2struct(EEG.setname);
EEG.etc.JSON.TaskName = KeysValues.task;
EEG.etc.JSON.EEGReference = EEG.ref;
EEG.etc.JSON.EEGChannelCount = sum(strcmpi({EEG.chanlocs.type}, 'EEG'));
EEG.etc.JSON.ECGChannelCount = sum(strcmpi({EEG.chanlocs.type}, 'ECG'));
EEG.etc.JSON.EMGChannelCount = sum(strcmpi({EEG.chanlocs.type}, 'EMG'));
EEG.etc.JSON.EOGChannelCount = sum(strcmpi({EEG.chanlocs.type}, 'EOG') | strcmpi({EEG.chanlocs.type}, 'VEOG') | strcmpi({EEG.chanlocs.type}, 'HEOG'));
EEG.etc.JSON.MiscChannelCount = EEG.nbchan - ...
    EEG.etc.JSON.EEGChannelCount - ...
    EEG.etc.JSON.ECGChannelCount - ...
    EEG.etc.JSON.EMGChannelCount - ...
    EEG.etc.JSON.EOGChannelCount;
EEG.etc.JSON.SamplingFrequency = EEG.srate;
EEG.etc.JSON.RecordingDuration = EEG.pnts/EEG.srate;
EEG.etc.JSON.RecordingType = ifelse(EEG.trials == 1, 'continuous', 'epoched');
EEG.etc.JSON.TrialCount = EEG.trials;
% -----
% Check to save as EDF or as SET
if Import.SaveAs.Type == 12
    [EEG, ~, Warnings] = SaveTenTwentyDataset(EEG, Import.SaveAs, Warnings);
else
    EEG = SaveDataset(EEG, 'all');
end
% -------------------------------------------------------------------------
% Generate the output variable
EEG.data = []; % To save memory
EEG.times = [];
EEG.specdata = [];
EEG.specchans = [];
EEG.specfreqs = [];
EEG.spectimes = [];
EEG.specnormmethod = 'none';
EEG.specnormvals = struct();
EEG.specnormfnc = [];
EEG.icaact = [];
EEG.icawinv = [];
EEG.icasphere = [];
EEG.icaweights = [];
EEG.icachansind = [];
EEG.specicaact = [];
EEG.filepath = strrep(EEG.filepath, filesep, '/');
ArgOut = EEG;

% What step to do next?
Next = 'AddFile';

end
