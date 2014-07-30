#!perl
use 5.12.0;
use utf8;
use Plack::Request;
use Plack::Builder;
use JSON 'encode_json';
use MIME::Base64 'encode_base64';
use Time::Piece;
use File::Basename;

my $distfile = $ENV{'ECCUBE_DIST_FILE'} or die 'ECCUBE_DIST_FILE environment variable needed';
-f $distfile or die 'distfile not found!';
my $basename = basename($distfile);
my $product_code = basename($distfile, '.tar.gz');

my $app = sub {
    my $req = Plack::Request->new(shift);
    my $path = $req->uri->path;
    if ($path =~ m{^/info/$}) {
        return [200, ['Content-Type' => 'text/plain'], ['you are using ostore test server on '.$req->uri]];
    } elsif ($path =~ m{^/upgrade/index.php$}) {
        if ($req->param('mode') eq 'download') { return &download($req) } 
        elsif ($req->param('mode') eq 'product_list') { return &products_list($req) }
    } elsif ($path =~ m{^/download}) {
        open my $fh, '<', $distfile or die;
        return [200, [
                'Content-Type' => 'binary/octet-stream',
                'Content-Disposition' => qq(attatchment; filename="$basename"),
            ], $fh];
    }
    return &return_404;
};

sub return_404 {
    return [404, ['Content-Type' => 'text/plain'], ['not found']];
}

sub products_list {
    my $req = shift;

    my $json = {
        status => 'SUCCESS',
        errcode => undef,
        msg => '',
        data => [
            {
                download_flg => 1,
                eccube_version_flg => 2,
                installed_flg => 1,
                installed_version => 'devel',
                last_update_date => localtime->strftime('%F %T'),
                main_list_comment => '',
                main_list_image => 'noimage.gif',
                name => 'your devel module',
                product_id => '999',
                status => '使用できます',
                version => 'devel',
                version_up_flg => '0',
            }
        ]
    };
    return [
        200,
        ['Content-Type' => 'text/javascript; charset=UTF-8'],
        [ encode_json($json) ],
    ];
}

sub download {
    my $req = shift;

    if ($req->param('product_id') == 999) {
        open my $fh, '<', $distfile or die;
        my $file = do {local $/; <$fh>};
        close $fh;
        my $json = {
            status => 'SUCCESS',
            errcode => undef,
            msg => '',
            data => {
                product_name => 'your devel module',
                download_flg => '1',
                version => 'devel',
                eccube_version_flg => '1',
                order_id => '99999',
                product_id => '999',
                status => '11',
                installed_flg => '1',
                installed_version => 'devel',
                product_code => $product_code,
                dl_file => encode_base64($file),
            }
        };
        return [
            200,
            ['Content-Type' => 'text/javascript; charset=UTF-8'],
            [encode_json($json)],
        ];
    } else {
        &return_404;
    }
}

sub download_commit {
    my $req = shift;
    &return_404;
}

builder {
    enable 'ReverseProxy';
    $app;
};
