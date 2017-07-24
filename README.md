PostgreSQL database server Docker image
=======================================

This repository contains Dockerfiles and scripts for PostgreSQL images based on CentOS.


Versions
--------

PostgreSQL versions provided:

* [PostgreSQL 9.4](9.4)
* [PostgreSQL 9.5](9.5)
* [PostgreSQL 9.6](9.6)

CentOS versions supported:

* CentOS 7


Installation
------------

* **CentOS 7 based image**

    This image is available on DockerHub. To download it run:
    
    ```
    $ docker pull ravensys/postgresql:9.6-centos7
    ```

    To build a CentOS based PostgreSQL image from source run:
    
    ```
    $ git clone --recursive https://github.com/ravensys/container-postgresql
    $ cd container-postgresql
    $ make build VERSION=9.6
    ```

For using other versions of PostgreSQL just replace `9.6` value by particular version in commands above.


Usage
-----

For information about usage of Dockerfile for PostgreSQL 9.4 see [usage documentation](9.4).

For information about usage of Dockerfile for PostgreSQL 9.5 see [usage documentation](9.5).

For information about usage of Dockerfile for PostgreSQL 9.6 see [usage documentation](9.6).


Test
----

This repository also provides a test framework, which check basic functionality of PostgreSQL image.

* **CentOS 7 based image**

    ```
    $ cd container-postgresql
    $ make test VERSION=9.6
    ```
    
For using other versions of PostgreSQL just replace `9.6` value by particular version in commands above.


Credits
-------

This project is derived from [`postgresql-container`](https://github.com/sclorg/postgresql-container) by 
[SoftwareCollections.org](https://www.softwarecollections.org).
