find -name '*.md' -execdir sed -i '/```/,/```/{ p; d; }; s/"\([- a-zA-Z]\{1,\}\)"/\1/g' {} +
