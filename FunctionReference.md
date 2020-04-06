# Function reference

## Markdown class

The core class used for creating markdown files and writing MATLAB generated content as markdown

### Base methods

Core methods for handling the markdown class and files

---

#### Markdown()

*Create a new instance of a Markdown Writer object. This object*
*can then be used to create the markdown file and write content*
*such as text and figures to it.*

**Arguments:**
Parameter | Description
--- | ---
FilePath |  Path to the markdown file to be written

**Returns:**
Parameter | Description
--- | ---
Markdown |  Reference to the newly created markdown class

**Example:**
```matlab
md = MarkDown('MyMarkDownFile.md');
md.CreateFile();
md.AddTitle('My Title');
md.CloseFile();
```

---

#### CreateFile()

*Create a new markdown file and overwrite its content. This*
*function must be called before any content can be written to the*
*markdown file (otherwise all Add*() and Replace*() functions will*
*result in an error.*

**Example:**
```matlab
md.CreateFile();
```

---

#### CloseFile()

*Close the opened markdown file and release its file handle.*

**Example:**
```matlab
md.CloseFile();
```

---

#### AppendTemplate()

*Appends the content of a template file to the already created*
*markdown file. The template file can be of any format and is*
*concatenated simply as text.*

*This method is typically used when working with templates that*
*are to be merged into the newly created markdown file.*

**Arguments:**
Parameter | Description
--- | ---
TemplateFile |  Path to the template file

**Example:**
```matlab
md = MarkDown('MyMarkDownFile.md');
md.CreateFile();
md.AppendTemplate('MyFirstTemplate.md');
md.AppendTemplate('MySecondTemplate.md');
md.CloseFile();
```

---

### Adding content

All methods for adding or replacing content in a markdown file

---

#### AddTitle()

*Adds a title to the markdown file.*

**Arguments:**
Parameter | Description
--- | ---
Title |  Text of the title to add
Level |  (optional,default=1) Depths level of the title to add

**Example:**
```matlab
md.AddTitle('MyAmazingTitle');
md.AddTitle('AnotherTitle',2); % depths of 2
```

---

#### AddText()

*Adds simple text to the markdown file.*

*The text can contain additional markdown formatting options such*
*as bold, itatlic, etc. and will simply be written to the target*
*file as plain text.*

*The function can also take an arbitrary number of input*
*parameters that will all be written to the file with a space as*
*separator in between. This is implemented for better formatting*
*of larget text blocks in code and for writing text cell arrays.*

**Arguments:**
Parameter | Description
--- | ---
Text |  (varargin) Text to add

**Example:**
```matlab
md.AddText('My text');
md.AddText('My text', 'is even longer');
myCell = {'My text', 'is even longer', 'than before');
md.AddText(myCell{:});
```

---

