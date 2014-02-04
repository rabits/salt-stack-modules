// Modules for jarmon

// Add charts from memory module
jarmon_modules = {};

jarmon_modules['memory'] = {
    type: 'Memory',
    data: [
        ['memory-buffered', 0, 'Buffered', 'B'],
        ['memory-used', 0, 'Used', 'B'],
        ['memory-cached', 0, 'Cached', 'B'],
        ['memory-free', 0, 'Free', 'B']
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS,
                                     jarmon.Chart.STACKED_OPTIONS)
}

jarmon_modules['swap'] = {
    type: 'Memory',
    data: [
        ['swap-free', 0, 'Free', 'B'],
        ['swap-used', 0, 'Used', 'B'],
        ['swap-cached', 0, 'Cached', 'B'],
//        ['swap_io-in', 0, 'IO in', 'B'],
//        ['swap_io-out', 0, 'IO out', 'B'],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS,
                                     jarmon.Chart.STACKED_OPTIONS)
}

jarmon_modules['cpu'] = {
    type: 'CPU',
    data: [
//        ['cpu-idle', 0, 'Idle', '%'],
        ['cpu-interrupt', 0, 'Interrupt', '%'],
        ['cpu-nice', 0, 'Nice', '%'],
        ['cpu-softirq', 0, 'SoftIRQ', '%'],
        ['cpu-steal', 0, 'Steal', '%'],
        ['cpu-system', 0, 'System', '%'],
        ['cpu-user', 0, 'User', '%'],
        ['cpu-wait', 0, 'Wait', '%'],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS)
}

jarmon_modules['load'] = {
    type: 'System',
    data: [
        ['load', 'shortterm', '1 min', ''],
        ['load', 'midterm', '5 min', ''],
        ['load', 'longterm', '10 min', ''],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS)
}

jarmon_modules['processes'] = {
    type: 'System',
    data: [
        ['ps_state-blocked', 0, 'Blocked', '#'],
        ['ps_state-paging', 0, 'Paging', '#'],
        ['ps_state-running', 0, 'Running', '#'],
        ['ps_state-zombies', 0, 'Zombie', '#'],
        ['ps_state-stopped', 0, 'Stopped', '#'],
        ['ps_state-sleeping', 0, 'Sleeping', '#'],
//        ['fork_rate', 0, 'Fork rate', 'fork/s'],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS,
                                     jarmon.Chart.STACKED_OPTIONS)
}

jarmon_modules['disk'] = {
    type: 'Disk',
    data: [
        ['disk_merged', 'read', 'Merged R', 'Ops/s'],
        ['disk_merged', 'write', 'Merged W', 'Ops/s'],
        ['disk_octets', 'read', 'Octets R', 'B/s'],
        ['disk_octets', 'write', 'Octets W', 'B/s'],
        ['disk_ops', 'read', 'Ops R', 'Ops/s'],
        ['disk_ops', 'write', 'Ops W', 'Ops/s'],
        ['disk_time', 0, 'Time', 'Time/Op'],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS)
}

jarmon_modules['interface'] = {
    type: 'Network',
    data: [
        ['if_octets', 'tx', 'TX', 'B/s'],
        ['if_octets', 'rx', 'RX', 'B/s'],
        ['if_packets', 0, 'Packets', 'packets/s'],
        ['if_errors', 0, 'Errors', 'errors/s'],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS)
}

jarmon_modules['openvpn'] = {
    type: 'Network',
    data: [
        ['if_octets', 'rx', 'Octets RX', 'Bytes/s'],
        ['if_octets', 'tx', 'Octets TX', 'Bytes/s'],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS)
}

jarmon_modules['contextswitch'] = {
    type: 'System',
    data: [
        ['contextswitch', 0, 'Context Switch', 'sw/s'],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS,
                                     jarmon.Chart.STACKED_OPTIONS)
}

jarmon_modules['df'] = {
    type: 'Disk',
    data: [
        ['df_complex-free', 0, 'Free', 'B'],
        ['df_complex-reserved', 0, 'Reserved', 'B'],
        ['df_complex-used', 0, 'Used', 'B'],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS,
                                     jarmon.Chart.STACKED_OPTIONS)
}

jarmon_modules['vmem'] = {
    type: 'Memory',
    data: [
        ['vmpage_faults', 'minflt', 'Min faults', ''],
        ['vmpage_faults', 'majflt', 'Maj faults', ''],
        ['vmpage_io-memory', 'in', 'IO memory IN', ''],
        ['vmpage_io-memory', 'out', 'IO memory OUT', ''],
        ['vmpage_io-swap', 0, 'IO swap IN', ''],
        ['vmpage_io-swap', 0, 'IO swap OUT', ''],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS)
}

