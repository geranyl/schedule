use v5.10;
use WWW::Mechanize;
use WWW::Mechanize::TreeBuilder;
use JSON;
use HTML::Tidy;

 
my $mech = WWW::Mechanize->new;
WWW::Mechanize::TreeBuilder->meta->apply($mech);

$mech->get( 'http://fitc.ca/event/to14/presentations/' );

# Find all <h1> tags
my @list = $mech->find_all_links(url_regex => qr/^http:\/\/fitc.ca\/presentation/i);

my @json;

my $tidy = HTML::Tidy->new({output_html => 1,
                                tidy_mark => 0,
                                markup => 1,
                                q{show-body-only} => 1,
                                preserve_entities=>1}); #without preserve entities you get "wide character found in print" errors
$tidy->ignore( type => TIDY_WARNING, type => TIDY_INFO );

# Now just iterate and process
my $prevUrl;
foreach (@list) {
	my $url = $_->url;
	if($prevUrl ne $url){
	 #create hash for json construction
	 my %pres;
	 $pres{url} = $_->url;
	 #print $_->url."\n";
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

	 	$pres{location}=$_->look_down('class'=>'location')->as_trimmed_text();


	 	my @tags = $_->look_down('class'=>'tags')->content_list;
	 	my @tagsList;
	 	foreach (@tags){
	 	     push(@tagsList,$_->as_trimmed_text());
	 	}
	 	$pres{tags} = join(', ',@tagsList);

	 

	 }
	 
	 my @desc = $mech->look_down('class'=>'single-overview clear', sub{0<grep {ref($_) and $_->tag eq 'p' or $_->tag eq 'div' or $_->tag eq 'ul'} $_[0]->content_list})->content_list();

        $descStr = '';
        foreach(@desc){
            if ($_->tag() ne 'h2'){
                my $html = $_->as_HTML();

                $html=~s/<div>(.*?)<\/div>/<p>$1<\/p>/ig;
                #replace inline styles - http://www.adobe.com/devnet/dreamweaver/articles/regular_expressions_pt2.html
                $html=~s/(<[^>]*)style\s*=\s*('|")[^\2]*?\2([^>]*>)/$1$3/ig;
                $html=~s/(<[^>]*)class\s*=\s*('|")[^\2]*?\2([^>]*>)/$1$3/ig;

                 $html = $tidy->clean($html);
                 #not sure why tidyp keeps adding \n to things
                 $html=~s/\n+//ig;
                $descStr.=$html;
            }
        }


     $pres{desc} = $descStr;
  	 #print $descStr;

	 
	 $mech->back();
	
     push(@json, encode_json \%pres);
	}
}


print join(', ', @json);


sub getTime {	
	return split(',',$_[0]);	
}


