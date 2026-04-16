use strict;
use warnings;

use Mojolicious::Lite -signatures;

$| = 1;

my @summaries = (
    "Freezing", "Bracing", "Chilly", "Cool", "Mild",
    "Warm", "Balmy", "Hot", "Sweltering", "Scorching",
);

get '/health' => sub ($c) {
    $c->render(json => { status => 'ok' });
};

get '/weatherforecast' => sub ($c) {
    my @forecasts;

    for my $i (1 .. 5) {
        my @t      = localtime(time + $i * 86400);
        my $date   = sprintf("%04d-%02d-%02d", $t[5] + 1900, $t[4] + 1, $t[3]);
        my $temp_c = int(rand(75)) - 20;

        push @forecasts, {
            date         => $date,
            temperatureC => $temp_c + 0,
            temperatureF => 32 + int($temp_c / 0.5556),
            summary      => $summaries[int(rand(scalar @summaries))],
        };
    }

    $c->render(json => \@forecasts);
};

if (!@ARGV) {
    my $port = $ENV{PORT} // 8080;
    @ARGV = ('daemon', '-l', "http://*:$port");
}

app->start;
