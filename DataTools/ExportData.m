function handles = ExportData(handles)

% Help for the Export Mean Data tool:
% Category: Data Tools
%
% Once image analysis is complete, use this tool to select the
% output file to extract the measurements and other information about
% the analysis.  The data will be converted to a comma-delimited text file
% which can be read by for example Excel or in a text editor.

% CellProfiler is distributed under the GNU General Public License.
% See the accompanying file LICENSE for details.
%
% Developed by the Whitehead Institute for Biomedical Research.
% Copyright 2003,2004,2005.
%
% Authors:
%   Anne Carpenter <carpenter@wi.mit.edu>
%   Thouis Jones   <thouis@csail.mit.edu>
%   In Han Kang    <inthek@mit.edu>
%
% $Revision$

%%% Ask the user to choose the file from which to extract measurements.
if exist(handles.Current.DefaultOutputDirectory, 'dir')
    [RawFileName, RawPathname] = uigetfile(fullfile(handles.Current.DefaultOutputDirectory,'.','*.mat'),'Select the raw measurements file');
    PathToSave = handles.Current.DefaultOutputDirectory;
else
    [RawFileName, RawPathname] = uigetfile('*.mat','Select the raw measurements file');
    PathToSave = RawPathname;
end

if RawFileName == 0
    return
end

%%% Load the specified CellProfiler output file
load(fullfile(RawPathname, RawFileName));

%%% Quick check if it seems to be a CellProfiler file or not
if ~exist('handles','var')
    errordlg('The selected file does not seem to be a CellProfiler output file.')
    return
end

%%% Opens a window that lets the user chose what to export
ExportInfo = ObjectsToExport(handles,RawFileName);

%%% Export process info
if strcmp(ExportInfo.ExportProcessInfo,'yes')
    WriteProcessInfo(handles,ExportInfo,RawFileName,RawPathname);
end

%%% Export measurements
if ~strcmp(ExportInfo.ReportStyle,'none')
    WriteMeasurements(handles,ExportInfo,RawPathname);
end

msgbox('','Exportation completed')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ExportInfo = ObjectsToExport(handles,RawFileName)
% This function displays a window so that lets the user choose which
% measurements to export. If the return variable 'ObjectNames' is empty
% it means that either no measurements were found or the user pressed
% the Cancel button (or the window was closed). 'Summary' takes on the values'yes'
% or 'no', depending if the user only wants a summary report (mean and std)
% or a full report.

% Initialize output variables
ExportInfo.ObjectNames = [];
ExportInfo.MeasurementFilename = [];
ExportInfo.ProcessInfoFilename = [];
ExportInfo.ReportStyle = [];
ExportInfo.ExportProcessInfo = [];

% The fontsize is stored in the 'UserData' property of the main Matlab window
FontSize = get(0,'UserData');

% Get measurement object fields
fields = fieldnames(handles.Measurements);

% Remove the 'GeneralInfo' field
index = setdiff(1:length(fields),strmatch('GeneralInfo',fields));
fields = fields(index);

if length(fields) > 20
    errordlg('There are more than 20 different objects in the chosen file. There is probably something wrong in the handles.Measurement structure.')
    return
end

% Create Export window
ETh = figure;
set(ETh,'units','inches','resize','on','menubar','none','toolbar','none','numbertitle','off','Name','Export window');
pos = get(ETh,'position');
Height = 2.2+length(fields)*0.25;                       % Window height in inches, depends on the number of objects
set(ETh,'position',[pos(1) pos(2) 4 Height]);

