# MATLAB Markdown Writer - Template example

Instead of writing the entire markdown file from within MATLAB you can also create a template file which will be updated and rewritten by the MATLAB Markdown Writer.

The template functions will always replace entire paragraphs which are marked by hashed HTML comments like <!---###Fig1###--->, where in this case *Fig1* is the tag name.

After replacement the tags will be added again at the beginning of the paragraph to enable for subsequent replacement (i.e. updating) within the same file. Alternatively the filled out template file can be written as a new output.

## Append template to markdown file

First start to create the target file which is passed as parameter to the **Markdown()** constructor. After creating the file append the content of the template file using the **AppendTemplate()** function. Note that you can also append multiple template files.

```matlab
md = Markdown('exampleTemplateFilled.md');
md.CreateFile();
md.AppendTemplate('exampleTemplate.md');;
```

After everything is set up content can be added using the respective **Add\*()** functions (see [example.m](example.m)) or tags can be selectively replaced.

## Replacing tags

To replace tags with MATLAB generated content the following methods do exist:

* ReplaceText()
* ReplaceArray()
* ReplaceMatrix()
* ReplaceStruct()
* ReplaceFigure()

These functions take the same parameters as their respective **Add\*()** counterparts with the exception of an additional (first) parameter that defines the tag which is to be replaced.

### Replacement examples

Below this template defines five tags, **Text1**, **Matrix1**, **Figure1**, **Array1** and **Struct1** which will be replaced by the following code:

```matlab
md.ReplaceText('Text1','Here be', 'dragons');
md.ReplaceArray('Array1', myArray);
md.ReplaceMatrix('Matrix1', myArray);
md.ReplaceStruct('Struct1', myStruct);
md.ReplaceFigure('Figure1', gcf);
```

Text:
<!---###Text1###--->

Array:

<!---###Array1###--->

Matrix:
<!---###Matrix1###--->

Struct:

<!---###Struct1###--->

Figure:

<!---###Figure1###--->
