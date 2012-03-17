require HTTP::Request;
require LWP::UserAgent;
use JSON;
use HTML::TreeBuilder;
require HTTP::Headers;

$appkey = '|readitlater appkey|';
$user = '|readitlater user|';
$pass = '|readitlater password|';
$baseurl = "https://readitlaterlist.com/v2/";
$basepars = "?username=$user&password=$pass&apikey=$appkey";
$out = "|output path|";
$espeak = "|espeak install dir|\\command_line\\espeak.exe";
$espars = "-v en-us+f2 -s 180 -g 10mS";

$json = readitlater("get");
@urls = @{processJSON($json)};
$i = 1;
foreach $url (@urls) {
    $txt = page2text($url);
    text2wav($txt, $out, $i);
    $i = $i + 1;
}

# readitlaterlist.com API connector
sub readitlater {
    local $fun = $_[0];

    return typed_wget("$baseurl$fun$basepars", '?'); #'?' = doesn't matter which content type
}

# wget, which can control the content type
sub typed_wget {
    local ($url, $ctype) = ($_[0], $_[1]);

    print "wget $url\n\n";

    $request = HTTP::Request->new(GET => $url);
    $ua = LWP::UserAgent->new;
    $response = $ua->request($request);
    if (($ctype eq '?') or ($response->headers->content_type eq $ctype)) {
	return $response->decoded_content;
    }
    else {
	return ''; # empty content if error of any kind
    }
}

# JSON processor
sub processJSON {
    local $json = $_[0];

    $perl = decode_json $json;
    %hash = %{$perl};
    $list = $hash{'list'};
    %hash = %{$list};
    @urls = ();
    foreach $key (%hash) {
	$val = $hash{$key};
	%hash_sub = %{$val};
	push(@urls, $hash_sub{'url'});
    }

    return \@urls;
}

# process an online document - wget it, but only if it's HTML and strip it to the plain text
sub page2text {
    local $url = $_[0];

    $content = typed_wget($url, 'text/html');
    $tree = HTML::TreeBuilder->new;
    $tree->parse($content);
    $stripped = $tree->as_text();

    return $stripped;
}

# save the stripped text to a text file and use eSpeak to create a WAV out of it
sub text2wav {
    local ($txt, $out, $cnt) = ($_[0], $_[1], $_[2]);

    $of = "$out\\f$cnt.txt";
    open _F, ">$of";
    binmode(_F, ":utf8");
    print _F $txt;
    close _F;

    $cmd = "$espeak -f $of -w $out\\f$cnt.wav $espars";
    system $cmd;
    unlink("$of");
}
