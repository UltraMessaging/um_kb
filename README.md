# um_kb
Experimental knowledge base (KB) repo. Provides a place to supply information that is easy to produce and consume knowledge.

This repo contains a copy of the Linux executable for the
[pmarkdown](https://metacpan.org/pod/App::pmarkdown) application,
version 1.06, which is used to build this kb.
See [its license](https://metacpan.org/dist/Markdown-Perl/view/script/pmarkdown#LICENCE).


# The Knowledge Base

This README.md file is intended for use by Informatica staff.

Go to the knowledge base [Home](https://ultramessaging.github.io/um_kb/html/home.html).


# Why a Knowledge Base?


Q: Why put stuff in a knowledge base (KB) and not in the product doc?

A: Some stuff just doesn't belong in the product doc.
For example, a work-in-progress can be in the KB and provide some benefit
to customers even though it is incomplete.
Also, it is MUCH MUCH quicker to throw something up on the KB than to
incorporate it into the product doc.
It is quite possible that some KB articles will grow in content and
maturity and graduate into being doc sections.

Q: Why not use the Informatica KB?

A: UM is a small product offering from Informatica.
We are a relatively small team as compared to the larger Informatica
product offerings.
The overhead of using the Informatica tools is proper and necessary for
teams the size of other Informatica teams,
but for UM the overhead is unnecessary and onerous.
This KB allows us to get information out to our customers quickly and
efficiently

Q: How is KB content maintained and expanded?

A: You should already be in the Ultra Messaging GitHub organization.
These instructions assume you are using Linux and already have your
GitHub account configured for use with command-line git.
This example assumes you want to modify the article `static-linking.md`.

> 1. `git clone git@github.com:UltraMessaging/um_kb.git`
> 2. `cd um_kb.git`
> 3. `vi kb/static-linking.md`
> 4. `./bld.sh`
> 5. `./checkin.sh`

Here are a few more tips:
* To create a new article, copy an existing one as a starting point.
* The first line should be of the form:

  > `# Title of Article`

  The name of the file should match the title, with all upper-case
  converted to lower-case, and all spaces replaced by dashes.
  For example, the above title implies the file name, "title-of-article.md".
* The table of contents is generated automatically; you don't need to hand-edit it.
