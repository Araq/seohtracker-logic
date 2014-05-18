=================
Seohtracker logic
=================

This is the module containing the logic for clients like `Seohtracker for iOS
<https://github.com/gradha/seohtracker-ios>`_ or `Seohtracker for Mac
<https://github.com/gradha/seohtracker-mac>`_. You don't use this directly,
rather embed it into other clients. For example::

    $ git submodule add https://github.com/gradha/seohtracker-logic.git


License
=======

`MIT license <LICENSE.rst>`_.


Documentation
=============

See the documentation index in the `docindex.rst file <docindex.rst>`_. For
some of the files you need to run ``nake doc`` to generate them, which requires
you to install `nake <https://github.com/fowlmouth/nake>`_ and check out this
repository using the ``--recursive`` switch, since it depends on other repos
for documentation generation.

Changes
=======

This is development version v6.1. For a list of changes see the
`docs/changes.rst file <docs/changes.rst>`_.


Git branches
============

This project uses the `git-flow branching model
<https://github.com/nvie/gitflow>`_ with reversed defaults. Stable releases are
tracked in the ``stable`` branch. Development happens in the default ``master``
branch. However, this module *alone* doesn't do much, and projects are likely
using ``git submodule`` to include it, so they don't really care about
stable/development versions. The stable versions are used just to mark client
milestones.


Feedback
========

You can send me feedback through `github's issue tracker
<https://github.com/gradha/seohtracker-logic/issues>`_. I also take a look at
`Nimrod's forums <http://forum.nimrod-code.org>`_ where you can talk to other
nimrod programmers.
