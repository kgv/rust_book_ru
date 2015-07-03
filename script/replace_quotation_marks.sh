find -name *.md -execdir sed -i '/```/,/```/{ p; d; }; s/"\([[:punct:][:space:]а-яА-Я]\{1,\}\)"/«\1»/g' {} +
