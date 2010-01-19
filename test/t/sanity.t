# vi:filetype=perl

use lib 'lib';
use Test::Nginx::Socket;

repeat_each(1);

plan tests => repeat_each() * 2 * blocks() + 2 * repeat_each() * 2;

run_tests();

no_diff();

__DATA__

=== TEST 1: sanity
little-endian systems only

db init:

create table cats (id integer, name text);
insert into cats (id) values (2);
insert into cats (id, name) values (3, 'bob');

--- http_config
    upstream backend {
        drizzle_server 127.0.0.1:3306 dbname=test
             password=some_pass user=monty protocol=mysql;
    }
--- config
    location /mysql {
        drizzle_pass backend;
        #drizzle_dbname $dbname;
        drizzle_query 'select * from cats';
        rds_json on;
    }
--- request
GET /mysql
--- response_headers_like
X-Resty-DBD-Module: ngx_drizzle \d+\.\d+\.\d+
Content-Type: application/json
--- response_body chomp
[{"id":2,"name":null},{"id":3,"name":"bob"}]
--- timeout: 15



=== TEST 2: keep-alive
little-endian systems only

db init:

create table cats (id integer, name text);
insert into cats (id) values (2);
insert into cats (id, name) values (3, 'bob');

--- http_config
    upstream backend {
        drizzle_server localhost dbname=test
             password=some_pass user=monty protocol=mysql;
        drizzle_keepalive max=1;
    }
--- config
    location /mysql {
        drizzle_pass backend;
        #drizzle_dbname $dbname;
        drizzle_query 'select * from cats';
        rds_json on;
    }
--- request
GET /mysql
--- response_body chop
[{"id":2,"name":null},{"id":3,"name":"bob"}]



=== TEST 3: update
little-endian systems only

db init:

create table cats (id integer, name text);
insert into cats (id) values (2);
insert into cats (id, name) values (3, 'bob');

--- http_config
    upstream backend {
        drizzle_server 127.0.0.1:3306 dbname=test
             password=some_pass user=monty protocol=mysql;
        drizzle_keepalive mode=single max=2 overflow=reject;
    }
--- config
    location /mysql {
        drizzle_pass backend;
        #drizzle_dbname $dbname;
        drizzle_query "update cats set name='bob' where name='bob'";
        rds_json on;
    }
--- request
GET /mysql
--- response_body chop
{"errcode":0,"errstr":Rows matched: 1  Changed: 0  Warnings: 0"}


=== TEST 4: select empty result
little-endian systems only

db init:

create table cats (id integer, name text);
insert into cats (id) values (2);
insert into cats (id, name) values (3, 'bob');

--- http_config
    upstream backend {
        drizzle_server 127.0.0.1:3306 dbname=test
             password=some_pass user=monty protocol=mysql;
        drizzle_keepalive mode=multi max=1;
    }
--- config
    location /mysql {
        drizzle_pass backend;
        drizzle_query "select * from cats where name='tom'";
        rds_json on;
    }
--- request
GET /mysql
--- response_body chop
[]



=== TEST 5: update & no module header
little-endian systems only

db init:

create table cats (id integer, name text);
insert into cats (id) values (2);
insert into cats (id, name) values (3, 'bob');

--- http_config
    upstream backend {
        drizzle_server 127.0.0.1:3306 dbname=test
             password=some_pass user=monty protocol=mysql;
        drizzle_keepalive mode=single max=2 overflow=reject;
    }
--- config
    location /mysql {
        drizzle_pass backend;
        drizzle_module_header off;
        drizzle_query "update cats set name='bob' where name='bob'";
        rds_json on;
    }
--- request
GET /mysql
--- response_headers
X-Resty-DBD-Module: 
Content-Type: application/json
--- response_body chop
{"errcode":0,"errstr":Rows matched: 1  Changed: 0  Warnings: 0"}
