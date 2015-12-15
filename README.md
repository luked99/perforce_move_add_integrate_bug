
Overview
========

This script demonstrates a problem with P4 when integrating a
file which has been moved and then re-added.

Step 1:
-------

Create a directory "dev" in P4. Add a plain file "mdev.conf"

Step 2:
-------

Integrate "dev" to "branched\_dev". After this, branched\_dev
contains a copy of the file mdev.conf.

Step 3:
-------

Rename mdev.conf.
In a separate commit, add a new file, also called mdev.conf.

After this, we have 2 files, mdev.conf and mdev\_initial.conf.

Step 4:
-------

Integrate again from dev to branched\_dev. We would expect that
branched\_dev is then identical to dev. But instead, the file
mdev.conf is missing from branched\_dev.

