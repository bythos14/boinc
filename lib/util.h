// The contents of this file are subject to the Mozilla Public License
// Version 1.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS"
// basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
// License for the specific language governing rights and limitations
// under the License.
//
// The Original Code is the Berkeley Open Infrastructure for Network Computing.
//
// The Initial Developer of the Original Code is the SETI@home project.
// Portions created by the SETI@home project are Copyright (C) 2002, 2003
// University of California at Berkeley. All Rights Reserved.
//
// Contributor(s):
//

#include <ctime>
#include <cstdlib>
#include <cmath>

#ifndef _UTIL_H_
#define _UTIL_H_

extern int double_to_ydhms (double x, int smallest_timescale, char *buf);
extern void get_byte_string(double nbytes, double total_bytes, char* str, int len);
extern double dtime();
extern void boinc_sleep(double);
extern int parse_command_line( char *, char ** );
extern int lock_file(char*);
extern void c2x(char *what);
extern void strip_whitespace(char *str);
extern void unescape_url(char *url);
extern void escape_url(char *in, char*out);
extern void escape_url_readable(char* in, char* out);
extern void canonicalize_master_url(char *url);
extern void safe_strncpy(char*, char*, int);
#define safe_strcpy(x, y) safe_strncpy(x, y, sizeof(x))
#define safe_strcat(x, y) if (strlen(x)+strlen(y)<sizeof(x)) strcat(x, y)
extern char* timestamp();

#ifndef max
#define max(a,b)            (((a) > (b)) ? (a) : (b))
#endif

#ifndef min
#define min(a,b)            (((a) < (b)) ? (a) : (b))
#endif

#define SECONDS_PER_DAY 86400

static inline double drand() {
    return (double)rand()/(double)RAND_MAX;
}

// return a random integer in the range [rmin,rmax)
static inline double rand_range(double rmin, double rmax)
{
    if (rmin < rmax)
        return drand() * (rmax-rmin) + rmin;
    else
        return rmin;
}

// return a random integer in the range [MIN,min(e^n,MAX))
int calculate_exponential_backoff(const char* debug_descr, int n, double MIN, double MAX, double factor=1.0);
extern bool debug_fake_exponential_backoff;

#endif
