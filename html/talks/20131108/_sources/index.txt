=============
Hacking HTSQL
=============

By Clark Evans, Yale Hack 2013

.. image:: rabbit-htsql.png 
   :width: 400

What is HTSQL?
==============

- *navigational* -- connecting data is intuitive
- *composable* -- query construction is incremental
- *modular*  -- properly modularize complex calculations
- *portable* -- it also works with SQLite, MySQL, etc.
- *embedable* -- use in Python, or on the web
- *extendable* -- with an extensive plugin mechanism
- *comprehensive* -- it is a non-leaky abstraction
- *experimental* -- it's in active development...

HTSQL Background
================

- Early sketches about 10 years ago
- "Accidental Programmer" 7 years ago
- HTSQL 2.X work started ~3.5 years ago
- Language itself is quite stable
- Last year added "rough draft" ETL
- Currently refactoring implementation
- Central to our OSS RexDB (TM) Plaform

How do we use HTSQL?
====================

- from Javascript Browser Apps
- from Python Server Processes
- for it for Data quality reports
- for sharing data sets with users
- for communicating requirements
- for ad-hoc querying (ala psql)
- for *data conversions* ala ETL

HTSQL Core Features
===================

- Automagic Foreign Key Navigation
- Smart Aggregates, Nested Aggregates
- Records & Lists
- Projection
- Sorting & Choosing
- Cross Products
- Macro Definitions
- Attachment (Ad Hoc Linking)
- Row Location and Identity
- Set Based insert/update/merge

Example Schema
==============

...

.. image:: schema.png

Fetch It
========

.. htsql::
   :cut: 10

   /school

Navigation
==========

.. htsql::
   :cut: 10

   /school.filter(campus='old').department

Smart Aggregates
================

.. htsql::
   :cut: 7

   /school{code, count(program), count(department)}

Nested Aggregates
=================

.. htsql::
   :cut: 7

   /school{code, max(department.count(course?credits>3))}

Records & Lists
===============

.. htsql::
   :cut: 15

   /department{code, school{name}, /course{no, title} } /:txt

Projections
===========

.. htsql::
   :cut: 5

   /distinct(school{campus}) {campus, count(school)}

Sorting & Choosing
==================

.. htsql::
   :cut: 5

   /school.sort(count(department)-) :top

Cross Products
==============

.. htsql::
   :cut: 5

   /course?credits>avg(@course.credits)

Macro Definitions
=================

.. htsql::
   :cut: 5

   /define($avg_credits:=avg(course.credits))
   .course?credits>$avg_credits

Attachments or Ad-Hoc Joins
===========================

.. htsql::
   :cut: 10

     /semester
     .define(starting_students:=
        (begin_date<=student.start_date&
         end_date>=student.start_date)@student)
     {year, season, /starting_students{id,name}}
     /:txt

Identity and Locator
====================

.. htsql::
   
   /course[acc.200] {id(), title}

.. htsql::
   
   /school[edu].department

Insert (One Record)
===================

.. htsql::
   
   /{'med' :as code,
     'School of Medicine' :as name,
     'new' :as campus} :as school

.. sourcecode:: htsql
   
   /{'med' :as code,
     'School of Medicine' :as name,
     'new' :as campus} :as school
   /:insert
   
Update (One Record)
===================

.. htsql::
   
   /{[acc.100], 3 :as credits} :as course

.. sourcecode:: htsql
   
   /{[acc.100], 3 :as credits} :as course 
   /:update

Set-Based Update
================

.. sourcecode:: htsql

   /family[$family]
   .individual
   .define(birth_yearmo :=
      head(string(private_detail.birth_date,7)))
   .select(id(), birth_yearmo)
   /:update

Where to?
=========

We're building HTSQL as we continue to do work in
the medical informatics field, dealing with complex
data sets.  We're guided by real world user needs.

* HTSQL is building block of OSS RexDB
* We're focused on RexDB currently
* We're working on refactor of HTSQL
* HTSQL 2.4 might be finalized next year

P.S.  We're hiring!

.. slideconf::
   :theme: single-level

