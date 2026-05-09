use strict;
use warnings;

use JSON::PP;

$| = 1; # autoflush stdout so prints appear in Aspire dashboard immediately

my $payload = {
    message => "hello from perl",
    pid     => $$,
    perl    => sprintf("%vd", $^V),
};

print encode_json($payload), "\n";
