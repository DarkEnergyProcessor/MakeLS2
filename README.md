Various LS2-related Scripts
=====

This scripts was used by me to aid me making beatmaps. I think this is gonna helpful to people who need it.

All files except `ls2.lua` and `JSON.lua` are released under public domain. Check `ls2.lua` and `JSON.lua` for their license terms respectively.

Note that all this scripts must be run under this directory because how Lua `require` search for files.

autotoken.lua
-----

Automatically generates token notes. Reads and writes SIF-compilant JSON-encoded beatmap from stdin to stdout respectively.

Usage: `livesim2.exe -dump -play <beatmap> | lua autotoken.lua <amount of token to add> > output.json`

dump_uimg.lua
-----

Dumps all custom units image (`UIMG` chunk in LS2) to a directory.

Usage: `lua dump_uimg.lua <input LS2> <output directory>`

`output directory` must exist beforehand!

JSON.lua
-----

This is [jf-JSON](http://regex.info/blog/lua/json).

ls2.lua
-----

This is Live Simulator: 2 v2.0 beatmap parser and writer.

ls2_pack.lua
-----

Given a directory, this will convert DEPLS folder-based beatmap to single-file .ls2 v2.0 beatmap.

The folder must contain `.ls2_create.json`. An example `.ls2_create.json` can be found [here](https://github.com/MikuAuahDark/livesim2-storyboards/blob/master/time_lapse/.ls2_create.json).

Usage: `lua ls2_pack.lua <DEPLS-project folder> <output.ls2>`

lyrics2srt.lua
-----

Converts my custom notated lyric to SRT file which can be parsed by LS2 as lyric file. Note that SRT lyric file is only supported in LS2 [v3.0.5](https://github.com/MikuAuahDark/livesim2/releases/tag/v3.0.5) and later.

The resulting SRT file is written to stdout. The file name must be `lyrics.srt` to be recognized by LS2.

Usage: `lua lyrics2srt.lua input.txt > lyrics.srt`

Example `input.txt` is provided, check `lyrics.txt`.

lyrics2yamlstory.lua
-----

Same as above, but converts it to YAML storyboard instead of lyrics file. This is only used for my [Time Lapse beatmap video](https://www.youtube.com/watch?v=Xl5jAM7qdBQ).

Usage: `lua lyrics2yamlstory.lua input.txt > storyboard.yaml`
