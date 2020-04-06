path = matlab.desktop.editor.getActiveFilename;
[path, ~, ~] = fileparts(path);

md = Markdown(fullfile(path,'../FunctionReference.md'));
md.CreateFile();

md.AddTitle('Function reference');

md.AddTitle('Markdown class',2);
md.AddText('The core class used for creating markdown files and writing', ...
           'MATLAB generated content as markdown');      
       
md.AddTitle('Base methods',3);
md.AddText('Core methods for handling the markdown class and files');

md.AddHorizontalLine();
md.AddFunctionReference('Markdown');
md.AddHorizontalLine();

md.AddFunctionReference('Markdown/CreateFile');
md.AddHorizontalLine();

md.AddFunctionReference('Markdown/CloseFile');
md.AddHorizontalLine();

md.AddFunctionReference('Markdown/AppendTemplate');
md.AddHorizontalLine();




md.AddTitle('Adding content',3);
md.AddText('All methods for adding or replacing content in a markdown file');

md.AddHorizontalLine();
md.AddFunctionReference('Markdown/AddTitle');
md.AddHorizontalLine();

md.AddFunctionReference('Markdown/AddText');
md.AddHorizontalLine();



md.CloseFile();
