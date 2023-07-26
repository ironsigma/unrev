# unrev
unRevision Control System, a simple way to archive diffs

### What is it?

unrev is a set of bash scripts written to emulate a bare-bones version of [GNU's RCS][rcs].
RCS is a feature-rich revision control system with log messages, branching, locks, and much, much more.
unrev has none of this, the only remote resemblance to RCS is the fact that unrev generates diffs
and store them in an archive for later use.

#### But why?

So why use unrev? I need a simple, fast way to create backups of my text files as I edit them.
Why not use git? Way to much for what I need, just a quick save of the diff and done.
Why not use RCS? I've used RCS in the past and the command line syntax and locks and other "features"
seem to get in the way. Just need a quick simple way to store changes on a per-file basis.

### Requirements

unrev uses the following tools, most of these should already be installed (except for 7z)

- 7z     to archive the diffs
- diff   to generate the patches
- patch  to restore revisions
- grep   to extract string
- sed    to transform strings
- sort   to order revisions
- date   to generate and format dates
- printf to format strings
- which  to find child scripts

### Bugs / Issues

I have not tested this out side my local Linux box openSUSE so I expect many bugs and issues when
it is run in different systems, as the scripts and tools are not written in any portable way.

# Using The Scripts

There are three scripts, a check-in script (ci) a list revisions script (ls) and a check out script (co).
There is also a parent script to find other scripts for future extensibility.

### Checking-in

In order to check-in a new revision use the following

```shell
$ unrev ci hello.txt

revision: 1
```

This will create a new archive `hello.txt,v.7z` in the current directory to hold the revisions.
Make more changes to `hello.txt` and repeat the same command a simple as that.

If you want to specify the name and location of the archive file add it at the end.

```shell
$ unrev ci hello.txt .vscode/hello.txt-revs.7z

revision: 3
```

You can use any name you like it doesn't even have to end in `7z` and can be stored anywhere.
You can also call the script directly `unrev-ci.sh` with the same arguments. I do this in my editor "save hook"
to avoid the overhead of calling multiple scripts.

Also note if you're going to use this as a "save hook" you can also use the `--skip-diff-check` argument improve
performance. This will skip checking for "no changes" before storing a new revision. Since I use it as part of
the "save hook" I know that it will only be called if there are changes to be saved, so no need to re-check.

### Listing Revisions

Listing revisions is easy, just specify the archive file.

```shell
$ unrev ls hello.txt,v.7z

r3 Wed Jul 26 13:52.19 2023
r2 Wed Jul 26 13:51.34 2023
r1 Wed Jul 26 13:50.01 2023
```

The command will output the revision number followed by the date it was stored

### Checking-out

To check out a specific revision use the following:

```shell
$ unrev co hello.txt,v.7z r3 .txt

/tmp/unrev-hello-R3-KSRZYc2G.txt
```

This will checkout the revision specified into a temporary file.
The name of the file is displayed, it will not be deleted, and must be cleaned up manually.


# Under The Hood

When the first revision is stored, it just compresses the entire file into the archive and
stores it as `HEAD-R1-YYYY-mm-dd_HH.MM.SS`.

When a new revision is added, it takes the latest `HEAD`, creates a reverse diff and stores
it stores it as `DIFF-RX-YYYY-mm-dd_HH.MM.SS` where `X` is the revision number of the
previous `HEAD`. The previous `HEAD` is deleted and a new head is stored as
`HEAD-RZ-YYYY-mm-dd_HH.MM.SS` where `Z` is the next incremental revision number.

This way `HEAD` always has the latest entire copy of how the file was last saved. And all `DIFF`
entries can be applied to `HEAD` to go back in time.


[rcs]: https://www.gnu.org/software/rcs/
