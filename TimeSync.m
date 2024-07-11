classdef TimeSync < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        DataAx                    matlab.ui.control.UIAxes
        TimeOffsetEditFieldLabel  matlab.ui.control.Label
        TimeOffset                matlab.ui.control.NumericEditField
        FreqeuncyHzLabel          matlab.ui.control.Label
        Frequency                 matlab.ui.control.NumericEditField
        OutputNameEditFieldLabel  matlab.ui.control.Label
        OutputName                matlab.ui.control.EditField
        SaveToWorkspaceButton     matlab.ui.control.Button
        Data1DropDownLabel        matlab.ui.control.Label
        Data1DropDown             matlab.ui.control.DropDown
        Data2DropDownLabel        matlab.ui.control.Label
        Data2DropDown             matlab.ui.control.DropDown
        MinXEditFieldLabel        matlab.ui.control.Label
        MinX                      matlab.ui.control.NumericEditField
        MaxXEditFieldLabel        matlab.ui.control.Label
        MaxX                      matlab.ui.control.NumericEditField
        MinYEditFieldLabel        matlab.ui.control.Label
        MinY                      matlab.ui.control.NumericEditField
        MaxYEditFieldLabel        matlab.ui.control.Label
        MaxY                      matlab.ui.control.NumericEditField
        UpdatePlotButton          matlab.ui.control.Button
        NudgeLeftButton           matlab.ui.control.Button
        NudgeRightButton          matlab.ui.control.Button
        StartMergeLabel           matlab.ui.control.Label
        StartMerge                matlab.ui.control.NumericEditField
        EndMergeLabel             matlab.ui.control.Label
        EndMerge                  matlab.ui.control.NumericEditField
        PlotAxesLabel             matlab.ui.control.Label
    end


    properties (Access = private)
        % Initialize with something so that we dont need to put in a ton of checks
        X1DataRaw = [0 0.5]';             % X-values associated with the first data series
        Y1DataRaw = [0 1.2]';             % Y-values associated with the first data series
        X2DataRaw = [0.125 0.25 0.375]'; % X-values associated with the second data series
        Y2DataRaw = [0.3   0.9  0.6]';   % Y-values associated with the second data series
        
        % Set default axes limits 
        XMin =  0; % X-axis minimum value
        XMax =  0.6; % X-axis maximum value
        YMin =  0; % Y-axis minimum value
        YMax =  1.4; % Y-axis maximium value
        
        % Merged Data Set
        XMerged = []; % Empty 
        YMerged = []; % Empty 
        
        % Shifted X2 Data Set for Plots
        X2Shift = [];
        Y2Shift = [];
        
    end

    methods (Access = private)
    
        function mergeWindow(app)
            % Merges the data based on the expected window 
            indsRawLowerWindow = (app.X1DataRaw < app.StartMerge.Value);
            indsRawUpperWindow = (app.X1DataRaw > app.EndMerge.Value);
            
            % Since we are shifting the second data set we have some modifiers
            indsBufferLowerWindow = (app.X2DataRaw + app.TimeOffset.Value >= app.StartMerge.Value);
            indsBufferUpperWindow = (app.X2DataRaw + app.TimeOffset.Value <= app.EndMerge.Value);
            indsBuffer = and(indsBufferLowerWindow, indsBufferUpperWindow);
            
            app.XMerged = [app.X1DataRaw(indsRawLowerWindow,:); ...
                           app.X2DataRaw(indsBuffer) + app.TimeOffset.Value; ...
                           app.X1DataRaw(indsRawUpperWindow,:)];
                       
            app.YMerged = [app.Y1DataRaw(indsRawLowerWindow,:); ...
                           app.Y2DataRaw(indsBuffer); ...
                           app.Y1DataRaw(indsRawUpperWindow,:)];
            
        end
        
        function updatePlot(app)            
            % Update merged values
            app.mergeWindow();
            
            % Shift the X2 Data Set
            app.X2Shift = app.X2DataRaw + app.TimeOffset.Value;
            app.Y2Shift = app.Y2DataRaw;
            
            % Plot Data
            plot(app.DataAx, app.X1DataRaw, app.Y1DataRaw, app.X2Shift, app.Y2Shift, app.XMerged, app.YMerged);
            
            % Update Axes
            ax = app.DataAx;
            h = get(ax, 'Children');
            set(h(3), 'Color', [0 0.4470 0.7410]);
            set(h(3), 'LineWidth', 1.2);
            set(h(3), 'LineStyle', '-')
            set(h(3), 'Marker', 'o');
            
            set(h(2), 'Color', [0.8500 0.3250 0.0980]);
            set(h(2), 'LineWidth', 1.2);
            set(h(2), 'LineStyle', '--')
            set(h(2), 'Marker', 'x');
            
            set(h(1), 'Color', [0.4660 0.6740 0.1880]);
            set(h(1), 'LineWidth', 1.2);
            set(h(1), 'LineStyle', ':')
            
            %             if app.XMax < app.XMin
            %                 % Update the max value by Xmin + 1 and update the field 
            %                 app.XMax = app.XMin + 1;
            %                 app.MaxX.Value = app.XMax;
            %             end
            %             
            %             if app.YMax < app.YMin
            %                 % Update the max value by Xmin + 1 and update the field 
            %                 app.YMax = app.YMin + 1; 
            %                 app.MaxY.Value = app.YMax;
            %             end
            
