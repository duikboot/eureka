# Run your Selenium tests in the cloud with Bitbucket Pipelines

Bitbucket was known for it's great Mercurial support. They're dropping it as
I write, but they are also great for having "free" pipelines (50 minutes a 
month). 

Pipelines are a great way to automate things after you push your code. One of 
these example is to automatically run unit-test, code analysers and/or unit 
tests.

A great way to also test the behaviour and functionality of a webapplication is
by testing it with Selenium. Selenium is a framework which executes tasks you 
would normally do yourself. Open the site, navigate, fill in a form, click the
submit button, check if the confirmation message is shown, make sure the images
are not broken, etc... This is done with the Selenium Webdriver.

If you want, you can read more in the 
[Selenium testing for the web documentation](https://www.selenium.dev/documentation/en/)


## Selenium browsers
Bitbucket pipelines are most know for it's easy to just fetch a Docker image, 
execute some commands and you're done. When you want to run Selenium tests, 
you need a browser instance. Your Selenium testsuite connects with a Selenium
browser instance (or 'node') and executes the commands you want it to.

This browser instance is running on another machine, remotely. The WebDriver
(which is available for all major browsers, and IE Edge 11) connects with this 
instance and reports back to the Selenium testsuite. The Selenium testsuite is
something that you commonly have in your repository. A browser node does not 
live there.

## Services in Bitbucket Pipelines

So if Selenium, on your pipelines-images, needs an external browser, how are 
you going to solve this? The answer is simple: services!

Services are not a very well known thing in pipelines. At least, not by me. 
When I finally discovered them, the combination of my own test-suite and a 
Docker service with a Selenium browser was quickly made.

A service is an _extra_ (Docker) image that's being spun up for the time your 
current 'step' is running. Because Selenium provides  
[it's own official and supported Docker images](https://hub.docker.com/u/selenium)
you are able to run them as a service and interact between your test suite and
the browser node in a single step.

### How to define a service
In your `bitbucket-pipelines.yml` you can add services under the 'definitions'.
Say you want to have a Chrome and a Firefox node, you'll need to add the 
following statements to (the end of) your file:
```yaml
definitions:
  services:
    selenium-chrome:
      image: selenium/standalone-chrome:3.141.59-oxygen
      ports:
        - "4444:4444"
    selenium-firefox:
      image: selenium/standalone-firefox:latest
      ports:
        - "4444:4444"
```

You can select any version you want, just check the DockerHub page for the 
corresponding tag. This allows you to also test against older versions of 
browser, if you need to.

Oh and btw, do you notice the port mappings? Sure you have! These will be
exposed on 'localhost'. So if you want Selenium to connect to a webdriver
you could just use the following line to connect to that service.
```php
$this->webDriver = RemoteWebDriver::create('http://localhost:4444/wd/hub', $capabilities);
```

### Using the service with Selenium / Steward
In the example I'll be using a PHP website installation which needs some 
`composer` dependencies. Also, the Selenium tests are being executed by a
tool named [Steward](https://github.com/lmc-eu/steward), which makes writing
tests easier and takes care of connecting to the browser, creating beautiful 
reports, screenshots, saving html-sources on failures and the lot.
Ofcourse, you can also use Selenium standalone.

In this example Steward is instructed to listen to "localhost:4444" for the
instance of the browser, but you cannot see that in the pipelines-config,
as this config is saved in the repository.

Steward is being installed with the line 
`composer install --no-interaction --working-dir=tests/steward`.
This allows us to only install it on specific cases, rather than including
it as a development dependency, as it installs quite a big heap of ~~shit~~
dependencies. Installing it as a dev dependency is an option of course.

The website we're about to test is also being setup with composer and a
test-db import. After this, it's served with PHP's built-in webserver.

## Final bitbucket-pipelines.yml
So, what will the final BitBucket Pipelines file look like?

A small recap, we will:
  * build the base on a php-pipeline image, which already contains
MySQL;
  * import the test-database;
  * install the Steward testsuite runner
  * install the websites dependencies;
  * start the webserver
  * run the Steward testsuite

This will result in the following `bitbucket-pipelines.yml` file:

```yaml
image: pyguerder/bitbucket-pipelines-php72

pipelines:
  default:
    - step:
        name: Run Steward (Selenium) tests with Chrome
        caches:
          - composer
        artifacts:
          - reports/**
        script:
          - service mysql start
          - mysql -h localhost -u root -proot test < tests/testdb.sql
          - composer install --no-interaction --working-dir=tests/steward
          - composer install --no-interaction
          - php -S 0.0.0.0:80 --docroot src &>/dev/null&
          - cd tests/steward
          - vendor/bin/steward run dev chrome -vv
        services:
          - selenium-chrome

definitions:
  services:
    selenium-chrome:
      image: selenium/standalone-chrome:3.141.59-oxygen
      ports:
        - "4444:4444"
```

## The result after running the testsuite
You can combine multiple steps in Bitbucket Pipelines and you can even use 
multiple services at the same time. I chose to use one service for one step at
this point but I might be combining all the tests together (this will probably
also use less build-minutes).

Anyway, when everything works according to plan (btw, "_I love it when a plan comes
together_") you should see a happy green screen like this:

![](/posts/images/bitbucket-pipelines-result.png "The endresult of Selenium testing in Bitbucket Pipelines") 

There are almost endless possibilities with these ingredients.

Happy testing / pipelining!

**One more thing:** Please be aware that by using a service, your build-minutes will
be doubled. So if you're on a free plan, instead of 50 minutes, 
you will have 25 minutes to build for free.
