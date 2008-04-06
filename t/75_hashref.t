#!/usr/bin/perl

use strict;
$^W = 1;

 use Test::More "no_plan";
#use Test::More tests => 31;

BEGIN {
    use_ok "Text::CSV_XS", ();
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    }

open  FH, ">_test.csv";
print FH <<EOC;
code,name,price,description
1,Dress,240.00,"Evening gown"
2,Drinks,82.78,"Drinks"
3,Sex,-9999.99,"Priceless"
EOC
close FH;

ok (my $csv = Text::CSV_XS->new (),	"new");
is ($csv->column_names, undef,		"No headers yet");

foreach my $args ([\1], ["foo", \1], [{ 1 => 2 }]) {
    eval { $csv->column_names (@$args) };
    like ($@, qr/^EHR/, "croak");
    is ($csv->error_diag () + 0, 3001, "Bad args to column_names");
    }

is ($csv->column_names (undef), undef, "reset column_names");

my $hr;
eval { $hr = $csv->getline_hr (*FH) };
is ($hr, undef,	"getline_hr before column_names");
like ($@, qr/^EHR/, "croak");
is ($csv->error_diag () + 0, 3002, "error code");

ok ($csv->column_names ("name", "code"), "column_names (list)");
is_deeply ([ $csv->column_names ], [ "name", "code" ], "well set");

open  FH, "<_test.csv";
my $row;
ok ($row = $csv->getline (*FH),		"getline headers");
is ($row->[0], "code",			"Header line");
ok ($csv->column_names ($row),		"column_names from array_ref");
is_deeply ([ $csv->column_names ], [ @$row ], "Keys set");
while (my $hr = $csv->getline_hr (*FH)) {
    ok (exists $hr->{code},			"Line has a code field");
    like ($hr->{code}, qr/^[0-9]+$/,		"Code is numeric");
    ok (exists $hr->{name},			"Line has a name field");
    like ($hr->{name}, qr/^[A-Z][a-z]+$/,	"Name");
    }
close FH;

my ($code, $name, $price, $desc) = (1..4);
is ($csv->bind_columns (), undef,		"No bound columns yet");
eval { $csv->bind_columns (\$code) };
is ($csv->error_diag () + 0, 3003,		"Arg cound mismatch");
eval { $csv->bind_columns ({}, {}, {}, {}) };
is ($csv->error_diag () + 0, 3004,		"bad arg types");
is ($csv->column_names (undef), undef,		"reset column_names");
eval { $csv->bind_columns ((\$code) x 300) };
is ($csv->error_diag () + 0, 3005,		"too many args");
ok ($csv->bind_columns (\($code, $name, $price)), "Bind columns");

eval { $csv->column_names ("foo") };
is ($csv->error_diag () + 0, 3003,		"Arg cound mismatch");
$csv->bind_columns (undef);

open  FH, "<_test.csv";
ok ($row = $csv->getline (*FH),			"getline headers");
ok ($csv->bind_columns (\($code, $name, $price, $desc)), "Bind columns");
ok ($csv->column_names ($row),			"column_names from array_ref");
is_deeply ([ $csv->column_names ], [ @$row ],	"Keys set");
my @row = $csv->getline (*FH);
close FH;
use Data::Dumper; $Data::Dumper::Sortkeys = 1;
print STDERR Dumper $csv,\@row, \$code, \$name, \$price, \$desc;

unlink "_test.csv";
