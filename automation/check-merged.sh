#!/bin/bash -e

rm -Rf exported-artifacts
mkdir -p exported-artifacts
cd exported-artifacts
for source in $(cd ..; find . -iname "*\.md"); do
    if ! [[ "${source}" =~ \.md$ ]]; then
        continue
    fi
    echo "Parsing source file $source"
    dst_dir="./${source}"
    dst_dir="${dst_dir%/*}"
    mkdir -p {html,wiki}/"$dst_dir"
    dst_file="${source%.md}"
    dst_file="${dst_file#./}"

    echo "    Generating HTML html/${dst_file}.html"
    # jenkins archives all the files in the same path
    # and for the wiki, the pages must be path_name, so we have to fix the urls
    # for the html files so we can navigate on jenkins
    #TODO: fix for cross-path referencees too
    if [[ "$dst_dir" == '.' ]]; then
        url_prefix=''
    else
        url_prefix="${dst_dir#./}_"
    fi
    pandoc --from markdown --to html "../$source" \
        | sed -e "s|/[iI]nfra/${url_prefix}\([^\"]*\)|\1.html|g" \
              -e "s|/[iI]nfra/\([^\"]*\)|\1.html|g" \
        > "html/${dst_file}.html"

    echo "    Generating Mediawiki markup wiki/${dst_file}.wiki"
    pandoc --from markdown --to mediawiki "../$source" \
        > "wiki/${dst_file}.wiki"
done
