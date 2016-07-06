#!/usr/bin/env python

from ansible.module_utils.basic import AnsibleModule
from subprocess import Popen, PIPE
from os import path
import re
import yaml

def parse_verify_output(output_lines, pkg_name, pkg_ver=None,
                        ex_re_list=None, cmd_md5sum=False):
    result = []
    for line in output_lines:
        if cmd_md5sum:
            parts = line.split(': ')
        else:
            parts = line.split()
            parts.reverse()
        if ex_re_list:
            skip_line = False
            for elem in ex_re_list:
                regex = None
                if type(elem) is dict:
                    if elem['package_name'] == pkg_name:
                        if 'package_version' in elem:
                            if elem['package_version'] == pkg_ver:
                                regex = elem['exclude_regex']
                        else:
                            regex = elem['exclude_regex']
                else:
                    regex = elem;
                if regex:
                    if type(regex) is list:
                        for r in regex:
                            if re.search(r, parts[0]):
                                skip_line = True
                                break
                    elif re.search(regex, parts[0]):
                        skip_line = True
                if skip_line:
                    break
            if skip_line:
                continue
        # c - config file flag
        if len(parts) == 3 and parts[1] == 'c':
            continue
        # parts[0][2] - md5 checksum fail flag
        if cmd_md5sum or parts[-1][2] == '5':
            file = parts[0]
            verify_details = parts[-1]
            result.append({'file': file, 'details': verify_details})
    return result


def main():
    exclude = ['^\.?/?etc/',
               '^\.?/?root/',
               '\.py[co]$',
               '/usr/share/openstack-dashboard/static/dashboard/manifest.json'
              ]
    module = AnsibleModule(
        argument_spec=dict(
            exclude_filter_file={'required': False, 'default': None}))
    if path.exists('/etc/redhat-release'):
        cmd = 'rpm -qa --qf "%{NAME}\\t%{EPOCH}\\t%{VERSION}\\t%{RELEASE}\\n"'
        distr = 'centos'
    elif path.exists('/usr/bin/lsb_release'):
        cmd = "dpkg-query -W -f='${Package}\\t${Version}\\n'"
        distr = 'ubuntu'
    p = Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE)
    out, err = p.communicate()
    out = out.splitlines()
    err = err.splitlines()
    if p.returncode:
        module.fail_json(msg='command exited non-zero', cmd=cmd,
                         rc=p.returncode, out_lines=out, err_lines=err)
    result = []
    if module.params['exclude_filter_file']:
        with open(module.params['exclude_filter_file'],'r') as f:
            content = f.read()
            if content:
                exclude += yaml.load(content)
    for line in out:
        item = {}
        md5_errors = []
        cmd_md5sum = False
        if distr == 'centos':
            pkg_name, pkg_epoch, pkg_version, pkg_release = line.split('\t')
            if pkg_epoch == '0' or pkg_epoch == '(none)':
                pkg_verstr = '%s-%s' % (pkg_version, pkg_release)
            else:
                pkg_verstr = '%s:%s-%s' % (pkg_epoch, pkg_version, pkg_release)
            cmd = 'nice -n 19 ionice -c 3 rpm --verify %s' % pkg_name
        elif distr == 'ubuntu':
            pkg_name, pkg_verstr = line.split('\t')
            dpkg = [s for s in out if s.startswith('dpkg\t')][0]
            dpkg_ver = dpkg.split('\t')[1]
            if dpkg_ver >= '1.17':
                cmd = 'nice -n 19 ionice -c 3 dpkg --verify %s' % pkg_name
            else:
              if path.exists('/var/lib/dpkg/info/%s:amd64.md5sums' % pkg_name):
                md5_file = '/var/lib/dpkg/info/%s:amd64.md5sums'
              elif path.exists('/var/lib/dpkg/info/%s.md5sums' % pkg_name):
                md5_file = '/var/lib/dpkg/info/%s.md5sums'
              if md5_file:
                  cmd = ('cd /; nice -n 19 ionice -c 3 md5sum --quiet -c '
                         '%s 2>&1') % md5_file
                  cmd_md5sum = True
              else:
                  # no md5 file, skipping
                  continue
        item['package_name'] = pkg_name
        item['package_version'] = pkg_verstr
        p = Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE)
        verify_out, verify_err = p.communicate()
        verify_out = verify_out.splitlines()
        if verify_out:
            md5_errors = parse_verify_output(verify_out, pkg_name,
                pkg_ver=pkg_verstr, ex_re_list=exclude, cmd_md5sum=cmd_md5sum)
        if md5_errors:
            item['md5_errors'] = md5_errors
            result.append(item)
    changed = True if result else False
    module.exit_json(changed=changed, result=result)

if __name__ == '__main__':
    main()