if ~isempty(fields)
    % Top text
    uicontrol(ETh,'style','text','String','The following measurements were found:','FontName','Times','FontSize',FontSize,...
        'HorizontalAlignment','left','units','inches','position',[0.2 Height-0.3 4 0.15],'BackgroundColor',get(ETh,'color'))

    % Radio buttons for extracted measurements
    h = [];
    for k = 1:length(fields)
        uicontrol(ETh,'style','text','String',fields{k},'FontName','Times','FontSize',FontSize,'HorizontalAlignment','left',...
            'units','inches','position',[0.6 Height-0.35-0.2*k 3 0.15],'BackgroundColor',get(ETh,'color'))
        h(k) = uicontrol(ETh,'Style','Radiobutton','units','inches','position',[0.2 Height-0.35-0.2*k 0.2 0.2],...
            'BackgroundColor',get(ETh,'color'),'Value',1);
    end

    % Report style?
    uicontrol(ETh,'style','text','String','Choose report style:','FontName','Times','FontSize',FontSize,...
        'HorizontalAlignment','left','units','inches','position',[0.2 1.35 1.5 0.2],'BackgroundColor',get(ETh,'color'))
    reportbutton = uicontrol(ETh,'Style','popup','units','inches','position',[0.2 1.2 1.5 0.2],...
        'backgroundcolor',[1 1 1],'String','Full report|Summary report|Both|None');

    % Filename
    % Remove 'OUT' and '.mat' extension from filename
    ProposedFilename = RawFileName;
    indexOUT = strfind(ProposedFilename,'OUT');
    if ~isempty(indexOUT),ProposedFilename = [ProposedFilename(1:indexOUT(1)-1) ProposedFilename(indexOUT(1)+3:end)];end
    indexMAT = strfind(ProposedFilename,'mat');
    if ~isempty(indexMAT),ProposedFilename = [ProposedFilename(1:indexMAT(1)-2) ProposedFilename(indexMAT(1)+3:end)];end
    ProposedFilename = [ProposedFilename,'_Export'];
    uicontrol(ETh,'style','text','String','Chose base of output filename:','FontName','Times','FontSize',FontSize,...
        'HorizontalAlignment','left','units','inches','position',[2 1.35 1.8 0.2],'BackgroundColor',get(ETh,'color'))
    EditMeasurementFilename = uicontrol(ETh,'Style','edit','units','inches','position',[2 1.2 1.8 0.2],...
        'backgroundcolor',[1 1 1],'String',ProposedFilename);
else  % No measurements found
    uicontrol(ETh,'style','text','String','No measurements found!','FontName','Times','FontSize',FontSize,...
        'units','inches','position',[0 Height-0.5 4 0.15],'BackgroundColor',get(ETh,'color'),'fontweight','bold')
end

%%% Process info
% Drop down menu for selecting whether to export process info or not
uicontrol(ETh,'style','text','String','Export process info:','FontName','Times','FontSize',FontSize,...
    'HorizontalAlignment','left','units','inches','position',[0.2 0.85 1.5 0.2],'BackgroundColor',get(ETh,'color'))
processbutton = uicontrol(ETh,'Style','popup','units','inches','position',[0.2 0.7 1.5 0.2],...
    'backgroundcolor',[1 1 1],'String','Yes|No');

% Propose a filename. Remove 'OUT' and '.mat' extension from filename
ProposedFilename = RawFileName;
indexOUT = strfind(ProposedFilename,'OUT');
if ~isempty(indexOUT),ProposedFilename = [ProposedFilename(1:indexOUT(1)-1) ProposedFilename(indexOUT(1)+3:end)];end
indexMAT = strfind(ProposedFilename,'mat');
if ~isempty(indexMAT),ProposedFilename = [ProposedFilename(1:indexMAT(1)-2) ProposedFilename(indexMAT(1)+3:end)];end
ProposedFilename = [ProposedFilename,'_ProcessInfo.txt'];
uicontrol(ETh,'style','text','String','Chose output filename:','FontName','Times','FontSize',FontSize,...
    'HorizontalAlignment','left','units','inches','position',[2 0.85 2.2 0.2],'BackgroundColor',get(ETh,'color'))
EditProcessInfoFilename = uicontrol(ETh,'Style','edit','units','inches','position',[2 0.7 1.8 0.2],...
    'backgroundcolor',[1 1 1],'String',ProposedFilename);


