#!/usr/bin/env python
# encoding: utf-8

import sys
import yaml


def get_report():
    """
    :rtype: list
    """
    tmp = yaml.load(sys.stdin)
    return [x for x in tmp if _is_noop_report(x)]


def _is_noop_report(report):
    """
    Takes report and checks for needed fields
    :param report: list
    :rtype: bool
    """
    try:
        return 'noop' in report['summary']['events']
    except (KeyError, AttributeError, TypeError):
        return False

if __name__ == "__main__":
    r1 = get_report()
    out = []
    for a in r1:
        out.append("\nTask {}: \n".format(a['task_name']))
        out.extend([" | {} : {}\n".format(x['source'], x['message'])
                    for x in a['summary']['raw_report']
                    if 'should be' in x['message']])

    print "".join(out)
