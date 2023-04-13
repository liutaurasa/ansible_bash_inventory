# ansible_bash_inventory
Proof of concept of dynamic inventory for Ansible using bash

Quick start
1. Create SQLite3 database file
```
sqlite3 ansible.sqlite
```
2. Create tables in database:
```
CREATE TABLE ansible_hosts (ID INTEGER PRIMARY KEY, host_name TEXT NOT NULL, ansible_host TEXT NOT NULL, ansible_user TEXT, ansible_group_id INTEGER, ansible_vars TEXT, FOREIGN KEY (ansible_group_id) REFERENCES ansible_groups (ID));

CREATE TABLE ansible_groups (ID INTEGER PRIMARY KEY, group_name TEXT NOT NULL, ansible_vars TEXT);
```
3. Insert data
```
INSERT INTO ansible_groups (0, 'all');
INSERT INTO ansible_groups VALUES (0, 'all');
INSERT INTO ansible_groups VALUES (1, 'linux', '{"custom_group_variable": "bb"}');
INSERT INTO ansible_groups VALUES (1, 'windows',);
INSERT INTO ansible_groups VALUES (2, 'windows');
INSERT INTO ansible_groups VALUES (3, 'switches');
INSERT INTO ansible_hosts VALUES (1, 'linux1', '10.0.0.15', 'roman', 1, '{"custom_host_variable": "aaa"}');
INSERT INTO ansible_hosts VALUES (2, 'linux2', '10.0.0.16', 'liutauras', 1, '{"custom_host_variable": "aaa"}');
INSERT INTO ansible_hosts VALUES (1, 'windows1', '10.0.0.17', 'roman', 2);
INSERT INTO ansible_hosts VALUES (3, 'windows1', '10.0.0.17', 'roman', 2);
INSERT INTO ansible_hosts VALUES (3, 'windows2', '10.0.0.18', 'liutauras', 2);
INSERT INTO ansible_hosts VALUES (4, 'windows2', '10.0.0.18', 'liutauras', 2);
```
4. Run the `inventory.sh` with ansible:
```
ansible-inventory --graph all -i inventory.sh --vars
```
