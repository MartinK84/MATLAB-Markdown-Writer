classdef Markdown < handle
    
    properties
        filePath;
        imagesPath;
        layout;
    end
    
    properties (Hidden)
        fileHandle;
        figureCount;
        codeStack;        
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
            assert(~isempty(Obj.fileHandle), 'file not created');
            
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
                try
                    Markdown.CopyProperties(Obj.layout.figure, Handle);
                catch
                    warning('Not all figure layout parameters could be copied');
                end
            end
            if (~isempty(Obj.layout.axis))
                axesHandles = find(contains(arrayfun(@class, Handle.Children, 'UniformOutput', false),'.Axes') == 1);
                for iAxes = 1:length(axesHandles)
                    try
                        Markdown.CopyProperties(Obj.layout.axis, Handle.Children(axesHandles(iAxes)));
                    catch
                        warning('Not all axes layout parameters could be copied');
                    end                    
                end
            end            
            
            % write file
            [~, markdownName, ~] = fileparts(Obj.filePath);
            imgFile = fullfile(Obj.imagesPath, strcat(markdownName, '_', Name, '.png'));
            img = getframe(Handle);
            imwrite(img.cdata, imgFile);
            
            % now we transform the file path to a relative path by
            % stripping the path to the markdown file
            [path,~] = fileparts(Obj.filePath);
            ind = strfind(imgFile,path);
            if (ind > 0)
                imgFile(ind:ind + length(path)) = [];
            end
            imgStr = sprintf(Obj.layout.image, Description, imgFile);
            
            fwrite(Obj.fileHandle, sprintf('%s\n\n', imgStr));
            
            Obj.figureCount = Obj.figureCount + 1;
        end   
        
        function AddStruct(Obj, Struct, PropertyList)
            assert(~isempty(Obj.fileHandle), 'file not created');
            
            if (nargin < 3)
                PropertyList = [];
            end
            
            fields = fieldnames(Struct);
            if (~isempty(PropertyList))
                fields = intersect(PropertyList, fields);
            end
            
            fwrite(Obj.fileHandle, sprintf('Property | Value\n'));
            fwrite(Obj.fileHandle, sprintf('--- | ---\n'));
            for iField = 1:length(fields)
                try
                    value = Struct.(fields{iField});
                    if (iscell(value))
                        value = cellfun(@mat2str, value, 'UniformOutput', false);
                        value = sprintf('%s, ', value{:});
                        value(end - 1:end) = []; % remove trailing comma and space
                        value = sprintf('{%s}', value);
                    else
                        value = mat2str(value);
                    end
                    fwrite(Obj.fileHandle, sprintf('%s | %s\n', fields{iField}, value));
                catch
                    % not all possible struct properties can be converted,
                    % instead of testing all in advance we just catch and
                    % errors and don't add those properties
                end
            end
            fwrite(Obj.fileHandle, sprintf('\n')); %#ok<SPRINTFN>
        end
        
        function AddArray(Obj, Array, FormatStr)
            assert(~isempty(Obj.fileHandle), 'File not created');
            assert((sum(size(Array) > 1) == 1), 'Only one dimensional arrays can be added');
                       
            if (nargin < 3)
                FormatStr = '%g';
            end
            
            if (iscell(Array))
                arrayStr = cellfun(@(x)(sprintf(sprintf('%s, ', FormatStr),x)), Array, 'UniformOutput', false);
                arrayStr(end) = [];
                arrayStr = cell2mat(arrayStr);
                arrayStr(end - 2:end) = [];
            else
                arrayStr = sprintf(sprintf('%s, ', FormatStr), Array);
                arrayStr(end - 2:end) = [];
            end
            
            fwrite(Obj.fileHandle, sprintf('>%s\n', arrayStr));
            fwrite(Obj.fileHandle, sprintf('\n')); %#ok<SPRINTFN>
        end
        
        function AddPageBreak(Obj)
            assert(~isempty(Obj.fileHandle), 'File not created');
            
            fwrite(Obj.fileHandle, sprintf('%s\n\n', Obj.layout.pageBreak)); 
        end
        
        function AddMatrix(Obj, Matrix, FormatStr)
            assert(~isempty(Obj.fileHandle), 'File not created');
            
            if (nargin < 3)
                FormatStr = '%g';
            end
            
            if (~ismatrix(Matrix))
                warning('Matrix has more than two dimensions. Only the first two dimensions will be written to markdown.');                
            end
            
            nX = size(Matrix,2);
            nY = size(Matrix,1);
            
            header = sprintf(' %i | ', 1:nX);
            header(end - 2:end) = [];
            fwrite(Obj.fileHandle, sprintf(' []() | %s\n', header));
            
            header = repmat(' --- |',[1 nX]);
            header(end - 1:end) = [];
            fwrite(Obj.fileHandle, sprintf(' --- | %s\n', header));
            for iY = 1:nY
                line = sprintf(sprintf(' %s | ', FormatStr), Matrix(iY,:));
                line(end - 2:end) = [];
                fwrite(Obj.fileHandle, sprintf(' **%i** | %s\n', iY, line));
            end
            fwrite(Obj.fileHandle, sprintf('\n')); %#ok<SPRINTFN>
        end
        
        function BeginCode(Obj)
            assert(~isempty(Obj.fileHandle), 'file not created');
            
            try
                stDebug = dbstack('-completenames');            
                
                [~,~,ext] = fileparts(stDebug(2).file);
                if (strcmpi(ext,'.mlx'))
                    warning('Code block could not be started as you are running a Live Script (.mlx) file.');
                    warning('This could also be caused by not running a complete .m file but by executing only sections of code.');
                    return;
                end
                
                Obj.codeStack{1} = stDebug(2).file;
                Obj.codeStack{2} = stDebug(2).line;
            catch
                Obj.codeStack = [];
                warning('Could not catch call stack for code tracking');
            end
        end
        
        function EndCode(Obj)
            assert(~isempty(Obj.fileHandle), 'file not created');
            
            if (isempty(Obj.codeStack))
                warning('Code tracking stack is empty, call the BeginCode() method before EndCode()');
                return;
            end
            
            try
                stDebug = dbstack('-completenames');            
            catch
                warning('Could not catch call stack for code tracking');
                return;
            end
            
            assert(isequal(Obj.codeStack{1}, stDebug(2).file), 'Code files between BeginCode() and EndCode() have changed, are you missing an EndCode() somewhere?');
            
            % read all lines of m file
            fid = fopen(stDebug(2).file,'r');
            lines = fread(fid, inf, 'uint8');
            lines = regexp(char(lines).', '\r\n|\r|\n', 'split');
            fclose(fid);
            
            % get and print code block
            lines = lines(Obj.codeStack{2} + 1:stDebug(2).line - 1);
            fwrite(Obj.fileHandle, sprintf('```matlab\n'));
            fwrite(Obj.fileHandle, sprintf('%s\n',lines{:}));
            fwrite(Obj.fileHandle, sprintf('```\n\n'));
            
            % reset code stack
            Obj.codeStack = [];            
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
