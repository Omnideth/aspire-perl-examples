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
        my @time_parts = localtime(time + $i * 86400);
        my $date = sprintf(
            "%04d-%02d-%02d",
            $time_parts[5] + 1900,
            $time_parts[4] + 1,
            $time_parts[3]
        );
        my $temperature_c = int(rand(75)) - 20;

        push @forecasts, {
            date         => $date,
            temperatureC => $temperature_c + 0,
            temperatureF => 32 + int($temperature_c / 0.5556),
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