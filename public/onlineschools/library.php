<?php


/**
 * cdClient main class file.
 * This file contains the codebase of the main cdClient engine.
 * @author Jesse Greathouse
 * @version 1.3
 * @package cdClient
 */

/**
 * cdClient class
 * You can pass an option array to the constructor
 * The options array will merge and overwrite the default options
 * $client = new cdClient($options);
 * @package cdClient
 */
class cdClient
{

    /**
     * Contains all pieces of the response from the curl request
     * @var array
     */
    protected $response = array();

    /**
     * Container for the curl_info() value
     * @var array
     */
    protected $info = array();
    /**
     * Container for the curl handler resource
     * @var resource
     */
    protected $ch;

    /**
     * Container for the DOM object
     * @var obj
     */
    protected $dom;

    /**
     * Container for the logger object
     * @var obj
     */
    protected $log;

    /**
     * all configurable options
     * @var array
     */
    protected $options = array(
        'mode'            => 'standard',
        'client_hostname' => null,
        'server'          => 'https://schools.collegedegrees.com',
        'controller'      => '/',
        'curl_options'    => array(
            'CURLOPT_CONNECTTIMEOUT' => 20,
            'CURLOPT_HEADER'         => true,
            'CURLOPT_FAILONERROR'    => true,
            'CURLOPT_FILETIME'       => true,
            'CURLOPT_FOLLOWLOCATION' => true,
            'CURLOPT_RETURNTRANSFER' => true,
            'CURLOPT_SSL_VERIFYHOST' => false,
            'CURLOPT_SSL_VERIFYPEER' => false,
        ),
        'curl_headers'    => array(
            'X-Vendor-Id: CDclient',
        ),
        'illegal_headers' => array(
            'Transfer-Encoding',
            'Set-Cookie',
        ),
        'action_map' => array(
            'gallery' => 'https://search.collegedegrees.com',
        )
    );

    /**
     * Constructor
     *
     * @param  null|array $options
     * @return void
     */
    public function __construct($options = array())
    {
        $this->setOptions($options);
        $dom = new Zend_Dom_Query;
        $this->setDom($dom);
        $this->prepare();
        $this->log = KLogger::instance($this->options['cache_dir'].'/log', KLogger::INFO);
    }

    /**
     * Executes http request via Curl
     *
     * @param  bool $cache
     */
    public function request($cache = true)
    {
        $this->log->logInfo('performing request with the following options: ');
        $this->log->logInfo(print_r($this->options, true));
        if ($this->isAjax()) {
            $this->options['curl_headers'][] = 'X-Requested-With: XMLHttpRequest';
            $cache = false;
        }

        if (($post = $this->getPost()) !== null) {
            $cache = false;
            $this->setPost($post);
        }

        if ($cache && file_exists($this->getCachePath($this->getRemoteUrl()))) {
            $this->response = $this->getCache();
            $cache = false;
        } else {
            $this->setCookie();
            $this->setOption('CURLOPT_HTTPHEADER', $this->options['curl_headers']);
            $this->response['raw'] = curl_exec($this->ch);
            $this->response['header'] = curl_getinfo($this->ch);
            $this->response['error_id'] = curl_errno($this->ch);
            $this->response['error'] = curl_error($this->ch);
            $this->response['content'] = substr($this->response['raw'], $this->response['header']['header_size']);
        }

        $header_size = $this->response['header']['header_size'];
        $header = substr($this->response['raw'], 0, $header_size);
        if ($this->response['header']['redirect_count'] > 0){
                $this->log->logInfo('Redirection ========================');
                $this->log->logInfo('Redirection redirect header detected');
                $this->log->logInfo('Redirection ========================');
                $cache = false;
                preg_match_all("/location:(.*?)\n/is", $header, $locations);
                $destination = trim(end($locations[1]));
                $this->log->logInfo('Redirection desitnation is: ' . $destination);
                if ($this->options['mode'] == 'cherrypick') {
                    $options = array(
                       'curl_options' => array(
                            'CURLOPT_URL' => $destination,
                        ),
                    );
                    $options = $this->mergeConfig($this->options, $options);
                    $client = new self($options);
                    $client->request();
                    $this->response = $client->getResponse();

                    $header_size = $this->response['header']['header_size'];
                    $header = substr($this->response['raw'], 0, $header_size);
                } else {
                    if (strpos($destination, 'http') !== false) {
                        $this->log->logInfo('Redirection destination is absolute path');
                        $urlparts = parse_url($destination);
                        $destination = $urlparts['path'];
                        if (!empty($urlparts['query'])) {
                           $destination .= '?'.$urlparts['query'];
                        }
                    }
                        
                    $destination = $this->getHost() . $destination;
                    $this->log->logInfo('Redirection destination is not absolute path ... reconstructing');
                    $this->log->logInfo('Redirection calling:  header("Location: ' . $destination . '");');
                    header("Location: " . $destination);
                    exit();
                }

        }

        if (isset($this->response['error']) && !empty($this->response['error'])) {
            $cache = false;
        }

        $this->response['headers'] = $this->stripIllegalHeaders(explode("\n", $header));

        if ($this->isType('html') || empty($this->response['content'])) {
            $cache = false;
            $this->response['content'] = $this->postProcess($this->response['content']);
        }

        $dom = new Zend_Dom_Query($this->response['content']);
        $this->setDom($dom);

        if ($cache) {
            $this->response['headers'][] = 'X-Cache-Hit: 0';
            $this->setCache($this->response);
        } else {
            $this->response['headers'][] = 'X-Cache-Hit: 0';
        }

        curl_close($this->ch);
    }

    /**
     * Infer an action from the url string
     *
     * @return false|string
     */
    public function getAction()
    {
        $uri = $this->stripController($_SERVER['REQUEST_URI']);
        $pieces = explode('/', $uri);
        if (count($pieces)>1) {
            return $pieces[1];
        } else {
            return false;
        }
    }

