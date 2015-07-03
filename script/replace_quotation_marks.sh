find -name '*.md' -execdir sed -i '/```/,/```/{ p; d; }; s/"\([- а-яА-Я]\{1,\}\)"/«\1»/g' {} +
