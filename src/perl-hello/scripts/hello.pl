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

# Keep the resource alive so it stays visible in the Aspire dashboard.
# Without this the process exits immediately and the resource flips to "Finished".
sleep 3600;
