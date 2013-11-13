#!/usr/bin/python
'''
Additional utils

:maintainer:    Rabit <home@rabits.org>
:maturity:      new
:depends:       state
:platform:      all
'''

def state_list():
    '''
    Returns list of current state on the node

    CLI Example::

        salt '*' additional.state_list
    '''
    import salt.state
    st_ = salt.state.HighState(__opts__)
    top = st_.get_top()
    return st_.top_matches(top)

def state_in(check, env=None, **kwargs):
    '''
    Return True if all check-modules in current state

    CLI Example::

        salt '*' additional.state_in 'check={"nginx", "collectd"}' env=master
    '''
    import salt.state
    from operator import add
    check = set(check)
    st_ = salt.state.HighState(__opts__)
    top = st_.get_top()
    match = st_.top_matches(top)
    if env != None:
        if env in match:
            return check.issubset(set(match[env]))
    else:
        for env in match:
            if check.issubset(set(match[env])):
                return True
    return False

def sd_list():
    '''
    Return list of sd sata disk devices

    CLI Example::

        salt '*' additional.sd_list
    '''
    import os
    return [name for name in os.listdir('/sys/block') if name.startswith('sd') ]

def substring_search(what, where):
    '''
    Return True if substring is placed in array of gpus

    CLI Example::

        salt '*' additional.substring_search 'Radeon' [{'model':'asd Radeon asdds'}]
    '''
    return any(what in s['model'] for s in where)
