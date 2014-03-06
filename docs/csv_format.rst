======================
Seohtracker csv format
======================

Starting with v4 of Seohtracker, users can export and import CSV (comma
separated values) files for backup purposes. There is no versioning for CSV
files, so this lists whatever changes went in during each public release. Also,
CSV files are not necessarily meant to be backwards compatible: newer versions
of Seohtracker will attempt to read older CSV files, but older versions of
Seohtracker might fail horribly importing newer CSV versions (or not).

Importation of CSV files ignores all extraneous or non parseable content. This
allows the CSV file to contain a small header for human readable purposes.


v4, initial version
===================

The exported CSV contains the following header::

    date,weight
    -----

After this header, two columns are present. Example::

    2014-01-07:23-51-37,101.900001525879kg
    2014-01-08:08-22-03,101.300003051758kg
    2014-01-09:09-55-18,100.0kg

First, the date is exported in format YYYY-MM-DD:HH-MM-SS. The most important
thing about this format is that the data is always kept in user local time.
This is different from the internal database, which tracks all entries in UTC
format.

Then, the weight is exported. The weight is always exported with the weight
unit it was stored in the database, so a dump may contained mixed units. The
units so far are:

* kg
* lb

The weight value itself is dumped as a floating point value.

The order of the columns is not important. Since it is obvious from the unit
suffix which column is which, the software will attempt to parse the columns in
any order. In fact, it should be able to deal with more columns, ignoring the
ones which don't match the expected format.
