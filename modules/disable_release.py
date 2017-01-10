#!/usr/bin/python

from ansible.module_utils.basic import AnsibleModule
from fuelclient.objects.release import Release


class ReleasePatched(Release):
    def get_self(self):
        url = self.instance_api_path.format(self.id)
        return self.connection.get_request(url)

    def update_self(self, data):
        url = self.instance_api_path.format(self.id)
        self.connection.put_request(url, data)


def main():
    module = AnsibleModule(
        argument_spec=dict(
            release=dict(required=True, type='str'),
        ))

    release = module.params['release']

    id = 0
    changed = False
    try:
        while True:
            id += 1
            r = ReleasePatched(id)
            data = r.get_self()

            if not data['name'] == release:
                continue

            if data['state'] != 'unavailable':
                data['state'] = 'unavailable'
                r.update_self(data)
                changed = True
            break
    except:
        pass

    module.exit_json(changed=changed, result=0)


if __name__ == '__main__':
    main()
