PostgreSQL 9.5 Docker image
===========================

This container image includes PostgreSQL database server version 9.5 based on CentOS.

The CentOS image is available on [Docker Hub](https://hub.docker.com/r/ravensys/postgres) as 
`ravensys/postgresql:9.5-centos7`.


Description
-----------

This container image provides a containerized packaging of the PostgreSQL postgres daemon and client application.
The postgres server daemon accepts connections from clients and provides access to content from PostgreSQL databases
on behalf of the clients. You can find more information on the PostgreSQL project from the project Web site 
(https://www.postgresql.org/).


Usage
-----

If the database data directory is not initialized, the entrypoint script will first run `initdb` and setup necessary
database users and password. After database is initialized, or if it was already present, `postgres` is executed and
will run as PID 1.

* **Simple user with database**

    This will create a container named `postgresql_database` running PostgreSQL with database named `db` and user with
    credentials `user:pass`. Port 5432 will be exposed and mapped to host.
    
    ```
    $ docker run -d --name postgresql_database -e POSTGRESQL_USER=user -e POSTGRESQL_PASSWORD=pass -e POSTGRESQL_DATABASE=db -p 5432:5432 ravensys/postgresql:9.5-centos7
    ```

* **Simple user without database**

    This will create a container named `postgresql_database` running PostgreSQL with user with credentials `user:pass` and
    admin with credentials `postgres:rootpass`. Port 5432 will be exposed and mapped to host.
    
    ```
    $ docker run -d --name postgresql_database -e POSTGRESQL_USER=user -e POSTGRESQL_PASSWORD=pass -e POSTGRESQL_ADMIN_PASSWORD=rootpass -p 5432:5432 ravensys/postgresql:9.5-centos7
    ```

* **Only admin account**

    This will create a container named `postgresql_database` running PostgreSQL with admin with credentials
    `postgres:rootpass`. Port 5432 will be exposed and mapped to host.
    
    ```
    $ docker run -d --name postgresql_database -e POSTGRESQL_ADMIN_PASSWORD=rootpass -p 5432:5432 ravensys/postgresql:9.5-centos7
    ```
    
    Alternatively the same configuration can be achieved by setting `POSTGRESQL_USER` environment variable to `postgres`.
    
    ```
    $ docker run -d --name postgresql_database -e POSTGRESQL_USER=postgres -e POSTGRESQL_PASSWORD=rootpass -p 5432:5432 ravensys/postgresql:9.5-centos7
    ```

To make database data persistent across container executions add `-v /host/db/path:/var/lib/pgsql/data` argument to the
Docker run command.

To stop detached container simply run `docker stop postgresql_database`.


Environment variables
---------------------

The image recognizes following environment variables which can be set during initialization by passing `-e VAR=VALUE`
to the Docker run command.

|  Variable name                |  Description                                |
| :---------------------------- | :------------------------------------------ |
|  `POSTGRESQL_ADMIN_PASSWORD`  |  Password for the `postgres` admin account  |
|  `POSTGRESQL_DATABASE`        |  Name of database to be created             |
|  `POSTGRESQL_PASSWORD`        |  Password for the user account              |
|  `POSTGRESQL_USER`            |  Name of user to be created                 |

Following environment variables influence PostgreSQL configuration file. They are all OPTIONAL.

|  Variable name                           |  Description                                                                                                                                                            |  Default                                                 |
| :--------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------- |
|  `POSTGRESQL_EFFECTIVE_CACHE_SIZE`       |  Sets the planner's assumption about the effective size of the disk cache that is available to a single query.                                                          |  128MB (or 50% of available memory)                      |
|  `POSTGRESQL_MAINTENANCE_WORK_MEM`       |  Specifies the maximum amount of memory to be used by maintenance operations, such as VACUUM, CREATE INDEX, and ALTER TABLE ADD FOREIGN KEY.                            |  32MB (or 12.5% of available memory)                     |
|  `POSTGRESQL_MAX_CONNECTIONS`            |  The maximum number of concurrent connections to the database server.                                                                                                   |  100                                                     |
|  `POSTGRESQL_MAX_PREPARED_TRANSACTIONS`  |  Sets the maximum number of transactions that can be in the "prepared" state simultaneously. Setting this parameter to zero disables the prepared-transaction feature.  |  0                                                       |
|  `POSTGRESQL_SHARED_BUFFERS`             |  Sets the amount of memory the database server uses for shared memory buffers.                                                                                          |  64MB (or 25% of available memory)                       |
|  `POSTGRESQL_WORK_MEM`                   |  Specifies the amount of memory to be used by internal sort operations and hash tables before writing to temporary disk files.                                          |  640kB (or 25% of available memory / `max_connections`)  |-


Secrets
-------

The image recognizes following secrets which can be created by running `echo <value> | docker secret create <name>`.

Default secret name can be changed by setting respective environment variable during initialization, value represents 
a relative path to a file located in secrets volume.

|  Secret name                  |  Description                                |  Environment variable                |
| :---------------------------- | :------------------------------------------ | :----------------------------------- |
|  `postgresql/admin_password`  |  Password for the `postgres` admin account  |  `POSTGRESQL_ADMIN_PASSWORD_SECRET`  |
|  `postgresql/database`        |  Name of database to be created             |  `POSTGRESQL_DATABASE_SECRET`        |
|  `postgresql/password`        |  Password for the user account              |  `POSTGRESQL_PASSWORD_SECRET`        |
|  `postgresql/user`            |  Name of user to be created                 |  `POSTGRESQL_USER_SECRET`            |

**Notice: Secrets takes precedence over environment variables, if both secret and environment variable are set, the 
value from secret is used.**


Volumes
-------

The following mount points can be set by passing `-v /host/path:/container/path` to the Docker run command.

|  Volume mount point     |  Description                |
| :---------------------- | :-------------------------- |
|  `/var/lib/pgsql/data`  |  PostgreSQL data directory  |

**Notice: When mounting a directory from host into container, ensure that the mounted directory has appropriate
permissions and that owner and group of directory matches UID of user running inside container.**


PostgreSQL auto-tuning
----------------------

When PostgreSQL image is run with the `--memory` parameter set and if there are no values provided for these
environment variables, their values will be automatically calculated based on available memory.

|  Variable name                      |  Configuration parameter  |  Relative value           |
| :---------------------------------- | :------------------------ | :------------------------ |
|  `POSTGRESQL_EFFECTIVE_CACHE_SIZE`  |  `effective_cache_size`   |  50%                      |
|  `POSTGRESQL_MAINTENANCE_WORK_MEM`  |  `maintenance_work_mem`   |  12.5%                    |
|  `POSTGRESQL_SHARED_BUFFERS`        |  `shared_buffers`         |  25%                      |
|  `POSTGRESQL_WORK_MEM`              |  `work_mem`               |  25% / `max_connections`  |


PostgreSQL admin account
------------------------

The admin account `postgres` has no password set by default, only allowing local connections. 
To allow `postgres` user login remotely the `POSTGRESQL_ADMIN_PASSWORD` environment variable must be set when 
initializing container. Local connections will still not require password.


PostgreSQL unprivileged account
-------------------------------

The unprivileged user account with `POSTGRESQL_USER` name is created, authenticated by password set in 
`POSTGRESQL_PASSWORD`, with owner privileges to database `POSTGRESQL_DATABASE`.


Changing passwords
------------------

Since passwords are part of the image configuration, the only supported method to change passwords for database user
(`POSTGRESQL_USER`) and admin `postgres` is by changing environment variables `POSTGRESQL_PASSWORD` and
`POSTGRESQL_ADMIN_PASSWORD`, respectively.

Changing these database passwords through SQL statements or any way other than through environment variables
aforementioned will cause a mismatch between values stored in variables and actual passwords. Whenever a database
container stars it will reset passwords to values stored in environment variables.


Post-initialization scripts
---------------------------

Image initialization process can by extended by placing sourcable shell scripts, these must have a `.sh` extension,
into post-initialization drop-in `/usr/share/container-entrypoint/postgresql/post-init.d` directory.

* **Mount volume with post-init scripts**
 
    To propagate post-initialization scripts from host into container add volume mount
    `-v /path/to/post-init/scripts:/usr/share/container-entrypoint/postgresql/post-init.d` argument to the Docker 
    run command.

    ```
    $ docker run -d --name postgresql_database -v /path/to/post-init/scripts:/usr/share/container-entrypoint/postgresql/post-init.d -e POSTGRESQL_ADMIN_PASSWORD=rootpass -p 5432:5432 ravensys/postgresql:9.5-centos7
    ```

* **Extend image with post-init scripts** 
    
    This Dockerfile will create Docker image based on `ravensys/postgresql:9.5-centos7` with built-in 
    post-initialization scripts from directory `post-init-scripts`. 
    
    ```dockerfile
    FROM ravensys/postgresql:9.5-centos7
    
    COPY post-init-scripts /usr/share/container-entrypoint/postgresql/post-init.d
    ```


Changing default locale
-----------------------

This Dockerfile will create a Docker image based on `ravensys/postgresql:9.6-centos7` with default locale set to
`de_DE.UTF-8`.

```dockerfile
FROM ravensys/postgresql:9.6-centos7

RUN localedef -f UTF-8 -i de_DE de_DE.UTF-8
ENV LANG de_DE.UTF-8
```


Troubleshooting
---------------

The container initialization scripts logs to the standard output, so these are available in container log.
This log can be examined by running:

```
$ docker logs <container>
```

The postgres daemon in container logs are stored in `pg_log` directory located in postgresql data directory.


See also
--------

Dockerfile and other sources for this container image are available on
https://github.com/ravensys/container-postgresql.
