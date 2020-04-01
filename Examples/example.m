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
           'previx of the markdown file name');

% create example figure;
x = linspace(0,2 * pi);
plot(x,sin(x), 'LineWidth', 2);
hold on;
plot(x,cos(x), 'LineWidth', 2);
hold off;
xlim([0, 2 * pi]);
xlabel('rad');

% add figure to markdown
md.AddFigure(gcf, 'fig1'); % figure file name
md.AddText('All figures and axes will be automatically styles based on the',...
           '**layout.figure** and **layout.axes** properties of the Markdown', ...
           'class. These properties are a structs and all fields of those structs',...
           'will directly overwrite the corresponding properties of the',...
           'figure (and their corresponding axes) which are to be added to the',...
           'markdown file');
       
md.CloseFile();