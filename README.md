# PLEASE READ

The intention of this work is to have a workable DevBox for local development, simplified and useful for our company development.
Please refer to Magento for latest updates.

# Instructions

1. Prepare your Magento installation (if you have your project already copy under ./shared/webroot)

```
mkdir -p shared
composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition shared/webroot

# Sample data if needed
cd shared/webroot/
php bin/magento sampledata:deploy
cd ../..
```

1. Download docker-compose.yml and edit for your project
```
curl .....docker-compose.yml
#
# Replace YOURPROJECT with the name of your project
#
# sed -i 's/YOURPROJECT/magento2ce/g' docker-compose.yml
#
```

1. Start your docker
```
docker-compose up --build -d
```

1. Create database for installation (or import your database)
```
mysql -h 0.0.0.0 -u root -p
CREATE DATABASE magento2ce;
```

1. Database settings
```
#
# Database Server Host: db
# Database Server Username: root
# Database Server Password: root
```

1. bin/magento access
```
ssh -p 4022 magento2@localhost
```
