md = Markdown('exampleTemplateFilled.md');
md.CreateFile();
md.AppendTemplate('exampleTemplate.md');

% replace tag with arbitrary text
md.ReplaceText('Text1','Here be', 'dragons');

% replace array
a = round(rand(1,6)*100);
md.ReplaceArray('Array1', a);

% replace matrix
m = round(rand(3,3)*100);
md.ReplaceMatrix('Matrix1', m);

% replace struct
myStruct = struct();
myStruct.Name = 'Example struct';
myStruct.Property = {'Here', 'be', 2, 'dragons'};
myStruct.OtherProperty = 1;
myStruct.AnotherProperty = [1 2 3 4];
md.ReplaceStruct('Struct1', myStruct);

% replace figure
x = linspace(0,2 * pi);
plot(x,sin(x), 'LineWidth', 2);
hold on;
plot(x,cos(x), 'LineWidth', 2);
hold off;
xlim([0, 2 * pi]);
xlabel('rad');
md.ReplaceFigure('Figure1', gcf);

md.CloseFile();