
-- view for all commits to a branch
-- -- upload_file()  
-- -- branch table   
-- -- create_branch() function
-- -- merge_branches() function
-- -- add_commit()
-- -- fork()
-- -- edit file()
-- -- move file()
-- -- delete file()
-- -- delete repo()
-- -- delete account()
-- request_access()


DROP EXTENSION IF EXISTS pgcrypto;
DROP TABLE IF EXISTS commit CASCADE;
DROP TABLE IF EXISTS tag CASCADE;
DROP TABLE IF EXISTS file CASCADE;
DROP TABLE IF EXISTS comment CASCADE;
DROP TABLE IF EXISTS collaborate CASCADE;
DROP TABLE IF EXISTS access CASCADE;
DROP TABLE IF EXISTS fork CASCADE;


DROP TABLE IF EXISTS developer CASCADE;
DROP TABLE IF EXISTS repository CASCADE;
CREATE EXTENSION IF NOT EXISTS pgcrypto;


-----------------------developer table------------------------------------
CREATE TABLE developer(                                                 --    
   developer_id SERIAL PRIMARY KEY,                                    --
   user_name VARCHAR(100) UNIQUE NOT NULL,                             --
   name VARCHAR(100) NOT NULL,                                         --
   email VARCHAR(100) UNIQUE NOT NULL,                                 -- |||||||||||||||||||||||||||||||
                                                                       -- |||||   DEVELOPER TABLE   |||||
   encrypted_password VARCHAR(100) NOT NULL,                           -- |||||||||||||||||||||||||||||||  
   num_repos INT DEFAULT 0 CHECK(num_repos >= 0),                      --  
   storage_used INT DEFAULT 0 CHECK(storage_used >= 0),                --  
   total_commits INT DEFAULT 0 CHECK(total_commits >= 0)               --
);                                                                      --
--------------------------------------------------------------------------

-----------------------repository table------------------------------------
CREATE TABLE repository(                                                 --
   repository_id INT PRIMARY KEY,                                        --
   repository_name VARCHAR(100) NOT NULL,                                --
   created_date_time timestamp,                                          --
   owner_id INT NOT NULL,                                                --
   is_public BOOLEAN DEFAULT true,                                       --
   root_id INT,                        /* root of the tree   */          --
   parent_id INT,                      /* parent of the repo */          --
   creator_id INT NOT NULL,            /* worker who created */          --
                                                                         --
   FOREIGN KEY (owner_id)                                                --
   REFERENCES developer(developer_id) ON DELETE CASCADE,                 --
   FOREIGN KEY (creator_id)                                              --
   REFERENCES developer(developer_id) ON DELETE CASCADE,                 --
   FOREIGN KEY (root_id)                                                 --
   REFERENCES repository(repository_id),                                 --
   FOREIGN KEY (parent_id)                                               --
   REFERENCES repository(repository_id)                                  --
);                                                                       --
---------------------------------------------------------------------------

-- owner of the file is the owner of its parent repository
-- creater of the file is any worker (may not be active worker)
-- 3) file table
CREATE TABLE file(
   file_id SERIAL PRIMARY KEY,
   file_name VARCHAR(50) NOT NULL,
   file_type VARCHAR(10),
   size INT DEFAULT 0,
   content text,
   parent_repository_id INT NOT NULL,
   created_date_time timestamp,
   last_update timestamp,
   creator_id INT NOT NULL,
  
   FOREIGN KEY(parent_repository_id)
   REFERENCES repository(repository_id) ON DELETE CASCADE,
   FOREIGN KEY(creator_id)
   REFERENCES developer(developer_id) ON DELETE CASCADE
);


/* creating datatype for different access */
DROP TYPE IF EXISTS access_flag CASCADE;
CREATE TYPE access_flag AS ENUM ('collaborator', 'viewer');


-- 4) access table
CREATE TABLE access(
   repository_id INT,
   developer_id INT,
   access_type access_flag,
  
   PRIMARY KEY(repository_id, developer_id),
   FOREIGN KEY (repository_id)
   REFERENCES repository(repository_id) ON DELETE CASCADE,
   FOREIGN KEY (developer_id)
   REFERENCES developer(developer_id) ON DELETE CASCADE
);


