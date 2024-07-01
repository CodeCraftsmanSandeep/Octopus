-----------------------------------------*      test area start      *-----------------------------------------
SELECT create_user('_sandeep_', 'sandeep reddy', '112101011@smail.iitpkd.ac.in', '2122');
SELECT * FROM developer;
SELECT * FROM repository;
SELECT * FROM branch;
SELECT login_user('_sandeep_', '2122');
select create_repo('DBMS', 1, '_sandeep_');
select create_repo('Compilers', 1, '_sandeep_');
select create_repo('OELP', 1, '_sandeep_');

select create_repo('Lab1', 2, '_sandeep_');
select create_repo('Lab2', 2, '_sandeep_');
select create_repo('Lab1', 3, '_sandeep_');
select create_repo('Lab2', 3, '_sandeep_');
-- select create_repo('References', 7, '_sandeep_');

-- creating files
SELECT create_file('readme', 'md', 'Name: Chekkala Sandeep Reddy <br/> Roll Number: 112101011 <br/> ', 2, '_sandeep_');
SELECT create_file('code', 'sql', ' SELECT * FROM student; ', 5, '_sandeep_');
SELECT create_file('code', 'sql', '-- Find pairs of films whose lengths are equal, (Here pair is unordered)
                                   SELECT f1.title, f2.title, f1.length
                                   FROM   
                                       film as f1
                                   INNER JOIN  film as f2
                                        ON f1.film_id > f2.film_id AND f1.length = f2.length
                                   ORDER BY f1.length; ', 6, '_sandeep_');
SELECT create_file('compiler', 'l', ' // lex code for lab1 ', 7, '_sandeep_');
SELECT create_file('compiler', 'y', ' // yass code for lab1 ', 7, '_sandeep_');
SELECT create_file('compiler', 'l', ' ', 8, '_sandeep_');
SELECT create_file('compiler', 'y', ' ', 8, '_sandeep_');
SELECT create_file('skip_list', 'c', ' // lex code ', 4, '_sandeep_');
-- creating file directly under universal repository
SELECT create_file('portfolio', 'md', ' <br> </br> ', 1, '_sandeep_');

/* making Compilers repository private */
SELECT change_view(3, '_sandeep_', false);

-- /* creating developer _manish_ */
SELECT create_user('_manish_', 'Manish M H', '112101002@smail.iitpkd.ac.in', '2123');
SELECT * FROM developer;
SELECT * FROM repository;
SELECT * FROM file;
select * from access;

-- /* granting access to _manish_ */
-- beauty of octopus is that, you can grant access to any repository (need not be root)
-- github doesn't allow it !!
SELECT * FROM access; 

-- _manish_ creating repo under References
select create_repo('IIT_PKD', 9, '_manish_');



SELECT * FROM access;

-- creating a branch
-- CREATE OR REPLACE FUNCTION create_branch(branch_name VARCHAR, repository_id INT, developer_user_name VARCHAR)
SELECT create_branch('feature', 7, '_sandeep_');
SELECT create_branch('feature', 6, '_sandeep_');
SELECT create_branch('feature', 1, '_sandeep_');

SELECT * FROM branch;

-- commiting
-- CREATE OR REPLACE FUNCTION add_commit(repository_id INT, branch_name VARCHAR, user_name VARCHAR, message VARCHAR)                            

-- invalid user name
SELECT add_commit(4, 'master', '_kdfmfdkm_', 'commiting oelp');

-- developer is not worker
SELECT add_commit(4, 'master', '_manish_', 'commiting oelp');

-- Invalid branch
SELECT add_commit(4, 'feature', '_sandeep_', 'commiting oelp');

select * from repository;
select * from commit_repository;

-- valid arguments
SELECT add_commit(4, 'master', '_sandeep_', 'commiting oelp');

SELECT add_commit(3, 'feature', '_manish_', 'commiting codes');

SELECT add_commit(8, 'feature', '_manish_', 'commting only Lab2');

SELECT add_commit(3, 'master', '_sandeep_', 'commiting all');

SELECT * FROM repository;

select * from branch;

-- NAME all the branches created by developer _sandeep_
SELECT branch.*
FROM branch, developer
WHERE branch.creator_id = developer.developer_id and
	   developer.user_name = '_sandeep_';

-- Finding all files of developer '_sandeep_'
SELECT file.*
FROM file, repository, developer
WHERE developer.user_name = '_sandeep_' AND
	file.parent_repository_id = repository.repository_id AND
	repository.owner_id = developer.developer_id;

-- find all repositires which can be viewed by _manish_
SELECT repository.*
FROM repository, developer
WHERE developer.user_name = '_manish_' AND
	can_view('_manish_', repository.repository_id)
;

-- granting collabration access of Lab1 of Compilers to _manish_
SELECT grant_or_update_access('_sandeep_', 3, '_manish_', 'collaborator');

SELECT repository.*
FROM repository, developer
WHERE developer.user_name = '_manish_' AND
	can_view('_manish_', repository.repository_id)
;


select * from access;






-- the following gives error message (expected)
SELECT grant_or_update_access('_sandeep_', 7, '_manish_', 'viewer');

-----------------------------------------*       test area end       *---------------------------------------------------------


