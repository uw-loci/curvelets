function statisticalVisualization()

    app = struct();
    appearanceOptions = struct('title', '', 'x_label', '', 'y_label', '', ...
            'cellColor', [0.00,0.45,0.74], 'fiberColor', [0.85,0.33,0.10]);
    typeOptions = struct('plotType', 'Boxplot', 'measurementType', 'Center-X', ...
            'objectType', 'Cell');
    uiStartup();

    function uiStartup()
        % Create UIFigure and hide until all components are created
        app.UIFigure = uifigure('Visible', 'off');
        app.UIFigure.Position = [100 100 320 390];
        app.UIFigure.Name = 'Statistical Visualization';

        % Create ObjectTypeDropDownLabel
        app.ObjectTypeDropDownLabel = uilabel(app.UIFigure);
        app.ObjectTypeDropDownLabel.Position = [32 348 133 22];
        app.ObjectTypeDropDownLabel.Text = 'Object Type';

        % Create ObjectTypeDropDown
        app.ObjectTypeDropDown = uidropdown(app.UIFigure);
        app.ObjectTypeDropDown.Items = {'Cell', 'Fiber', 'Cell & Fiber'};
        app.ObjectTypeDropDown.ValueChangedFcn = @(src, event)ObjectTypeDropDownValueChanged (src, event);
        app.ObjectTypeDropDown.Position = [188 348 101 22];
        app.ObjectTypeDropDown.Value = 'Cell';

        % Create PlotTypeDropDownLabel
        app.PlotTypeDropDownLabel = uilabel(app.UIFigure);
        app.PlotTypeDropDownLabel.Position = [32 307 55 22];
        app.PlotTypeDropDownLabel.Text = 'Plot Type';

        % Create PlotTypeDropDown
        app.PlotTypeDropDown = uidropdown(app.UIFigure);
        app.PlotTypeDropDown.Items = {'Boxplot', 'Violinplot', 'Histogram'};
        app.PlotTypeDropDown.ValueChangedFcn = @(src, event)PlotTypeDropDownValueChanged (src, event);
        app.PlotTypeDropDown.Position = [188 307 101 22];
        app.PlotTypeDropDown.Value = 'Boxplot';

        % Create MeasurementTypeDropDownLabel
        app.MeasurementTypeDropDownLabel = uilabel(app.UIFigure);
        app.MeasurementTypeDropDownLabel.Position = [32 266 159 22];
        app.MeasurementTypeDropDownLabel.Text = 'Measurement Type';

        % Create MeasurementTypeDropDown
        app.MeasurementTypeDropDown = uidropdown(app.UIFigure);
        app.MeasurementTypeDropDown.Items = {'Center-X', 'Center-Y', 'Orientation', 'Area', 'Circularity'};
        app.MeasurementTypeDropDown.ValueChangedFcn =  @(src, event)MeasurementTypeDropDownValueChanged (src, event);
        app.MeasurementTypeDropDown.Position = [188 266 101 22];
        app.MeasurementTypeDropDown.Value = 'Center-X';

        % Create XAxisLabelEditFieldLabel
        app.XAxisLabelEditFieldLabel = uilabel(app.UIFigure);
        app.XAxisLabelEditFieldLabel.Position = [32 180 72 22];
        app.XAxisLabelEditFieldLabel.Text = 'X-Axis Label';

        % Create XAxisLabelEditField
        app.XAxisLabelEditField = uieditfield(app.UIFigure, 'text');
        app.XAxisLabelEditField.ValueChangedFcn = @(src, event)XAxisLabelEditFieldValueChanged (src, event);
        app.XAxisLabelEditField.Position = [32 157 257 22];

        % Create YAxisLabelEditFieldLabel
        app.YAxisLabelEditFieldLabel = uilabel(app.UIFigure);
        app.YAxisLabelEditFieldLabel.Position = [32 131 71 22];
        app.YAxisLabelEditFieldLabel.Text = 'Y-Axis Label';

        % Create YAxisLabelEditField
        app.YAxisLabelEditField = uieditfield(app.UIFigure, 'text');
        app.YAxisLabelEditField.ValueChangedFcn = @(src, event)YAxisLabelEditFieldValueChanged (src, event);
        app.YAxisLabelEditField.Position = [32 108 257 22];

        % Create TitleEditFieldLabel
        app.TitleEditFieldLabel = uilabel(app.UIFigure);
        app.TitleEditFieldLabel.Position = [32 229 27 22];
        app.TitleEditFieldLabel.Text = 'Title';

        % % Create TitleEditField
        app.TitleEditField = uieditfield(app.UIFigure, 'text');
        app.TitleEditField.ValueChangedFcn =  @(src, event)TitleEditFieldValueChanged (src, event);
        app.TitleEditField.Position = [32 206 257 22];

        % Create FiberColorButton
        app.FiberColorButton = uibutton(app.UIFigure, 'push');
        app.FiberColorButton.ButtonPushedFcn = @(src, event)FiberColorButtonPushed (src, event);
        app.FiberColorButton.BackgroundColor = [0.851 0.3294 0.102];
        app.FiberColorButton.Position = [262 68 28 23];
        app.FiberColorButton.Text = '';

        % Create FiberColorLabel
        app.FiberColorLabel = uilabel(app.UIFigure);
        app.FiberColorLabel.Position = [177 69 64 22];
        app.FiberColorLabel.Text = 'Fiber Color';

        % Create CellColorButton
        app.CellColorButton = uibutton(app.UIFigure, 'push');
        app.CellColorButton.ButtonPushedFcn = @(src, event)CellColorButtonPushed (src, event);
        app.CellColorButton.BackgroundColor = [0 0.451 0.7412];
        app.CellColorButton.Position = [117 68 28 23];
        app.CellColorButton.Text = '';

        % % Create CellColorLabel
        app.CellColorLabel = uilabel(app.UIFigure);
        app.CellColorLabel.Position = [35 69 58 22];
        app.CellColorLabel.Text = 'Cell Color';

        % % Create ApplyButton
        app.ApplyButton = uibutton(app.UIFigure, 'push');
        app.ApplyButton.ButtonPushedFcn =  @(src, event)ApplyButtonPushed (src, event);
        app.ApplyButton.Position = [176 24 113 25];
        app.ApplyButton.Text = 'Apply';

        % % Create CancelButton
        app.CancelButton = uibutton(app.UIFigure, 'push');
        app.CancelButton.ButtonPushedFcn =  @(src, event)CancelButtonPushed (src, event);
        app.CancelButton.Position = [34 24 110 25];
        app.CancelButton.Text = 'Cancel';

        % Show the figure after all components are created
        app.UIFigure.Visible = 'on';
    end

    function ObjectTypeDropDownValueChanged(~, event)
        typeOptions.objectType = event.Value;
        if ~strcmp(event.Value, 'Cell')
            app.MeasurementTypeDropDown.Items = {'Center-X', 'Center-Y',...
                    'Orientation'};
        else
            app.MeasurementTypeDropDown.Items = {'Center-X', 'Center-Y',...
                    'Orientation', 'Area', 'Circularity'};
        end

        if strcmp(event.Value, 'Cell & Fiber')
            app.PlotTypeDropDown.Items = {'Boxplot', 'Violinplot', ...
                'Histogram (Side-By-Side)', 'Histogram (Overlapping)'};
        else
            app.PlotTypeDropDown.Items = {'Boxplot', 'Violinplot', 'Histogram'};
        end
    end

    function PlotTypeDropDownValueChanged(~, event)
        typeOptions.plotType = event.Value;
    end

    function MeasurementTypeDropDownValueChanged(~, event)
        typeOptions.measurementType = event.Value;
    end

    function TitleEditFieldValueChanged(~, event)
        appearanceOptions.title = event.Value;
    end

    function XAxisLabelEditFieldValueChanged(~, event)
        appearanceOptions.x_label = event.Value;
    end

    function YAxisLabelEditFieldValueChanged(~, event)
        appearanceOptions.y_title = event.Value;
    end

    function CellColorButtonPushed(~, ~)
        cellColor = uisetcolor([0 0.4470 0.7410]);
        app.CellColorButton.BackgroundColor = cellColor;
        appearanceOptions.cellColor = app.CellColorButton.BackgroundColor;
    end

    function FiberColorButtonPushed(~, ~)
        fiberColor = uisetcolor([0.8500 0.3250 0.0980]);
        app.FiberColorButton.BackgroundColor = fiberColor;
        appearanceOptions.fiberColor = app.FiberColorButton.BackgroundColor;
    end

    function ApplyButtonPushed(~, ~)

    end

    function CancelButtonPushed(~, ~)
        delete(app.UIFigure);
    end

end