-- commit area includes the following:
--      1) commit_repository_table
--      2) commit_file_table
-- commit_repository_table
-- who can commit?
-- a worker can commit
--          1) a owner is a worker
--          2) a collabarator is a worker
DROP TABLE IF EXISTS commit_repository CASCADE;
CREATE TABLE commit_repository(
   repository_id INT PRIMARY KEY,
   repository_name VARCHAR(100) NOT NULL,
   created_date_time timestamp,
   owner_id INT NOT NULL,
   is_public BOOLEAN DEFAULT true,
   parent_id INT,
   root_id INT,
  
   FOREIGN KEY (owner_id)
   REFERENCES developer(developer_id)
   ON DELETE CASCADE
);


-- commit_file_table
DROP TABLE IF EXISTS commit_file_table CASCADE;
CREATE TABLE commit_file_table(
   file_id SERIAL PRIMARY KEY,
   file_name VARCHAR(50) NOT NULL,
   file_type VARCHAR(10),
   size INT DEFAULT 0,
   content text,
   parent_repository_id INT NOT NULL,
   created_date_time timestamp,
   last_update timestamp,
  
   FOREIGN KEY (parent_repository_id)
   REFERENCES commit_repository(repository_id) ON DELETE CASCADE
);


-- branch is a weak entity
-- branch does not exist if repository for which developer is direct parent does not exists
-- there could be multiple branches with same repository and developer_id
DROP TABLE IF EXISTS branch CASCADE;
CREATE TABLE branch(
   branch_id INT PRIMARY KEY,
   branch_name VARCHAR NOT NULL,
   repository_id INT NOT NULL,                         /* repository id */
   creator_id INT,                                     /* developer id  */
  
   FOREIGN KEY (repository_id)
   REFERENCES repository(repository_id) ON DELETE CASCADE,
   FOREIGN KEY (creator_id)
   REFERENCES developer(developer_id) ON DELETE CASCADE
);


-- commit table
-- a commit is uniquely identified by
--          branch
--          developer
--          repository
--          time (at different times same developer can commit to same branch in same repository)
CREATE TABLE commit(
   commit_id INT PRIMARY KEY,
   repository_id INT,                  /* repository where commit took place                   */
   developer_id INT,                   /* developer who committed                              */
   commit_root_node INT NOT NULL,      /* this points to commit area                           */
   branch_id INT NOT NULL,             /* this points to branch to which a commit belongs to   */
   message VARCHAR(100),
   commit_date_time timestamp,
  
   FOREIGN KEY (repository_id)
   REFERENCES repository(repository_id) ON DELETE CASCADE,
   FOREIGN KEY (developer_id)
   REFERENCES developer(developer_id) ON DELETE CASCADE,
   FOREIGN KEY (commit_root_node)
   REFERENCES commit_repository(repository_id) ON DELETE CASCADE,
   FOREIGN KEY (branch_id)
   REFERENCES branch (branch_id)
);


-----------------------------------------* END OF CREATION OF TABLES *------------------------------------------------------


-----------------------------------------*    FUNCTION: login_user   *------------------------------------------
-- The function login_user
--                  returns developer_id
--                  returns -1
CREATE OR REPLACE FUNCTION login_user(user_name VARCHAR(100), password VARCHAR)
RETURNS INT
AS $$
BEGIN
   IF NOT EXISTS
       (SELECT developer.user_name
       FROM developer
       WHERE developer.user_name = login_user.user_name and
             developer.encrypted_password = (crypt(login_user.password, '$2024$DBMS$fixedsalt')))
   THEN
       RETURN -1;
   END IF;
  
   RETURN  (SELECT developer.developer_id FROM developer WHERE developer.user_name = login_user.user_name and developer.encrypted_password = (crypt(login_user.password, '$2024$DBMS$fixedsalt')));
END;
$$ LANGUAGE plpgsql;


-- The crypt function is a one-way hashing function, meaning it transforms data into a fixed-length string
-- (hash) that cannot be reversed to recover the original data.


-----------------------------------------*    FUNCTION: check_user   *------------------------------------------
-- The function check_user (lookup)
--                  returns true if the input user_name is present (that is the provided user_name is valid)
--                  returns false otherwise
DROP FUNCTION IF EXISTS check_user;
CREATE OR REPLACE FUNCTION check_user(user_name VARCHAR(100))
RETURNS BOOLEAN
AS $$
BEGIN
   RETURN check_user.user_name IN (SELECT developer.user_name FROM developer WHERE developer.user_name = check_user.user_name);
