all: prepare clean build

prepare: prepare-dev prepare-deploy

run:
  # Run the server
  hexo serve

build:
  # Copy the new posts to the folder
  cp `find contents/ -name "*.md"` source/_posts/
  # Generate the site
  hexo generate

clean:
  # Clean static site
  hexo clean
  # Remove the old posts
  rm -rf source/_posts/*

prepare-dev:
  # Install pre-commit
  python3 -m pip install pre-commit
  pre-commit install --install-hooks

prepare-deploy:
  # Install hexo
  npm install -g hexo-cli
  # Install necessary packages
  npm install
