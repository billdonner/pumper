# PUMPER - Read a script and Pump thru ChatGPT

Freeport.Software - 0.2.14
```
OVERVIEW:  Step 1: Pumper executes the script, sending each prompt to the
ChatBot and generating a single output file of JSON Challenges which is read by
Prepper and, in a later step, by Blender.

USAGE: pumper <input> <output> [--max <max>] [--dots <dots>] [--verbose <verbose>] [--unique <unique>] [--dontcall <dontcall>] [--split_pattern <split_pattern>] [--comments_pattern <comments_pattern>]

ARGUMENTS:
  <input>                 Input text script file (Between_0_1.txt):
  <output>                Output json file (Between_1_2.json):

OPTIONS:
  --max <max>             How many prompts to execute (default: 65535)
  --dots <dots>           Print dots whilst awaiting AI (default: false)
  --verbose <verbose>     Print a lot more (default: false)
  --unique <unique>       Generate Unique File Names (default: true)
  --dontcall <dontcall>   Don't call AI (default: false)
  --split_pattern <split_pattern>
                          The pattern to use to split the file (default: ***)
  --comments_pattern <comments_pattern>
                          The pattern to use to indicate a comments line
                          (default: ///)
  --version               Show the version.
  -h, --help              Show help information.
  ```

