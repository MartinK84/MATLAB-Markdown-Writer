md = Markdown('example.md');
md.CreateFile();

% general intro
md.AddTitle('MATLAB Markdown Writer - Example', 1);
md.AddText('This example generates a simple markdown file directly from Matlab',...
           'and will also include figures, tables, structs and arrays that will',...
           'be properly formatted in markdown.');
md.AddText('To see how this file is created please see **Examples/example.m**',...
           'from within Matlab');

       
       
% adding figures
md.AddTitle('Adding figures', 2);
md.AddText('To add figures simply call the *AddFigure()* functions. the figure',...
           'will be written as .png file to the images sub directory with a',...
           'prefix of the markdown file name');

% create example figure;
x = linspace(0,2 * pi);
plot(x,sin(x), 'LineWidth', 2);
hold on;
plot(x,cos(x), 'LineWidth', 2);
hold off;
xlim([0, 2 * pi]);
xlabel('rad');

% add figure to markdown
md.BeginCode();
md.AddFigure(gcf, 'fig1'); % fig1 = figure file name
md.EndCode();
md.AddText('All figures and axes will be automatically styles based on the',...
           '**layout.figure** and **layout.axes** properties of the Markdown', ...
           'class. These properties are a structs and all fields of those structs',...
           'will directly overwrite the corresponding properties of the',...
           'figure (and their corresponding axes) which are to be added to the',...
           'markdown file');


% adding code
md.AddTitle('Adding code', 2);
md.AddText('Although not the primary focus of this Mardown class you can also',...
           'add matlab code directly from your scripts to the markdown file.',...
           'Simply enclose the code you want to run and include in the markup',...
           'between the **BeginCode()** and **EndCode()** functions');
md.BeginCode();
a = 1;
b = 2;
c = a + b;
md.EndCode();



% adding structs
md.AddTitle('Adding structs', 2);
md.AddText('Structs can easily be added as table by using the **AddStruct()**', ...
           'function. Lets create a struct and add it to the markdown.');
md.BeginCode();
myStruct = struct();
myStruct.Name = 'Example struct';
myStruct.Property = {'Here', 'be', 2, 'dragons'};
myStruct.OtherProperty = 1;
myStruct.AnotherProperty = [1 2 3 4];
md.EndCode();
md.AddText('And render it to the markdown file using **AddStruct()**:');
md.BeginCode();
md.AddStruct(myStruct);
md.EndCode();





% adding arrays and matrices
md.AddTitle('Adding arrays and matrices', 2);
md.AddText('To render matrices as tables use the **AddMatric()** function.');

% row vector
md.BeginCode();
a = round(rand(1,6)*100);
md.AddMatrix(a);
md.EndCode();
md.AddHorizontalLine();

% column vector
md.BeginCode();
a = round(rand(1,3)*100).';
md.AddMatrix(a);
md.EndCode();
md.AddHorizontalLine();

% 2D matrix
md.BeginCode();
m = round(rand(6,4)*100);
md.AddMatrix(m);
md.EndCode();
md.AddHorizontalLine();

md.AddText('To add arrays as block quotes and not as a matric the **AddArray()**',...
           'function can be used.');
md.BeginCode();
md.AddArray(a);
md.EndCode();

       
       
       

md.CloseFile();