% Export and Cancel pushbuttons
exportbutton = uicontrol(ETh,'style','pushbutton','String','Export','FontName','Times','FontSize',FontSize,'units','inches',...
    'position',[1.15 0.1 0.75 0.3],'Callback','[foo,fig] = gcbo;set(fig,''UserData'',1);uiresume(fig)');
cancelbutton = uicontrol(ETh,'style','pushbutton','String','Cancel','FontName','Times','FontSize',FontSize,'units','inches',...
    'position',[2.1 0.1 0.75 0.3],'Callback','[foo,fig] = gcbo;set(fig,''UserData'',0);uiresume(fig)');

uiwait(ETh)                         % Wait until window is destroyed or uiresume() is called

if get(ETh,'Userdata') == 0         % The user pressed the Cancel button
    close(ETh)
elseif get(ETh,'Userdata') == 1     % The user pressed the Export button

    % Which kind of report (these variables only exist if there exist
    % measurements)
    if ~isempty(fields)
        reportchoice = get(reportbutton,'value');
        ReportStyles = {'full','summary','both','none'};
        ExportInfo.ReportStyle = ReportStyles{reportchoice};
    end

    % Export process info?
    if get(processbutton,'value') == 1
        ExportInfo.ExportProcessInfo = 'yes';
    else
        ExportInfo.ExportProcessInfo = 'no';
    end

    % File names
    if ~isempty(fields)
        ExportInfo.MeasurementFilename = get(EditMeasurementFilename,'String');
    end
    ExportInfo.ProcessInfoFilename = get(EditProcessInfoFilename,'String');

    % Get measurements to export
    if ~isempty(fields)
        buttonchoice = get(h,'Value');
        if iscell(buttonchoice)                              % buttonchoice will be a cell array if there are several objects
            buttonchoice = cat(1,buttonchoice{:});
        end
        ExportInfo.ObjectNames = fields(find(buttonchoice));  % Get the fields for which the radiobuttons are enabled
    end
    close(ETh)
else
    ExportInfo.ObjectNames = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function WriteProcessInfo(handles,ExportInfo,RawFileName,RawPathname)
%%% This function extracts info about the process that generated a
%%% CellProfiler output file, and writes this info to a textfile.

%%% Open file for writing
fid = fopen(fullfile(RawPathname,ExportInfo.ProcessInfoFilename),'w');
if fid == -1
    errordlg(sprintf('Cannot create the output file %s. There might be another program using a file with the same name.',ExportInfo.ProcessInfoFilename));
    return
end

fprintf(fid,'Processing info for file: %s\n',fullfile(RawPathname, RawFileName));
fprintf(fid,'Processed: %s\n\n',handles.Current.TimeStarted);

fprintf(fid,'Pipeline:\n');
for module = 1:length(handles.Settings.ModuleNames)
    fprintf(fid,'\t%s\n',handles.Settings.ModuleNames{module});
    varibles = handles.Settings.VariableValues(module,:);
    % Can add info about what the module did
    %switch handles.Settings.ModuleNames{module}
    %    case 'LoadImagesText'
    %    case 'RGBSplit'
    %    case 'IdentifyEasy'
    %end
end

fprintf(fid,'\nPixel size: %s micrometer(s)\n',handles.Settings.PixelSize);
fprintf(fid,'Number of image sets: %d\n\n',handles.Current.NumberOfImageSets);

% Get variable names used
VariableNames = fieldnames(handles.Pipeline);
Variableindex = find(cellfun('isempty',strfind(VariableNames,'FileList'))==0);
VariableNames = VariableNames(Variableindex);

% Get objects segmented
if isfield(handles,'Measurements') && isfield(handles.Measurements,'GeneralInfo')
    ObjectNames   = fieldnames(handles.Measurements.GeneralInfo);
    Thresholdindex = find(cellfun('isempty',strfind(ObjectNames,'ImageThreshold'))==0);
    ObjectNames = ObjectNames(Thresholdindex);
else
    ObjectNames = [];
end

