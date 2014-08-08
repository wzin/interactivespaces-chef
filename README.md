interactivespaces-chef
======================

Chef cookbook for managing [Interactive Spaces](https://github.com/interactivespaces/interactivespaces) installations

Usage
=====
Interactivespaces stack can be defined using

```json
"interactivespaces" : {
  "ispaces_client" : {
    "relaunch_sequence" : [
      "SV and Supporting",
      "GE and Supporting",
      "LG Web Interface"
      ]
  },
  "master_port": 11311,
  "master_service_enable" : true,
  "install_master" : true,
  "install_controllers" : true,
  "activities" : {
    "activity_name" : {
      "uri" : "http://example.com/fancy.zip",
      "version " : "1.0.0dev",
    },
    "activity_name2" : {
      "uri" : "http://example.com/fancy.tar.gz or /opt/example/fancy.tar.gz",
      "version " : "1.0.0dev",
    }
  },
  "space_controllers" : {
    "space_controller_name" : {
      "name" : "some name",
      "description" : "some description",
      "host_id" : "host_id"
    },
    "space_controller_name2" : {
      "name" : "some name",
      "description" : "some description",
      "host_id" : "host_id"
    },
  },
  "live_activities" : {
    "live_activity_name" : {
      "controller" : "controller_name",
      "description" : "some description",
      "metadata" : {
        "lg.earth.viewSync.horizFov": "29",
        "lg.earth.viewSync.receive" : "true",
        "lg.earth.viewSync.yawOffset" : "36"
      }
    },
    "another_live_activity_name" : {
      "activity" : "activity_name2",
      "controller" : "controller_name",
      "description" : "some description",
      "metadata" : {
        "lg.earth.viewSync.horizFov": "29",
        "lg.earth.viewSync.receive" : "true",
        "lg.earth.viewSync.yawOffset" : "36"
      }
    },
    "yet_another_live_activity_name" : {
      "activity" : "activity_name3",
      "controller" : "controller_name",
      "description" : "some description",
      "metadata" : {
        "key" : "value"
      }
    }
  },
  "live_activity_groups" : {
    "live_activity_group_name" : ["live_activity_name", "another_live_activity_name2" ],
    "another_live_activity_group_name" : ["yet_another_live_activity_name", "another_live_activity_name" ],
    "metadata" : {
      "key" : "value"
    }
  },
  "spaces" : {
    "space_name" : "some space_name",
    "live_activity_groups" : ["live_activity_group_name", "another_live_activity_group_name"],
    "metadata" : {
      "key" : "value"
    }
  }
}

```
