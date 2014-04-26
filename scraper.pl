use v5.10;
use WWW::Mechanize;
use WWW::Mechanize::TreeBuilder;
use JSON;
 
my $mech = WWW::Mechanize->new;
WWW::Mechanize::TreeBuilder->meta->apply($mech);

$mech->get( 'http://fitc.ca/event/to14/presentations/' );

# Find all <h1> tags
my @list = $mech->find_all_links(url_regex => qr/^http:\/\/fitc.ca\/presentation/i);

my @json;

# Now just iterate and process
my $prevUrl;
foreach (@list) {
	my $url = $_->url;
	if($prevUrl ne $url){
	 #create hash for json construction
	 my %pres;
	 $pres{url} = $_->url;
	 print $_->url."\n";
	 $prevUrl = $url;	
	 
	 #follow the link
	 $mech->get($url);
	 my @info = $mech->look_down('class'=>'single-info clear');
	 foreach (@info){
	 
	 	$pres{title}=$_->look_down('class'=>'title')->as_trimmed_text();
	 	$pres{speaker}=$_->look_down('class'=>'speaker')->as_trimmed_text();
	 	
	 	my @time = getTime($_->look_down('class'=>'time')->as_trimmed_text());
	 	$pres{date}=@time[0];
	 	$pres{time}=@time[1];
	 	
	 	print @time[0];
	 	print @time[1];
	 	
	 	$pres{location}=$_->look_down('class'=>'location')->as_trimmed_text();
	 	$pres{tags}=$_->look_down('class'=>'tags')->as_trimmed_text();
	 
	 	# print $_->look_down('class'=>'title')->as_trimmed_text()."\n";
# 	 	print $_->look_down('class'=>'speaker')->as_trimmed_text()."\n";
# 	 	print $_->look_down('class'=>'time')->as_trimmed_text()."\n";
# 	    print $_->look_down('class'=>'location')->as_trimmed_text()."\n";
# 	 	print $_->look_down('class'=>'tags')->as_trimmed_text()."\n";
	 }
	 
	 my @desc = $mech->look_down('class'=>'single-overview clear', sub{0<grep {ref($_) and $_->tag eq 'p' or $_->tag eq 'div'} $_[0]->content_list});
	 my $descStr = '';
     for ($i = 0; $i < @desc; $i++) {
    	$descStr.=clean(@desc[$i]->as_trimmed_text());
 	 }
     $pres{desc} = $descStr;
#  	 print $descStr."\n\n";

	 
	 $mech->back();
	
     push(@json, encode_json \%pres);
	}
}


print join(', ', @json);

sub clean {
	my $str = $_[0];
	$str =~ s/[^[:ascii:]]/ /g;
	$str =~ s/^Overview/ /g;
	return $str;
}

sub getTime {	
	return split(',',$_[0]);	
}


