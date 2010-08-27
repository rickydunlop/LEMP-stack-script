LEMP Stack Script
=================

This script mainly consists of the work of rnolen's Linode stack script
http://www.linode.com/stackscripts/view/?StackScriptID=41

I have added a function to install git and removed the linode specific parts, so that it can be used anywhere.

Usage
-----

* Set the database password at the top of the script.
* Upload the file to your server
* Run ./lemp-setup.sh
* Remove the script after you have finished (VERY IMPORTANT as it contains your database password in plain text)

TODO
----
* function to install PHP-APC
* mysql_secure_installation
* iptables
