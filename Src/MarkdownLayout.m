classdef MarkdownLayout < handle
    
    properties 
        title = '#';
        image = '![%s](%s)';
        pageBreak = '<div style="page-break-after: always;"></div>';
                
        figure = [];
        axis = [];
    end
    
    methods
        function Obj = MarkdownLayout()
            % default figure layout
            Obj.figure.Color = [1 1 1];
            
            % default axes layout
            Obj.axis.FontSize = 20;
            Obj.axis.XAxis.LineWidth = 2;
            Obj.axis.YAxis.LineWidth = 2;
            Obj.axis.ZAxis.LineWidth = 2;
            Obj.axis.XGrid = 'on';
            Obj.axis.YGrid = 'on';
            Obj.axis.ZGrid = 'on';
            Obj.axis.XMinorGrid = 'on';
            Obj.axis.YMinorGrid = 'on';
            Obj.axis.ZMinorGrid = 'on';
        end
    end
end