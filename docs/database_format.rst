===========================
Seohtracker database format
===========================

This documents the different versions the internal `Seohtracker
<https://github.com/gradha/seohtracker-logic>`_ database has gone through.  The
strategy of the database is to have it auto update itself. The database doesn't
actually know how to create a database in the last version. Instead, it always
creates a database for version 1, then from that on applies upgrade
modification queries. All the upgrade paths have to work on existing data.

Implicit constants
==================

Weights table, weight_type constants
------------------------------------

The **Weights table** uses since `Version 2`_ the following implicit constants
for the ``weight_type`` column.

===== ==========================================================================
Value Meaning
===== ==========================================================================
0     The value stored in the ``weight`` column uses the kilogram unit (kg).
      This is the default, to follow a proper upgrade path. Also, if any value
      is found outside of the documented values, zero is presumed.
1     The value stored in the ``weight`` column uses the pounds unit (lb).
===== ==========================================================================

Version 0
=========

Weights table
-------------

Stores the data entered by the user.

======== ==================================================
Column   Type
======== ==================================================
id       int, not null, monotonically incrementing
date     int, not null, stores the time since epoch in GMT
weight   real, not null, stores the weight in kilograms
======== ==================================================

Constraints:

* ``id`` and ``date`` have to be unique, they are the composite primary key.

Globals table
-------------

Used to configure the app and otherwise keep track of database versioning and
maybe other meta data.

======== ==================================================
Column   Type
======== ==================================================
id       int, primary key
int_val  int, may be null
real_val real, may be null
text_val text, may be null
======== ==================================================

Content:

* Row 1 stores in ``int_val`` the numerical version of the database, which
  ranges from 0 to positive infinite. If no value exists, version zero is
  presumed.

Version 1
=========

No real changes done here, this is just to bootstrap the auto updating
mechanism. By default the database has an empty **Globals table**. To go from
version 0 to 1 the version number 1 is inserted in the **Globals table**. But
actually the insert could put any value there, since the auto updating
mechanism will update the table anyway after all the queries have executed. So
the insertion is actually to prevent the ``UPDATE`` from failing due to a
missing row.

Version 2
=========

The **Weights table** grows a ``weight_type`` column to store the unit mass
used for the measurements.  The valid values for this column are mentioned in
the `Implicit constants`_ section. The **Weights table** ends up looking like
this after the upgrade:

=========== ==================================================
Column      Type
=========== ==================================================
id          int, not null, monotonically incrementing
date        int, not null, stores the time since epoch in GMT
weight      real, not null, stores the weight in kilograms
weight_type int, not null, default zero, stores the unit type. See `Weights
            table, weight_type constants`_.
=========== ==================================================

Constraints:

* ``id`` and ``date`` have to be unique, they are the composite primary key.

