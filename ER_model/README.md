
```diff
- text in red
+ text in green
! text in orange
# text in gray
@@ text in purple (and bold) @@
```

# ER model of octopus

## Overview

+ [Inroduction](#Introduction)
+ [Entity sets and their attributes](#Entity-sets-and-their-attributes)
+ [Relationship sets and their attirbutes](#Relationship-sets-and-their-attributes)
+ [ER diagram](#ER-diagram)

## Introduction

Entity-relationship data model (often abbreviated as ER data model (or) ER model) is one of the data models, which specifies the structure of a database.  
```
ER data model employs 3 basic concepts:  
 1) attributes
 2) entity sets 
 3) relationship sets  
```
We shall see more about the above 3 basic concepts of ```octopus``` in the coming sections.  

## Entity sets and their attributes
An entity is basically a distinguishable object. An entity set is a set of entities of the same type that share the same attributes (properties). <br/>
A database is a collection of entity sets, which are related by relationships. <br/>


1) **user** enitiy set has all information of a user(which we can also call by name developer, but we decided to call as **user** which is ofcourse a superset of **developer** i.e every developer can be called as user but not otherwise)
2) **repositry** entity set has details of a repositry. <br/>
	A repositry has exactly one owner(who must be user). <br/>
	A owner can own multiple repositires. <br/>
	The owner of a repo is by default one of the collaborators of the repo. A repo can have one (or) more collaborators (who are users, need not be the owner of this repo). <br/>
3) **file** entity set has meta data and data of files. We could not come with good reason why we should not have a file without parent repositry(i.e file not being in any repo), as a result we allowed to have files which do not have parent repo. <br/>
4) **commit**
5) **tag**
6) **comment** 
 
## Relationship sets and their attributes
A **relationship** is an association among several entities.  
A **relationship set** is a set of relationships of the same type.   

## ER diagram
ER diagram is a graphical way of expressing the logical structure of a database.  


