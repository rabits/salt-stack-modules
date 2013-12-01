// Configuration of jarmon
if(typeof(jarmon) === 'undefined') {
    var jarmon = {};
}

jarmon.TAB_RECIPES = {};
jarmon.CHART_RECIPES = {};

jarmon.config = {
    RRD_DIR:    '/rrd',
    RE_HOSTS:   /<a .+>([^<>]+[^.])\/<\/a>/g,
    RE_MODULES: /<a .+>([^<>]+[^-.])\/<\/a>/g,
    RE_RRD:     /<a .+>(.+rrd)<\/a>/g,

    hostname: null,
    draw_counter: null,

    // Lock that counts to zero and call a callback function
    LockCounter: function(init, callback) {
        this.counter = init;
        this.callback = callback;
        this.count = function(ticks) {
            if (ticks) {
                this.counter -= ticks;
            } else {
                this.counter--;
            }
            // If zero or less, trigerring callback
            if (this.counter <=0) {
                this.callback();
            }
        }
    },

    // Return HTTP Get variable value by name
    getQueryVariable: function(variable) {
        var query = window.location.search.substring(1);
        var vars = query.split("&");
        for (var i=0;i<vars.length;i++) {
            var pair = vars[i].split("=");
            if (pair[0] == variable) {
                return pair[1];
            }
        } 
        return undefined;
    },

    // Return array with all regexp captures
    getRegexpAllCaptures: function(data, re) {
        var matches = new Array()
        var match
        while (match = re.exec(data)) {
            matches.push(match[1])
        }
        return matches
    },

    // Return unique substrings of given regular expression capture
    getRegexpCaptureUniq: function(arr, re) {
        var patterns = []
        for(var i=0; i<arr.length; i++) {
            if (match = re.exec(arr[i])) {
                var value = match[1]
                // Push only if not exists already
                if (jQuery.inArray(value, patterns) == -1) {
                    patterns.push(value)
                }
            }
        }
        return patterns
    },

    // Called when we got hostname list
    handleHostnameList: function(data) {
        var hostnames = this.getRegexpAllCaptures(data, this.RE_HOSTS)
        for (var i=0; i<hostnames.length; i++) {
            var link = (hostnames[i] !== this.hostname) ? '<a href="?host=' + hostnames[i] + '">' + hostnames[i] + '</a>' : '<b>' + hostnames[i] + '</b>';
            jQuery("#host_list").append('<li>' + link + '</li>');
        }
    },

    // Called when we got new hostname and need to get the list of modules for hostname
    handleModuleList: function(data) {
        var modules = this.getRegexpAllCaptures(data, this.RE_MODULES);
        this.draw_counter = new this.LockCounter(modules.length, this.draw); // Will draw when all modules stopped working
        for (var i=0; i<modules.length; i++) {
            this.addModule(modules[i], i);
        }
    },

    // Called when we got new metrics list for given module for  hostname
    handleMetricsList: function(data, module, pos) {
        this.addMetrics(this.getRegexpAllCaptures(data, this.RE_RRD), module, pos)
    },

    // Called when new module for hostname has been parsed
    addModule: function(module, pos) {
        jQuery.get(this.RRD_DIR + '/' + this.hostname + '/' + module + '/', function (data) { jarmon.config.handleMetricsList(data, module, pos); } )
    },

    // Called when we got metrics list for given module
    addMetrics: function(metrics, module, pos) {
        var name = module.split('-')[0];
        if( typeof(jarmon_modules[name]) == 'object' ) {
            var obj = {
                title: name.toUpperCase() + ((name === module) ? '' : (' ' + module.replace(name+'-',''))) + ' (' + this.hostname + ')',
                options: jarmon_modules[name].options,
                data: []
            };
            if( typeof(jarmon_modules[name].filldata) == 'function' )
                jarmon_modules[name].filldata(metrics);
            for( var i in jarmon_modules[name].data ) {
                if(jQuery.inArray(jarmon_modules[name].data[i][0] + '.rrd', metrics) > -1) {
                    obj.data[i] = [];
                    for( var j=0; j<jarmon_modules[name].data[i].length; j++ )
                        obj.data[i][j] = jarmon_modules[name].data[i][j];
                    obj.data[i][0] = this.RRD_DIR + '/' + this.hostname + '/' + module + '/' + obj.data[i][0] + '.rrd';
                }
            }

            if( obj.data.length > 0 ) {
                // Adding tab to chart and redrawing
                if( typeof(jarmon.CHART_RECIPES[this.hostname+'_'+module]) == 'undefined' )
                    jarmon.CHART_RECIPES[this.hostname+'_'+module] = obj;
                if( typeof(jarmon.TAB_RECIPES[jarmon_modules[name].type]) != 'object' )
                    jarmon.TAB_RECIPES[jarmon_modules[name].type] = [];
                jarmon.TAB_RECIPES[jarmon_modules[name].type][pos] = this.hostname+'_'+module;
            } else {
                console.warn("Module \"" + module + "\" has no data (requested for \"" + this.hostname + "\")");
            }

        } else {
            console.warn("Module \"" + module + "\" is not supported (requested for \"" + this.hostname + "\")");
        } 
        this.draw_counter.count() // Counting module as finished execution
    },

    // Draw charts
    draw: function() {
        // Remove empty charts
        for( var i in jarmon.TAB_RECIPES ) {
            jarmon.TAB_RECIPES[i] = jarmon.TAB_RECIPES[i].filter(String);
        }
        // Build
        jarmon.buildTabbedChartUi($('.chart-container').remove(),
                                  jarmon.CHART_RECIPES,
                                  $('.tabbed-chart-interface'),
                                  jarmon.TAB_RECIPES,
                                  $('.chartRangeControl'));
    },

    // Lunch the application
    main: function() {
        // Fill list of hostnames
        jQuery.get(this.RRD_DIR, function(data) { jarmon.config.handleHostnameList(data); });

        // If we have "host" set in GET, display charts for this host
        this.hostname = this.getQueryVariable('host');
        if (this.hostname) {
            //Get list of modules for host and draw charts
            jQuery.get(this.RRD_DIR + '/' + this.hostname + '/', function (data) { jarmon.config.handleModuleList(data); } );
        }        
    }
};

jQuery(document).ready( function() {
    jarmon.config.main();
    setInterval(function() { jQuery('input[name="action"]').click() }, 3000000);
} );
