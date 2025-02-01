#!/bin/sh
# checkin.sh

git add .
git commit -m "updates"
git push

git fetch
git checkout gh-pages
git merge main
git push
git checkout main