    /**
     * Get the action key => value store
     *
     * @return array
     */
    public function getActionMap()
    {
        return $this->options['action_map'];
    }

    /**
     * Gets any cached content related to the request
     *
     * @return array
     */
    public function getCache()
    {
        $path = $this->getCachePath($this->getRemoteUrl());
        $this->log->logInfo('Fetched cache file: '. $path);
        return unserialize(file_get_contents($path));
    }

    /**
     * Saves the cached content in the request
     */
    public function setCache()
    {
        $path = $this->getCachePath($this->getRemoteUrl());
        $fh = fopen($path, "w");
        if (!$fh) {
            $this->log->logFatal($path . ' could not be created for writing.');
            Throw new Exception($path . ' could not be created for writing.');
        } else {
           $this->log->logInfo('Writing content to cache file: '. $path);
        }
        fwrite($fh, serialize($this->response));
        fclose($fh);
    }

    /**
     * Transpose the path to the cached content based on the url
     * @param  string $url
     * @return string
     */
    public function getCachePath($url)
    {
        $file = substr(str_replace('/', '-', $this->convertUriToPath($url)), 1);
        return $this->options['cache_dir'] . '/cache/' . $file;
    }

    /**
     * Get the content of the request
     * @param  string null|string|array $selector
     * @return string
     */
    public function getContent($selector = null, $exclude = null)
    {
        if (isset($this->response['content'])) {
            if ($this->isType('html') && ($selector != null || $exclude != null)) {
                $content = $this->response['content'];

                if ($selector != null) {
                    if (!is_array($selector)) {
                        $selector = array($selector);
                    }
                    $composite = new DomDocument;
                    foreach ($selector as $selection) {
                        $results = $this->dom->query($selection);
                        foreach ($results as $result) {
                            $composite->appendChild($composite->importNode($result, true));
                        }
                        unset($results);
                    }
                    unset($selector);

                    $content = $composite->saveHTML();
                }

                if ($exclude != null) {
                    if (!is_array($exclude)) {
                        $exclude = array($exclude);
                    }

                    foreach ($exclude as $antiSelection) {
                        $results = $this->dom->query($antiSelection);
                        foreach ($results as $result) {
                            $antiComposite = new DomDocument;
                            $antiComposite->appendChild($antiComposite->importNode($result, true));
                            $content = str_replace($antiComposite->saveHTML(), '', $content);
                            unset($antiComposite);
                        }
                        unset($results);
                    }
                }
                return $content;
            } else {
                return $this->response['content'];
            }
        } else {
            return null;
        }
    }

    /**
     * Gets the name of the controller
     *
     * @return string
     */
    public function getController()
    {
        if ($this->options['controller'] == '/') {
            return '';
        }
        return $this->options['controller'];
    }

    /**
     * Handles the cookies during the request
     *
     */
    function setCookie()
    {
        $dir = $this->options['cache_dir'] . '/session';
        if (!isset($_COOKIE['CSid'])) {
            $CSid = md5(date('U'));
            setcookie('CSid', $CSid, 0, '/');
        } else {
            $CSid = $_COOKIE['CSid'];
        }
        $ckfile = $dir.'/'.$CSid;
        $this->setOption('CURLOPT_COOKIEJAR', $ckfile);
        $this->setOption('CURLOPT_COOKIEFILE', $ckfile);
    }

    /**
     * Gets the current version of the script
     *
     * @return false|string
     */
    public function getCurrentRevision()
    {
        $file = $this->options['cache_dir'] . '/cache/REVISION';
        if (file_exists($file)) {
            $fh = fopen($file, 'r');
            $contents = fread($fh, filesize($file));
            fclose($fh);
            return $contents;
        } else {
            return false;
        }
    }

    /**
     * Sets the current revision of the script
     * @param string $content
     *
     */
    public function setCurrentRevision($content)
    {
        prepare();
        $file = $this->options['cache_dir'] . '/cache/REVISION';
        $fh = fopen($file, "w");
        fwrite($fh, $content);
        fclose($fh);
    }

    /**
     * Gets the dom container
     *
     * @return Zend_Dom_Query
     */
    public function getDom()
    {
        return $this->dom;
    }

    /**
     * Sets the dom container
     * @param Zend_Dom_Query $dom
     *
     */
    public function setDom(Zend_Dom_Query $dom)
    {
        $this->dom = $dom;
    }

    /**
     * Gets the headers from the request
     *
     * @return array
     */
    public function getHeaders()
    {
        return $this->response['headers'];
    }

    /**
     * sets the curl resource handler
     * @param resource $ch
     *
     */
    public function setHandler($ch = null)
    {
        unset($this->ch);
        if ($ch == null) {
            $ch = curl_init();
        }
        $this->ch = $ch;
    }

    /**
     * Gets the current host
     *
     * @return string
     */
    public function getHost()
    {
        if ($this->options['client_hostname'] != null) {
            $host = $this->options['client_hostname'];
        } else {
            $host = $_SERVER['SERVER_NAME'];
        }
        return 'http://'.$host.$this->getController();
    }

    /**
     * Gets the latest revision from the remote server
     *
     * @return bool|string
     */
    public function getLatestRevision()
    {
        $feed = $this->getServer().'/revision';
        $client = new self(array('curl_options' => array('CURLOPT_URL' => $feed)));
        $response = $client->getResponse();
	    if (isset($response['content']) && $response['content'] != "") {
	        return $response['content'];
        } else {
            return 0;
        }
    }

    /**
     * Gets the content of the info container
     *
     * @return array
     */
    public function getInfo() {
        if (empty($this->info)) {
            $this->info = curl_getinfo($this->ch);
        }
        return $this->info;
    }

