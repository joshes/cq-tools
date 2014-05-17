CQ-Tools
========

Tools to make working with CQ/AEM a little faster/easier/better

## Requirements:

1. Ruby
2. Java 7
3. DirectoryWatcher

## Installation

Bash gist below, but follow the comments if you want to install other ways.

```sh
# Get the stuff
git clone https://github.com/joshes/cq-tools.git
git clone https://github.com/joshes/directory-watcher.git

# Ensure you have these gems
gem install activesupport json nokogiri

# Build the DirectoryWatcher and add to the path
cd directory-watcher
mvn clean package
echo "exec java  -jar `pwd`/target/DirectoryWatcher.jar \"\$@\"" >> DirectoryWatcher
echo "export PATH=`pwd`:$PATH" >> ~/.bash_profile
chmod a+x DirectoryWatcher

# Install the cq-tools default configuration and add to path
cd ../cq-tools
cp -r .cq ~
echo "source ~/.cq/env" >> ~/.bash_profile
echo "export PATH=`pwd`:$PATH" >> ~/.bash_profile
```

## Configuration

1. Edit ~/.cq/config.json & ~/.cq/project-config.json to your requirements, adding as many servers and/or workspaces as required
2. Run: cq-set-server and choose the server you want to use for the current session
3. Run: cq-set-workspace and choose the workspace you want to use for the current session

These scripts effectively manage the ~/.cq/env file for you based on your configuration settings.
