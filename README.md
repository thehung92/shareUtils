# shareUtils

## description

various programs that I write for my genomic analysis


## create another remote for push

```shell
#
git remote add server nscc:/home/users/ntu/nguyentr/Tools/shareUtils
#
git add . && git commit -m 'fast sync' && git push --set-upstream server main

# server
git config receive.denyCurrentBranch ignore
printf '#!/bin/sh
git --git-dir=. --work-tree=.. checkout -f' > .git/hooks/post-receive
chmod +x .git/hooks/post-receive

```