// Berkeley Open Infrastructure for Network Computing
// http://boinc.berkeley.edu
// Copyright (C) 2005 University of California
//
// This is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation;
// either version 2.1 of the License, or (at your option) any later version.
//
// This software is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU Lesser General Public License for more details.
//
// To view the GNU Lesser General Public License visit
// http://www.gnu.org/copyleft/lesser.html
// or write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

// The structure of the memory segment shared between
// the feeder and schedulers
// This is essentially a cache of DB contents:
// small static tables like app_version,
// and a queue of results waiting to be sent.

#ifndef _SCHED_SHMEM_H_
#define _SCHED_SHMEM_H_

#include "boinc_db.h"
#include "hr_info.h"

// the following must be at least as large as DB tables
// (counting only non-deprecated entries for the current major version)
// Increase as needed
//
#define MAX_PLATFORMS       50
#define MAX_APPS            10
#define MAX_APP_VERSIONS    50
#define MAX_ASSIGNMENTS     10

// Default number of work items in shared mem.
// You can configure this in config.xml (<shmem_work_items>)
// If you increase this above 100,
// you may exceed the max shared-memory segment size
// on some operating systems.
//
#define MAX_WU_RESULTS      100

// values of WU_RESULT.state
#define WR_STATE_EMPTY   0
#define WR_STATE_PRESENT 1
// If neither of the above, the value is the PID of a scheduler process
// that has this item reserved

// a workunit/result pair
struct WU_RESULT {
    int state;
    int infeasible_count;
    bool need_reliable;		// try to send to a reliable host
    WORKUNIT workunit;
    int resultid;
    int time_added_to_shared_memory;
    int result_priority;
    double fpops_size;      // measured in stdevs
};

// this struct is followed in memory by an array of WU_RESULTS
//
struct SCHED_SHMEM {
    bool ready;             // feeder sets to true when init done
        // the following fields let the scheduler make sure
        // that the shared mem has the right format
    int ss_size;            // size of this struct, including WU_RESULT array
    int platform_size;      // sizeof(PLATFORM)
    int app_size;           // sizeof(APP)
    int app_version_size;   // sizeof(APP_VERSION)
    int assignment_size;    // sizeof(ASSIGNMENT))
    int wu_result_size;     // sizeof(WU_RESULT)
    int nplatforms;
    int napps;
    double app_weights;
    int napp_versions;
    int nassignments;
    int max_platforms;
    int max_apps;
    int max_app_versions;
    int max_assignments;
    int max_wu_results;
    PERF_INFO perf_info;
    PLATFORM platforms[MAX_PLATFORMS];
    APP apps[MAX_APPS];
    APP_VERSION app_versions[MAX_APP_VERSIONS];
    ASSIGNMENT assignments[MAX_ASSIGNMENTS];
    WU_RESULT wu_results[0];

    void init(int nwu_results);
    int verify();
    int scan_tables();
    bool no_work(int pid);
    void restore_work(int pid);
    void show(FILE*);

    APP* lookup_app(int);
    APP_VERSION* lookup_app_version(int appid, int platform);
    PLATFORM* lookup_platform_id(int);
    PLATFORM* lookup_platform(char*);
};

#endif
