====================================
What to do for a new public release?
====================================

* Create new milestone with version number.
* Create new dummy issue `Release versionname` and assign to that milestone.
* ``git flow release start versionname`` (versionname without v).
* Update version numbers:

  * Modify `README.rst <../README.rst>`_ (s/development/stable/).
  * Modify `docs/changes.rst <changes.rst>`_ with list of changes and
    version/number.

* ``git commit -av`` into the release branch the version number changes.
* ``git flow release finish versionname`` (the tagname is versionname without
  ``v``).  When specifying the tag message, copy and paste a text version of
  the full changes log into the message. Add rst item markers.
* Move closed issues to the release milestone.
* Increase version numbers, ``master`` branch gets +0.1.

  * Modify `README.rst <../README.rst>`_.
  * Add to `docs/changes.rst <changes.rst>`_ development version with unknown
    date.

* ``git commit -av`` into ``master`` with `Bumps version numbers for
  development version. Refs #release issue`.
* Push all to git: ``git push origin master stable --tags``.
* Close the dummy release issue.
* Close the milestone on github.
