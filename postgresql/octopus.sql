DROP EXTENSION IF EXISTS pgcrypto;
drop table if exists sub_repository CASCADE;
DROP TABLE IF EXISTS commit CASCADE;
DROP TABLE IF EXISTS tag CASCADE;
DROP TABLE IF EXISTS file CASCADE;
DROP TABLE IF EXISTS comment CASCADE;
DROP TABLE IF EXISTS collaborate CASCADE;
DROP TABLE IF EXISTS access CASCADE;
DROP TABLE IF EXISTS fork CASCADE;


DROP TABLE IF EXISTS developer CASCADE;
DROP TABLE IF EXISTS repository CASCADE;
DROP TABLE IF EXISTS copy_repository CASCADE;
DROP TABLE IF EXISTS copy_file CASCADE;

-- copy_repository table
CREATE TABLE copy_repository(
	copy_repository_id SERIAL PRIMARY KEY,
	last_update timestamp, 					/* copied last_update */
	size INT DEFAULT 0 CHECK(size >= 0) 	/* copied size */
);

-- copy_file table
CREATE TABLE copy_file(
	copy_file_id SERIAL PRIMARY KEY,
	file_name VARCHAR(50) NOT NULL,
	size INT DEFAULT 0,
	content text,
	parent_copy_id INT NOT NULL,
	last_update timestamp,
	
	FOREIGN KEY (parent_copy_id) 
	REFERENCES copy_repository(copy_repository_id) ON DELETE CASCADE
);

-- 1) Developer table
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE developer(
	developer_id SERIAL PRIMARY KEY,
	user_name VARCHAR(100) UNIQUE NOT NULL,
	name VARCHAR(100) NOT NULL,
	email VARCHAR(100) UNIQUE NOT NULL,
	encrypted_password VARCHAR(100) NOT NULL,
	num_repos INT DEFAULT 0 CHECK(num_repos >= 0),
	storage_used INT DEFAULT 0 CHECK(storage_used >= 0), 
	total_commits INT DEFAULT 0 CHECK(total_commits >= 0)
);


-- 2) repository table
CREATE TABLE repository(
	repository_id SERIAL PRIMARY KEY,
	repository_name VARCHAR(100) NOT NULL,
	size INT DEFAULT 0 CHECK(size >= 0),
	created_date_time timestamp,
	last_update timestamp,
	owner_id INT NOT NULL,
	is_public BOOLEAN DEFAULT true,
	num_workers INT DEFAULT 1 CHECK(num_workers >= 1),
	FOREIGN KEY (owner_id) 
	REFERENCES developer(developer_id) 
	ON DELETE CASCADE
);

-- 3) sub_repository table
CREATE TABLE sub_repository(
	parent_repo_id INT NOT NULL,
	child_repo_id INT PRIMARY KEY,
	
	FOREIGN KEY(parent_repo_id) 
	REFERENCES repository(repository_id) ON DELETE CASCADE,
	FOREIGN KEY(child_repo_id) 
	REFERENCES repository(repository_id) ON DELETE CASCADE
);


-- 4) collaborate table
CREATE TABLE collaborate(
	repository_id INT,
	developer_id INT,
	
	PRIMARY KEY (repository_id, developer_id),
	FOREIGN KEY (repository_id) 
	REFERENCES repository(repository_id) ON DELETE CASCADE,
	FOREIGN KEY (developer_id) 
	REFERENCES developer(developer_id) ON DELETE CASCADE
);

-- 5) comment table
CREATE TABLE comment(
	repository_id INT,
	developer_id INT,
	comment_id SERIAL, 
	message	VARCHAR(100),
	comment_date_time timestamp,
	
	PRIMARY KEY(repository_id, developer_id, comment_id),
	FOREIGN KEY (repository_id) 
	REFERENCES repository(repository_id) ON DELETE CASCADE,
	FOREIGN KEY (developer_id) 
	REFERENCES developer(developer_id) ON DELETE CASCADE
);

