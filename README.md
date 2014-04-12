CQ-Tools
========

Tools to make working with CQ/AEM a little faster/easier/better

## Requirements:

### General

1. Ruby 1.9.3

### For cq-sync:

1. DirectoryWatcher
2. Java 7

## Installation

### Install with Homebrew

```sh
brew tap joshes/homebrew-tap
brew install cq-tools
```

### Install manually

```sh
git clone https://github.com/joshes/cq-tools.git
cp cq-tools/.cq/* ~
```

## Configuration

Regardless of your configuration path chosen below, add this to your environment startup (e.g. ~/.bash_profile).

```sh
source ~/.cq/env
```

There are two ways to configure these tools.

1. Simple - if you only have one project and one CQ instance use this
2. Switchable - if you have multiple projects or switch between multiple CQ servers use this

### Simple

1. Edit ~/.cq/env to match your system

**CQ_SERVER_HOME** should point to the root of your server (e.g. ~/Servers/cq5/cq-quickstart)

**CQ_BRANCH_HOME** should point to your CQ project and is only necessary to be set if you use cq-sync - this will sync all files realtime found under /jcr_root/

### Switchable

1. Edit ~/.cq/cfg to your requirements, adding as many servers and/or branches as required
2. Run: cq-set-server and choose the server you want to use for the current session
3. Run: cq-set-branch and choose the branch you want to use for the current session

These scripts effectively manage the ~/.cq/env file for you based on your configuration settings.
