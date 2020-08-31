==============
ETL with HTSQL
==============

By Clark Evans, PostgreSQL Open, Sept 18, 2013

.. image:: rabbit-htsql.png 
   :width: 400

Verifiable Transformations
==========================

* We help medical researchers with data management
* We have many clients with large data sets
* We have many analysts who work on those data sets
* We have lots and lots of data transformations
* We need transformations to be correct and auditable

Simple Request
==============

..

    For a given $family in our research study, please 
    update all *individual* records in the database so 
    that a useful but reduced-resolution ``birth_yearmo``
    variable preserves the year and month, but not the
    day, from the birth date found in that individual's
    *identifying detail*.

A "Dumb" Approach
=================

1. Find the family in the system, navigate to the corresponding 
   individual records, collecting the corresponding birth dates, 
   and then jotting down the individual codes and dates.

2. Calculate the truncated date as requested, preserving the 
   indvidual's code so you know who gets what truncated date.
  
3. Verify the computation, checking that the truncated dates
   look reasonable for the individuals in that family.

4. Update each individual's record appropriately.

SQL Expert Approach!
====================

.. sourcecode:: sql

   UPDATE individual AS sr
      SET birth_yearmo = (
          SELECT TO_CHAR(pd.birth_date, 'YYYY-MM')
            FROM private_detail pd
           WHERE pd.individual_id = sr.id)
    WHERE family_id = $family

Computationally efficient.  Completely transparent 
if you're familiar with SQL and have a solid 
understanding of the database schema & its contents.

What Could Be Better?
=====================

.. sourcecode:: sql

   WITH changes AS (
      SELECT sr.id, TO_CHAR(pd.birth_date, 'YYYY-MM')
                    AS birth_yearmo
       FROM individual AS sr 
       JOIN private_detail pd 
         ON (sr.id = pd.individual_id)
      WHERE sr.family_id = $family)
   UPDATE individual
      SET birth_year_month = changes.birth_year_month
    WHERE id = changes.id

Perhaps a ``WITH`` ... ``UPDATE`` construct might permit 
a query to be tested so that you could select your output 
before applying it in an update. 

In HTSQL, you'd write
=====================

.. sourcecode:: htsql

   /family[$family]
   .individual
   .define(birth_yearmo :=
      head(string(private_detail.birth_date,7)))
   .select(id(), birth_yearmo)
   /:update

1. Navigate to the selected family, 
2. navigate further to corresponding individuals,
3. define the birth_yearmo calculation
4. request the identity and the change you wish
5. reflect the select as an update

What is HTSQL?
==============

.. rst-class:: build

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

.. rst-class:: build

- Early sketches about 10 years ago
- "Accidental Programmer" 7 years ago
- HTSQL 2.X work started ~3.5 years ago
- Language itself is quite stable
- Last year added "rough draft" ETL
- Currently refactoring implementation
- Central to our OSS RexDB (TM) Plaform

How do we use HTSQL?
====================

.. rst-class:: build

- from Javascript Browser Apps
- from Python Server Processes
- for it for Data quality reports
- for sharing data sets with users
- for communicating requirements
- for ad-hoc querying (ala psql)
- for *data conversions* ala ETL

Case Study : Autism Speaks
==========================

As of last year this time, Autism Speaks had 
three main internal database systems that we
spent several months converting to RexDB.

- Lots of tables with hand-entered data
- Not a huge data set (in the 10's of GBs)
- Some data quality issues, mostly good
- Imperfect alignment with RexDB tables

We received the data set as CSVs, loaded them 
into SQLite so we could cross-reference them,
and merged results into a PostgreSQL database.

Autism Speaks : Topology
========================

The HTSQL "ETL" process built SQLite database
from CSVs, executed queries and pushed data
output over to PostgreSQL. 

.. sourcecode:: htsql
   
   /source_table :as
    .define(....)
    .select(....)
    .where(....)
   :as destination_table
   /:from_sqlite
   /:merge

Autism Speaks, How Bad?
=======================

Roughly 15k lines of queries:

- 1.5k of re-usable macros, 250 definitions
- 30% of the lines were simply recodes
- a few "de-normalizations" ala pivots
- lots of date wrangling (SQLite lacks DATE)
- lots of custom business logic & twists

Written primarily by 3 data analysts on 
with dozens and dozens of client calls.

Typical Re-Code Example
=======================

.. sourcecode:: htsql

     race_code(race) :=
       if(race ~ 'White' & race ~ 'American', null(),
          race ~ 'indian' & race ~ 'Alaskan', 'american-indian-alaskan-native',
          race ~ 'black' & race ~ 'African', 'black-or-african-american',
          race ~ 'asian', 'asian',
          race ~ 'more than', 'more-than-one-race',
          race ~ 'hawaiian', 'native-hawaiian-or-other-pacific-islander',
          race ~ 'not asked', 'not-asked',
          race ~ 'unknown', 'unknown',
          race = {'White', 'white'}, 'white')

Typical Navigation
==================

.. sourcecode:: htsql

   /individual
   .filter(exists(todo_raw)&!exists(
         protocol_participation?protocol='agre.unknown'))
   ...

Typical Query
=============

.. sourcecode:: htsql

     /blood.define (
 	$individual := memberid :string,
 	$agrednaforaudit := make_date(agrednaforaudit),
 	$blooddrawdate := if(blooddrawdate='2/7/0207',date(2007,2,7),
 		blooddrawdate='8/11/0207',date(2007,8,11),
 		make_date(blooddrawdate)),
     ){
 	individual:= [$individual],
 	blooddrawdate := $blooddrawdate,
 	...
     }
     :as blood
     /:source
     /:merge

Autism Speaks, Retrospective
============================

- HTSQL macros made errors easy to spot/fix
- HTSQL was solid with composition/navigation
- HTSQL isn't great with scalar manipulation
- Next time... load CSVs into PostgreSQL!
- We didn't need to rely upon core developers.

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

Sorting & First
===============

.. htsql::
   :cut: 5

   /school.sort(count(department)-) :top

Products
========

.. htsql::
   :cut: 5

   /course?credits>avg(@course.credits)

Definitions
===========

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

Batch Update
============

.. sourcecode:: htsql

   /family[$family]
   .individual
   .define(birth_yearmo :=
      head(string(private_detail.birth_date,7)))
   .select(id(), birth_yearmo)
   /:update

Where to?
=========

* HTSQL is building block of OSS RexDB
* We're focused on RexDB currently
* We're working on refactor of HTSQL
* HTSQL 1.4 may be finalized next year

Thanks!

.. slideconf::
   :theme: single-level

