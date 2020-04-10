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
        function Obj = Markdown(FilePath)
        % Create a new instance of a Markdown Writer object. This object
        % can then be used to create the markdown file and write content 
        % such as text and figures to it. 
        %
        % Arguments:
        %   FilePath: Path to the markdown file to be written
        %
        % Returns:
        %   Markdown: Reference to the newly created markdown class
        %
        % Example:
        %   md = MarkDown('MyMarkDownFile.md');
        %   md.CreateFile();
        %   md.AddTitle('My Title');
        %   md.CloseFile();
        %
            if (nargin > 0)
                Obj.filePath = FilePath;
                
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
        % Create a new markdown file and overwrite its content. This
        % function must be called before any content can be written to the
        % markdown file (otherwise all Add*() and Replace*() functions will
        % result in an error.
        %        
        % Example:
        %   md.CreateFile();
        %            
            
            assert(~isempty(Obj.filePath), 'FilePath propery not set');
            
            if (~isempty(Obj.fileHandle))
                Obj.CloseFile();
            end
            
            Obj.fileHandle = fopen(Obj.filePath, 'w+');
        end
        
        function OpenFile(Obj)
            assert(~isempty(Obj.filePath), 'FilePath propery not set');
            
            if (~isempty(Obj.fileHandle))
                Obj.CloseFile();
            end
            
            Obj.fileHandle = fopen(Obj.filePath, 'a+');
        end
        
        function CloseFile(Obj)
        % Close the opened markdown file and release its file handle.
        %        
        % Example:
        %   md.CloseFile();
        %                        
            
            assert(~isempty(Obj.fileHandle), 'Output file not created');
            
            %fwrite(Obj.fileHandle, sprintf('\n')); %#ok<SPRINTFN> % add single newline character as file end);            
            fclose(Obj.fileHandle);
            Obj.fileHandle = [];
        end
        
        function AppendTemplate(Obj, TemplateFile)
        % Appends the content of a template file to the already created
        % markdown file. The template file can be of any format and is
        % concatenated simply as text.
        %
        % This method is typically used when working with templates that
        % are to be merged into the newly created markdown file.
        %
        % Arguments:
        %   TemplateFile: Path to the template file
        %
        % Example:
        %   md = MarkDown('MyMarkDownFile.md');
        %   md.CreateFile();
        %   md.AppendTemplate('MyFirstTemplate.md');
        %   md.AppendTemplate('MySecondTemplate.md');
        %   md.CloseFile();            
            
            assert(~isempty(Obj.fileHandle), 'Output file not created');
            
            fid = fopen(TemplateFile, 'r');
            tplData = fread(fid, inf, 'uint8');
            fwrite(Obj.fileHandle, tplData);
            fwrite(Obj.fileHandle, sprintf('\n')); %#ok<SPRINTFN>
            fclose(fid);
        end
    end
        
    % methods for conversion of input to markdown string
    methods
        function [MarkDown] = ConvertTitle(Obj, Str, Level)
            levelStr = repmat(Obj.layout.title, [1 Level]);
            
            MarkDown = sprintf('%s %s', levelStr, Str);
        end
        
        function [MarkDown] = ConvertText(~, varargin)
            textStr = sprintf('%s ', varargin{:}); % concatenate all given strings, spaced by a space char
            textStr(end) = []; % remove trailing white space
            
            MarkDown = textStr;
        end
        
        function [MarkDown] = ConvertFigure(Obj, Handle, Name, Description)
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
            img = getFrameMinimal(Handle);
            imwrite(img, imgFile);
            
            % now we transform the file path to a relative path by
            % stripping the path to the markdown file
            [path,~] = fileparts(Obj.filePath);
            ind = strfind(imgFile,path);
            if (ind > 0)
                imgFile(ind:ind + length(path)) = [];
            end
            imgStr = sprintf(Obj.layout.image, Description, imgFile);
            
            MarkDown = imgStr;
        end
        
        function [MarkDown] = ConvertStruct(Obj, Struct, PropertyList)
            fields = fieldnames(Struct);
            if (~isempty(PropertyList)) % check if only selected properties are to be converted
                fields = intersect(PropertyList, fields);
            end
            
            MarkDown = [];
            MarkDown = cat(1, MarkDown, {sprintf('Property%sValue\n', Obj.layout.tableSpacer)});
            MarkDown = cat(1, MarkDown, {sprintf('%s%s%s\n', Obj.layout.tableHeader, Obj.layout.tableSpacer, Obj.layout.tableHeader)});            
            for iField = 1:length(fields)
                try
                    value = Struct.(fields{iField});
                    if (iscell(value))
                        value = cellfun(@(x)(mat2str(x,3)), value, 'UniformOutput', false);
                        value = sprintf('%s, ', value{:});
                        value(end - 1:end) = []; % remove trailing comma and space
                        value = sprintf('{%s}', value);
                    else
                        value = mat2str(value,3);
                    end
                    MarkDown = cat(1, MarkDown, {sprintf('%s%s%s\n', fields{iField}, Obj.layout.tableSpacer, value)});            
                catch
                    % not all possible struct properties can be converted,
                    % instead of testing all in advance we just catch and
                    % errors and don't add those properties
                end
            end
        end
            
        function [MarkDown] = ConvertMatrix(Obj, Matrix, FormatStr)
            MarkDown = [];
            if (~ismatrix(Matrix))
                warning('Matrix has more than two dimensions. Only the first two dimensions will be written to markdown.');                
                return;
            end
            
            nX = size(Matrix,2);
            nY = size(Matrix,1);
            
            MarkDown = [];
            
            header = sprintf(' %i | ', 1:nX);
            header(end - 2:end) = [];
            MarkDown = cat(1, MarkDown, {sprintf(' []()%s%s\n', Obj.layout.tableSpacer, header)});
            
            header = repmat(' --- |',[1 nX]);
            header(end - 1:end) = [];
            MarkDown = cat(1, MarkDown, {sprintf(' %s%s%s\n', Obj.layout.tableHeader, Obj.layout.tableSpacer, header)});
            
            for iY = 1:nY
                line = sprintf(sprintf(' %s%s', FormatStr,Obj.layout.tableSpacer), Matrix(iY,:));
                line(end - 2:end) = [];
                MarkDown = cat(1, MarkDown, {sprintf(' **%i**%s%s\n', iY, Obj.layout.tableSpacer, line)});
            end
        end
        
        function [MarkDown] = ConvertArray(Obj, Array, FormatStr)
            if (iscell(Array))
                arrayStr = cellfun(@(x)(sprintf(sprintf('%s, ', FormatStr),x)), Array, 'UniformOutput', false);
                arrayStr(end) = [];
                arrayStr = cell2mat(arrayStr);
                arrayStr(end - 2:end) = [];
            else
                arrayStr = sprintf(sprintf('%s, ', FormatStr), Array);
                arrayStr(end - 1:end) = [];
            end
            
            MarkDown = sprintf('%s%s\n', Obj.layout.blockQuote, arrayStr);
        end
    end
    
    % markdown specific methods
    methods
        function AddFunctionReference(Obj, Function)
            narginchk(2,2);
            
            refStr = help(Function);
            refStr = regexp(refStr,'\n','split');
            refStr = cellfun(@strtrim, refStr, 'UniformOutput', false);                        
            
            % remove matlab reference
            try
                refStr(find(contains(refStr,'Reference page in Doc Center') == 1,1):end) = [];
            catch
            end
            
            % title with function name
            Function = regexp(Function,'/','split'); % remove class name
            functionStr = sprintf('#### %s()\n', Function{end});
            fwrite(Obj.fileHandle, sprintf('%s\n',functionStr));
           
            % help/description string
            firstBlock = find(contains(refStr,':') == 1);
            helpStr = refStr(1:firstBlock-2);
            for iHelpStr = 1:length(helpStr)                
                if (isempty(helpStr{iHelpStr}))
                    fwrite(Obj.fileHandle, sprintf('\n')); %#ok<SPRINTFN>
                else
                    fwrite(Obj.fileHandle, sprintf('*%s*\n', helpStr{iHelpStr}));
                end
            end
            fwrite(Obj.fileHandle, sprintf('\n')); %#ok<SPRINTFN>
            
            refStr = refStr(firstBlock:end);
            emptyLines = find(cellfun(@isempty, refStr) == 1);
            emptyLines = [1 emptyLines];
            
            % loop over blocks
            for iBlock = 1:length(emptyLines)-1
                block = refStr(emptyLines(iBlock):emptyLines(iBlock+1)-1);
                if (isempty(block{1}))
                    block(1) = [];
                end
                fwrite(Obj.fileHandle, sprintf('**%s**\n', block{1}));
                
                if (strcmp(block{1},'Example:'))
                    fwrite(Obj.fileHandle, sprintf('```matlab\n'));
                    fwrite(Obj.fileHandle, sprintf('%s\n',block{2:end}));
                    fwrite(Obj.fileHandle, sprintf('```\n\n'));
                else                                    
                    markDown = [];
                    markDown = cat(1, markDown, {sprintf('Parameter%sDescription\n', Obj.layout.tableSpacer)});
                    markDown = cat(1, markDown, {sprintf('%s%s%s\n', Obj.layout.tableHeader, Obj.layout.tableSpacer, Obj.layout.tableHeader)});            

                    block = block(2:end); % rest of the block
                    paramIndex = find(contains(block,':') == 1);
                    paramIndex = [paramIndex length(paramIndex)];
                    for iParam = 1:length(paramIndex) - 1
                        param = block(paramIndex(iParam):max(paramIndex(iParam),paramIndex(iParam+1)-1));
                        paramName = regexp(param{1},':','split');
                        desc = cat(2, paramName(2), param(2:end));
                        desc = sprintf('%s<br>',desc{:});
                        desc(end-3:end) = [];
                        paramName = paramName{1};

                        markDown = cat(1, markDown, {sprintf('%s%s%s\n', paramName, Obj.layout.tableSpacer, desc)});            
                    end

                    for iMarkDown = 1:length(markDown)
                        fwrite(Obj.fileHandle, sprintf('%s', markDown{iMarkDown}));
                    end
                    fwrite(Obj.fileHandle, sprintf('\n')); %#ok<SPRINTFN>
                end
            end
        end
        
        function AddTitle(Obj, Title, Level)
        % Adds a title to the markdown file. 
        %
        % Arguments:
        %   Title: Text of the title to add
        %   Level: (optional,default=1) Depths level of the title to add
        %
        % Example:
        %   md.AddTitle('MyAmazingTitle');            
        %   md.AddTitle('AnotherTitle',2); % depths of 2
            
            narginchk(2,3);

            assert(~isempty(Obj.fileHandle), 'Output file not created');
            
            if (nargin < 3)
                Level = 1;
            end
                        
            fwrite(Obj.fileHandle, sprintf('%s\n\n', Obj.ConvertTitle(Title, Level)));
        end
        
        function AddText(Obj, varargin)
        % Adds simple text to the markdown file. 
        %
        % The text can contain additional markdown formatting options such 
        % as bold, itatlic, etc. and will simply be written to the target 
        % file as plain text.
        %
        % The function can also take an arbitrary number of input
        % parameters that will all be written to the file with a space as
        % separator in between. This is implemented for better formatting
        % of larget text blocks in code and for writing text cell arrays.
        %
        % Arguments:
        %   Text: (varargin) Text to add        
        %
        % Example:
        %   md.AddText('My text');
        %   md.AddText('My text', 'is even longer');
        %   myCell = {'My text', 'is even longer', 'than before');
        %   md.AddText(myCell{:});
        
            
            assert(~isempty(Obj.fileHandle), 'Output file not created');
                       
            fwrite(Obj.fileHandle, sprintf('%s\n\n', Obj.ConvertText( varargin{:})));
        end
        
        function ReplaceText(Obj, Tag, varargin)
            assert(~isempty(Obj.fileHandle), 'Output file not created');
            
            Obj.ReplaceTag(Tag, sprintf('%s\n', Obj.ConvertText( varargin{:})));
        end
        
        function AddFigure(Obj, Handle, Name, Description)  
            narginchk(2,4);
            assert(~isempty(Obj.fileHandle), 'File not created');
            
            if (nargin < 2)
                Handle = gcf;
            end
            if (nargin < 3)
                Name = sprintf('%03i', Obj.figureCount);
            end
            if (nargin < 4)
                Description = '';
            end
            
            fwrite(Obj.fileHandle, sprintf('%s\n\n', Obj.ConvertFigure(Handle, Name, Description)));
            
            Obj.figureCount = Obj.figureCount + 1;
        end   
        
        function ReplaceFigure(Obj, Tag, Handle, Name, Description)
            narginchk(3,5);
            assert(~isempty(Obj.fileHandle), 'File not created');
            
            if (nargin < 3)
                Handle = gcf;
            end
            if (nargin < 4)
                Name = sprintf('%03i', Obj.figureCount);
            end
            if (nargin < 5)
                Description = '';
            end
            
            Obj.ReplaceTag(Tag, sprintf('%s\n', Obj.ConvertFigure(Handle, Name, Description)));
            
            Obj.figureCount = Obj.figureCount + 1;
        end
        
        function AddStruct(Obj, Struct, PropertyList)
            narginchk(2,3);
            assert(~isempty(Obj.fileHandle), 'Output file not created');
            
            if (nargin < 3)
                PropertyList = [];
            end
            
            markDown = Obj.ConvertStruct(Struct, PropertyList);
            for iLine = 1:length(markDown)
                fwrite(Obj.fileHandle, sprintf('%s', markDown{iLine}));
            end
            fwrite(Obj.fileHandle, sprintf('\n')); %#ok<SPRINTFN>
        end        
        
        function ReplaceStruct(Obj, Tag, Struct, PropertyList)
            narginchk(3,4);
            assert(~isempty(Obj.fileHandle), 'Output file not created');
            
            if (nargin < 4)
                PropertyList = [];
            end
            
            markDown = Obj.ConvertStruct(Struct, PropertyList);
            
            Obj.ReplaceTag(Tag, sprintf('%s',markDown{:}));
        end
               
        function ReplaceTag(Obj, Tag, Text)
            narginchk(2,3);
            assert(~isempty(Obj.fileHandle), 'Output file not created');
            
            % string tag to hashed tag
            Tag = sprintf('<!---###%s###--->', Tag);
            
            % first we read in the entire file as cell array
            fseek(Obj.fileHandle, 0, 'bof');
            lines = fread(Obj.fileHandle, inf, 'uint8');
            lines = regexp(char(lines).', '\r\n|\r|\n', 'split');
            lines(end) = [];
            
            % we need an empty line at the end
            if (~isempty(lines{end}))
                lines{end+1} = '';
            end
            
            % find the index of the Tag and all empty lines and remove paragraph in between
            tagInd = find(contains(lines, Tag) == 1);
            if (isempty(tagInd))% tag not found
                warning('Tag %s not found, skipping', Tag);
                return 
            end
            emptyInd = find(cellfun(@isempty,lines) == 1);            
            leftInd = find((emptyInd - tagInd) < 0);
            rightInd = find((emptyInd - tagInd) > 0);
            clearLines = emptyInd(leftInd(end)):emptyInd(rightInd(1));            
            lines(clearLines) = [];
            
            % add new paragraph with replacement text         
            lines = cat(2, lines(1:emptyInd(leftInd(end))-1),...
                                 {sprintf('\n%s\n%s', Tag, Text)}, ...
                                 lines(emptyInd(leftInd(end)):end));
                                   
            % write to file (overwrite entire file)
            fclose(Obj.fileHandle);
            Obj.fileHandle = fopen(Obj.filePath, 'w+');
            for iLine = 1:length(lines)
                fwrite(Obj.fileHandle, sprintf('%s\n', lines{iLine}));
            end
        end
        
        function AddArray(Obj, Array, FormatStr)
            narginchk(2,3);
            assert(~isempty(Obj.fileHandle), 'Output file not created');
            assert((sum(size(Array) > 1) == 1), 'Only one dimensional arrays can be added');
                       
            if (nargin < 3)
                FormatStr = '%g';
            end
                        
            fwrite(Obj.fileHandle, sprintf('%s\n\n', Obj.ConvertArray(Array, FormatStr)));
        end
        
        function ReplaceArray(Obj, Tag, Array, FormatStr)
            narginchk(3,4);
            assert(~isempty(Obj.fileHandle), 'Output file not created');
            assert((sum(size(Array) > 1) == 1), 'Only one dimensional arrays can be added');
                       
            if (nargin < 4)
                FormatStr = '%g';
            end
                        
            Obj.ReplaceTag(Tag, Obj.ConvertArray(Array, FormatStr));
        end
        
        function AddPageBreak(Obj)
            assert(~isempty(Obj.fileHandle), 'Output file not created');
            
            fwrite(Obj.fileHandle, sprintf('%s\n\n', Obj.layout.pageBreak)); 
        end
        
        function AddHorizontalLine(Obj)
            assert(~isempty(Obj.fileHandle), 'Output file not created');
            
            fwrite(Obj.fileHandle, sprintf('%s\n\n', Obj.layout.horizontalLine)); 
        end
        
        function AddMatrix(Obj, Matrix, FormatStr)
            narginchk(2,3);
            assert(~isempty(Obj.fileHandle), 'Output file not created');
            
            if (nargin < 3)
                FormatStr = '%g';
            end
            
            markDown = Obj.ConvertMatrix(Matrix, FormatStr);
            for iLine = 1:length(markDown)
                fwrite(Obj.fileHandle, sprintf('%s', markDown{iLine}));
            end
            fwrite(Obj.fileHandle, sprintf('\n')); %#ok<SPRINTFN>
        end
        
        function ReplaceMatrix(Obj, Tag, Matrix, FormatStr)
            narginchk(3,4);
            assert(~isempty(Obj.fileHandle), 'Output file not created');
            
            if (nargin < 4)
                FormatStr = '%g';
            end
            
            markDown = Obj.ConvertMatrix(Matrix, FormatStr);
            Obj.ReplaceTag(Tag, sprintf('%s',markDown{:}));
        end
        
        function BeginCode(Obj)
            assert(~isempty(Obj.fileHandle), 'Output file not created');
            
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
            assert(~isempty(Obj.fileHandle), 'Output file not created');
            
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