%             xlim(app.DataAx,[app.XMin, app.XMax]) ; 
%             ylim(app.DataAx,[app.YMin, app.YMax]) ; 
            axis(app.DataAx, [app.XMin, app.XMax, app.YMin, app.YMax] );
            
            grid(ax,'on')
            legend(ax,'location','bestoutside');
        end
        
    end


    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Update initial values for buttons 
            app.MinX.Value = app.XMin;
            app.MinY.Value = app.YMin;
            app.MaxX.Value = app.XMax;
            app.MaxY.Value = app.YMax;
            
            app.StartMerge.Value = 0.12;
            app.EndMerge.Value = 0.46;
            app.Frequency.Value = 8;
            
            % Get list of variables in workspace 
            varNames = evalin('base', 'whos');
            cellArr  = {};
            for ii = 1:length(varNames)
                
                % Remove any data where the number of elements is not equal to size(A,1)*size(A,2)
                % First check makes sure we have a double array of size Nx2 or 2xM;
                if and(numel(varNames(ii).size) == 2, strcmpi(varNames(ii).class,'double'))
                    % This checks that at least one column or row is size 2, the code breaks if using two rows with 3 or more elements anyways
                    if any(varNames(ii).size(2) == 2)
                         cellArr{end+1} = varNames(ii).name;
                    end
                end
            end
            if isempty(cellArr)
                cellArr = {'NoVar','NoVal'};
            end
            app.Data1DropDown.Items = cellArr;
            app.Data2DropDown.Items = cellArr;
            
            app.updatePlot();
        end

        % Value changed function: Data1DropDown
        function Data1DropDownValueChanged(app, event)
            % Updates the data stored in the app workspace for X1
            value = app.Data1DropDown.Value;
            data = evalin('base', value);
            app.X1DataRaw = data(:,1);
            app.Y1DataRaw = data(:,2);
            
        end

        % Value changed function: Data2DropDown
        function Data2DropDownValueChanged(app, event)
            % Updates the data stored in the app workspace for X2
            value = app.Data2DropDown.Value;
            data = evalin('base', value);
            app.X2DataRaw = data(:,1);
            app.Y2DataRaw = data(:,2);
        end

        % Value changed function: EndMerge
        function EndMergeValueChanged(app, event)
            value = app.EndMerge.Value;
            % If this is greater than the end merge time set it to end merge time - 1 time step 
            if value <= app.StartMerge.Value
                app.EndMerge.Value = app.StartMerge.Value + 1/app.Frequency.Value;
            end
            % Update Merge Window
            app.updatePlot();
        end

        % Value changed function: Frequency
        function FrequencyValueChanged(app, event)
            value = app.Frequency.Value;
            if value == 0
                warning('Frequency is zero, setting to 1 Hz')
                app.Frequency.Value = 1;
            end
        end

        % Value changed function: MaxX
        function MaxXValueChanged(app, event)
            value = app.MaxX.Value;
            if value <= app.XMin
                app.MinX.Value = value - 1;
                app.XMin = value -1;
            end
            app.XMax = value;
            app.updatePlot();
        end

        % Value changed function: MaxY
        function MaxYValueChanged(app, event)
            value = app.MaxY.Value;
            if value <= app.YMin
                app.MinY.Value = value - 1;
                app.YMin = value - 1;
            end
            app.YMax = value;
            app.updatePlot();
        end

        % Value changed function: MinX
        function MinXValueChanged(app, event)
            value = app.MinX.Value;
            if value >= app.XMax
                app.MaxX.Value = value + 1;
                app.XMax = value + 1;
            end
            app.XMin = value;
            app.updatePlot();
        end

        % Value changed function: MinY
        function MinYValueChanged(app, event)
            value = app.MinY.Value;
            if value >= app.YMax
                app.MaxY.Value = value + 1;
                app.YMax = value + 1;
            end
            app.YMin = value;
            app.updatePlot();
        end

        % Button pushed function: NudgeLeftButton
        function NudgeLeftButtonPushed(app, event)
            % This function nudges the data by a time defined relative to frequency
            % t = 1/frequency
            if app.Frequency ~= 0
                app.TimeOffset.Value = app.TimeOffset.Value - 1/app.Frequency.Value;
            end
            app.updatePlot();
        end

        % Button pushed function: NudgeRightButton
        function NudgeRightButtonPushed(app, event)
            % This function nudges the data by a time defined relative to frequency
            % t = 1/frequency
            if app.Frequency ~= 0
                app.TimeOffset.Value = app.TimeOffset.Value + 1/app.Frequency.Value;
            end
            app.updatePlot();
        end

        % Value changed function: OutputName
        function OutputNameValueChanged(app, event)
            value = app.OutputName.Value;
            % Check if the variable already exists in the work space and if so pop a warning
            varNames = evalin('base', 'whos');
            isVarName = false;
            for ii = 1:length(varNames)
                if strcmp(varNames(ii).name, value)
                    isVarName = true;
                end
            end
            % Display warning if the variable exists
            if isVarName
                evalin('base',"warning('This variable exists within the workspace, rename or it will be overwritten')")
            end
        end

        % Button pushed function: SaveToWorkspaceButton
        function SaveToWorkspaceButtonPushed(app, event)
            value = app.OutputName.Value;
            % Check if the variable already exists in the work space and if so pop a warning
            varNames = evalin('base', 'whos');
            isVarName = false;
            for ii = 1:length(varNames)
                if strcmp(varNames(ii).name, value)
                    isVarName = true;
                end
            end
            
            % Force update of all data before sending to the data so that the user can verify the data is what we think it be
            app.updatePlot;
            
            % Display warning if the variable exists
            if isVarName
                evalin('base',"warning('Overwriting variable in workspace')")
            end
            assignin('base',value,[ app.XMerged, app.YMerged ])
        end

        % Value changed function: StartMerge
        function StartMergeValueChanged(app, event)
            value = app.StartMerge.Value;
            % If this is greater than the end merge time set it to end merge time - 1 time step 
            if value >= app.EndMerge.Value
                app.StartMerge.Value = app.EndMerge.Value - 1/app.Frequency.Value;
            end
            
            app.updatePlot();
        end

        % Value changed function: TimeOffset
        function TimeOffsetValueChanged(app, event)
            value = app.TimeOffset.Value;
            app.updatePlot;
        end

        % Button pushed function: UpdatePlotButton
        function UpdatePlotButtonPushed(app, event)
            % Update Variables
            value = app.Data1DropDown.Value;
            data = evalin('base', value);
            app.X1DataRaw = data(:,1);
            app.Y1DataRaw = data(:,2);
            
            value = app.Data2DropDown.Value;
            data = evalin('base', value);
            app.X2DataRaw = data(:,1);
            app.Y2DataRaw = data(:,2);
            
            app.updatePlot()
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure
            app.UIFigure = uifigure;
            app.UIFigure.Position = [100 100 834 765];
            app.UIFigure.Name = 'UI Figure';

            % Create DataAx
            app.DataAx = uiaxes(app.UIFigure);
            xlabel(app.DataAx, 'X')
            ylabel(app.DataAx, 'Y')
            app.DataAx.Position = [21 231 770 515];

            % Create TimeOffsetEditFieldLabel
            app.TimeOffsetEditFieldLabel = uilabel(app.UIFigure);
            app.TimeOffsetEditFieldLabel.HorizontalAlignment = 'right';
            app.TimeOffsetEditFieldLabel.Position = [59 167 66 15];
            app.TimeOffsetEditFieldLabel.Text = 'Time Offset';

            % Create TimeOffset
            app.TimeOffset = uieditfield(app.UIFigure, 'numeric');
            app.TimeOffset.ValueChangedFcn = createCallbackFcn(app, @TimeOffsetValueChanged, true);
            app.TimeOffset.Position = [156 163 100 22];

            % Create FreqeuncyHzLabel
            app.FreqeuncyHzLabel = uilabel(app.UIFigure);
            app.FreqeuncyHzLabel.HorizontalAlignment = 'right';
            app.FreqeuncyHzLabel.Position = [59 125 87 15];
            app.FreqeuncyHzLabel.Text = 'Freqeuncy [Hz]';

            % Create Frequency
            app.Frequency = uieditfield(app.UIFigure, 'numeric');
            app.Frequency.ValueChangedFcn = createCallbackFcn(app, @FrequencyValueChanged, true);
            app.Frequency.Position = [156 121 100 22];

            % Create OutputNameEditFieldLabel
            app.OutputNameEditFieldLabel = uilabel(app.UIFigure);
            app.OutputNameEditFieldLabel.HorizontalAlignment = 'right';
            app.OutputNameEditFieldLabel.Position = [59 83 77 15];
            app.OutputNameEditFieldLabel.Text = 'Output Name';

            % Create OutputName
            app.OutputName = uieditfield(app.UIFigure, 'text');
            app.OutputName.ValueChangedFcn = createCallbackFcn(app, @OutputNameValueChanged, true);
            app.OutputName.Position = [156 79 100 22];

            % Create SaveToWorkspaceButton
            app.SaveToWorkspaceButton = uibutton(app.UIFigure, 'push');
            app.SaveToWorkspaceButton.ButtonPushedFcn = createCallbackFcn(app, @SaveToWorkspaceButtonPushed, true);
            app.SaveToWorkspaceButton.Position = [96.5 40 123 22];
            app.SaveToWorkspaceButton.Text = 'Save To Workspace';

            % Create Data1DropDownLabel
            app.Data1DropDownLabel = uilabel(app.UIFigure);
            app.Data1DropDownLabel.HorizontalAlignment = 'right';
            app.Data1DropDownLabel.Position = [418 173 41 15];
            app.Data1DropDownLabel.Text = 'Data 1';

            % Create Data1DropDown
            app.Data1DropDown = uidropdown(app.UIFigure);
            app.Data1DropDown.Items = {'Option 1', 'Option 2', 'Option 3', 'Option 4', 'Option 5'};
            app.Data1DropDown.ValueChangedFcn = createCallbackFcn(app, @Data1DropDownValueChanged, true);
            app.Data1DropDown.Position = [474 169 100 22];

            % Create Data2DropDownLabel
            app.Data2DropDownLabel = uilabel(app.UIFigure);
            app.Data2DropDownLabel.HorizontalAlignment = 'right';
            app.Data2DropDownLabel.Position = [418 143 41 15];
            app.Data2DropDownLabel.Text = 'Data 2';

            % Create Data2DropDown
            app.Data2DropDown = uidropdown(app.UIFigure);
            app.Data2DropDown.ValueChangedFcn = createCallbackFcn(app, @Data2DropDownValueChanged, true);
            app.Data2DropDown.Position = [474 139 100 22];

            % Create MinXEditFieldLabel
            app.MinXEditFieldLabel = uilabel(app.UIFigure);
            app.MinXEditFieldLabel.HorizontalAlignment = 'right';
            app.MinXEditFieldLabel.Position = [418 57 36 15];
            app.MinXEditFieldLabel.Text = 'Min X';

            % Create MinX
            app.MinX = uieditfield(app.UIFigure, 'numeric');
            app.MinX.ValueChangedFcn = createCallbackFcn(app, @MinXValueChanged, true);
            app.MinX.Position = [472 53 100 22];

            % Create MaxXEditFieldLabel
            app.MaxXEditFieldLabel = uilabel(app.UIFigure);
            app.MaxXEditFieldLabel.HorizontalAlignment = 'right';
            app.MaxXEditFieldLabel.Position = [418 32 39 15];
            app.MaxXEditFieldLabel.Text = 'Max X';

            % Create MaxX
            app.MaxX = uieditfield(app.UIFigure, 'numeric');
            app.MaxX.ValueChangedFcn = createCallbackFcn(app, @MaxXValueChanged, true);
            app.MaxX.Position = [472 28 100 22];

            % Create MinYEditFieldLabel
            app.MinYEditFieldLabel = uilabel(app.UIFigure);
            app.MinYEditFieldLabel.HorizontalAlignment = 'right';
            app.MinYEditFieldLabel.Position = [630 57 36 15];
            app.MinYEditFieldLabel.Text = 'Min Y';

            % Create MinY
            app.MinY = uieditfield(app.UIFigure, 'numeric');
            app.MinY.ValueChangedFcn = createCallbackFcn(app, @MinYValueChanged, true);
            app.MinY.Position = [684 53 100 22];

            % Create MaxYEditFieldLabel
            app.MaxYEditFieldLabel = uilabel(app.UIFigure);
            app.MaxYEditFieldLabel.HorizontalAlignment = 'right';
            app.MaxYEditFieldLabel.Position = [630 32 39 15];
            app.MaxYEditFieldLabel.Text = 'Max Y';

            % Create MaxY
            app.MaxY = uieditfield(app.UIFigure, 'numeric');
            app.MaxY.ValueChangedFcn = createCallbackFcn(app, @MaxYValueChanged, true);
            app.MaxY.Position = [684 28 100 22];

            % Create UpdatePlotButton
            app.UpdatePlotButton = uibutton(app.UIFigure, 'push');
            app.UpdatePlotButton.ButtonPushedFcn = createCallbackFcn(app, @UpdatePlotButtonPushed, true);
            app.UpdatePlotButton.Position = [684 210 100 22];
            app.UpdatePlotButton.Text = 'Update Plot';

            % Create NudgeLeftButton
            app.NudgeLeftButton = uibutton(app.UIFigure, 'push');
            app.NudgeLeftButton.ButtonPushedFcn = createCallbackFcn(app, @NudgeLeftButtonPushed, true);
            app.NudgeLeftButton.Position = [499 210 75 22];
            app.NudgeLeftButton.Text = 'Nudge Left';

            % Create NudgeRightButton
            app.NudgeRightButton = uibutton(app.UIFigure, 'push');
            app.NudgeRightButton.ButtonPushedFcn = createCallbackFcn(app, @NudgeRightButtonPushed, true);
            app.NudgeRightButton.Position = [584.5 210 84 22];
            app.NudgeRightButton.Text = 'Nudge Right';

            % Create StartMergeLabel
            app.StartMergeLabel = uilabel(app.UIFigure);
            app.StartMergeLabel.HorizontalAlignment = 'right';
            app.StartMergeLabel.Position = [598 173 68 15];
            app.StartMergeLabel.Text = 'Start Merge';

            % Create StartMerge
            app.StartMerge = uieditfield(app.UIFigure, 'numeric');
            app.StartMerge.ValueChangedFcn = createCallbackFcn(app, @StartMergeValueChanged, true);
            app.StartMerge.Position = [684 169 100 22];

            % Create EndMergeLabel
            app.EndMergeLabel = uilabel(app.UIFigure);
            app.EndMergeLabel.HorizontalAlignment = 'right';
            app.EndMergeLabel.Position = [604 143 65 15];
            app.EndMergeLabel.Text = 'End Merge';

            % Create EndMerge
            app.EndMerge = uieditfield(app.UIFigure, 'numeric');
            app.EndMerge.ValueChangedFcn = createCallbackFcn(app, @EndMergeValueChanged, true);
            app.EndMerge.Position = [684 139 100 22];

            % Create PlotAxesLabel
            app.PlotAxesLabel = uilabel(app.UIFigure);
            app.PlotAxesLabel.FontSize = 16;
            app.PlotAxesLabel.FontWeight = 'bold';
            app.PlotAxesLabel.Position = [571 80 78 20];
            app.PlotAxesLabel.Text = 'Plot Axes';
        end
    end

    methods (Access = public)

        % Construct app
        function app = TimeSync

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end