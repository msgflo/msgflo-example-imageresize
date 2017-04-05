[![Build Status](https://travis-ci.org/msgflo/msgflo-example-imageresize.svg?branch=master)](https://travis-ci.org/msgflo/msgflo-example-imageresize)
# MsgFlo example: Image resizing service

Example of how to build a backend service for CPU-intensive tasks using [Msgflo](https://msgflo/org).

## API

* API. HTTP POST. JSON body. Array of images. URL and desired height/width. Returns 202 Accepted, with `Location`.
Ref. https://benramsey.com/blog/2008/04/http-status-201-created-vs-202-accepted/
* Downloads image. Rescales. Uploads downscaled. Updates job status.

## Status
**Work-in-progress**

## TODO

Minimal

* Add test for successful job completion
* Deploy to Heroku, test live
* Test with GuvScale

Bonus

* Make tests support running against remote app
* Script for querying processing times
* Heroku Button support
* UI: Accept URLs

