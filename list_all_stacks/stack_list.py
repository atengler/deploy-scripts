#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os

from copy import deepcopy
from collections import namedtuple
from datetime import datetime
from heatclient import client as heatclient
from keystoneauth1 import loading, session
from keystoneclient.v2_0 import client as keystoneclient
from threading import Thread

AUTH_URL = os.environ.get('OS_AUTH_URL', '')
USERNAME = os.environ.get('OS_USERNAME', '')
PASSWORD = os.environ.get('OS_PASSWORD', '')
PROJECT_ID = os.environ.get('OS_TENANT_ID', '')
PROJECT_NAME = os.environ.get('OS_TENANT_NAME', '')


class ClientManager(object):
    def __init__(self, auth_url, username, password, project_id, project_name):
        self.auth_url = auth_url
        self.username = username
        self.password = password
        self.project_id = project_id
        self.project_name = project_name

    @property
    def session(self):
        loader = loading.get_plugin_loader('password')
        options = {
            'auth_url': self.auth_url,
            'username': self.username,
            'password': self.password,
        }

        if self.project_id:
            options['project_id'] = self.project_id
        elif self.project_name:
            options['project_name'] = self.project_name

        auth = loader.load_from_options(**options)

        return session.Session(auth=auth)

    @property
    def keystone(self):
        return keystoneclient.Client(session=self.session)
    
    @property    
    def heat(self):
        return heatclient.Client('1', session=self.session)


def _print_table(rows):
    headers = rows[0]._fields
    lens = []
    for i in range(len(rows[0])):
      lens.append(len(max([x[i] for x in rows] + [headers[i]],key=lambda x:len(str(x)))))
    formats = []
    hformats = []
    for i in range(len(rows[0])):
      if isinstance(rows[0][i], int):
        formats.append("%%%dd" % lens[i])
      else:
        formats.append("%%-%ds" % lens[i])
      hformats.append("%%-%ds" % lens[i])
    pattern = " | ".join(formats)
    hpattern = " | ".join(hformats)
    separator = "-+-".join(['-' * n for n in lens])
    print hpattern % tuple(headers)
    print separator
    _u = lambda t: t.decode('UTF-8', 'replace') if isinstance(t, str) else t
    for line in rows:
        print pattern % tuple(_u(t) for t in line)


def _format_datetime(datetime_str):
    try:
        formatted_time = datetime.strptime(datetime_str, '%Y-%m-%dT%H:%M:%S').strftime('%c')
    except:
        formatted_time = datetime_str
    return formatted_time


def _process_project(manager, project):
    Row = namedtuple('Row', ['Author', 'Created', 'Name', 'Status'])
    manager.project_id = project.id
    try:
        stack_info = [{'name': stack.stack_name, 'creation_time': _format_datetime(stack.creation_time), 'status': stack.stack_status, 'author': ''}
                      for stack
                      in manager.heat.stacks.list()]
    
        for stack in stack_info:
            name_list = stack.get('name').split('-') or stack.get('name').split('_')
            if name_list:
                user = [str(user.username) + ', ' + str(user.email) for user in user_list if user.username == name_list[0]]
                if user:
                    stack['author'] = user[0]
    
        stack_rows = [Row(stack.get('author', ''), stack.get('creation_time', ''), stack.get('name', ''), stack.get('status', '')) for stack in stack_info]
        project_data = {
            'tenant_id': project.id,
            'tenant_name': project.name,
            'stack_info': stack_rows
        }
        print 'Stack lookup in project %s - %s - OK!' % (project.name, project.id)
    except Exception as e:
        project_data = {}
        print 'Stack lookup in project %s - %s - FAIL: %s' % (project.name, project.id, repr(e))

    return project_data


def _process_projects(manager, projects, store=None):
    if store is None:
        store = {}

    for project in projects:
        if project.enabled:
            store[project.id] = _process_project(manager, project)

    return store


def _threaded_process_projects(nthreads, manager, project_list):
    store = {}
    threads = []

    for i in range(nthreads):
        projects = project_list[i::nthreads]
        t = Thread(target=_process_projects, args=(manager, projects, store))
        threads.append(t)

    [ t.start() for t in threads ]
    [ t.join() for t in threads ]

    return store


def main():
    manager = ClientManager(AUTH_URL, USERNAME, PASSWORD, PROJECT_ID, PROJECT_NAME)
    project_list = manager.keystone.tenants.list()
    global user_list
    user_list = [user for user in manager.keystone.users.list()]

    projects = _threaded_process_projects(8, deepcopy(manager), project_list)
    clean_projects = [p for p in projects.values() if p.get('stack_info', [])]

    for project in clean_projects:
        heading = 'Project: %s - %s' % (project.get('tenant_name', ''), project.get('tenant_id', ''))
        underline = ''.join(['=' for char in heading])
        print '\n\n%s\n%s\n\n' % (heading, underline)
        _print_table(project.get('stack_info'))

    print '\n\n'


if __name__ == "__main__":
    main()

