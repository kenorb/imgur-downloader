#!/bin/bash
#
# imgur profile album downloader
# Usage: ./$0 URL
#
# Supported links:
# - profile pages (http://user.imgur.com/)
# - albums (http://imgur.com/a/xXyYz)
# - multiple albums (http://imgur.com/a/xXyYz http://imgur.com/a/xXyYz)
#
# Not supported:
# - direct links (http://imgur.com/xXxXz)
# - galleries (http://imgur.com/r/gallery)
#
# Requirements: seq or gseq, wget, uniq
# Tested on: Linux, Mac

INDEX=index.html.$RANDOM
ALIST=albums.list.$RANDOM
ILIST=images.list.$RANDOM
EXTS="(jpg|jpeg|gif)"
ALBUM=$(echo $1 | grep -oE "\w+" | sed -n 2p)
DELAY=0.2 # Delay for each request (e.g. 0.2, 1)
WGET="wget -w$DELAY --content-disposition -UMozilla"
SEQ=$(which seq || which gseq)
which $SEQ && which wget && which uniq || exit 1  # Check the requirements

# Fetch the user's album page.
$WGET -O $INDEX $*
# Strip the user's page down to a list of album hyperlinks.
cat $INDEX | grep -Eo "imgur.com/a/\w+" > $ALIST

# Count how many albums we are to fetch.
COUNT=$(wc -l $ALIST | awk '{print $1}')

# Descend into a loop to fetch all of the images.
for i in $($SEQ 1 $COUNT)
do
        # Make a directory.
        ADIR=$(cat $ALIST | sed -n "${i}p" | awk -F/ '{print $NF}' || echo $i)
        mkdir -vp $ALBUM/$ADIR || continue
        cd $ALBUM/$ADIR
        # Fetch this particular album index.
        $WGET -c $(cat ../../$ALIST | sed -n "${i}p")        # Variable-ize it.
        mv $(ls -1 . | grep -vE $EXTS) $ILIST
        # Strip the file down to the actual image links.
        cat $ILIST | grep -Eo "http://i.imgur.com.*$EXTS"  | sed -E "s/s.(jpg|jpeg|gif)/.\1/g" | uniq > $ILIST
        # Fetch the album's images.
        $WGET -c -i $ILIST
        # Cleanup.
        rm -v $ILIST
        # Repeat.
        cd ../..
done

# Cleanup.
rm -v $INDEX $ALIST