    /**
     * Sets an option to the curl resource
     * @param string $option
     * @param string $value
     *
     */
    public function setOption($option, $value)
    {
        curl_setopt($this->ch, constant($option), $value);
    }

    /**
     * Gets the current options
     *
     * @return array
     */
    public function getOptions()
    {
        return $this->options;
    }

    /**
     * Sets an array of options
     * @param array $options
     * @param null|resource $ch
     *
     */
    public function setOptions($options = array(), $ch = null)
    {
        //remapping for backwards compatibility
        if (isset($options['home_dir'])) { $options['cache_dir'] = $options['home_dir']; }
        
        $this->setHandler($ch);
        $this->options = $this->mergeConfig($this->options, $options);
        //when the default and user are merged, then merge the dynamic server options
        $this->options = $this->mergeConfig($this->getWebserverConfigs(), $this->options);
        foreach ($this->options['curl_options'] as $option => $value) {
            $this->setOption($option, $value);
        }
    }

    /**
     * Gets the global _POST params
     *
     * @return null|$_POST
     */
    public function getPost()
    {
        if ($_SERVER['REQUEST_METHOD'] == 'POST') {
            return $_POST;
        } else {
            return null;
        }
    }

    /**
     * Sets up the curl resource to use POST
     * @param array $params
     *
     */
    public function setPost($params)
    {
        $this->options['curl_headers'][] = 'Content-type: application/x-www-form-urlencoded';
        $this->setOption('CURLOPT_POST', true);
        $this->setOption('CURLOPT_POSTFIELDS', http_build_query($params));
    }

    /**
     * Gets the current response container
     *
     */
    public function getResponse()
    {
        return $this->response;
    }

    /**
     * Gets current server
     *
     * @return string
     */
    public function getServer()
    {
        $server = $this->options['server'];
        if ((($action = $this->getAction()) !== false) &&
              array_key_exists($action, $this->options['action_map'])) {
              $server  = $this->options['action_map'][$action];
        }
        return $server;
    }

    /**
     * Gets current uri without the controller or mapped actions
     *
     * @return string
     */
    public function getUri()
    {
        $uri = $_SERVER['REQUEST_URI'];
        foreach (array_keys($this->getActionMap()) as $needle) {
            if (strpos($uri, '/'.$needle) !== false) {
                $uri = str_replace('/'.$needle, '', $uri);
            }
        }
        return $this->stripController($uri);
    }

    /**
     * Gets remote uri via the info container
     *
     * @return string
     */
    public function getRemoteUrl()
    {
        $info = $this->getInfo();
        return $info['url'];
    }

    /**
     * Gets webserver configs dynamically from the $_SERVER global
     *
     * @return array
     */
    private function getWebserverConfigs()
    {
        return array(
            'cache_dir'     => realpath(dirname(__FILE__)),
            'curl_options' => array(
                'CURLOPT_URL'       => $this->getServer().$this->getUri(),
                'CURLOPT_REFERER'   => $this->getHost(),
            ),
            'curl_headers' => array(
                'Host: '.str_replace(array('http://','https://'), '', $this->getServer()),
                'User-Agent: '.$_SERVER['HTTP_USER_AGENT'],
                'X-Publisher-Id: '.$_SERVER['SERVER_NAME'],
            ),
        );
    }

    /**
     * Sends all headers to output
     *
     */
    public function initHeaders()
    {
        foreach ($this->getHeaders() as $header) {
            header($header);
        }
    }

    /**
     * greps the Input string against the "Content Type:" of the request
     * @param string $type
     * @return bool
     */
    public function isType($type) {
        if (key(preg_grep("/$type/i", $this->response['headers'])) !== null) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * Takes a Uri string and converts it to a file path
     * @param string $uri
     * @return string
     */
    public function convertUriToPath($uri)
    {
        $pattern = '/(http:|https:)\/\/(.+?)\//i';
        $replacement = '/';
        $uri = preg_replace($pattern, $replacement, $uri );

        if ($uri === '/') {
            $uri = '/index';
        }
        $lastchar = strlen($uri)-1;
        if (substr($uri,$lastchar) === '/') {
            $uri = substr($uri, 0, $lastchar);
        }

        return $uri;
    }

    /**
     * Strips out any headers based on the Illegal_headers config
     * @param array $headers
     * @return array
     */
    public function stripIllegalHeaders($headers)
    {
        $headers = array_filter(array_map("trim", $headers));
        foreach ($this->options['illegal_headers'] as $val) {
            unset($headers[key(preg_grep("/$val/i", $headers))]);
        }
        return $headers;
    }

    /**
     * Takes a string of content and runs it through arbitrary methods
     * @param string $content
     * @return string
     */
    public function postProcess($content)
    {
        $content = $this->swapHosts($content);
        $content = $this->stripRootReference($content);
        $content = $this->filterEduDirectImages($content);
        return $content;
    }

    /**
     * Greps the content for the remote server address and replaces it with the local host
     * @param string $content
     * @return string
     */
    public function swapHosts($content)
    {
        $pattern = "/".addcslashes($this->getServer(),'/')."/";
        $replacement = $this->getHost();
        $newcontent = preg_replace($pattern , $replacement , $content );
        return $newcontent;
    }

    /**
     * Greps the content for a root reference and removes it
     * @param string $content
     * @return string
     */
    public function stripRootReference($content)
    {
        $pattern = '/\=\"\/(\w)/';
        $replacement = '="$1';
        $newcontent = preg_replace ($pattern, $replacement , $content);

        #for linked js
        $pattern = '/\"\/js/';
        $replacement = '"'.$this->getController().'/js';
        $newcontent = preg_replace ($pattern, $replacement , $newcontent);

        return $newcontent;
    }

    /**
     * Greps the content for a certain image host and replaces it with the local host
     * @param string $content
     * @return string
     */
    public function filterEduDirectImages($content)
    {
        $pattern = 'https://search.collegedegrees.com';
        $replacement = $this->getHost().'/gallery';
        $newcontent = preg_replace("/".addcslashes($pattern,'/')."/" , $replacement , $content );
        return $newcontent;
    }

    /**
     * Removes the controller from a given uri string
     * @param string $uri
     * @return string
     */
    public function stripController($uri = "")
    {
        $controller = $this->getController();
        if (strpos($uri, $controller) !== false) {
            $uri = str_replace($controller, '', $uri);
        }
        return $uri;
    }

    /**
     * Checks for software updates and executes if there is a new revision
     *
     */
    public function checkForUpdates()
    {
        $latest = getLatestRevision();
        if ($latest && ($latest != getCurrentRevision())) {
            dumpCache();
            setCurrentRevision($latest);
        }
    }

    /**
     * deletes the cache folder
     *
     */
    public function dumpCache()
    {
        $this->rmdir_recursive($this->options['cache_dir'] . '/cache');
    }

    /**
     * Removes a directory and all files and subdirectories within it
     * @param string $dir
     *
     */
    public function rmdir_recursive($dir)
    {
        if (is_dir($dir)) {
            $objects = scandir($dir);
            foreach ($objects as $object) {
                if ($object != "." && $object != "..") {
                    if (filetype($dir."/".$object) == "dir") rmdir_recursive($dir."/".$object); else unlink($dir."/".$object);
                }
            }
            reset($objects);
            rmdir($dir);
        }
    }

    /**
     * Determines if the current request is using Ajax by the $_SERVER global
     *
     * @return bool
     */
    public function isAjax()
    {
        if (isset($_SERVER['HTTP_X_REQUESTED_WITH']) &&
            strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) == 'xmlhttprequest') {
            return true;
        } else {
            return false;
        }
    }

