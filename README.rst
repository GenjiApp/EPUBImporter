==============
 EPUBImporter
==============

EPUBImporter is Spotlight Importer for EPUB.


Install
=======

Copy EPUBImporter.mdimporter to `/Library/Spotlight` or `~/Library/Spotlight`.


Assignments of metadata
=======================

.. csv-table::
   :header: "EPUB metadata", "Spotlight metadata"
   :widths: 1, 2

   title, kMDItemTitle
   creator, kMDItemAuthors
   subject, kMDItemKeywords
   description, "kMDItemDescription, kMDItemHeadline"
   publisher, "kMDItemPublishers, kMDItemOrganizations"
   contributor, kMDItemContributors
   identifier, kMDItemIdentifier
   language, kMDItemLanguages
   coverage, kMDItemCoverage
   rights, "kMDItemCopyright, kMDItemRights"
   "Body text", kMDItemTextContent
   "Number of HTMLs in EPUB", kMDItemNumberOfPages

