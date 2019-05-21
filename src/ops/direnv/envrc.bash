#!/usr/bin/env bash
# ^ shebang is unused as this file is sourced, but present for editor
# integration. Note: Direnv guarantees it *will* be parsed using bash.

function punt () {
    :
}

function prepend() {
    varname=$1 # example: varname might contain the string "PATH"

    # drop off the varname
    shift

    separator=$1 # example: separator would usually be the string ":"

    # drop off the separator argument, so the remaining arguments
    # are the arguments to export
    shift

    # set $original to the contents of the the variable $varname
    # refers to
    original="${!varname}"

    # effectfully accept the new variable's contents
    export "${@?}";

    # re-set $varname's variable to the contents of varname's
    # reference, plus the current (updated on the export) contents.
    eval "$varname=${!varname}$separator$original"
}

function append() {
    varname=$1 # example: varname might contain the string "PATH"

    # drop off the varname
    shift

    separator=$1 # example: separator would usually be the string ":"
    # drop off the separator argument, so the remaining arguments
    # are the arguments to export
    shift


    # set $original to the contents of the the variable $varname
    # refers to
    original="${!varname}"

    # effectfully accept the new variable's contents
    export "${@?}";

    # re-set $varname's variable to the contents of varname's
    # reference, plus the current (updated on the export) contents.
    eval "$varname=$original$separator${!varname}"
}

varmap() {
    # Capture the name of the variable being set
    IFS="=" read -r -a cur_varname <<< "$1"

    while read -r line; do
        IFS=$'\t' read -r -a args <<< "$line"
        unset IFS

        map_instruction=${args[0]}
        map_variable=${args[1]}
        map_separator=${args[2]}

        if [ "$map_variable" == "${cur_varname[0]}" ]; then
            if [ "$map_instruction" == "append" ]; then
                append "$map_variable" "$map_separator" "$@"
                return
            fi
        fi
    done < "$EVALUATION_ROOT/varmap"


    export "${@?}"
}

function declare() {
    if [ "$1" == "-x" ]; then shift; fi

    # Some variables require special handling.
    #
    # - punt:    don't set the variable at all
    # - prepend: take the new value, and put it before the current value.
    case "$1" in
        # vars from: https://github.com/NixOS/nix/blob/92d08c02c84be34ec0df56ed718526c382845d1a/src/nix-build/nix-build.cc#L100
        "HOME="*) punt;;
        "USER="*) punt;;
        "LOGNAME="*) punt;;
        "DISPLAY="*) punt;;
        "PATH="*) prepend "PATH" ":" "$@";;
        "TERM="*) punt;;
        "IN_NIX_SHELL="*) punt;;
        "TZ="*) punt;;
        "PAGER="*) punt;;
        "NIX_BUILD_SHELL="*) punt;;
        "SHLVL="*) punt;;

        # vars from: https://github.com/NixOS/nix/blob/92d08c02c84be34ec0df56ed718526c382845d1a/src/nix-build/nix-build.cc#L385
        "TEMPDIR="*) punt;;
        "TMPDIR="*) punt;;
        "TEMP="*) punt;;
        "TMP="*) punt;;

        # vars from: https://github.com/NixOS/nix/blob/92d08c02c84be34ec0df56ed718526c382845d1a/src/nix-build/nix-build.cc#L421
        "NIX_ENFORCE_PURITY="*) punt;;

        *) varmap "$@" ;;
    esac
}

export IN_NIX_SHELL=1
# shellcheck disable=SC1090
. "$EVALUATION_ROOT/bash-export"

unset declare