    /**
     * Prepares the current environment for use
     *
     */
    private function prepare()
    {
        //create required folders
        $home = $this->options['cache_dir'];
        foreach (array(
            $home . '/cache',
            $home . '/session',
            $home . '/log',
        ) as $dir) {
            if (!is_dir($dir)) {
                if (!mkdir($dir)) {
                   Throw new Exception($dir . ' could not be created. Check and see if ' . $home . ' is writeable');
                }
            }
        }
    }

    /**
     * taken from php.net http://php.net/manual/en/function.array-merge-recursive.php
     *
     * posted by: mark dot roduner at gmail dot com 14-Feb-2010 07:34
     * originally posted as array_merge_recursive_distinct
     *
     * Merges any number of arrays / parameters recursively, replacing
     * entries with string keys with values from latter arrays.
     * If the entry or the next value to be assigned is an array, then it
     * automagically treats both arguments as an array.
     * Numeric entries are appended, not replaced, but only if they are
     * unique
     *
     * calling: result = this::mergeConfig(a1, a2, ... aN)
     * @param array $arr1
     * @param array $arr2
     * @return array
    **/

    private function mergeConfig($arr1, $arr2)
    {
      $arrays = func_get_args();
      $base = array_shift($arrays);
      if(!is_array($base)) $base = empty($base) ? array() : array($base);
      foreach($arrays as $append) {
        if(!is_array($append)) $append = array($append);
        foreach($append as $key => $value) {
          if(!array_key_exists($key, $base) and !is_numeric($key)) {
            $base[$key] = $append[$key];
            continue;
          }
          if(is_array($value) or is_array($base[$key])) {
            $base[$key] = $this->mergeConfig($base[$key], $append[$key]);
          } else if(is_numeric($key)) {
            if(!in_array($value, $base)) $base[] = $value;
          } else {
            $base[$key] = $value;
          }
        }
      }
      return $base;
    }

}


/**
 * Finally, a light, permissions-checking logging class.
 *
 * Originally written for use with wpSearch
 *
 * Usage:
 * $log = new KLogger('/var/log/', KLogger::INFO );
 * $log->logInfo('Returned a million search results'); //Prints to the log file
 * $log->logFatal('Oh dear.'); //Prints to the log file
 * $log->logDebug('x = 5'); //Prints nothing due to current severity threshhold
 *
 * @package KLogger
 * @author  Kenny Katzgrau <katzgrau@gmail.com>
 * @since   July 26, 2008
 * @link    http://codefury.net
 * @version 0.1
 */

/**
 * Class documentation
 */
class KLogger
{
    /**
     * Error severity, from low to high. From BSD syslog RFC, secion 4.1.1
     * @link http://www.faqs.org/rfcs/rfc3164.html
     */
    const EMERG  = 0;  // Emergency: system is unusable
    const ALERT  = 1;  // Alert: action must be taken immediately
    const CRIT   = 2;  // Critical: critical conditions
    const ERR    = 3;  // Error: error conditions
    const WARN   = 4;  // Warning: warning conditions
    const NOTICE = 5;  // Notice: normal but significant condition
    const INFO   = 6;  // Informational: informational messages
    const DEBUG  = 7;  // Debug: debug messages

    //custom logging level
    /**
     * Log nothing at all
     */
    const OFF    = 8;
    /**
     * Alias for CRIT
     * @deprecated
     */
    const FATAL  = 2;

    /**
     * Internal status codes
     */
    const STATUS_LOG_OPEN    = 1;
    const STATUS_OPEN_FAILED = 2;
    const STATUS_LOG_CLOSED  = 3;

    /**
     * Current status of the log file
     * @var integer
     */
    private $_logStatus         = self::STATUS_LOG_CLOSED;
    /**
     * Holds messages generated by the class
     * @var array
     */
    private $_messageQueue      = array();
    /**
     * Path to the log file
     * @var string
     */
    private $_logFilePath       = null;
    /**
     * Current minimum logging threshold
     * @var integer
     */
    private $_severityThreshold = self::INFO;
    /**
     * This holds the file handle for this instance's log file
     * @var resource
     */
    private $_fileHandle        = null;