END;
$$ LANGUAGE plpgsql;


-----------------------------------------*    FUNCTION: create_user   *------------------------------------------
-- function create_user
--                  creates user if email, username are not already found in developer table and returns true if valid,
--                  else return false
DROP FUNCTION IF EXISTS create_user;
CREATE OR REPLACE FUNCTION create_user(user_name VARCHAR(100), name VARCHAR(100), email VARCHAR(100), pass VARCHAR(100))
RETURNS BOOLEAN
AS $$
DECLARE
developer_id INT;
repo_name VARCHAR;
BEGIN
   /* checking for uniqueness of user_name and email */
   if (create_user.user_name in (select developer.user_name from developer)) then
       RAISE NOTICE '% user_name already exists!!', create_user.user_name;
       if (create_user.email in (select developer.email from developer)) then
           RAISE NOTICE '% is already linked to an account!!', create_user.email;
       end if;
       return false;
   end if;
  
   /* checking for uniqueness of email */
   if (create_user.email in (select developer.email from developer)) then
       RAISE NOTICE '% is already linked to an account!!', create_user.email;
       return false;
   end if;
  
   /* Inserting into developer table */
   --  password need to be checked
   INSERT INTO developer(user_name, encrypted_password, name, email)
   VALUES (create_user.user_name, (crypt(create_user.pass, '$2024$DBMS$fixedsalt')) , create_user.name, create_user.email);
  
   developer_id := (SELECT developer.developer_id
                    FROM developer
                    WHERE developer.user_name = create_user.user_name);
   /* Every developer has one repository created by octopus */
   /* COALESCE() function returns first non-null expression in its list of arguments */
   repo_name := '@' || user_name;
   INSERT INTO repository(repository_id, repository_name, created_date_time, owner_id, creator_id)
   VALUES ( (SELECT COALESCE(MAX(repository.repository_id), 0) FROM repository) + 1,
            repo_name,
            localtimestamp,
            developer_id,
            developer_id
   );
  
   /* Interactive message */
   RAISE NOTICE 'Welcome to cloud-repository octopus %!!', create_user.name;
   return true;
END;
$$ LANGUAGE plpgsql;
-----------------------------------------*  VIEW : immediate_repos *--------------------------------------------
-- CREATE OR REPLACE VIEW immediate_repos AS
-- SELECT  
-- FROM
-- WHERE


------------------------------ helper functions ------------------------------
CREATE OR REPLACE FUNCTION is_worker(developer_id INT, repository_id INT)
RETURNS BOOLEAN AS $$
BEGIN
   IF is_worker.developer_id = (SELECT owner_id
                                FROM repository
                                WHERE repository.repository_id = is_worker.repository_id)
   THEN
       /* is owner */
       RETURN true;
   END IF;
  
   IF is_worker.developer_id in (SELECT access.developer_id
                                 FROM access
                                 WHERE access.repository_id = is_worker.repository_id AND
                                       access.access_type = CAST('collaborator' AS access_flag))
   THEN
       /* is collaborator */
       RETURN true;
   END IF;
  
   RETURN false;
END;
$$ LANGUAGE plpgsql;


