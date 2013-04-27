#!/bin/bash
#
################################################################################
#                                                                              #
# fixWPHost - Fix Wordpress database when you change blog domain for multisite #
# wordpress using subfolders Options                                           #
# Copyright (C) 2013 Diego Resendez                                            #
#                                                                              #
# URL:   http://www.GoForLinux.de/scripts/mcurl/                               #
# eMail: Sven.Wegener@Stealer.de                                               #
#                                                                              #
################################################################################


Version="0.1.0"
Prefix="wp_"

# Function to output a warning message
function WarningMessage ()
{
  echo -e "Warning: $1"
}

# Function to output an error message and terminate
function ErrorMessage ()
{
  echo -e "Error: $1"

  exit 1
}
# Output usage information
function OutputUsage ()
{
  echo "fixWPHost - Fix Database host"
  echo "Usage: `basename $0` [options...] [DOMAIN]"
  echo "Options:"
  echo "  -u/--user <user mysql>  Set user for mysql "
  echo "  -d/--database <database mysql>  Set database where modifications will apply "
  echo "  -p/--password <password mysql>  Password for mysql user "
  echo "  -P/--prefix <user mysql>  Wordpress table's prefix "
  echo "  -V/--version <user mysql>  Version of this script "
  echo "  -h/--help             Output this message"
  echo
  

  exit 1
}
if [ "$#" -eq "0" ]; then
  OutputUsage
  exit 0
fi 

# Parse command-line arguments
while [ "$#" -gt "0" ]; do
  case "$1" in
   
    -h|--help)
      # Output usage information
      OutputUsage
    ;;

    -d|--database)
      DATABASE_MYSQL="$2"
      shift 2
    ;;

    -p|--password)
      PASS_MYSQL="$2"
      shift 2
    ;;

    -P|--prefix)
      Prefix="$2"
      shift 2
    ;;

    -u|--user)
      USER_MYSQL="$2"
      shift 2
    ;;
     
    -V|--version)
      # Output version information
      echo "fixWPHost v$Version"
      exit 0
    ;;

    -*|--*)
      # Unknown option found
      ErrorMessage "Unknown option $1."

      exit 1
    ;;

    *)
      # Seems this is the URL
      DOMAIN="$1"
      break
    ;;  
  esac
  
done

if [ -z $USER_MYSQL ]; then
   ErrorMessage 'Please enter a username for mysql'
fi

if [ -z $DATABASE_MYSQL ]; then
   ErrorMessage 'Please enter a valid database'
fi

if [ -z $DOMAIN ]; then
   ErrorMessage 'Enter the DOMAIN to modify WP Site url'
fi

if [ -z $PASS_MYSQL ]; then
   read -e -s -p "Enter mysql password for ${USER_MYSQL}:" PASS_MYSQL
   echo
fi

#regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'

#if [[ ! $URL =~ $regex ]]; then
#  ErrorMessage "$URL must be a valid URL"
#fi
mysql -u "$USER_MYSQL" -p"$PASS_MYSQL" --database="$DATABASE_MYSQL" << EOF
update wp_site set domain="$DOMAIN";
update wp_blogs set domain="$DOMAIN";
EOF

BLOGS=($(mysql -u $USER_MYSQL -p$PASS_MYSQL --database=$DATABASE_MYSQL -e"select blog_id from wp_blogs"))

for i in "${BLOGS[@]:1}"
do
BLOG="${Prefix}${i}_options"
SUBBLOG=($(mysql -u $USER_MYSQL -p$PASS_MYSQL --database=$DATABASE_MYSQL -e"SELECT CONCAT(domain,path) as subblog FROM wp_blogs WHERE blog_id=${i}"))
mysql -u "$USER_MYSQL" -p"$PASS_MYSQL" --database="$DATABASE_MYSQL" << EOF
Update $BLOG SET option_value="http://${SUBBLOG[1]}" WHERE option_name='siteurl';
Update $BLOG SET option_value="http://${SUBBLOG[1]}" WHERE option_name='home';
EOF
done