    /**
     * Standard messages produced by the class. Can be modified for il8n
     * @var array
     */
    private $_messages = array(
        //'writefail'   => 'The file exists, but could not be opened for writing. Check that appropriate permissions have been set.',
        'writefail'   => 'The file could not be written to. Check that appropriate permissions have been set.',
        'opensuccess' => 'The log file was opened successfully.',
        'openfail'    => 'The file could not be opened. Check permissions.',
    );

    /**
     * Default severity of log messages, if not specified
     * @var integer
     */
    private static $_defaultSeverity    = self::DEBUG;
    /**
     * Valid PHP date() format string for log timestamps
     * @var string
     */
    private static $_dateFormat         = 'Y-m-d G:i:s';
    /**
     * Octal notation for default permissions of the log file
     * @var integer
     */
    private static $_defaultPermissions = 0777;
    /**
     * Array of KLogger instances, part of Singleton pattern
     * @var array
     */
    private static $instances           = array();

    /**
     * Partially implements the Singleton pattern. Each $logDirectory gets one
     * instance.
     *
     * @param string  $logDirectory File path to the logging directory
     * @param integer $severity     One of the pre-defined severity constants
     * @return KLogger
     */
    public static function instance($logDirectory = false, $severity = false)
    {
        if ($severity === false) {
            $severity = self::$_defaultSeverity;
        }
        
        if ($logDirectory === false) {
            if (count(self::$instances) > 0) {
                return current(self::$instances);
            } else {
                $logDirectory = dirname(__FILE__);
            }
        }

        if (in_array($logDirectory, self::$instances)) {
            return self::$instances[$logDirectory];
        }

        self::$instances[$logDirectory] = new self($logDirectory, $severity);

        return self::$instances[$logDirectory];
    }

    /**
     * Class constructor
     *
     * @param string  $logDirectory File path to the logging directory
     * @param integer $severity     One of the pre-defined severity constants
     * @return void
     */
    public function __construct($logDirectory, $severity)
    {
        $logDirectory = rtrim($logDirectory, '\\/');

        if ($severity === self::OFF) {
            return;
        }

        $this->_logFilePath = $logDirectory
            . DIRECTORY_SEPARATOR
            . 'log_'
            . date('Y-m-d')
            . '.txt';

        $this->_severityThreshold = $severity;
        if (!file_exists($logDirectory)) {
            mkdir($logDirectory, self::$_defaultPermissions, true);
        }

        if (file_exists($this->_logFilePath) && !is_writable($this->_logFilePath)) {
            $this->_logStatus = self::STATUS_OPEN_FAILED;
            $this->_messageQueue[] = $this->_messages['writefail'];
            return;
        }

        if (($this->_fileHandle = fopen($this->_logFilePath, 'a'))) {
            $this->_logStatus = self::STATUS_LOG_OPEN;
            $this->_messageQueue[] = $this->_messages['opensuccess'];
        } else {
            $this->_logStatus = self::STATUS_OPEN_FAILED;
            $this->_messageQueue[] = $this->_messages['openfail'];
        }
    }

    /**
     * Class destructor
     */
    public function __destruct()
    {
        if ($this->_fileHandle) {
            fclose($this->_fileHandle);
        }
    }
    /**
     * Writes a $line to the log with a severity level of DEBUG
     *
     * @param string $line Information to log
     * @return void
     */
    public function logDebug($line)
    {
        $this->log($line, self::DEBUG);
    }

    /**
     * Returns (and removes) the last message from the queue.
     * @return string
     */
    public function getMessage()
    {
        return array_pop($this->_messageQueue);
    }

    /**
     * Returns the entire message queue (leaving it intact)
     * @return array
     */
    public function getMessages()
    {
        return $this->_messageQueue;
    }

    /**
     * Empties the message queue
     * @return void
     */
    public function clearMessages()
    {
        $this->_messageQueue = array();
    }

    /**
     * Sets the date format used by all instances of KLogger
     * 
     * @param string $dateFormat Valid format string for date()
     */
    public static function setDateFormat($dateFormat)
    {
        self::$_dateFormat = $dateFormat;
    }

    /**
     * Writes a $line to the log with a severity level of INFO. Any information
     * can be used here, or it could be used with E_STRICT errors
     *
     * @param string $line Information to log
     * @return void
     */
    public function logInfo($line)
    {
        $this->log($line, self::INFO);
    }

    /**
     * Writes a $line to the log with a severity level of NOTICE. Generally
     * corresponds to E_STRICT, E_NOTICE, or E_USER_NOTICE errors
     *
     * @param string $line Information to log
     * @return void
     */
    public function logNotice($line)
    {
        $this->log($line, self::NOTICE);
    }

    /**
     * Writes a $line to the log with a severity level of WARN. Generally
     * corresponds to E_WARNING, E_USER_WARNING, E_CORE_WARNING, or 
     * E_COMPILE_WARNING
     *
     * @param string $line Information to log
     * @return void
     */
    public function logWarn($line)
    {
        $this->log($line, self::WARN);
    }

    /**
     * Writes a $line to the log with a severity level of ERR. Most likely used
     * with E_RECOVERABLE_ERROR
     *
     * @param string $line Information to log
     * @return void
     */
    public function logError($line)
    {
        $this->log($line, self::ERR);
    }

    /**
     * Writes a $line to the log with a severity level of FATAL. Generally
     * corresponds to E_ERROR, E_USER_ERROR, E_CORE_ERROR, or E_COMPILE_ERROR
     *
     * @param string $line Information to log
     * @return void
     * @deprecated Use logCrit
     */
    public function logFatal($line)
    {
        $this->log($line, self::FATAL);
    }

