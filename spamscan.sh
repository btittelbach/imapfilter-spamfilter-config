#!/bin/bash
#imapfilter terminates if spamc breaks the pipe
#this happens if the message is larger than spamd will check
#so we need to protect imapfilter from spamc
cat >/dev/shm/__spamtest 
spamc -c < /dev/shm/__spamtest
E=$?
rm /dev/shm/__spamtest
exit $E