-----------------------------------------*    FUNCTION: create_repo   *------------------------------------------
-- function create_repo
--          create_repo checks all conditions (mentioned in below function) and throws error if any condition fails
--          if all conditions are met, then a new repository and a new link between new repository and parent repository is created
DROP FUNCTION IF EXISTS create_repo;
CREATE OR REPLACE FUNCTION create_repo(repository_name VARCHAR(100), parent_repository_id INT, user_name VARCHAR(100))
RETURNS TABLE (is_created BOOLEAN, msg VARCHAR)
AS $$
DECLARE
dev_id INT;
owner_id INT;
parent_repo_name VARCHAR;
child_repository_id INT;
root_id INT;
BEGIN
   /* repository_name should only contain alphabets, numbers, _ */
   IF repository_name ~ '^[a-zA-Z0-9_]+$' THEN
   ELSE
       RETURN QUERY SELECT false AS is_created, CAST(repository_name || ' contains characters other than alphabets, numbers, _' AS VARCHAR) AS msg;
       RETURN;
   END IF;


   /* invalid user_name */
   IF(check_user(user_name) = false)
   THEN
       RETURN QUERY SELECT false AS is_created, CAST(create_repo.user_name || ' user_name is invalid!!'  AS VARCHAR) AS msg;
       RETURN;
   END IF;
  
   dev_id := (select developer.developer_id
              from developer
              where developer.user_name = create_repo.user_name);
             
   /* checking validity of parent_repository_id */
   if parent_repository_id not in ( select repository.repository_id
                                    from repository)
   THEN
       RETURN QUERY SELECT false AS is_created, CAST(parent_repository_id || ' is not valid repository_id'  AS VARCHAR) AS msg;
       RETURN;
   END IF;
  
   SELECT repository.repository_name, repository.owner_id
   INTO parent_repo_name, owner_id
   FROM repository
   WHERE repository.repository_id = parent_repository_id;
          
   /* checking whether user(dev_id, user_name) is not worker */
   IF is_worker(dev_id, parent_repository_id) = false
   THEN
       RETURN QUERY SELECT false AS is_created, CAST(user_name || ' is not worker of ' || parent_repo_name || '(id = ' || parent_repository_id || ')' AS VARCHAR) AS msg;
       RETURN;
   END IF;
  
   /* repo_name should be different from all its sibling names */
   IF (create_repo.repository_name IN  (SELECT repository.repository_name
                                        FROM repository
                                        WHERE repository.owner_id = dev_id and
                                             repository.parent_id = parent_repository_id))
   THEN
       RETURN QUERY SELECT false AS is_created, CAST(repository_name || ' is already a child of ' || parent_repo_name || '(id = ' || parent_repository_id || '), try with another name!!'  AS VARCHAR) AS msg;
       RETURN;
   END IF;
  
   /* Updating number of repositires of owner */
   UPDATE developer
   SET num_repos = num_repos + 1
   WHERE developer.user_name = create_repo.user_name;
  
   /* Getting unique child repositroy_id */
   child_repository_id = (select max(repository.repository_id) from repository ) + 1;
  
   IF (parent_repo_name ~ '^@.+$')
   THEN
       /* root points to itself       */
       root_id = child_repository_id;
   ELSE
       /* descendent pointing to root */
       root_id = (SELECT repository.root_id
                  FROM repository
                  WHERE repository.repository_id = parent_repository_id);
   END IF;
  
   /* creating a new repository */
   INSERT INTO repository(repository_id, repository_name, created_date_time, owner_id, creator_id, parent_id, root_id)
   VALUES ( child_repository_id,
            create_repo.repository_name,
            localtimestamp,
            owner_id,
            dev_id,
            parent_repository_id,
            root_id);
  
   RETURN QUERY SELECT true AS is_created, CAST(repository_name || ' is created' AS VARCHAR) AS msg;
   RETURN;
END;
$$ LANGUAGE plpgsql;


