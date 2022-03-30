function pns = pns_workspaces()
% -----
% Initialize empty structure
pns = struct(); %#ok<*NASGU>
i = 1;
% -----
% KDT Workspace
pns(i).labels = 'ECG'; pns(i).type = 'ECG'; i = i+1;
% -----
% MWT Workspace
pns(i).labels = 'EMG'; pns(i).type = 'EMG'; i = i+1;
% -----
% PSG Workspace
pns(i).labels = 'SpO2-Pulse'; pns(i).type = 'MISC'; i = i+1;
pns(i).labels = 'SpO2-OSat'; pns(i).type = 'MISC'; i = i+1;
pns(i).labels = 'Resp. Temp'; pns(i).type = 'Respiratory'; i = i+1;
pns(i).labels = 'Resp. Flow'; pns(i).type = 'NasalPressure'; i = i+1;
pns(i).labels = 'Thor. Effort'; pns(i).type = 'Respiratory'; i = i+1;
pns(i).labels = 'Abdo. Effort'; pns(i).type = 'Respiratory'; i = i+1;
pns(i).labels = 'Snore'; pns(i).type = 'Snoring'; i = i+1;
pns(i).labels = 'Chin'; pns(i).type = 'EMG'; i = i+1;
pns(i).labels = 'Left leg'; pns(i).type = 'EMG'; i = i+1;
pns(i).labels = 'Right leg'; pns(i).type = 'EMG'; i = i+1;
pns(i).labels = 'Left FDS'; pns(i).type = 'EMG'; i = i+1;
pns(i).labels = 'Right FDS'; pns(i).type = 'EMG'; i = i+1;
pns(i).labels = 'Left EDB'; pns(i).type = 'EMG'; i = i+1;
pns(i).labels = 'Right EDB'; pns(i).type = 'EMG'; i = i+1;
pns(i).labels = 'Body Position'; pns(i).type = 'MISC'; i = i+1;
% -----
% Compumedics Workspace
pns(i).labels = 'VEOU'; pns(i).type = 'EOG'; pns(i).relabel = 'VEOG'; i = i+1;
pns(i).labels = 'HEOR'; pns(i).type = 'EOG'; pns(i).relabel = 'HEOG'; i = i+1;
pns(i).labels = 'BP 3'; pns(i).type = 'Respiratory'; pns(i).relabel = 'Abdo. Effort'; i = i+1;
pns(i).labels = 'BP 4'; pns(i).type = 'Respiratory'; pns(i).relabel = 'Thor. Effort'; i = i+1;
pns(i).labels = 'BP 5'; pns(i).type = 'NasalPressure'; pns(i).relabel = 'Resp. Flow'; i = i+1;
pns(i).labels = 'BP 6'; pns(i).type = 'Snoring'; pns(i).relabel = 'Snore'; i = i+1;
pns(i).labels = 'BP 7'; pns(i).type = 'Respiratory'; pns(i).relabel = 'Resp. Temp'; i = i+1;
pns(i).labels = 'BP 8'; pns(i).type = 'ECG'; pns(i).relabel = 'ECG'; i = i+1;
pns(i).labels = 'BP 9'; pns(i).type = 'EMG'; pns(i).relabel = 'EMG Chin'; i = i+1;
pns(i).labels = 'BP 10'; pns(i).type = 'EMG'; pns(i).relabel = 'EMG Left Leg'; i = i+1;
pns(i).labels = 'BP 11'; pns(i).type = 'EMG'; pns(i).relabel = 'EMG Right Leg'; i = i+1;
pns(i).labels = 'BP 12'; pns(i).type = 'MISC'; pns(i).relabel = 'Body Position'; i = i+1;
pns(i).labels = 'BP 13'; pns(i).type = 'EMG'; pns(i).relabel = 'EMG Right Arm'; i = i+1;
pns(i).labels = 'BP 14'; pns(i).type = 'EMG'; pns(i).relabel = 'EMG Left Arm'; i = i+1;
pns(i).labels = 'BP 15'; pns(i).type = 'EMG'; pns(i).relabel = 'EMG Right Foot'; i = i+1;
pns(i).labels = 'BP 16'; pns(i).type = 'EMG'; pns(i).relabel = 'EMG Left Foot'; i = i+1;
pns(i).labels = 'SpO2'; pns(i).type = 'MISC'; pns(i).relabel = 'SpO2'; i = i+1;
end
