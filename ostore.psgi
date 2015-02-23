#!perl
use 5.12.0;
use utf8;
use Plack::Request;
use Plack::Builder;
use JSON 'encode_json';
use MIME::Base64 'encode_base64';
use Time::Piece;
use File::Basename;
use Data::Dumper;

my $app = sub {
    my $req = Plack::Request->new(shift);
    my $path = $req->uri->path;
    if ($path =~ m{^/(store_)?info/$}) {
        return [200, ['Content-Type' => 'text/plain'], ['you are using ostore test server on '.$req->uri]];
    } elsif ($path =~ m{^/upgrade/index.php$}) {
        if ($req->param('mode') eq 'download') { return &download($req) } 
        elsif ($req->param('mode') eq 'products_list') { return &products_list($req) }
    } else {
        return [302, ['Location' => 'http://www.ec-cube.net'.$req->uri->path_query],['']];
    }
    return &return_404;
};

sub return_404 {
    return [404, ['Content-Type' => 'text/plain'], ['not found']];
}

sub get_archives {
    my $version = shift;
    my @ver = split(/\./, $version);
    my @files = map {
        my $filename = $_;
        my @parts = split(/-/, $filename); # 999-mdl_foobar-0.0.1-eccube-2.13.0-fffffff.tar.gz
        my @compliant_version = split(/\./, $parts[4]);
        my $download_flg = 
            $ver[0] != $compliant_version[0] ? 0 :
            $ver[1] != $compliant_version[1] ? 0 :
            $ver[2] >= $compliant_version[2] ? 1 : 0;
        {
            id => $parts[0],
            name => $parts[1],
            version => $parts[2],
            download_flg => $download_flg,
        }
    } glob('*.tar.gz');
    return @files;
}

sub products_list {
    my $req = shift;
    my @files = get_archives($req->param('ver'));

    my $json = {
        status => 'SUCCESS',
        errcode => undef,
        msg => '',
        data => [ map { {
                download_flg => $_->{download_flg},
                installed_flg => 0,
                installed_version => '',
                last_update_date => localtime->strftime('%F %T'),
                main_list_comment => '',
                main_list_image => 'noimage.gif',
                name => $_->{name},
                product_id => $_->{id},
                status => $_->{download_flg} ? '使用できます' : "使用できません\n対応バージョンを\n確認してください",
                version => $_->{version},
                version_up_flg => '0',
            } } @files
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
    my ($filename) = glob(sprintf('%d-*.tar.gz', $req->param('product_id')));

    if ($filename) {
        open my $fh, '<', $filename or die;
        my $file = do {local $/; <$fh>};
        close $fh;
        my @parts = split(/-/, $filename);
        my $json = {
            status => 'SUCCESS',
            errcode => undef,
            msg => '',
            data => {
                product_id => $parts[0],
                product_name => $parts[1],
                version => $parts[2],
                product_code => $parts[1],
                module_filename => '',
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
