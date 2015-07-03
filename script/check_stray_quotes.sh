grep -rne '^[^«]*».*$' src
grep -rne '«[^»]*$' src
egrep -rne '«.{0,3}»' src