-----------------------------------------*    FUNCTION: create_file   *------------------------------------------
-- create_file() function
--      create_file() function will check first whether passed arguments are valid (or) not. If they are not valid it returns false
--      if the parameters are valid, a new file and new link between file and parent repository is created
DROP FUNCTION IF EXISTS create_file;
CREATE OR REPLACE FUNCTION  create_file(file_name VARCHAR(50), file_type VARCHAR(10), content text, parent_repository_id INT, developer_user_name VARCHAR(100))
RETURNS TABLE (created BOOLEAN, msg VARCHAR)
AS $$
DECLARE
developer_id INT;
file_size INT;
create_time timestamp;
parent_repository_name VARCHAR;
BEGIN
   /* checking existence of user_name */
   IF (developer_user_name not in (SELECT user_name FROM developer)) THEN
   	   RETURN QUERY SELECT false AS created, CAST(developer_user_name || ' is invalid!!' AS VARCHAR) AS msg;
       RETURN;
   END IF;
   developer_id := (SELECT developer.developer_id FROM developer WHERE user_name = developer_user_name);
  
   /* checking existence of parent_repository_id */
   IF (parent_repository_id not in (SELECT repository_id FROM repository WHERE repository.owner_id = developer_id)) THEN
   		RETURN QUERY SELECT false AS created, CAST('repository of id ='  || parent_repository_id ||  ', is not present in ' || developer_user_name ||  ' repositires' AS VARCHAR) AS msg;
        RETURN;
   END IF;
   parent_repository_name := (SELECT repository_name FROM repository WHERE repository_id = parent_repository_id AND repository.owner_id = developer_id);
   
   /* developer_user_name should be worker of parent_repository */
   IF (is_worker(developer_id, parent_repository_id) = false)
   THEN
   		RETURN QUERY SELECT false AS created, CAST(developer_user_name || 'is not a worker of repository ' || parent_repository_name || '( id = ' || parent_repository_id || ')' AS VARCHAR) AS msg;
        RETURN;
   END IF;
   
   /* file_name should not already be present in children files of parent repository */
   /* note that there may exist child repo with name same as file_name */
   /* file_name with different file types can be siblings */
   IF (file_name in (SELECT file.file_name
                     FROM file
                     WHERE file.parent_repository_id = create_file.parent_repository_id and
                           file.file_type = create_file.file_type))
   THEN
   	   RETURN QUERY SELECT false AS created, CAST(file_name || ' ' || file_type || ' is already child of ' || parent_repository_name || '(id =' || parent_repository_id || ') of developer ' || developer_user_name AS VARCHAR) AS msg;
       RETURN ;
   END IF;
  
   file_size := LENGTH(content);
   create_time := localtimestamp;
  
   /* updating developer table */
   UPDATE developer
   SET storage_used = storage_used + file_size
   WHERE developer.user_name = developer_user_name;
  
   /* inserting into file table */
   INSERT INTO file(file_name, file_type, size, content, parent_repository_id, created_date_time, last_update, creator_id)
   VALUES (create_file.file_name, create_file.file_type, file_size, content, parent_repository_id, create_time, create_time, developer_id);
  
   RETURN QUERY SELECT true AS created, CAST(file_name || ' file created in ' || parent_repository_name || ' (id = ' || parent_repository_id || ')' || ' of ' || developer_user_name AS VARCHAR) AS msg;
   RETURN ;
END;
$$ LANGUAGE plpgsql;


-- function make_private()
--      if repository is made private then with the help of trigger, all its descendents are also made private
-- subtle point: Can any repository made private?? or only repostries who are directly owned ny developer can be made private ?????
CREATE OR REPLACE FUNCTION make_private(repository_id INT, owner_user_name VARCHAR)
RETURNS BOOLEAN
AS $$
DECLARE
owner_id INT;
repository_name VARCHAR;
BEGIN
   /* checking existence of owner_user_name */
   IF owner_user_name not in (SELECT user_name FROM developer)
   THEN
       RAISE NOTICE '% is not present', owner_user_name;
       RETURN false;
   END IF;
   owner_id := (SELECT developer.developer_id FROM developer WHERE developer.user_name = owner_user_name);
  
   /* checking existence of repository_id */
   IF repository_id not in (SELECT repository.repository_id FROM repository)
   THEN
       RAISE NOTICE 'repository with id = % is not present', repository_id;
       RETURN false;
   END IF;
   repository_name := (SELECT repository.repository_name FROM repository WHERE repository.repository_id = make_private.repository_id);
  
   /* checking ownership of owner_user_name */
   IF owner_id <> (SELECT repository.owner_id FROM repository WHERE repository.repository_id = make_private.repository_id)
   THEN
       RAISE NOTICE '% is not owner of %(ID = %)', owner_user_name, repository_name, repository_id;
       RETURN false;
   END IF;
  
   /* making repository private */
   UPDATE repository
   SET is_public = false
   WHERE repository.repository_id = make_private.repository_id;   
   RAISE NOTICE 'successfully made private';
   RETURN true;
END;
$$ LANGUAGE plpgsql;

-- creating a trigger for the following scinerio
--          whenever a repository is made private
--          then all its descendant repositries are also made private with the help of trigger
-- recursive in natrue
CREATE OR REPLACE FUNCTION procedure_make_private()
RETURNS TRIGGER AS $$
BEGIN
   IF NOT NEW.is_public THEN
       /* Make descendent repositories private */
       UPDATE repository
       SET is_public = false
       WHERE repository_id IN (
           SELECT repository_id
           FROM repository
           WHERE repository.parent_id = NEW.repository_id);
   END IF;
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER trigger_make_private
BEFORE UPDATE OF is_public ON repository
FOR EACH ROW
EXECUTE FUNCTION procedure_make_private();


