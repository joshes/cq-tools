CQ-Tools
========

Tools to make working with CQ/AEM a little faster/easier/better

## Requirements:

### General

1. Ruby >= 1.9.3

### For cq-sync:

1. Java 7
2. DirectoryWatcher

## Installation

### Install with Homebrew

```sh
brew tap joshes/homebrew-tap
brew install cq-tools
```

### Install manually

Bash gist below, but follow the comments if you want to install other ways.

Open a terminal and run the following:

```sh
# Get the stuff
git clone https://github.com/joshes/cq-tools.git
git clone https://github.com/joshes/directory-watcher.git

# Build the DirectoryWatcher and add to the path
mvn clean package -f directory-watcher/pom.xml
echo "exec java  -jar `pwd`/directory-watcher/target/DirectoryWatcher.jar $@" >> directory-watcher/target/DirectoryWatcher
echo "export PATH=`pwd`/directory-watcher/target:$PATH" >> ~/.bash_profile
chmod a+x directory-watcher/target/DirectoryWatcher

# Install the cq-tools default configuration and add to path
cp cq-tools/.cq ~
echo "source ~/.cq/env" >> ~/.bash_profile
echo "export PATH=`pwd`/cq-tools:$PATH" >> ~/.bash_profile
```

## Configuration

1. Add 'source ~/.cq/env' to ~/.bash_profile
2. Edit ~/.cq/cfg to your requirements, adding as many servers and/or workspaces as required
2. Run: cq-set-server and choose the server you want to use for the current session
3. Run: cq-set-workspace and choose the workspace you want to use for the current session

These scripts effectively manage the ~/.cq/env file for you based on your configuration settings.

Note that after running cq-set-* you should run 

```sh
source ~/.cq/env
```

On any open terminals for the changes to take effect.

