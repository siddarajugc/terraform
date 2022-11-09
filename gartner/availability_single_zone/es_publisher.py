#!/usr/bin/python3
#
# =============================================================================================
# IBM Confidential
# (C) Copyright IBM Corp. 2019
# The source code for this program is not published or otherwise divested of its trade secrets,
# irrespective of what has been deposited with the U.S. Copyright Office.
# =============================================================================================
#

import abc
import copy
import math
import time
import json

from elasticsearch import Elasticsearch


class SampleCollector(object):
  """
  Supports incorporating additional metadata into samples, and publishing
  results via any number of SamplePublishers.
  """

  def __init__(self, es_uri, es_index, es_type):
    self.es_uri = es_uri
    self.es_index = es_index
    self.es_type = es_type
    self.samples = []
    self.publishers = [ElasticsearchPublisher(es_uri=self.es_uri, es_index=self.es_index, es_type=self.es_type)]

  def AddSamples(self, samples):
    """Adds data samples to the publisher. """
    for s in samples:
      self.samples.append(s)

  def PublishSamples(self):
    """Publish samples via all registered publishers."""

    for publisher in self.publishers:
      publisher.PublishSamples(self.samples)
    self.samples = []


class SamplePublisher(object):
  """An object that can publish performance samples."""

  __metaclass__ = abc.ABCMeta

  @abc.abstractmethod
  def PublishSamples(self, samples):
    """Publishes 'samples'.

    PublishSamples will be called exactly once. Calling
    SamplePublisher.PublishSamples multiple times may result in data being
    overwritten.

    Args:
      samples: list of dicts to publish.
    """
    raise NotImplementedError()


class ElasticsearchPublisher(SamplePublisher):
  """Publish samples to an Elasticsearch server. Index and document type
  will be created if they do not exist.
  """

  def __init__(self, es_uri=None, es_index=None, es_type=None):
    self.es_uri = es_uri
    self.es_index = es_index.lower()
    self.es_type = es_type
    self.mapping = {
      "mappings": {
        self.es_type: {
          "numeric_detection": True,
          "properties": {
            "timestamp": {
              "type": "date",
              "format": "yyyy-MM-dd HH:mm:ss.SSSSSS"
            }
          },
          "dynamic_templates": [{
            "strings": {
              "match_mapping_type": "string",
              "mapping": {
                "type": "text",
                "fields": {
                  "raw": {
                    "type": "keyword",
                    "ignore_above": 256
                  }
                }
              }
            }
          }]
        }
      }
    }

  def PublishSamples(self, samples):
    """Publish samples to Elasticsearch service"""
    es = Elasticsearch([self.es_uri])
    if not es.indices.exists(index=self.es_index):
      es.indices.create(index=self.es_index, body=self.mapping)
    for s in samples:
      sample = copy.deepcopy(s)
      sample['timestamp'] = self._FormatTimestampForElasticsearch(
        sample['timestamp']
      )
      # Keys cannot have dots for ES
      sample = self._deDotKeys(sample)
      res = es.create(index=self.es_index, doc_type=self.es_type,
                      id=sample['sample_uri'], body=json.dumps(sample))
      print(json.dumps(res))

  def _FormatTimestampForElasticsearch(self, epoch_us):
    """Convert the floating epoch timestamp in micro seconds epoch_us to
    yyyy-MM-dd HH:mm:ss.SSSSSS in string
    """
    ts = time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime(epoch_us))
    num_dec = ("%.6f" % (epoch_us - math.floor(epoch_us))).split('.')[1]
    new_ts = '%s.%s' % (ts, num_dec)
    print(new_ts)
    return new_ts

  def _deDotKeys(self, res):
    """Recursively replace dot with underscore in all keys in a dictionary."""
    for key, value in res.items():
      if isinstance(value, dict):
        self._deDotKeys(value)
      new_key = key.replace('.', '_')
      if new_key != key:
        res[new_key] = res.pop(key)
    return res
