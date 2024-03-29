# Mac Suggestions Logger

This tiny utility logs Mac OS word suggestions. It reads a CSV file and appends the word suggestions generated by Mac OS's spell checker's API using each line as input.


## Install

No particular install step should be required. Simply clone the git repository.


## Build

Use XCode to build the project (Product > Archive).

## Usage

```
$ ./suggestionsLogger
-h, --help                     Show this help message
-i path, --input-file=path     Specify input file path
-s skip, --skip-until-line=ski Specify the number of line to skip from the input file (default: 0)
-o path, --output-file=path    Specify output file path
-c column, --sentence-column=c (optional) CSV-type only: specify the name of the column in the input file to use as a sentence. If unspecified, the program will use the first column and assume that there are no headers.
-t type, --input-type=type     The type of input file (csv or text, default: text)
Program ended with exit code: 1
```

For example:

```sh
./suggestionsLogger -i mackenzie-soukoreff.txt -o suggestions.csv
```

## Outpout and Disclaimer

Mac OS spell checker's API was seldom documented at the time I wrote this script. It provides several functions such as:

- "completion" (produces multiple words),
- "guess" (produces multiple words),
- "correction" (produces one single word), or
- "completion" (produces multiple words).

All these are written as is by this tool.
