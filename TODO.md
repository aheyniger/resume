# Things to work on, add, tweak, or fix later
## Formatting
- Remove/fix double line at beginning both before and after Education
- consider centering section titles (prob not tho)
- consider adding more color
- move gpa next to degrees, remove deans list and honor society
- make words smaller so i can fit more in (make sure its still readable)

## New Features
- Different themes or layout options?
- a way to compress things into one page if possible (like a compressed theme/format)
- second repo that is private to include private versions so i can download right from that. would likely work by having the public repo workflow build the private PDF and publish it over to the private repo. would need an access token as a secret for the workflow to write to another repo
- script to act as a helper for many things, like maybe one that can list all topics
- a way to add things like concise variants for both specific bullet points and for entire entries
- add some way/option of putting stack/tech on the name line, right after the project/company name separated by a |, to save space (but prefer separate stack line)
- maybe a periodic auto-release to kind of just snapshot my resume over time more generally
    - only do the periodic release when stuff has also actually changed. like, if it is run every month, then only release it in the months where there's changes, so that you dont just not make any changes for 7 months but still have like 7 auto-releases

## Changes
- recommend typemist extension in README if using vscode
- instructions for installing fonts in README
- make the GitHub Pages page differentiate tailored general versions and ones for specific companies
- add comments as personal notes to content.yaml to do things like give a full summary/description/explanation/rundown of a job/project and things to remember when considering or updating it
- split CLAUDE.md into a "How to use the tool" section that explains this whole resume tool i have, and then a "How to do the resume" section that is for specific things to the resume itself, like how to abbreviate months, or how many items can be in a stack line, or to make sure to use official spellings for tools in the stack

## Fixes
- Fix/redo comments throughout app
    - make sure to make them more frequent in places like layout.typ which really requires everything to be explained
- Fix/redo readme
- make this work on mac/linux, including better error messages and shit
    - one example is how we specifically refer to winget for typst version and shit

## Stuff to check
- is this system/workflow/whatever a good way to let ai modify and use my resume (for automated job applications)
- ask claude about more topics to add for what i have
- review CLAUDE.md
