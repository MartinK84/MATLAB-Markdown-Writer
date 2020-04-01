classdef Markdown < handle
    
    properties
        filePath;
        imagesPath;
        layout;
    end
    
    properties (Hidden)
        fileHandle;
        figureCount;
    end
    
    % basic class methods
    methods
        function Obj = Markdown(filePath)
            if (nargin > 0)
                Obj.filePath = filePath;
                
                % set path for images
                [path, ~] = fileparts(Obj.filePath);
                if (isempty(path))
                    Obj.imagesPath = 'images';
                else
                    Obj.imagesPath = strcat(path, filesep, 'images');
                end
                
                % try to create path for images
                try
                    warning off;
                    mkdir(Obj.imagesPath);
                    warning on;
                catch
                    warning('Failed to create image path "%s"', Obj.imagesPath);
                end
            end            
            
            Obj.figureCount = 1;
            Obj.layout = MarkdownLayout;
        end
        
        function CreateFile(Obj)
            assert(~isempty(Obj.filePath), 'filePath propery not set');
            
            if (~isempty(Obj.fileHandle))
                Obj.CloseFile();
            end
            
            Obj.fileHandle = fopen(Obj.filePath, 'w');
        end
        
        function CloseFile(Obj)
            assert(~isempty(Obj.fileHandle), 'file not created');
            
            %fwrite(Obj.fileHandle, sprintf('\n')); %#ok<SPRINTFN> % add single newline character as file end);            
            fclose(Obj.fileHandle);
            Obj.fileHandle = [];
        end
    end
    
    % markdown specific methods
    methods
        function AddTitle(Obj, Str, Level)
            assert(~isempty(Obj.fileHandle), 'file not created');
            
            if (nargin < 3)
                Level = 1;
            end
            
            levelStr = repmat(Obj.layout.title, [1 Level]);
            
            fwrite(Obj.fileHandle, sprintf('%s %s\n\n', levelStr, Str));
        end
        
        function AddText(Obj, varargin)
            assert(~isempty(Obj.fileHandle), 'file not created');
            
            textStr = sprintf('%s ', varargin{:}); % concatenate all given strings, spaced by a 
            textStr(end) = []; % remove trailing white space
            
            fwrite(Obj.fileHandle, sprintf('%s\n\n', textStr));
        end
        
        function AddFigure(Obj, Handle, Name, Description)
            if (nargin < 2)
                Handle = gcf;
            end
            if (nargin < 3)
                Name = sprintf('%03i', Obj.figureCount);
            end            
            if (nargin < 4)
                Description = '';
            end
            
            % apply custom layout to figure and axis
            if (~isempty(Obj.layout.figure))
                Markdown.CopyProperties(Obj.layout.figure, Handle);
            end
            if (~isempty(Obj.layout.axis))
                axesHandles = find(contains(arrayfun(@class, Handle.Children, 'UniformOutput', false),'.Axes') == 1);
                for iAxes = 1:length(axesHandles)
                    Markdown.CopyProperties(Obj.layout.axis, Handle.Children(axesHandles(iAxes)));
                end
            end            
            
            % write file
            [~, markdownName, ~] = fileparts(Obj.filePath);
            imgFile = fullfile(Obj.imagesPath, strcat(markdownName, '_', Name, '.png'));
            img = getframe(Handle);
            imwrite(img.cdata, imgFile);
            
            imgStr = sprintf(Obj.layout.image, Description, imgFile);
            
            fwrite(Obj.fileHandle, sprintf('%s\n\n', imgStr));
            
            Obj.figureCount = Obj.figureCount + 1;
        end        
    end
    
    methods (Static)
        function CopyProperties(Src, Dst, Prefix)
            if (nargin < 3)
                Prefix = [];
            end
            
            if (isempty(Prefix))
                fields = fieldnames(Src);
            else
                fields = fieldnames(getfield(Src, Prefix{:}));
            end
            
            for iField = 1:length(fields)      
                subPrefix = cat(1, Prefix, {fields{iField}});
                field = getfield(Src, subPrefix{:});
                
                if (isstruct(field))
                    Markdown.CopyProperties(Src, Dst, subPrefix);
                    continue;
                end                
                
                Dst = setfield(Dst, subPrefix{:}, field);
            end
        end
    end
end
