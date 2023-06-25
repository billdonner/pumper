# PUMPER - Read a script and Pump thru ChatGPT

Freeport.Software - 0.1.5
```
OVERVIEW: Split up a script file of Prompts and pump them in to the AI

 version 0.1.4

USAGE: pumper <url> <output> [--split_pattern <split_pattern>] [--comments_pattern <comments_pattern>] [--max <max>] [--dots <dots>] [--verbose <verbose>]

ARGUMENTS:
  <url>                   The url of input script
  <output>                Output file for AI JSON utterances

OPTIONS:
  --split_pattern <split_pattern>
                          The pattern to use to split the file (default: ***)
  --comments_pattern <comments_pattern>
                          The pattern to use to indicate a comments line
                          (default: ///)
  --max <max>             How many prompts to create (default: 65535)
  --dots <dots>           Print dots whilst awaiting AI (default: false)
  -v, --verbose <verbose> Print a lot more (default: false)
  --version               Show the version.
  -h, --help              Show help information.
  ```

