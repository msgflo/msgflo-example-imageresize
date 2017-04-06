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

* Add checks for successful job completion test
* Test with GuvScale

Bonus

* Script for querying processing times
* Fix marking job status with completed
* Heroku Button support
* Allow hosting `store` inside `web` worker
* Tools for summarizing/visualizing performance
* UI: Accept URLs

## Docs

Run performance tests of different architectures.

* Syncronous HTTP request-response
* Everything-in-web-role
* Dedicated worker
* Dedicated worker with autoscaling