--------------------------------------------* API : read_file *-----------------------------------------------------------
CREATE OR REPLACE FUNCTION read_file(parent_repository_id INT, file_name VARCHAR, developer_user_name VARCHAR)
RETURNS TABLE (is_readable BOOLEAN, content text) AS $$
BEGIN
  
END;
$$ LANGUAGE plpgsql;


--------------------------------------------------* grant_or_update_access *--------------------------------------------------
-- function grant_or_update_access
--          will grant (or) undate access if inputs are valid
-- NOTE: A owner by default has edit, read access of a repository.
--       In this design, collaborator is one who has edit and read access of repository.(which genrally is the case)
--                       viewer is the one who has read only access
--       Only owner can grant access
CREATE OR REPLACE FUNCTION grant_or_update_access(owner_user_name VARCHAR, repository_id INT, to_user_name VARCHAR, access_type VARCHAR)   
RETURNS TABLE (given BOOLEAN, msg VARCHAR)
AS $$
DECLARE
   from_id INT;
   to_id INT;
BEGIN
   /* checking for validity of owner_user_name */
   IF (check_user(owner_user_name) = false) THEN
       RETURN QUERY SELECT false, CAST(owner_user_name || ' username is not present' AS VARCHAR) AS msg;
       RETURN;
   END IF;
  
   /* checking for validity of to_user_name */
   IF (check_user(to_user_name) = false) THEN
       RETURN QUERY SELECT false, CAST(to_user_name || ' username is not present' AS VARCHAR) AS msg;
       RETURN;
   END IF;


   from_id := (SELECT developer_id FROM developer WHERE developer.user_name = grant_or_update_access.owner_user_name);
   to_id   := (SELECT developer_id FROM developer WHERE developer.user_name = grant_or_update_access.to_user_name);


   /* checking for validity of repository_id */
   IF repository_id NOT IN (SELECT repository.repository_id
                            FROM repository
                            WHERE repository.repository_id = grant_or_update_access.repository_id and
                                   repository.owner_id = from_id)
   THEN
       RETURN QUERY SELECT false AS given, CAST('repository of id = ' || repository_id || ' is not owned by ' || owner_user_name AS VARCHAR) AS msg;
       RETURN;
   END IF;
  
   /* check if the to_user_name has some access to repo */
   IF EXISTS (SELECT access.repository_id
              FROM access
              WHERE access.repository_id = grant_or_update_access.repository_id and
                    access.developer_id = to_id)
   THEN
       /* there exists some access permission to to_user_name */
       UPDATE access
       SET access_type = CAST(grant_or_update_access.access_type AS access_flag)
       WHERE access.repository_id = grant_or_update_access.repository_id and
             access.developer_id = to_id;
       RETURN QUERY SELECT true AS given, CAST('Access updated!!' AS VARCHAR) AS msg;
   ELSE
       /* grant access */
       INSERT INTO access(repository_id, developer_id, access_type)
       VALUES  (grant_or_update_access.repository_id, to_id, CAST(grant_or_update_access.access_type AS access_flag));


       RETURN QUERY SELECT true AS given, CAST('Access granted!!' AS VARCHAR) AS msg;
   END IF;
END;
$$ LANGUAGE plpgsql;




------------------------------------------trigger-------------------------------------------------------------
-- creating a trigger for the following scinerio                                                            --
--          whenever a user is given access to a repository                                                 --
--          then all its descendant repositries are also given access with the help of recursive trigger    --
CREATE OR REPLACE FUNCTION function_grant_or_update_access()                                                --
RETURNS TRIGGER AS $$                                                                                       --
DECLARE                                                                                                     --
   children CURSOR FOR                                                                                     --
           (SELECT repository_id                          
            FROM  repository                              
            WHERE repository.parent_id = NEW.repository_id);
   child RECORD;                                                                                           --
   prev_access_type access_flag;                                                                           --
