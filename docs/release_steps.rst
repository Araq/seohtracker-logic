===============================
Seohtracker logic release steps
===============================

Release steps for `Seohtracker logic
<https://github.com/gradha/seohtracker-logic>`_.

* Create new milestone with version number (vXXX) at
  https://github.com/gradha/seohtracker-logic/issues/milestones.
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

* Regenerate static website.

  * ``git checkout gh-pages`` to switch to ``gh-pages``.
  * ``rm -Rf `git ls-files -o` docs`` to purge files from other branches
    and force regeneration of all docs, even tags.
  * ``gh_nimrod_doc_pages -c . && git add . && git commit``. Tag with
    `Regenerates website. Refs #release_issue`.

* Push all to git: ``git push origin master stable gh-pages --tags``.
* Close the dummy release issue.
* Close the milestone on github.
