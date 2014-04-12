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

## Configuration

1. Add 'source ~/.cq/env' to ~/.bash_profile
2. Edit ~/.cq/cfg to your requirements, adding as many servers and/or branches as required
2. Run: cq-set-server and choose the server you want to use for the current session
3. Run: cq-set-branch and choose the branch you want to use for the current session

These scripts effectively manage the ~/.cq/env file for you based on your configuration settings.
