all: clean build

prepare: prepare-dev prepare-deploy

run:
  # Run the server
  hexo serve

build:
  # Copy the new posts to the folder
  find contents/ -type f -name "*.md" -exec cp {} source/_posts/ \;
  find contents/ -type f -name "*.png" -exec cp {} source/images/ \;
  find contents/ -type f -name "*.svg" -exec cp {} source/images/ \;
  find contents/ -type f -name "*.jpg" -exec cp {} source/images/ \;
  # Copy images
  cp images/* source/images/
  # Generate the site
  hexo generate

clean:
  # Clean static site
  hexo clean
  # Remove the old posts
  rm -rf source/_posts/*

prepare-dev:
  # Install pre-commit
  pipx install pre-commit
  pre-commit install --install-hooks

prepare-deploy:
  # Install hexo
  npm install -g hexo-cli
  # Install necessary packages
  npm install
