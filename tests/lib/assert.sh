# Assertion helpers. Source after tests/lib/sandbox.sh has set up the sandbox.
# Each failure increments ASSERT_FAILURES; the test file exits with that count.

ASSERT_FAILURES=0

fail() {
    printf '  FAIL: %s\n' "$*" >&2
    ASSERT_FAILURES=$((ASSERT_FAILURES + 1))
}

assert_eq() {
    [ "$1" = "$2" ] || fail "${3:-values differ}: expected [$2], got [$1]"
}

assert_contains() {
    case "$1" in
        *"$2"*) ;;
        *) fail "${3:-substring missing}: [$2] not found in [$1]" ;;
    esac
}

assert_not_contains() {
    case "$1" in
        *"$2"*) fail "${3:-unexpected substring}: [$2] found in [$1]" ;;
    esac
}

assert_file() {
    [ -f "$1" ] || fail "${2:-expected a file}: $1"
}

assert_symlink_to() {
    if [ ! -L "$1" ]; then
        fail "${3:-not a symlink}: $1"
        return
    fi
    local got want
    got=$(readlink -f "$1")
    want=$(readlink -f "$2")
    [ "$got" = "$want" ] || fail "${3:-wrong symlink target}: $1 -> $got, expected $want"
}

# assert_status EXPECTED CMD... — run CMD, compare its exit status.
assert_status() {
    local expected=$1
    shift
    local got=0
    "$@" >/dev/null 2>&1 || got=$?
    [ "$got" -eq "$expected" ] || fail "exit status: expected $expected, got $got from: $*"
}
