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
-o path, --output-file=path    Specify output file path
-s sentence, --sentence-column (optional) CSV-type only: specify the name of the
  column in the input size to use as a sentence. If unspecified, the program will
  use the first column and assume that there are no headers.
-t type, --input-type=type     The type of input file (csv or text, default: text)
```

For example:

```sh
./suggestionsLogger -i mackenzie-soukoreff.txt -o suggestions.csv
```

## Outpout and Disclaimer

Mac OS spell checker's API was seldom documented at the time I wrote this script. It provides several functions such as "completion" (produces multiple words), "guess" (produces multiple words), "correction" (produces one single word), or "completion" (produces multiple words).
All these are written as is by this took.

Unfortunately, it is currently rather unclear how these functions are actually supposed to be used to provide reliable predictions. Consequently, I had to reverse engineer these the best I could, and proceed with a trial and error approach to get them to work.

It is also rather unclear how Mac OS uses these values, for example it is unclear how it combines these to create the 3-word suggestion list provided to users as they typed (to the best of my knowledge, it seems to be mostly coming from the "completion" list, albeith "guess" may also be inserted from time to time).
