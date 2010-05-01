import hashlib
from ConfigParser import ConfigParser
from simpycity import config
from model import *

in_config = ConfigParser()
in_config.readfp(open('settings.conf'))
items = dict(in_config.items('database'))

config.host = items['host']
config.port = items['port']
config.user = items['user']
config.password = items['password']
config.database = items['database']

PER_PAGE = 20

class Controller():

    def read_config(self):
        in_config = ConfigParser()
        in_config.readfp(open('settings.conf'))
        out_config = dict([('idiot_' + x[0], x[1]) for x in \
            in_config.items('idiot')])
        if self.logged():
            out_config['logged'] = True
            out_config['username'] = self.session.username
        return out_config

    def logged(self):
        if hasattr(self.session,'logged_in') and self.session.logged_in and \
            User.check_login(self.session.username, self.session.password):
            return True
        else:
            return False

    def browse(self, page):
        if not self.logged():
            results = Project.get_public_project_page(page, PER_PAGE)
        else:
            results = Project.get_user_project_page(page, PER_PAGE,
                self.session.username)
        self.config['projects'] = results
        return self.render.browse(self.config)

    def issue(self, issue_id):
        # TODO
        # Check if issue is part of a project user is attached to.
        # If so, display it, otherwise, deny.
        pass

    def project(self, project_name):
        if (not self.logged() and \
            Project.is_public(project_name).fetchall()[0][0] is True) or \
            (self.logged() and \
            Project.has_access(project_name, self.session.username) is True):
            result = Project.get(project_name)
            self.config['project'] = result.fetchall()[0]
            result = Project.get_issue_page(project_name, 1, PER_PAGE)
            self.config['issues'] = result
        else:
            self.config['error'] = "You do not have permission to view this project."
        return self.render.project(self.config)

    def project_issues(self, project_name, page):
        if (not self.logged() and \
            Project.is_public(project_name).fetchall()[0][0] is True) or \
            (logged(self.session) and \
            Project.has_access(project_name, self.session.username) is True):
            result = Project.get(project_name)
            self.config['project'] = result.fetchall()[0]
            result = Project.get_issue_page(project_name, page, PER_PAGE)
            self.config['issues'] = result
        else:
            self.config['error'] = "You do not have permission to view this project."
        return self.render.project_issues(self.config)

    def user(self, username):
        # TODO
        # Display a user profile.
        pass

    def admin(self):
        # TODO
        # Admin panel
        pass

    def login(self, username, password):
        if User.login(username, password):
            self.session.logged_in = True
            self.session.username = username
            self.session.password = hashlib.md5(password).hexdigest()
            return session
        else:
            return session

    def __init__(self, session, render):
        self.session = session
        self.render = render
        self.config = self.read_config()
        # Initialize common stuff here

