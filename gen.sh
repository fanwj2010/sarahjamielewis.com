#!/bin/bash


SITE_FILES="./site/"

mkdir -p ./tmp/
find $SITE_FILES -name "*.md~" | xargs rm -f

# Copy all Markdown files in site/ to tmp/
cp -r $SITE_FILES/* ./tmp/

FILES=$(find ./tmp/ -name "*.md")

for f in $FILES
do
  echo "Processing $f file..."

  # Each directory attempts to use its own template.
  BASE=$(basename $(dirname $f))

  if [ $BASE = "tmp" ]; then
	BASE="default"
  fi
  TITLE=$(head -n 1 $f | cut -c3-)
  DES=$(sed -n '4p' $f)
  
  perl Markdown.pl --html4tags $f > ${f%.*}.stage.html;
  cp ./templates/$BASE.html ${f%.*}.tmp.html

  # Search and replace time.
  sed -e "/\%body/r ${f%.*}.stage.html" -e "/$str/d" ${f%.*}.tmp.html > ${f%.*}.title.html
  sed "s/\%title/$TITLE/g" ${f%.*}.title.html > ${f%.*}.des.html 
  sed "s/\%des/$DES/g" ${f%.*}.des.html > ${f%.*}.html 
  rm ${f%.*}.stage.html ${f%.*}.title.html ${f%.*}.des.html  ${f%.*}.tmp.html $f
done

# Clean up and rename
rm -rf ./_site
mv ./tmp ./_site
