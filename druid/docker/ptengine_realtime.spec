{
  "dataSchema": {
    "dataSource" : "wikipedia",
    "parser" : {
      "type" : "string",
      "parseSpec" : {
        "format" : "json",
        "timestampSpec" : {
          "column" : "timestamp",
          "format" : "auto"
        },
        "dimensionsSpec" : {
          "dimensions": ["page","language","user","unpatrolled","newPage","robot","anonymous","namespace","continent","country","region","city"],
          "dimensionExclusions" : [],
          "spatialDimensions" : []
        }
      }
    },
    "metricsSpec" : [{
      "type" : "count",
      "name" : "count"
    }, {
      "type" : "doubleSum",
      "name" : "added",
      "fieldName" : "added"
    }, {
      "type" : "doubleSum",
      "name" : "deleted",
      "fieldName" : "deleted"
    }, {
      "type" : "doubleSum",
      "name" : "delta",
      "fieldName" : "delta"
    }],
    "granularitySpec" : {
      "segmentGranularity" : "DAY",
      "queryGranularity" : "NONE",
      "intervals" : [ "2013-08-31/2013-09-01" ]
    }
  },
  "ioConfig": {
  },
  "tuningConfig": {
  }
}