jarmon_modules['cpufreq'] = {
    type: 'CPU',
    filldata: function(metrics) {
        this.data = [];
        for( var i in metrics ) {
            this.data.push([metrics[i].slice(0,-4), 0, 'cpu-'+i, 'Hz']);
        }
    },
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS)
}

jarmon_modules['users'] = {
    type: 'System',
    data: [
        ['users', 0, 'Users', '#'],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS,
                                     jarmon.Chart.STACKED_OPTIONS)
}

jarmon_modules['uptime'] = {
    type: 'System',
    data: [
        ['uptime', 0, 'Uptime', 'Days', function (v) { return v/60/60/24; }],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS,
                                     jarmon.Chart.STACKED_OPTIONS)
}

jarmon_modules['tail'] = {
    type: 'Security',
    data: [
        ['counter-sshd-invalid_user', 0, 'SSH Invalid User', '#'],
        ['counter-sshd-failed_password', 0, 'SSH Failed Pwd', '#'],
        ['counter-sshd-accepted_password', 0, 'SSH Accepted Pwd', '#'],
        ['counter-sshd-accepted_publickey', 0, 'SSH Accepted Key', '#'],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS)
}

jarmon_modules['sensors'] = {
    type: 'System',
    filldata: function(metrics) {
        this.data = [];
        for( var i in metrics ) {
            this.data.push([metrics[i].slice(0,-4), 0, metrics[i].slice(0,-4), '#']);
        }
    },
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS)
}

jarmon_modules['ping'] = {
    type: 'Network',
    filldata: function(metrics) {
        this.data = [];
        for( var i in metrics ) {
            if( metrics[i].split('-')[0] != 'ping_stddev' )
                this.data.push([metrics[i].slice(0,-4), 0, metrics[i].slice(5,-4), 'ms']);
        }
    },
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS)
}

jarmon_modules['tcpconns'] = {
    type: 'Network',
    data: [
        ['tcp_connections-CLOSING', 0, 'CLOSING', ''],
        ['tcp_connections-SYN_SENT', 0, 'SYN_SENT', ''],
        ['tcp_connections-LISTEN', 0, 'LISTEN', ''],
        ['tcp_connections-TIME_WAIT', 0, 'TIME_WAIT', ''],
        ['tcp_connections-SYN_RECV', 0, 'SYN_RECV', ''],
        ['tcp_connections-CLOSE_WAIT', 0, 'CLOSE_WAIT', ''],
        ['tcp_connections-CLOSED', 0, 'CLOSED', ''],
        ['tcp_connections-LAST_ACK', 0, 'LAST_ACK', ''],
        ['tcp_connections-FIN_WAIT1', 0, 'FIN_WAIT1', ''],
        ['tcp_connections-FIN_WAIT2', 0, 'FIN_WAIT2', ''],
        ['tcp_connections-ESTABLISHED', 0, 'ESTABLISHED', ''],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS,
                                     jarmon.Chart.STACKED_OPTIONS)
}

jarmon_modules['nut'] = {
    type: 'Power',
    data: [
        ['frequency-input', 0, 'Input freq', 'Hz'],
        ['percent-charge', 0, 'Charge', '%'],
        ['percent-load', 0, 'Load',  '%'],
        ['temperature-ups', 0, 'Temp', 'C'],
        ['voltage-battery', 0, 'Battery V', 'V'],
        ['voltage-input', 0, 'Input V', 'V'],
        ['voltage-output', 0, 'Output V', 'V'],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS)
}

jarmon_modules['conntrack'] = {
    type: 'Network',
    data: [
        ['conntrack', 0, 'Entries', '#'],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS,
                                     jarmon.Chart.STACKED_OPTIONS)
}

jarmon_modules['nginx'] = {
    type: 'Network',
    data: [
        ['nginx_connections-active', 0, 'Active Conn', '#'],
        ['nginx_connections-reading', 0, 'Reading Conn', '#'],
        ['nginx_connections-waiting', 0, 'Waiting Conn', '#'],
        ['nginx_connections-writing', 0, 'Writing Conn', '#'],
        ['nginx_requests', 0, 'Requests', '#'],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS)
}

jarmon_modules['video_load'] = {
    type: 'Video',
    data: [
        ['gauge-load', 0, 'Load', '%'],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS)
}

jarmon_modules['video_freq'] = {
    type: 'Video',
    data: [
        ['gauge-cpu', 0, 'CPU Freq', 'Hz'],
        ['gauge-mem', 0, 'MEM Freq', 'Hz'],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS)
}

jarmon_modules['video_temp'] = {
    type: 'Video',
    data: [
        ['temperature', 0, 'Temp', 'C'],
    ],
    options: jQuery.extend(true, {}, jarmon.Chart.BASE_OPTIONS)
}
