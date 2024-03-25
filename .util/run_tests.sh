#!/bin/bash
tempdir=$(mktemp -d)
confpath=$tempdir/minetest.conf
worldpath=$tempdir/world
trap 'rm -rf "$tempdir"' EXIT

[ -f worldedit/mod.conf ] || { echo "Must be run in modpack root folder." >&2; exit 1; }

mtserver=
if [ "$1" == "--docker" ]; then
	command -v docker >/dev/null || { echo "Docker is not installed." >&2; exit 1; }
	[ -d minetest_game ] || { echo "To run the test with Docker, a source checkout of minetest_game is required." >&2; exit 1; }
else
	mtserver=$(command -v minetestserver)
	[[ -z "$mtserver" && -x ../../bin/minetestserver ]] && mtserver=../../bin/minetestserver
	[ -z "$mtserver" ] && { echo "To run the test outside of Docker, an installation of minetestserver is required." >&2; exit 1; }
fi

mkdir $worldpath
printf '%s\n' mg_name=singlenode '[end_of_params]' >$worldpath/map_meta.txt
printf '%s\n' worldedit_run_tests=true >$confpath

if [ -z "$mtserver" ]; then
	chmod -R 777 $tempdir
	[ -z "$DOCKER_IMAGE" ] && DOCKER_IMAGE="ghcr.io/minetest/minetest:master"
	docker run --rm -i \
		-v "$confpath":/etc/minetest/minetest.conf \
		-v "$tempdir":/var/lib/minetest/.minetest \
		-v "$PWD/minetest_game":/var/lib/minetest/.minetest/games/minetest_game \
		-v "$PWD/worldedit":/var/lib/minetest/.minetest/world/worldmods/worldedit \
		"$DOCKER_IMAGE"
else
	mkdir $worldpath/worldmods
	ln -s "$PWD/worldedit" $worldpath/worldmods/worldedit
	$mtserver --config "$confpath" --world "$worldpath" --logfile /dev/null
fi

test -f $worldpath/tests_ok || exit 1
exit 0
