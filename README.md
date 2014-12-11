interactivespaces-chef
======================

Chef cookbook for managing [Interactive Spaces](https://github.com/interactivespaces/interactivespaces) installations

Usage
=====
Interactivespaces stack can be defined using node attributes:

```json
"interactivespaces" : {
  "deploy" : {
    "master" : {
      "version" : "1.6.5",
      "revision" : "release-1.6.5"
    },
    "controller" : {
      "version" : "1.6.5",
      "revision" : "release-1.6.5"
    }
  },
  "ispaces_client" :  {
    "relaunch_sequence" : [
      "Pre-Start",
    "Google Earth",
    "Street View",
    "Liquid Galaxy"
      ]
  },
  "activities" : {
    "Street View Panorama" : {
      "url" : "https://galaxy.endpoint.com/interactivespaces/activities/com.endpoint.lg.streetview.pano-1.0.0.dev.zip",
      "version " : "1.0.0dev"
    }
  },
  "live_activities" : {
    "SV Pano on 42-a" : {
      "controller" : "ISCtl42a",
      "initial_state" : "deploy - not yet used",
      "description" : "some description",
      "activity" : "Street View Panorama",
      "metadata" : {
        "lg.svpano.some_key": "some_value",
        "some_other_key" : "some_other_value"
      }
    }
  },
  "controllers" : {
    "ISCtl42a" : {
      "description" : "some fancy controller description",
      "hostid" : "isctl42a"
    }
  },
  "live_activity_groups" : {
    "live_activity_group_name" : {
      "live_activities" : [
      {"live_activity_name" : "SV Pano on 42-a",
        "space_controller_name" : "ISCtl42a"
      }
      ],
        "metadata" : {
          "key" : "value"
        }
    }
  }
```

or LWRP
