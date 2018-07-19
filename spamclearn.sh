#!/bin/sh
RES=$(spamc -L spam < /dev/stdin)
EC=$?
[ $EC -gt 0 ]  && exit $EC
if [ "$RES" = "Message was already un/learned" ]; then
	EC=6
else
	EC=5
fi
exit $EC