BEGIN
   IF (TG_OP = 'INSERT') THEN
       /* for insert operation */
           OPEN children;
           LOOP
               FETCH children INTO child;
               EXIT WHEN NOT FOUND;
              
               SELECT access.access_type
               INTO prev_access_type
               FROM access
               WHERE access.repository_id = child.repository_id and
                     access.developer_id = NEW.developer_id;
                    
               IF prev_access_type IS NOT NULL
               THEN
                   /* Then there exists some access tuple related to child, developer */
                   IF prev_access_type <> NEW.access_type
                   THEN
                       /* need to update the access flag */
                       UPDATE access
                       SET access_type = NEW.access_type
                       WHERE access.repository_id = child.repository_id and
                             access.developer_id = NEW.developer_id;
                   END IF;
               ELSE
                   /* There is no tuple in access table related to child, developer */
                   /* So need to insert into access table                           */
                   INSERT INTO access(repository_id, developer_id, access_type)
                   VALUES (child.repository_id, NEW.developer_id, NEW.access_type);
               END IF;
           END LOOP;
           CLOSE children;
   ELSIF (TG_OP = 'UPDATE') THEN
       /* for update operation                                                 */
       /* when parent repo is getting updated, then child repo must be updated */
       /* thanks to invariant                                                  */
           OPEN children;
           LOOP
               FETCH children INTO child;
               EXIT WHEN NOT FOUND;


               UPDATE access
               SET access_type = NEW.access_type
               WHERE access.repository_id = child.repository_id and
                     access.developer_id = NEW.developer_id;
           END LOOP;
           CLOSE children;                                                                                 --
   END IF;                                                                                                 --
   /* Thanks to recursion !! */                                                                            --
   RETURN NEW;                                                                                             --
END;                                                                                                   --
$$ LANGUAGE plpgsql;                                                                                        --
                                                                                                           --
CREATE OR REPLACE TRIGGER trigger_grant_or_update_access                                                    --
BEFORE INSERT OR UPDATE ON access                                                                           --
FOR EACH ROW                                                                                                --
EXECUTE FUNCTION function_grant_or_update_access();                                                         --
--------------------------------------------------------------------------------------------------------------


-----------------------------------------*        add_commit         *------------------------------------------------------
CREATE OR REPLACE FUNCTION add_commit(repository_id INT, branch_id INT, user_name VARCHAR)                                --
RETURNS TABLE(status BOOLEAN, msg VARCHAR)
AS $$
DECLARE
   branch_id INT;
   developer_id INT;
BEGIN
   /* checking for valid user_name */
   IF (check_user(user_name) == false)
   THEN
       RETURN QUERY SELECT false AS status, CAST('Invalid user_name' AS VARCHAR) AS msg;
       RETURN;
   END IF;
  
   /* checking for validity of branch id */
   IF branch_id NOT IN (SELECT branch.branch_id FROM branch WHERE branch)
   THEN
       RETURN QUERY SELECT false AS status, CAST('Invalid branch' AS VARCHAR) AS msg;
       RETURN;
   END IF;
  
END;
$$ LANGUAGE plpgsql;
-----------------------------------------------------------------------------------------------------------------------------




-----------------------------------------*      test area start      *-----------------------------------------


SELECT create_user('_sandeep_', 'sandeep reddy', '112101011@smail.iitpkd.ac.in', '2122');
SELECT * FROM developer;
SELECT login_user('_sandeep_', '2122');
select create_repo('DBMS', 1, '_sandeep_');
select create_repo('Compilers', 1, '_sandeep_');
select create_repo('OELP', 1, '_sandeep_');


select create_repo('Lab1', 2, '_sandeep_');
select create_repo('Lab2', 2, '_sandeep_');
select create_repo('Lab1', 3, '_sandeep_');
select create_repo('Lab2', 3, '_sandeep_');
select create_repo('References', 7, '_sandeep_');


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
SELECT create_file('compiler', 'l', 'ffdfdfdffddf ', 7, '_sandeep_');
SELECT create_file('compiler', 'y', ' ', 7, '_sandeep_');
SELECT create_file('compiler', 'l', ' ', 8, '_sandeep_');
SELECT create_file('compiler', 'y', ' ', 8, '_sandeep_');


SELECT * FROM repository;




/* making Compilers repository private */
SELECT make_private(3, '_sandeep_');
SELECT * FROM file;


-- /* creating developer _manish_ */
SELECT create_user('_manish_', 'Manish M H', '112101002@smail.iitpkd.ac.in', '2123');
SELECT * FROM developer;
SELECT * FROM repository;


-- /* granting access to _manish_ */
SELECT * FROM access;
-- beauty of octopus is that, you can grant access to any repository (need not be root)
-- github doesn't allow it !!
SELECT * FROM access; give access to any sub-repositry, and not access to only repositries directly parented by developer