-- 6) access table
CREATE TABLE access(
	repository_id INT,
	developer_id INT,
	
	PRIMARY KEY(repository_id, developer_id),
	FOREIGN KEY (repository_id) 
	REFERENCES repository(repository_id) ON DELETE CASCADE,
	FOREIGN KEY (developer_id) 
	REFERENCES developer(developer_id) ON DELETE CASCADE
);

-- 7) file table
CREATE TABLE file(
	file_id	SERIAL PRIMARY KEY,
	file_name VARCHAR(50) NOT NULL,
	file_type VARCHAR(10),
	size INT DEFAULT 0,
	content text,
	parent_repository_id INT NOT NULL,
	last_update timestamp,
	
	FOREIGN KEY(parent_repository_id) 
	REFERENCES repository(repository_id) ON DELETE CASCADE
);

-- 8) commit table
CREATE TABLE commit(
	commit_id SERIAL,
	repository_id INT,
	developer_id INT,
	message	VARCHAR(100),
	data_snap_shot INT NOT NULL,
	commit_date_time timestamp,
	
	PRIMARY KEY(commit_id),
	FOREIGN KEY (repository_id) 
	REFERENCES repository(repository_id) ON DELETE CASCADE,
	FOREIGN KEY (developer_id) 
	REFERENCES developer(developer_id) ON DELETE CASCADE,
	FOREIGN KEY (data_snap_shot)
	REFERENCES copy_repository(copy_repository_id)
);

-- 9) tag table
CREATE TABLE tag(
	repository_id INT,
	developer_id INT,
	tag_id INT,
	commit_id INT,
	tag_name VARCHAR(50) NOT NULL,
	tag_date_time timestamp,
	
	PRIMARY KEY(repository_id, developer_id, tag_id),
	FOREIGN KEY (repository_id) REFERENCES repository(repository_id),
	FOREIGN KEY (developer_id) REFERENCES developer(developer_id),
	FOREIGN KEY (commit_id) REFERENCES commit(commit_id)
);

-- The function check_user (lookup)
-- 					returns true if the input user_name is present (that is the provided user_name is valid)
-- 					returns false otherwise 
DROP FUNCTION IF EXISTS check_user;
CREATE OR REPLACE FUNCTION check_user(user_name VARCHAR(100))
RETURNS BOOLEAN
AS $$
BEGIN
	RETURN check_user.user_name IN (SELECT developer.user_name FROM developer WHERE developer.user_name = check_user.user_name);
END;
$$ LANGUAGE plpgsql;


-- function create_user
-- 					creates user if email, username are not already found in developer table and returns true if valid,
-- 					else return false
DROP FUNCTION IF EXISTS create_user;
CREATE OR REPLACE FUNCTION create_user(user_name VARCHAR(100), name VARCHAR(100), email VARCHAR(100), pass VARCHAR(100))
RETURNS BOOLEAN
AS $$
BEGIN
	if (create_user.user_name in (select developer.user_name from developer)) then
		RAISE NOTICE '% user_name already exists!!', create_user.user_name;
		if (create_user.email in (select developer.email from developer)) then
			RAISE NOTICE '% is already linked to an account!!', create_user.email;
		end if;
		return false;
	end if;
	if (create_user.email in (select developer.email from developer)) then
		RAISE NOTICE '% is already linked to an account!!', create_user.email;
		return false;
	end if;
	INSERT INTO developer(user_name, encrypted_password, name, email) 
	VALUES (create_user.user_name, (crypt(create_user.pass, gen_salt('bf'))) , create_user.name, create_user.email);
	RAISE NOTICE 'Welcome to cloud-repository octopus %!!', create_user.name;
	return true;
END;
$$ LANGUAGE plpgsql;

