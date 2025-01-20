function envload
    for line in (cat $argv | grep -v '^\s*#' | grep -v '^\s*$')
        set item (string split -m 1 '=' $line)
        if test (count $item) -eq 2
            set -gx $item[1] $item[2]
            # echo "Exported key $item[1] with value $item[2]"
        else
            echo "Skipping malformed line: $line" >&2
        end
    end
end
