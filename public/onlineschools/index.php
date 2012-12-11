<?php

//error_reporting(E_ALL | E_STRICT);
//ini_set("display_errors", 1);

include('library.php');

$options = array(
      'controller'  => '/onlineschools',
//    'server'      => 'http://staging.schools.collegedegrees.com',
);


$client = new cdClient($options);
$client->request();
$client->initHeaders();

// Pass images, CSS & JS straight through
if (! $client->isType('html')) {
    echo $client->getContent();
    return;
}

//echo $client->getContent();

$url_vars = explode("/",$_SERVER['REQUEST_URI']);

if($url_vars[2] == 'forms'){
    $im_home = false;
} else {
    $im_home = true;
}

?>


<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
    <head>
        <?php echo str_replace('CollegeDegrees', 'Education Database Online', $client->getContent('title')) ?>
		<!--work-->
        <?php echo $client->getContent('head base') ?>
        <?php echo $client->getContent('head link') ?>
        <?php echo $client->getContent('head style') ?>
        <?php echo $client->getContent('head script') ?>
		<?php if(!$im_home):?>
				<link href="/stylesheets/reset.css?1300864529" media="screen" rel="stylesheet" type="text/css" />
				<link href="/stylesheets/style.css?1302395856" media="screen" rel="stylesheet" type="text/css" />
				<link href="/stylesheets/fonts.css?1300864529" media="screen" rel="stylesheet" type="text/css" />
		<?php endif; ?>
				<link href="school-form.css?1302395856" media="screen" rel="stylesheet" type="text/css" />
				<!--[if lte IE 7]>
				<link rel="stylesheet" type="text/css" href="/stylesheets/ie7.css" />
				<![endif]-->
				<!--[if IE 8]>
				<link rel="stylesheet" type="text/css" href="/stylesheets/ie8.css" />
				<![endif]-->

		<style type="text/css">
		  #seals { display: none; }
		</style>
	</head>

<body<?php if($im_home):?> id="index_pg"<?php endif;?>>
	<div id="oe_header">
		<div id="header_content">
			<div id="logo"><h1>Education Database Online</h1></div>
			<!-- end #logo -->
			<div id="nav"></div>
			<!-- end #nav -->
			<div class="clear"></div>
		</div>
	</div>
	<!-- end #header -->
	<?php
	// The <body> tag contains lots of goodies need for the form to work (Javascript, a custom ID/CSS, etc.)
	$content = $client->getContent('body');

	// Replace references to CollegeDegrees to OnlineCollege.org
	$content = str_replace(array('CollegeDegrees.com', 'CollegeDegress'), 'OnlineEducation.net', $content);

	// Point privacy page to the Wordpress privacy page
	$content = str_replace('pages/privacy-policy', '/privacy-policy', $content);

	//$pattern = '/<script.*?<\/body>/im';
	//$content = preg_replace($pattern, '', $content);

        $pattern = '/<!-- Google Start Analytics.*?Google End Analytics -->/ims';
        $content = preg_replace($pattern, '', $content);

        $pattern = '/<!-- Start Visual Website Optimizer Code.*?End Visual Website Optimizer Code -->/ims';
        $content = preg_replace($pattern, '', $content);

        $pattern = '/<!-- ClickTale Top part.*?ClickTale end of Top part -->/ims';
        $content = preg_replace($pattern, '', $content);

        $pattern = '/<span class="analytics">.*?<\/body>/ims';
        $content = preg_replace($pattern, '</body>', $content);

        $pattern = '/<img id="school-banner-logo".*?>/ims';
        $content = preg_replace($pattern, '', $content);


        $pattern = '/<div id="footer" class="span-7">.*?<\/div>/ims';
        $content = preg_replace($pattern, '', $content);





	echo $content;
	?>
		<div id="footer">
			<div id="footer_content">
				<div class="left">
					&copy; 2012 Education Database Online | <a target="_blank" href="/privacy-policy">Privacy Policy</a><br/><br/>
				</div>
				<div class="right">

				</div>
				<div class="clear"></div>
			</div>
		</div>
			<script type="text/javascript"> 
			  var _gaq = _gaq || [];
			  _gaq.push(['_setAccount', 'UA-16775402-1']);
			  _gaq.push(['_trackPageview']);
			  (function() {
			    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
			    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
			    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
			  })();
			  $('#lead').submit(function(){
                	    var path = '/_conversions/' + window.location.pathname.substring(19);
                	    _gaq.push(['_trackPageview', path]);
            		  });
			</script> 

	</body>
</html>