-- function create_repo
DROP FUNCTION IF EXISTS create_repo;
CREATE OR REPLACE FUNCTION create_repo(repository_name VARCHAR(100), user_name VARCHAR(100))
RETURNS BOOLEAN
AS $$
BEGIN
	/* for a user, repo_name must be unique */
	if (create_repo.repository_name in  (select repository.repository_name
										from repository, developer
										where repository.owner_id = developer.developer_id and developer.user_name = create_repo.user_name)) then
		/* repository is already present in repos of owner*/
		RAISE NOTICE '% already exists in % repostires', create_repo.repository_name, create_repo.user_name;
		return false;
	end if;
	
	if(check_user(user_name) = false) then
		RAISE NOTICE '% user_name is invalid!!', create_repo.user_name;
		RETURN false;
	end if;
	
	/* Updating number of repositires of owner */
	UPDATE developer
	SET num_repos = num_repos + 1
	WHERE developer.user_name = create_repo.user_name;
	
	/* creating a new repository */
	INSERT INTO repository(repository_name, created_date_time, last_update, owner_id)
	VALUES ( create_repo.repository_name,
			 localtimestamp,
			 localtimestamp,
			 (select developer.developer_id
			 from developer
		     where developer.user_name = create_repo.user_name)
	);
	
	RAISE NOTICE '% created!!', create_repo.repository_name;
	return true;
END;
$$ LANGUAGE plpgsql;

-- create file function
DROP FUNCTION IF EXISTS create_file;
CREATE OR REPLACE FUNCTION 	create_file(file_name VARCHAR(50), file_type VARCHAR(10), content text, parent_repository_name VARCHAR(100), owner_user_name VARCHAR(100))
RETURNS BOOLEAN
AS $$
DECLARE 
repo_id INT;
own_id INT;
file_size INT;
create_time timestamp;
BEGIN
	IF (owner_user_name not in (SELECT user_name FROM developer)) THEN
		RAISE NOTICE '% is invalid user_name', owner_user_name;
		RETURN false;
	END IF;
	own_id := (SELECT developer_id FROM developer WHERE user_name = owner_user_name);
	
	IF (parent_repository_name not in (SELECT repository_name FROM repository WHERE repository.owner_id = own_id)) THEN
		RAISE NOTICE '% is not present in % repositires', parent_repository_name, owner_user_name;
		RETURN false;
	END IF;
	repo_id := (SELECT repository_id FROM repository WHERE repository_name = parent_repository_name AND repository.owner_id = own_id);
	
	IF (file_name in (SELECT file.file_name FROM file WHERE parent_repository_id = repo_id and file.file_type = create_file.file_type)) THEN
	 	RAISE NOTICE '% % is already present in % of developer %', file_name, file_type, parent_repository_name, owner_user_name;
		RETURN false;
	END IF;
	file_size := LENGTH(content);
	create_time := localtimestamp;
	
	/* updating developer table */ 
	UPDATE developer
	SET storage_used = storage_used + file_size
	WHERE developer.developer_id = own_id;
	
	/* updating repositry table */
	UPDATE repository
	SET size = size + file_size, last_update = create_time
	WHERE repository_id = repo_id;
	
	/* inserting into file table */
	INSERT INTO file(file_name, file_type, size, content, parent_repository_id, last_update)
	VALUES (create_file.file_name, create_file.file_type, file_size, content, repo_id, create_time);
	
	RAISE NOTICE '% file created in % of %.', file_name, parent_repository_name, owner_user_name;
	RETURN true;
END;
$$ LANGUAGE plpgsql;

