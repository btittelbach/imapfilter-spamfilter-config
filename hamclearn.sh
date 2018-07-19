#!/bin/sh
if [ -n "$1" ]; then
	RES=$(spamc -L ham < "$1")
	EC=$?
else
	RES=$(spamc -L ham < /dev/stdin)
	EC=$?
fi
[ $EC -gt 0 ]  && exit $EC
if [ "$RES" = "Message was already un/learned" ]; then
	EC=6
else
	EC=5
fi
exit $EC
