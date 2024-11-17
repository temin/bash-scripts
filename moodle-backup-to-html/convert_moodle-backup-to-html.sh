#!/bin/bash

xml="$(cat moodle.xml)" # Moodle backup XML file
outputPath="./moodle-book" # Output directory
filenamePrefix="section_" # File Name: `prefix` + `section number` + `.html` 

# Section count
sectionNumber="$(echo ${xml} | xmlstarlet sel -t -v "//SECTION/ID" | wc -l)"

# BEGIN Create index page
# Add section data to HTML
echo "Processing: index"
htmlContent+="<!DOCTYPE html><html lang=\"\"><head><meta charset=\"utf-8\"><title>${sectionTitle}</title><link rel="stylesheet" href="style.css"></head><body id=\"course-section\">"
  htmlContent+="<header>"
    htmlContent+="<h1 id=\"course-title\">$(echo ${xml} | xmlstarlet sel -t -v '//COURSE/HEADER/FULLNAME')</h1>"
    htmlContent+="<p id=\"course-summary\">$(echo ${xml} | xmlstarlet sel -t -v '//COURSE/HEADER/SUMMARY')</p>"
  htmlContent+="</header>"
  htmlContent+="<main id=\"course-index\"><h2 class=\"course-index\">Course Index</h2>"

# Create first page with index
while read -r section; do

  # BEGIN Processing section data
    # Get section data
      sectionTitle="$(echo ${xml} | xmlstarlet sel -t -m "//SECTION[NUMBER='${section}']" -v 'NAME' | w3m -dump -T text/html | sed -f sed-commands)"
      htmlContent+="<p class=\"course-index\"><a href=\"${filenamePrefix}${section}.html\">${sectionTitle}</a></p>"

done < <(echo ${xml} | xmlstarlet sel -t \
                        -m '//SECTIONS' \
                        -v 'SECTION/NUMBER' \
                        -n )

  htmlContent+="</main>"
htmlContent+="</body></html>"

echo "${htmlContent}" > ${outputPath}/index.html
# END Create index page

