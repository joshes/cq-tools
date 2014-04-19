#!/usr/bin/env ruby

# Need a repo of *.zip packages + credentials
# Need a server instance + credentials
# Need a list of package names

# 1. Read list of packages from server into memory
# 2. Read list ...
# 3. For each package name:
#      if package name not found:
#        package = get from server
#        if package not found:
#          log error in audit log
#        else install package (catch error if install fails) and note in audit log