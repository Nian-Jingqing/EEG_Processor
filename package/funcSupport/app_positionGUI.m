function app_positionGUI(MainApp, ChildFigure, RelPosition)
if nargin < 3
    RelPosition = 'middlecenter';
end
switch RelPosition
    case 'middlecenter'
        % ---------------------------------------------------------
        % Position the new app in the center of the parent app
        pos = MainApp.UIFigure.Position;
        w = ChildFigure.Position(3);
        h = ChildFigure.Position(4);
        x = pos(1) + (pos(3) - w)/2;
        y = pos(2) + (pos(4) - h)/2;
        x = max([0, x]);
        y = max([0, y]);
    case 'topright'
        % ---------------------------------------------------------
        % Position the new app on the right of the parent app
        pos = MainApp.UIFigure.Position;
        w = ChildFigure.Position(3);
        h = ChildFigure.Position(4);
        x = pos(1) + pos(3);
        y = pos(2) + (pos(4) - h);
        x = max([0, x]);
        y = max([0, y]);
end
ChildFigure.Position = [x, y, w, h];
ChildFigure.Resize = 'off';
drawnow;
end