-- procedure grant_collab_access
-- 			will grant acess if inputs are valid (owner grants collboration access to another user)
-- NOTE: A owner by default has edit, read access of a repository. 
-- In this design, collaborator is one who has edit and read access of repository.(which genrally is the case)
DROP PROCEDURE IF EXISTS grant_collab_access;
CREATE OR REPLACE PROCEDURE grant_collab_access(repository_name VARCHAR(100), owner_user_name VARCHAR(100), to_user_name VARCHAR(100))	
AS $$
DECLARE 
dont_grant boolean DEFAULT false;
repo_id INT;
from_id INT;
to_id INT;
BEGIN
	/* checking for validity of user_names */
	IF (check_user(owner_user_name) = false) THEN
		RAISE NOTICE '% is not present', owner_user_name;
		dont_grant := true;
	END IF;
	IF (check_user(to_user_name) = false) THEN
		RAISE NOTICE '% is not present', to_user_name;
		dont_grant := true;
	END IF;
	IF (dont_grant = false) THEN
		from_id := (SELECT developer_id FROM developer WHERE developer.user_name = grant_collab_access.owner_user_name);
		to_id := (SELECT developer_id FROM developer WHERE developer.user_name = grant_collab_access.to_user_name);
	END IF;
	IF (dont_grant = false) AND (grant_collab_access.repository_name NOT IN
								(SELECT repository.repository_name FROM repository WHERE repository.owner_id = from_id)) THEN
		RAISE NOTICE '% is not owner of repository %', owner_user_name, repository_name;
		dont_grant := true;
	END IF;
	
	IF (dont_grant = false) THEN
		repo_id := (SELECT repository.repository_id FROM repository 
					WHERE repository.repository_name = grant_collab_access.repository_name AND repository.owner_id = from_id);
		/* grant access */
		INSERT INTO collaborate
		VALUES  (repo_id, to_id);
		
		/* modify repository */
		UPDATE repository
		SET num_workers = num_workers + 1
		WHERE repository.repository_id = repo_id;
		
		RAISE NOTICE 'Access granted!!';
	ELSE
		RAISE NOTICE 'Access denied!!';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- procedure add_comment
--  		 adds comment to the comment_table provided if the given inputs repository_id, user_name are valid
-- NOTE: 1) We cannot take only repository_name as input parameter for adding comment because there could be multiple repositires with same repository_name
-- 		 2) The current database design supports that any user of OCTOPUS can comment on a repository, if the repository is public (or) he is the owner of the repository (or) collaborator of the repository (or) has access (view basically) to the repository.
-- 			(that is having at least view access)
DROP PROCEDURE IF EXISTS add_comment;
CREATE OR REPLACE PROCEDURE add_comment(owner_user_name VARCHAR, repository_name VARCHAR, user_name VARCHAR(100), message VARCHAR(100))
AS $$
DECLARE 
repo_id INT;
have_permission BOOLEAN DEFAULT false;
invoke_id INT;
BEGIN
	repo_id := (SELECT repository.repository_id FROM repository JOIN developer ON repository.owner_id = developer.developer_id
			   WHERE repository.repository_name = add_comment.repository_name AND developer.user_name = owner_user_name);
	IF ((repo_id IN  (SELECT repository.repository_id FROM repository)) AND
		(add_comment.user_name IN (SELECT developer.user_name FROM developer))) THEN
		-- given repository_id and user_name are valid
		invoke_id = (select developer_id FROM developer WHERE developer.user_name = add_comment.user_name);
		
		IF ((select is_public FROM repository WHERE repository.repository_id = repo_id) = true) then
			/* public repository */
			have_permission := true;
		ELSIF ((select owner_id FROM repository WHERE repository.repository_id = repo_id) = invoke_id) THEN
			/* is owner */
			have_permission := true;
		ELSIF ( invoke_id IN (SELECT collaborate.developer_id FROM collborate WHERE collaborate.repository_id = repo_id)) THEN
			/* collaborator */
			have_permission := true;
		ELSIF (invoke_id IN (SELECT access.developer_id FROM access WHERE access.repository_id = repo_id)) THEN
			/* private view access */
			have_permission := true;
		END IF;
		
		IF (have_permission) THEN
			INSERT INTO comment(repository_id, developer_id, message, comment_date_time)
			VALUES (repo_id,
					invoke_id,
					add_comment.message,
					localtimestamp);
			RAISE NOTICE 'Comment added!!';			
		ELSE
			RAISE NOTICE 'From procedure add_comment: No access for % to comment repository with repository_id %!!', add_comment.user_name, repo_id;
		END IF;
	ELSE
		RAISE NOTICE 'Invalid input!!';
	END IF;
END;
$$ LANGUAGE plpgsql;