    /**
     * Writes a $line to the log with a severity level of ALERT.
     *
     * @param string $line Information to log
     * @return void
     */
    public function logAlert($line)
    {
        $this->log($line, self::ALERT);
    }

    /**
     * Writes a $line to the log with a severity level of CRIT.
     *
     * @param string $line Information to log
     * @return void
     */
    public function logCrit($line)
    {
        $this->log($line, self::CRIT);
    }

    /**
     * Writes a $line to the log with a severity level of EMERG.
     *
     * @param string $line Information to log
     * @return void
     */
    public function logEmerg($line)
    {
        $this->log($line, self::EMERG);
    }

    /**
     * Writes a $line to the log with the given severity
     *
     * @param string  $line     Text to add to the log
     * @param integer $severity Severity level of log message (use constants)
     */
    public function log($line, $severity)
    {
        if ($this->_severityThreshold >= $severity) {
            $status = $this->_getTimeLine($severity);
            $this->writeFreeFormLine("$status $line \n");
        }
    }

    /**
     * Writes a line to the log without prepending a status or timestamp
     *
     * @param string $line Line to write to the log
     * @return void
     */
    public function writeFreeFormLine($line)
    {
        if ($this->_logStatus == self::STATUS_LOG_OPEN
            && $this->_severityThreshold != self::OFF) {
            if (fwrite($this->_fileHandle, $line) === false) {
                $this->_messageQueue[] = $this->_messages['writefail'];
            }
        }
    }

    private function _getTimeLine($level)
    {
        $time = date(self::$_dateFormat);

        switch ($level) {
            case self::EMERG:
                return "$time - EMERG -->";
            case self::ALERT:
                return "$time - ALERT -->";
            case self::CRIT:
                return "$time - CRIT -->";
            case self::FATAL: # FATAL is an alias of CRIT
                return "$time - FATAL -->";
            case self::NOTICE:
                return "$time - NOTICE -->";
            case self::INFO:
                return "$time - INFO -->";
            case self::WARN:
                return "$time - WARN -->";
            case self::DEBUG:
                return "$time - DEBUG -->";
            case self::ERR:
                return "$time - ERROR -->";
            default:
                return "$time - LOG -->";
        }
    }
}
/**
 * Zend Framework
 *
 * LICENSE
 *
 * This source file is subject to the new BSD license that is bundled
 * with this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://framework.zend.com/license/new-bsd
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to license@zend.com so we can send you a copy immediately.
 *
 * @category   Zend
 * @package    Zend_Dom
 * @copyright  Copyright (c) 2005-2010 Zend Technologies USA Inc. (http://www.zend.com)
 * @license    http://framework.zend.com/license/new-bsd     New BSD License
 */

/**
 * Transform CSS selectors to XPath
 *
 * @package    Zend_Dom
 * @subpackage Query
 * @copyright  Copyright (c) 2005-2010 Zend Technologies USA Inc. (http://www.zend.com)
 * @license    http://framework.zend.com/license/new-bsd     New BSD License
 * @version    $Id$
 */
class Zend_Dom_Query_Css2Xpath
{
    /**
     * Transform CSS expression to XPath
     *
     * @param  string $path
     * @return string
     */
    public static function transform($path)
    {
        $path = (string) $path;
        if (strstr($path, ',')) {
            $paths       = explode(',', $path);
            $expressions = array();
            foreach ($paths as $path) {
                $xpath = self::transform(trim($path));
                if (is_string($xpath)) {
                    $expressions[] = $xpath;
                } elseif (is_array($xpath)) {
                    $expressions = array_merge($expressions, $xpath);
                }
            }
            return implode('|', $expressions);
        }

        $paths    = array('//');
        $path     = preg_replace('|\s+>\s+|', '>', $path);
        $segments = preg_split('/\s+/', $path);
        foreach ($segments as $key => $segment) {
            $pathSegment = self::_tokenize($segment);
            if (0 == $key) {
                if (0 === strpos($pathSegment, '[contains(')) {
                    $paths[0] .= '*' . ltrim($pathSegment, '*');
                } else {
                    $paths[0] .= $pathSegment;
                }
                continue;
            }
            if (0 === strpos($pathSegment, '[contains(')) {
                foreach ($paths as $key => $xpath) {
                    $paths[$key] .= '//*' . ltrim($pathSegment, '*');
                    $paths[]      = $xpath . $pathSegment;
                }
            } else {
                foreach ($paths as $key => $xpath) {
                    $paths[$key] .= '//' . $pathSegment;
                }
            }
        }

        if (1 == count($paths)) {
            return $paths[0];
        }
        return implode('|', $paths);
    }

    /**
     * Tokenize CSS expressions to XPath
     *
     * @param  string $expression
     * @return string
     */
    protected static function _tokenize($expression)
    {
        // Child selectors
        $expression = str_replace('>', '/', $expression);

        // IDs
        $expression = preg_replace('|#([a-z][a-z0-9_-]*)|i', '[@id=\'$1\']', $expression);
        $expression = preg_replace('|(?<![a-z0-9_-])(\[@id=)|i', '*$1', $expression);

        // arbitrary attribute strict equality
        $expression = preg_replace_callback(
            '|\[([a-z0-9_-]+)=[\'"]([^\'"]+)[\'"]\]|i',
            array(__CLASS__, '_createEqualityExpression'),
            $expression
        );

        // arbitrary attribute contains full word
        $expression = preg_replace_callback(
            '|\[([a-z0-9_-]+)~=[\'"]([^\'"]+)[\'"]\]|i',
            array(__CLASS__, '_normalizeSpaceAttribute'),
            $expression
        );

        // arbitrary attribute contains specified content
        $expression = preg_replace_callback(
            '|\[([a-z0-9_-]+)\*=[\'"]([^\'"]+)[\'"]\]|i',
            array(__CLASS__, '_createContainsExpression'),
            $expression
        );

        // Classes
        $expression = preg_replace(
            '|\.([a-z][a-z0-9_-]*)|i', 
            "[contains(concat(' ', normalize-space(@class), ' '), ' \$1 ')]", 
            $expression
        );

        /** ZF-9764 -- remove double asterix */
        $expression = str_replace('**', '*', $expression);

        return $expression;
    }