% Report info for each image set
for imageset = 1:handles.Current.NumberOfImageSets
    fprintf(fid,'Image set #%d ---------------------------------------\n',imageset);
    fprintf(fid,'\tVariables:\n');
    for k = 1:length(VariableNames)
        fprintf(fid,'\t\t%s: %s\n',VariableNames{k}(9:end),handles.Pipeline.(VariableNames{k}){imageset});
    end
    fprintf(fid,'\n');
    fprintf(fid,'\tObjects:\n');
    for k = 1:length(ObjectNames)
        fprintf(fid,'\t\t%s',ObjectNames{k}(15:end));
        fprintf(fid,'\t Threshold: %g\n',handles.Measurements.GeneralInfo.(ObjectNames{k}){imageset});
    end
    fprintf(fid,'\n');
end
fclose(fid);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function WriteMeasurements(handles,ExportInfo,RawPathname)
%%% This function exports full and summary measurement reports

for Object = 1:length(ExportInfo.ObjectNames)
    ObjectName = ExportInfo.ObjectNames{Object};

    %%% Get fields in handles.Measurements
    fields = fieldnames(handles.Measurements.(ObjectName));

    %%% Organize features in format suitable for exportation. Create
    %%% a cell array Measurements where all features are concatenated
    %%% with each column corresponding to a separate feature
    FeatureNames = {};
    Measurements = {};
    for k = 1:length(fields)
        if ~isempty(strfind(fields{k},'Features'))                              % Found a field with feature names

            % Get the associated cell array of measurements
            try
                tmp = handles.Measurements.(ObjectName).(fields{k}(1:end-8));
            catch
                fclose(fid);
                errordlg('Error in handles.Measurements structure. The field ',fields{k},' does not have an associated measurement field.');
            end

            % Concatenate measurement and feature name matrices
            if isempty(Measurements)                                           % Have to initialize
                Measurements = tmp;
            else
                for j = 1:length(tmp)
                    Measurements(j) = {cat(2,Measurements{j},tmp{j})};
                end
            end

            % Construct informative feature names
            tmp = handles.Measurements.(ObjectName).(fields{k});
            for j = 1:length(tmp)
                tmp{j} = [tmp{j} ' (' , fields{k}(1:end-8),')'];
            end
            FeatureNames = cat(2,FeatureNames,tmp);
        end
    end

    % Count objects
    NumObjects = zeros(length(Measurements),1);
    for k = 1:length(Measurements)
        NumObjects(k) = size(Measurements{k},1);
    end

    % Get general information from handles.Measurements.GeneralInfo
    InfoFields = fieldnames(handles.Measurements.GeneralInfo);
    Filenames  = InfoFields(strmatch('Filename',InfoFields));
    if ~isempty(strmatch('ImageThreshold',InfoFields))                         % Some measurement do not require a segmentation/thresholding, e.g. MeasureCorrelation
        Thresholds = InfoFields(strmatch('ImageThreshold',InfoFields));
        for k = 1:length(Thresholds)
            if strcmp(Thresholds{k}(15:end),ObjectName)
                Threshold = handles.Measurements.GeneralInfo.(Thresholds{k});
            end
        end
    end
    Time = handles.Measurements.GeneralInfo.TimeElapsed;

    if ~strcmp(ExportInfo.ReportStyle,'summary')                          % The user wants a full report

        % Open a file for exporting the measurements
        ExportFileName = [ExportInfo.MeasurementFilename,'_',ObjectName,'.xls'];

        fid = fopen(fullfile(RawPathname,ExportFileName),'w');
        if fid == -1
            errordlg(sprintf('Cannot create the output file %s. There might be another program using a file with the same name.',ExportFileName));
            return
        end

        %%% Write comma-separated file that can be imported into Excel
        % Header part
        fprintf(fid,'%s: Summary\nTotal time: %0.2f s\n', ObjectName,Time{end});

        % Write feature names in one row
        % Interleave feature names with commas and write to file
        str = cell(2*length(FeatureNames),1);
        str(1:2:end) = {','};
        str(2:2:end) = FeatureNames;
        fprintf(fid,',%s\n',cat(2,str{:}));

        % Loop over the images sets
        for k = 1:length(Measurements)

            % Write info about the image set
            fprintf(fid,'Set #%d, %d objects\n',k,NumObjects(k));
            fprintf(fid,'Filenames: ');
            for j = 1:length(Filenames)
                fprintf(fid,'"%s":%s ',Filenames{j}(9:end),handles.Measurements.GeneralInfo.(Filenames{j}){k});
            end

            % Write segmentation threshold if it exists
            if exist('Threshold','var')
                fprintf(fid,',Threshold: %g\n',Threshold{k});
            else
                fprintf(fid,'\n');
            end

            % Write measurements
            if ~isempty(Measurements{k})
                for row = 1:size(Measurements{k},1)                        % Loop over the rows
                    tmp = cellstr(num2str(Measurements{k}(row,:)','%g'));  % Create cell array with measurements
                    str = cell(2*length(tmp),1);                           % Interleave with commas
                    str(1:2:end) = {','};
                    str(2:2:end) = tmp;
                    fprintf(fid,',%s\n',cat(2,str{:}));                    % Write to file
                end
            end
            fprintf(fid,'\n');                                         % Separate image sets with a blank row
        end % End loop over image sets
        fclose(fid);
    end % End of full report writing


    if ~strcmp(ExportInfo.ReportStyle,'full')                          % The user wants a summary report

        % For the summary report, replace the entries in Measurements with
        % mean, median and standard deviation of the measurements
        for k = 1:length(Measurements)
            if ~isempty(Measurements{k})       % Make sure there are some measurements
                Measurements{k} = [mean(Measurements{k},1);median(Measurements{k},1);std(Measurements{k},0,1)];
            end
        end
        SummaryInfo = {'Mean','Median','Std'};

        % Open a file for exporting the measurements
        ExportFileName = [ExportInfo.MeasurementFilename,'_',ObjectName,'_Summary.xls'];
        fid = fopen(fullfile(RawPathname,ExportFileName),'w');
        if fid == -1
            errordlg(sprintf('Cannot create the output file %s. There might be another program using a file with the same name.',ExportFileName));
            return
        end

        %%% Write comma-separated file that can be imported into Excel
        % Header part
        fprintf(fid,'%s: Full report\nTotal time: %0.2f s\n', ObjectName,Time{end});

        % Write feature names in one row
        % Interleave feature names with commas and write to file
        str = cell(2*length(FeatureNames),1);
        str(1:2:end) = {','};
        str(2:2:end) = FeatureNames;
        fprintf(fid,',%s\n',cat(2,str{:}));

        % Loop over the images sets
        for k = 1:length(Measurements)

            % Write info about the image set
            fprintf(fid,'Set #%d, %d objects\n',k,NumObjects(k));
            fprintf(fid,'Filenames: ');
            for j = 1:length(Filenames)
                fprintf(fid,'"%s":%s ',Filenames{j}(9:end),handles.Measurements.GeneralInfo.(Filenames{j}){k});
            end

            % Write segmentation threshold if it exists
            if exist('Threshold','var')
                fprintf(fid,',Threshold: %g\n',Threshold{k});
            else
                fprintf(fid,'\n');
            end

            % Write measurements
            if ~isempty(Measurements{k})
                for row = 1:size(Measurements{k},1)                        % Loop over the rows
                    fprintf(fid,'%s',SummaryInfo{row});                    % Writes the word "mean", "median" or "std"
                    tmp = cellstr(num2str(Measurements{k}(row,:)','%g'));  % Create cell array with measurements
                    str = cell(2*length(tmp),1);                           % Interleave with commas
                    str(1:2:end) = {','};
                    str(2:2:end) = tmp;
                    fprintf(fid,',%s\n',cat(2,str{:}));                    % Write to file
                end
            end
            fprintf(fid,'\n');                                         % Separate image sets with a blank row
        end % End loop over image sets
        fclose(fid);
    end % End of summary report writing

end % End of looping over object names




