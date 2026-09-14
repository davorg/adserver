use strict;
use warnings;

use Test::More;
use FindBin;
use Template;
use URI;

my $tt = Template->new({
    INCLUDE_PATH => "$FindBin::Bin/../views",
    START_TAG => '<%',
    END_TAG => '%>',
});

for my $referer (
    'https://publisher.example/article',
    'https://publisher.example/article?a=1&b=two+words&quote="hello"#section',
    'Unknown referer',
) {
    for my $with_image (0, 1) {
        my $html;
        $tt->process('standard.tt', {
            request => { base => 'https://ads.example/' },
            referer => $referer,
            impression => { token => 'a' x 32 },
            ad => {
                hash => 'abc123',
                heading => 'Example',
                body_text => 'Example body',
                display_url => 'advertiser.example',
                image => $with_image ? 'example.png' : undef,
                campaign => { client => { code => 'example' } },
            },
        }, \$html) or die $tt->error;

        my @links = $html =~ /<a\b[^>]*\bhref="([^"]*)"/g;
        is(scalar @links, $with_image ? 2 : 1, 'Expected number of click links');
        for my $link (@links) {
            my $uri = URI->new($link);
            is($uri->path, '/ad/abc123', 'Link uses the tracking route');
            my %query = $uri->query_form;
            is_deeply(\%query, { impression => 'a' x 32 },
                'Click link carries only the opaque impression token');
        }
    }
}

my $html;
$tt->process('standard.tt', {
    request => { base => 'https://ads.example/' },
    impression => { token => 'a' x 32 },
    ad => {
        hash => 'abc123', heading => '<script>alert("heading")</script>',
        body_text => '<b>Plain & simple</b>',
        display_url => 'example.test/?a=1&b=<tag>',
        image => 'image.png" onerror="alert(1)',
        campaign => { client => { code => 'client" onclick="alert(1)' } },
    },
}, \$html) or die $tt->error;
like($html, qr/&lt;script&gt;alert\(&quot;heading&quot;\)&lt;\/script&gt;/,
    'Heading is escaped');
like($html, qr/&lt;b&gt;Plain &amp; simple&lt;\/b&gt;/, 'Body is plain text');
like($html, qr/example\.test\/\?a=1&amp;b=&lt;tag&gt;/, 'Display URL is escaped');
like($html, qr/image\.png&quot; onerror=&quot;alert\(1\)/, 'Image cannot break the attribute');
like($html, qr/client&quot; onclick=&quot;alert\(1\)/, 'Client code cannot break the attribute');
unlike($html, qr/<script>|<b>|" onerror="|" onclick="/, 'No injected markup or attributes');
like($html, qr{</body>}, 'Body closing tag is valid');

done_testing;
