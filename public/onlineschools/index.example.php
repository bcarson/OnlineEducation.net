<?php
include('library.php');

$options = array(
//    'home_dir'        => '/var/www/mySite/myCDclient',          # directory on the server 
//    'server'          => 'http://staging.collegedegrees.com',   # target content server
//    'controller'      => '/myCDclient',                         # http://mySite.com/myCDclient
);

$client = new cdClient($options);
$client->request();
$client->initHeaders();

if (!$cdClient->isType('html')) {
    echo $client->getContent();
    exit();
}

echo $client->getContent();