SELECT grant_or_update_access('_sandeep_', 7, '_manish_', 'collaborator');


SELECT grant_or_update_access('_sandeep_', 7, '_manish_', 'viewer');
SELECT * FROM access;


SELECT grant_or_update_access('_sandeep_', 3, '_manish_', 'collaborator');
SELECT * FROM access;






-----------------------------------------*       test area end       *---------------------------------------------------------
-- -- procedure add_comment
-- --        adds comment to the comment_table provided if the given inputs repository_id, user_name are valid
-- -- NOTE: 1) We cannot take only repository_name as input parameter for adding comment because there could be multiple repositires with same repository_name
-- --        2) The current database design supports that any user of OCTOPUS can comment on a repository, if the repository is public (or) he is the owner of the repository (or) collaborator of the repository (or) has access (view basically) to the repository.
-- --           (that is having at least view access)
-- DROP PROCEDURE IF EXISTS add_comment;
-- CREATE OR REPLACE PROCEDURE add_comment(owner_user_name VARCHAR, repository_name VARCHAR, user_name VARCHAR(100), message VARCHAR(100))
-- AS $$
-- DECLARE
-- repo_id INT;
-- have_permission BOOLEAN DEFAULT false;
-- invoke_id INT;
-- BEGIN
--  repo_id := (SELECT repository.repository_id FROM repository JOIN developer ON repository.owner_id = developer.developer_id
--             WHERE repository.repository_name = add_comment.repository_name AND developer.user_name = owner_user_name);
--  IF ((repo_id IN  (SELECT repository.repository_id FROM repository)) AND
--      (add_comment.user_name IN (SELECT developer.user_name FROM developer))) THEN
--      -- given repository_id and user_name are valid
--      invoke_id = (select developer_id FROM developer WHERE developer.user_name = add_comment.user_name);
      
--      IF ((select is_public FROM repository WHERE repository.repository_id = repo_id) = true) then
--          /* public repository */
--          have_permission := true;
--      ELSIF ((select owner_id FROM repository WHERE repository.repository_id = repo_id) = invoke_id) THEN
--          /* is owner */
--          have_permission := true;
--      ELSIF ( invoke_id IN (SELECT collaborate.developer_id FROM collborate WHERE collaborate.repository_id = repo_id)) THEN
--          /* collaborator */
--          have_permission := true;
--      ELSIF (invoke_id IN (SELECT access.developer_id FROM access WHERE access.repository_id = repo_id)) THEN
--          /* private view access */
--          have_permission := true;
--      END IF;
      
--      IF (have_permission) THEN
--          INSERT INTO comment(repository_id, developer_id, message, comment_date_time)
--          VALUES (repo_id,
--                  invoke_id,
--                  add_comment.message,
--                  localtimestamp);
--          RAISE NOTICE 'Comment added!!';        
--      ELSE
--          RAISE NOTICE 'From procedure add_comment: No access for % to comment repository with repository_id %!!', add_comment.user_name, repo_id;
--      END IF;
--  ELSE
--      RAISE NOTICE 'Invalid input!!';
--  END IF;
-- END;
-- $$ LANGUAGE plpgsql;


-- -- 5) comment table
-- CREATE TABLE comment(
--  repository_id INT,
--  developer_id INT,
--  comment_id SERIAL,
--  message VARCHAR(100),
--  comment_date_time timestamp,
  
--  PRIMARY KEY(repository_id, developer_id, comment_id),
--  FOREIGN KEY (repository_id)
--  REFERENCES repository(repository_id) ON DELETE CASCADE,
--  FOREIGN KEY (developer_id)
--  REFERENCES developer(developer_id) ON DELETE CASCADE
-- );


-- -- 9) tag table
-- CREATE TABLE tag(
--  repository_id INT,
--  developer_id INT,
--  tag_id INT,
--  commit_id INT,
--  tag_name VARCHAR(50) NOT NULL,
--  tag_date_time timestamp,
  
--  PRIMARY KEY(repository_id, developer_id, tag_id),
--  FOREIGN KEY (repository_id) REFERENCES repository(repository_id),
--  FOREIGN KEY (developer_id) REFERENCES developer(developer_id),
--  FOREIGN KEY (commit_id) REFERENCES commit(commit_id)
-- );