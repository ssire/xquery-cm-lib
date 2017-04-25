XQuery Content Management Library
=======

The XQuery Content Management Library (XCM) contains shared code and data to develop content management applications with features such as workflow management, semi-structured content editing, formular generation and e-mail engine. It has been initially developped to create case tracker applications as documented in this [software documentation manual](https://github.com/ssire/case-tracker-manual). You can checkout the [case tracker pilote](https://github.com/ssire/case-tracker-pilote) project to learn how to develop new applications using this library.

This project is written in XQuery / XSLT / Javascript and the [Oppidum](https://github.com/ssire/oppidum) web application framework. It follows the conventions of a full stack XML application architecture.

This work has been supported by the CoachCom2020 coordination and support action (H2020-635518; 09/2014-08/2016). Coachcom 2020 has been selected by the European Commission to develop a framework for the business innovation coaching offered to the beneficiaries of the Horizon 2020 SME Instrument.

Several case tracker applications based on this library are used in production since 2013 for the eldest, in Switzerland and in Belgium.

Contributors
---------

The XQuery Content Management Library and the case tracker pilote have been initially developped and are maintained by Stéphane Sire at Oppidoc, France.

Some other authors also contributed :

* Christine Vanoirbeek at the Ecole Polytechnique Fédérale de Lausanne (EPFL, Switzerland)
* Frédéric Dumonceaux at the Executive Agency for SMEs (EASME, Belgium)

Dependencies
----------

Runs inside [eXist-DB](http://exist-db.org/) (developed with [version 2.2](https://bintray.com/existdb/releases/exist))

Back-end made with [Oppidum](https://www.github.com/ssire/oppidum/) XQuery framework

Front-end made with [AXEL](http://ssire.github.io/axel/), [AXEL-FORMS](http://ssire.github.io/axel/) and [Bootstrap](http://twitter.github.io/bootstrap/) (all embedded inside the *resources* folder)

Compatiblity
----------

The current version runs inside eXist-DB installed on Linux or Mac OS X environments only. The Windows environment is not yet supported. This requires some adaptations to the Oppidum framework amongst which to generate file paths with the file separator for Windows.

License
-------

The XQuery Content Management Library is released as free software, under the terms of the LGPL version 2.1.

You are welcome to join our efforts to improve the code base at any time and to become part of the contributors by making your changes and improvements and sending *pull* requests.

Installation
------------

See the [case tracker pilote](https://github.com/ssire/case-tracker-pilote) installation instructions. 

To use the XCM library you only need to clone it inside the same project folder as your application.

You MUST clone it with the *xcm* name if you want to use it off the shelf with the case tracker pilote application :

    git clone https://github.com/ssire/xquery-cm-lib.git xcm

Coding conventions
---------------------

* _soft tabs_ (2 spaces per tab)
* no space at end of line (ex. with sed : `sed -E 's/[ ]+$//g'`)