# BEGIN Create section pages
while read -r section; do

  # BEGIN Processing section data
  echo -en "Processing: section ${section}/${sectionNumber}\r"
    # Get section data
    sectionTitle="$(echo ${xml} | xmlstarlet sel -t -m "//SECTION[NUMBER='${section}']" -v 'NAME' | w3m -dump -T text/html | sed -f sed-commands)"
    sectionSummary="$(echo ${xml} | xmlstarlet sel -t -m "//SECTION[NUMBER='${section}']" -v 'SUMMARY' | w3m -dump -T text/html | sed -f sed-commands)"
    # Add HTML head code
    htmlContent+="<!DOCTYPE html><html lang=\"\"><head><meta charset=\"utf-8\"><title>${sectionTitle}</title><link rel="stylesheet" href="style.css"></head><body id=\"course-section\">"
      # Add section navigation
      htmlContent+="<header>"
        if [[ ${section} != 0 ]]; then
          htmlContent+="<div class=\"section-previous\"><a href=\"${filenamePrefix}$(expr ${section} - 1).html\">previous section</a></div>"
        fi
        htmlContent+="<div class=\"section-index\"><a href=\"index.html\">index</a></div>"
        if [[ ${section} != ${sectionNumber} ]]; then
          htmlContent+="<div class=\"section-next\"><a href=\"${filenamePrefix}$(expr ${section} + 1).html\">next section</a></div>"
        fi
      htmlContent+="</header>"

      # Add section data to HTML
      htmlContent+="<article id=\"section\">"
        htmlContent+="<h1 id=\"section-title\">${sectionTitle}</h1>"
        htmlContent+="<div id=\"section-summary\">${sectionSummary}</div>"
      htmlContent+="</article>"
  # END Processing section data

  # BEGIN Processing module data
    # Get modules list for section
    declare -a instances
    while read -r i; do
      instances+=(${i})
    done < <(echo ${xml} | xmlstarlet sel -t \
                                          -m "//SECTION[NUMBER='$section']/MODS" \
                                          -v 'MOD/INSTANCE' \
                                          -n )

    # BEGIN Processing individual section module
    for moduleId in "${instances[@]}"; do

      # Get module data
      moduleType="$(echo ${xml} | xmlstarlet sel -t -m "//MODULES/MOD[ID='${moduleId}']" -v 'MODTYPE' -o '|' -v 'TYPE' | w3m -dump -T text/html | sed -f sed-commands)"
      moduleName="$(echo ${xml} | xmlstarlet sel -t -m "//MODULES/MOD[ID='${moduleId}']" -v 'NAME' | w3m -dump -T text/html | sed -f sed-commands)"

      # Add module data to HTML
      htmlContent+="<article class=\"module module-${moduleType%|*}\">"
      htmlContent+="<h2 class=\"module-title\">${moduleName}</h2>"
      htmlContent+="<p class=\"module-type\">${moduleType%|*} | ${moduleType#*|}</p>"

      # BEGIN Styling ouptut depending on module type
      # Style module type Label
      if [[ ${moduleType%|*} = 'label' ]]; then
        moduleText="$(echo ${xml} | xmlstarlet sel -t -m "//MODULES/MOD[ID='${moduleId}']" -v 'CONTENT' | w3m -dump -T text/html | sed -f sed-commands)"
        htmlContent+="<div class=\"module-content type-label\">${moduleText}</div>"
      # Style module type Forum
      elif [[ ${moduleType%|*} = 'forum' ]]; then
        moduleText="$(echo ${xml} | xmlstarlet sel -t -m "//MODULES/MOD[ID='${moduleId}']" -v 'INTRO' | w3m -dump -T text/html | sed -f sed-commands)"
        htmlContent+="<div class=\"module-${moduleType%|*} type-${moduleType#*|}\">${moduleText}</div>"
      # Style module type Resources
      elif [[ ${moduleType%|*} = 'resource' ]]; then
        # Directory
        # Style resource type Directory
        if [[ ${moduleType#*|} = 'directory' ]]; then
          moduleReference="$(echo ${xml} | xmlstarlet sel -t -m "//MODULES/MOD[ID='${moduleId}']" -v 'REFERENCE' | w3m -dump -T text/html | sed -f sed-commands)"
          moduleSummary="$(echo ${xml} | xmlstarlet sel -t -m "//MODULES/MOD[ID='${moduleId}']" -v 'SUMMARY' | w3m -dump -T text/html | sed -f sed-commands)"
          htmlContent+="<div class=\"module-${moduleType%|*} type-${moduleType#*|} summary\">${moduleSummary}</div>"
          htmlContent+="<div class=\"module-${moduleType%|*} type-${moduleType#*|} reference\">directory: <a href=\"course_files/${moduleReference}\">${moduleReference}</a></div>"
        # Style resource type File
        elif [[ ${moduleType#*|} = 'file' ]]; then
          moduleReference="$(echo ${xml} | xmlstarlet sel -t -m "//MODULES/MOD[ID='${moduleId}']" -v 'REFERENCE' | w3m -dump -T text/html | sed -f sed-commands)"
          moduleSummary="$(echo ${xml} | xmlstarlet sel -t -m "//MODULES/MOD[ID='${moduleId}']" -v 'SUMMARY' | w3m -dump -T text/html | sed -f sed-commands)"
          htmlContent+="<div class=\"module-${moduleType%|*} type-${moduleType#*|} summary\">${moduleSummary}</div>"
          htmlContent+="<div class=\"module-${moduleType%|*} type-${moduleType#*|} reference\">file: <a href=\"course_files/${moduleReference}\">${moduleReference}</a></div>"
        # Style resource type Html 
        elif [[ ${moduleType#*|} = 'html' ]]; then
          moduleText="$(echo ${xml} | xmlstarlet sel -t -m "//MODULES/MOD[ID='${moduleId}']" -v 'ALLTEXT' | w3m -dump -T text/html | sed -f sed-commands)"
          htmlContent+="<div class=\"module-${moduleType%|*} type-${moduleType#*|}\">${moduleText}</div>"
        # Style resource type Lecturerecording
        elif [[ ${moduleType#*|} = 'lecturerecording' ]]; then
          moduleText="$(echo ${xml} | xmlstarlet sel -t -m "//MODULES/MOD[ID='${moduleId}']" -v 'ALLTEXT' | w3m -dump -T text/html | sed -f sed-commands)"
          htmlContent+="<div class=\"module-${moduleType%|*} type-${moduleType#*|}\">lecture_recording_id: ${moduleText}</div>"
        # Style resource type Link
        elif [[ ${moduleType#*|} = 'link' ]]; then
          moduleReference="$(echo ${xml} | xmlstarlet sel -t -m "//MODULES/MOD[ID='${moduleId}']" -v 'REFERENCE' | w3m -dump -T text/html | sed -f sed-commands)"
          moduleSummary="$(echo ${xml} | xmlstarlet sel -t -m "//MODULES/MOD[ID='${moduleId}']" -v 'SUMMARY' | w3m -dump -T text/html | sed -f sed-commands)"
          htmlContent+="<div class=\"module-${moduleType%|*} type-${moduleType#*|} summary\">${moduleSummary}</div>"
          htmlContent+="<div class=\"module-${moduleType%|*} type-${moduleType#*|} reference\">URL: <a href=\"${moduleReference}\">${moduleReference}</a></div>"
        # Style resource type Text
        elif [[ ${moduleType#*|} = 'text' ]]; then
          moduleText="$(echo ${xml} | xmlstarlet sel -t -m "//MODULES/MOD[ID='${moduleId}']" -v 'ALLTEXT' | w3m -dump -T text/html | sed -f sed-commands)"
          htmlContent+="<div class=\"module-${moduleType%|*} type-${moduleType#*|}\">${moduleText}</div>"
        fi
      fi
      # END Styling ouptut depending on module type

      htmlContent+="</article>"
    done
  # END Processing module data

    # Add section navigation
    htmlContent+="<footer>"
      if [[ ${section} > 0 ]]; then
        htmlContent+="<div class=\"section-previous\"><a href=\"${filenamePrefix}$(expr ${section} - 1).html\">previous section</a></div>"
      fi
      htmlContent+="<div class=\"section-index\"><a href=\"index.html\">index</a></div>"
      if [[ ${section} < ${sectionNumber} ]]; then
        htmlContent+="<div class=\"section-next\"><a href=\"${filenamePrefix}$(expr ${section} + 1).html\">next section</a></div>"
      fi
    htmlContent+="</footer>"
  htmlContent+="</body></html>"

  # Output HTML code to file
  echo "${htmlContent}" > ${outputPath}/${filenamePrefix}${section}.html

  unset instances
  unset htmlContent

done < <(echo ${xml} | xmlstarlet sel -t \
                        -m '//SECTIONS' \
                        -v 'SECTION/NUMBER' \
                        -n )
# END Create section pages
