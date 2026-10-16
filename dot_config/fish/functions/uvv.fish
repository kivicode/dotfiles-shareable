function uvv --description 'Run uv against the python env currently on PATH'
    set -l py (command -s python)
    or begin
        echo "uvv: no python on PATH" >&2
        return 1
    end
    UV_PROJECT_ENVIRONMENT=(path dirname (path dirname $py)) command uv $argv
end