    /**
     * Callback for creating equality expressions
     * 
     * @param  array $matches 
     * @return string
     */
    protected static function _createEqualityExpression($matches)
    {
        return '[@' . strtolower($matches[1]) . "='" . $matches[2] . "']";
    }

    /**
     * Callback for creating expressions to match one or more attribute values
     * 
     * @param  array $matches 
     * @return string
     */
    protected static function _normalizeSpaceAttribute($matches)
    {
        return "[contains(concat(' ', normalize-space(@" . strtolower($matches[1]) . "), ' '), ' " 
             . $matches[2] . " ')]";
    }

    /**
     * Callback for creating a strict "contains" expression
     * 
     * @param  array $matches 
     * @return string
     */
    protected static function _createContainsExpression($matches)
    {
        return "[contains(@" . strtolower($matches[1]) . ", '" 
             . $matches[2] . "')]";
    }
}

/**
 * Zend Framework
 *
 * LICENSE
 *
 * This source file is subject to the new BSD license that is bundled
 * with this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://framework.zend.com/license/new-bsd
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to license@zend.com so we can send you a copy immediately.
 *
 * @category   Zend
 * @package    Zend_Dom
 * @copyright  Copyright (c) 2005-2010 Zend Technologies USA Inc. (http://www.zend.com)
 * @license    http://framework.zend.com/license/new-bsd     New BSD License
 */

/**
 * Results for DOM XPath query
 *
 * @package    Zend_Dom
 * @subpackage Query
 * @uses       Iterator
 * @copyright  Copyright (c) 2005-2010 Zend Technologies USA Inc. (http://www.zend.com)
 * @license    http://framework.zend.com/license/new-bsd     New BSD License
 * @version    $Id$
 */
class Zend_Dom_Query_Result implements Iterator,Countable
{
    /**
     * Number of results
     * @var int
     */
    protected $_count;

    /**
     * CSS Selector query
     * @var string
     */
    protected $_cssQuery;

    /**
     * @var DOMDocument
     */
    protected $_document;

    /**
     * @var DOMNodeList
     */
    protected $_nodeList;

    /**
     * Current iterator position
     * @var int
     */
    protected $_position = 0;

    /**
     * @var DOMXPath
     */
    protected $_xpath;

    /**
     * XPath query
     * @var string
     */
    protected $_xpathQuery;

    /**
     * Constructor
     *
     * @param  string $cssQuery
     * @param  string|array $xpathQuery
     * @param  DOMDocument $document
     * @param  DOMNodeList $nodeList
     * @return void
     */
    public function  __construct($cssQuery, $xpathQuery, DOMDocument $document, DOMNodeList $nodeList)
    {
        $this->_cssQuery   = $cssQuery;
        $this->_xpathQuery = $xpathQuery;
        $this->_document   = $document;
        $this->_nodeList   = $nodeList;
    }

    /**
     * Retrieve CSS Query
     *
     * @return string
     */
    public function getCssQuery()
    {
        return $this->_cssQuery;
    }

    /**
     * Retrieve XPath query
     *
     * @return string
     */
    public function getXpathQuery()
    {
        return $this->_xpathQuery;
    }

    /**
     * Retrieve DOMDocument
     *
     * @return DOMDocument
     */
    public function getDocument()
    {
        return $this->_document;
    }

    /**
     * Iterator: rewind to first element
     *
     * @return void
     */
    public function rewind()
    {
        $this->_position = 0;
        return $this->_nodeList->item(0);
    }

    /**
     * Iterator: is current position valid?
     *
     * @return bool
     */
    public function valid()
    {
        if (in_array($this->_position, range(0, $this->_nodeList->length - 1)) && $this->_nodeList->length > 0) {
            return true;
        }
        return false;
    }

    /**
     * Iterator: return current element
     *
     * @return DOMElement
     */
    public function current()
    {
        return $this->_nodeList->item($this->_position);
    }

    /**
     * Iterator: return key of current element
     *
     * @return int
     */
    public function key()
    {
        return $this->_position;
    }

    /**
     * Iterator: move to next element
     *
     * @return void
     */
    public function next()
    {
        ++$this->_position;
        return $this->_nodeList->item($this->_position);
    }

    /**
     * Countable: get count
     *
     * @return int
     */
    public function count()
    {
        return $this->_nodeList->length;
    }
}


/**
 * Zend Framework
 *
 * LICENSE
 *
 * This source file is subject to the new BSD license that is bundled
 * with this package in the file LICENSE.txt.
 * It is also available through the world-wide-web at this URL:
 * http://framework.zend.com/license/new-bsd
 * If you did not receive a copy of the license and are unable to
 * obtain it through the world-wide-web, please send an email
 * to license@zend.com so we can send you a copy immediately.
 *
 * @category   Zend
 * @package    Zend_Dom
 * @copyright  Copyright (c) 2005-2010 Zend Technologies USA Inc. (http://www.zend.com)
 * @license    http://framework.zend.com/license/new-bsd     New BSD License
 * @version    $Id$
 */

/**
 * @see Zend_Dom_Query_Css2Xpath
 */
//require_once 'Zend/Dom/Query/Css2Xpath.php';

/**
 * @see Zend_Dom_Query_Result
 */
