#!/bin/bash

# Remove the old posts
rm -rf source/_posts/*
# Copy the new posts to the folder
cp `find source/contents/ -name "*.md"` source/_posts/
# Generate the site
hexo clean && hexo generate
