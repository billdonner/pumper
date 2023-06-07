# PUMPER - Read a script and Pump thru ChatGPT

Freeport.Software - in development

June 6, 7:20PM
```
OVERVIEW: Split up a file of Prompts and pump them in to the AI Assistant

USAGE: pumper <url> <split_pattern> <comments_pattern> --output <output> [--max <max>] [--nodots <nodots>] [--verbose <verbose>] [--dontcall <dontcall>] [--json-valid <json-valid>]

ARGUMENTS:
  <url>                   The url of the Sparky file to split
  <split_pattern>         The pattern to use to split the file
  <comments_pattern>      The pattern to use to indicate a comments line

OPTIONS:
  --output <output>       Output file for AI JSON utterances
  -m, --max <max>         How many prompts to create (default: 65535)
  -n, --nodots <nodots>   Don't print dots whilst waiting (default: true)
  -v, --verbose <verbose> Print a lot more (default: true)
  -d, --dontcall <dontcall>
                          Don't call AI (default: false)
  -j, --json-valid <json-valid>
                          Generate valid JSON for Prepper (default: true)
  --version               Show the version.
  -h, --help              Show help information.
  ```