//require_once 'Zend/Dom/Query/Result.php';

/**
 * Query DOM structures based on CSS selectors and/or XPath
 *
 * @package    Zend_Dom
 * @subpackage Query
 * @copyright  Copyright (c) 2005-2010 Zend Technologies USA Inc. (http://www.zend.com)
 * @license    http://framework.zend.com/license/new-bsd     New BSD License
 */
class Zend_Dom_Query
{
    /**#@+
     * Document types
     */
    const DOC_XML   = 'docXml';
    const DOC_HTML  = 'docHtml';
    const DOC_XHTML = 'docXhtml';
    /**#@-*/

    /**
     * @var string
     */
    protected $_document;

    /**
     * DOMDocument errors, if any
     * @var false|array
     */
    protected $_documentErrors = false;

    /**
     * Document type
     * @var string
     */
    protected $_docType;

    /**
     * XPath namespaces
     * @var array
     */
    protected $_xpathNamespaces = array();

    /**
     * Constructor
     *
     * @param  null|string $document
     * @return void
     */
    public function __construct($document = null)
    {
        $this->setDocument($document);
    }

    /**
     * Set document to query
     *
     * @param  string $document
     * @return Zend_Dom_Query
     */
    public function setDocument($document)
    {
        if (0 === strlen($document)) {
            return $this;
        }
        // breaking XML declaration to make syntax highlighting work
        if ('<' . '?xml' == substr(trim($document), 0, 5)) {
            return $this->setDocumentXml($document);
        }
        if (strstr($document, 'DTD XHTML')) {
            return $this->setDocumentXhtml($document);
        }
        return $this->setDocumentHtml($document);
    }

    /**
     * Register HTML document
     *
     * @param  string $document
     * @return Zend_Dom_Query
     */
    public function setDocumentHtml($document)
    {
        $this->_document = (string) $document;
        $this->_docType  = self::DOC_HTML;
        return $this;
    }

    /**
     * Register XHTML document
     *
     * @param  string $document
     * @return Zend_Dom_Query
     */
    public function setDocumentXhtml($document)
    {
        $this->_document = (string) $document;
        $this->_docType  = self::DOC_XHTML;
        return $this;
    }

    /**
     * Register XML document
     *
     * @param  string $document
     * @return Zend_Dom_Query
     */
    public function setDocumentXml($document)
    {
        $this->_document = (string) $document;
        $this->_docType  = self::DOC_XML;
        return $this;
    }

    /**
     * Retrieve current document
     *
     * @return string
     */
    public function getDocument()
    {
        return $this->_document;
    }

    /**
     * Get document type
     *
     * @return string
     */
    public function getDocumentType()
    {
        return $this->_docType;
    }

    /**
     * Get any DOMDocument errors found
     * 
     * @return false|array
     */
    public function getDocumentErrors()
    {
        return $this->_documentErrors;
    }

    /**
     * Perform a CSS selector query
     *
     * @param  string $query
     * @return Zend_Dom_Query_Result
     */
    public function query($query)
    {
        $xpathQuery = Zend_Dom_Query_Css2Xpath::transform($query);
        return $this->queryXpath($xpathQuery, $query);
    }

    /**
     * Perform an XPath query
     *
     * @param  string|array $xpathQuery
     * @param  string $query CSS selector query
     * @return Zend_Dom_Query_Result
     */
    public function queryXpath($xpathQuery, $query = null)
    {
        if (null === ($document = $this->getDocument())) {
            require_once 'Zend/Dom/Exception.php';
            throw new Zend_Dom_Exception('Cannot query; no document registered');
        }

        libxml_use_internal_errors(true);
        $domDoc = new DOMDocument;
        $type   = $this->getDocumentType();
        switch ($type) {
            case self::DOC_XML:
                $success = $domDoc->loadXML($document);
                break;
            case self::DOC_HTML:
            case self::DOC_XHTML:
            default:
                $success = $domDoc->loadHTML($document);
                break;
        }
        $errors = libxml_get_errors();
        if (!empty($errors)) {
            $this->_documentErrors = $errors;
            libxml_clear_errors();
        }
        libxml_use_internal_errors(false);

        if (!$success) {
            require_once 'Zend/Dom/Exception.php';
            throw new Zend_Dom_Exception(sprintf('Error parsing document (type == %s)', $type));
        }

        $nodeList   = $this->_getNodeList($domDoc, $xpathQuery);
        return new Zend_Dom_Query_Result($query, $xpathQuery, $domDoc, $nodeList);
    }

    /**
     * Register XPath namespaces
     *
     * @param   array $xpathNamespaces
     * @return  void
     */
    public function registerXpathNamespaces($xpathNamespaces)
    {
        $this->_xpathNamespaces = $xpathNamespaces;
    }

    /**
     * Prepare node list
     *
     * @param  DOMDocument $document
     * @param  string|array $xpathQuery
     * @return array
     */
    protected function _getNodeList($document, $xpathQuery)
    {
        $xpath      = new DOMXPath($document);
        foreach ($this->_xpathNamespaces as $prefix => $namespaceUri) {
            $xpath->registerNamespace($prefix, $namespaceUri);
        }
        $xpathQuery = (string) $xpathQuery;
        if (preg_match_all('|\[contains\((@[a-z0-9_-]+),\s?\' |i', $xpathQuery, $matches)) {
            foreach ($matches[1] as $attribute) {
                $queryString = '//*[' . $attribute . ']';
                $attributeName = substr($attribute, 1);
                $nodes = $xpath->query($queryString);
                foreach ($nodes as $node) {
                    $attr = $node->attributes->getNamedItem($attributeName);
                    $attr->value = ' ' . $attr->value . ' ';
                }
            }
        }
        return $xpath->query($xpathQuery);
    }
}

