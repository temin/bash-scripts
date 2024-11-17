# Convert Moodle backup to HTML pages

This Bash script converts Moodle course backup files to HTML pages. Script creates an index page and a page for each section,

Script was built for converting backups from Moodle version 1.9. Specificaly to convert OER course "[Observing the 1980s](https://blogs.sussex.ac.uk/observingthe80s/home/oer)".

Script uses:

- `xmlstarlet` to read *moodle.xml* file
- `sed` and `w3m` to cleanup HTML code

## Observing the 1980s

- Input files: [https://sussex.box.com/s/fjmbjphpkmyvuuixfl3x7i8gh9fv37vq](https://sussex.box.com/s/fjmbjphpkmyvuuixfl3x7i8gh9fv37vq)
- Output files: [https://oer.podreka.net/observing-the-1980s/](https://oer.podreka.net/observing-the-1980s/)