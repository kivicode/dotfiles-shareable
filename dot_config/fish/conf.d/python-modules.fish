# Adds project-local dotted modules (and the project venv's installed modules) to
# `python -m`, `python3 -m`, `uv run python -m` and `uv run -m`. Additive to fish's built-ins.

function __pymod_wants_module
    set -l tokens (commandline -opc)
    test (count $tokens) -ge 2; and test "$tokens[-1]" = -m; or return 1
    switch $tokens[1]
        case python python3 'python3.*'
            return 0
        case uv
            contains -- run $tokens
            return
    end
    return 1
end

function __pymod_python
    if set -q VIRTUAL_ENV; and test -x $VIRTUAL_ENV/bin/python
        echo $VIRTUAL_ENV/bin/python
        return
    end
    set -l dir $PWD
    while test $dir != /
        if test -x $dir/.venv/bin/python
            echo $dir/.venv/bin/python
            return
        end
        set dir (path dirname $dir)
    end
    command -s python3
end

function __pymod_list
    # fd honours .gitignore, so .venv/node_modules/build output are never walked.
    if command -q fd
        fd --type f --extension py --max-depth 6 --exclude __pycache__ . 2>/dev/null \
            | string replace -r '\.py$' '' \
            | string replace -r '/?__init__$' '' \
            | string replace -a / . \
            | string match -r '^[A-Za-z_][\w.]*$'
    end
    set -l py (__pymod_python)
    test -n "$py"; and $py -c 'import pkgutil; print("\n".join(m.name for m in pkgutil.iter_modules()))' 2>/dev/null
end

# fish's python completion declares -m as taking an argument, so candidates must be
# attached to that option; generic completions are ignored in option-argument position.
complete -c python -c python3 -n __fish_python_no_arg -s m -x -a '(__pymod_list)'
complete -c uv -n __pymod_wants_module -f -a '(__pymod_list)'