-- Inserting data using create_user function
SELECT create_user('_sandeep_', 'sandeep reddy', '112101011@smail.iitpkd.ac.in', 'palakkad@3');
SELECT create_user('_manish_', 'manish', '112101002@smail.iitpkd.ac.in', 'apple@22');
SELECT create_user('_swarna_', 'sunapral swarnalatha bai', '112101003@smail.iitpkd.ac.in', 'pass123');

-- SELECT create_user('_sandeep_', 'sandy', 'sandeep@gmail.com', 'iitpkd@2025'); example for not inserted

SELECT * FROM developer;

-- creating repostires (data)
select create_repo('math', '_sandeep_');
select create_repo('phy', '_sandeep_');
select create_repo('math', '_manish_');
select create_repo('chem', '_swarna_');

SELECT * FROM developer;
SELECT * FROM repository;

select create_repo('chem', '_swarna_'); /* duplicate repositires are not allowed */

-- adding files
SELECT create_file('problems', 'txt', 'In how many ways n choclates can be split across k children?', 'math', '_sandeep_');
SELECT create_file('exams', 'txt', 'exam1, exam2, exam3', 'math', '_sandeep_');
SELECT create_file('labs', 'txt', 'Why convex mirrors are used in rear view mirrors of motor vehicles?', 'phy', '_sandeep_');
SELECT create_file('problems', 'txt', 'Are L1, L2 NORMS are equivalent? If yes proove.', 'math', '_manish_');
SELECT create_file('labs', 'txt', 'What are the affects of having hydrogen boding in water?', 'chem', '_swarna_');

SELECT * FROM file;
SELECT * FROM developer;
SELECT * FROM repository;

-- granting collaboration
CALL  grant_collab_access('math', '_manish_', '_sandeep_');
CALL  grant_collab_access('math', '_manish_', '_swarna_');

/* _sandeep_ granted collaboration access to _manish_ for repository 'phy': */
CALL  grant_collab_access('phy', '_sandeep_', '_manish_'); 

SELECT * FROM repository;
SELECT * FROM collaborate;

-- comments by developers.
CALL add_comment('_sandeep_', 'math', '_manish_', 'math: Answer to the problem is (n+k-1)^2');
CALL add_comment('_sandeep_', 'math', '_sandeep_', 'math: NO!! (n+k-1) choose k');
CALL add_comment('_sandeep_', 'phy', '_swarna_', 'phy: gives full size diminished image of distant objects');
CALL add_comment('_swarna_', 'chem', '_sandeep_', 'chem: High boiling point');
CALL add_comment('_swarna_', 'chem', '_manish_', 'chem: Expansion upon freezing!!');

SELECT * FROM comment;



-- Query1) Give the number of files owned by each of the developers in descending order.
SELECT d.developer_id, d.user_name, count(file_id) as "number of files"
FROM developer d, repository r, file f
WHERE d.developer_id = r.owner_id AND f.parent_repository_id = r.repository_id
GROUP BY d.developer_id
ORDER BY "number of files" DESC;

-- Query2) Find all files owned by '_manish_'
SELECT f.file_id, f.file_name, f.file_type
FROM developer d, repository r, file f
WHERE d.developer_id = r.owner_id AND f.parent_repository_id = r.repository_id AND d.user_name = '_manish_';

-- Query3) Find all comments which are made on repositires owned by '_sandeep_'
SELECT (SELECT developer.user_name FROM developer WHERE developer.developer_id = c.developer_id),
		c.message
FROM developer d, repository r, comment c
WHERE d.user_name = '_sandeep_' AND
	  d.developer_id = r.owner_id AND
	  c.repository_id = r.repository_id;


-- Query4) Find all comments made by developer '_sandeep_'
SELECT comment.message
FROM developer, comment
WHERE developer.user_name = '_sandeep_' AND 
	  comment.developer_id = developer.developer_id;

-- Query5) Find the content of all files which are present in repositires commented by '_manish_'
SELECT file.file_id, file.content
FROM file, repository, comment, developer
WHERE developer.user_name = '_manish_' AND
	  comment.developer_id = developer.developer_id AND
	  comment.repository_id = repository.repository_id AND
	  file.parent_repository_id = repository.repository_id;
